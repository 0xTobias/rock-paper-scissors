// SPDX-License-Identifier: MIT
// An example of a consumer contract that relies on a subscription for funding.
pragma solidity ^0.8.4;
import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract RockPaperScissors is VRFConsumerBaseV2 {
    struct UserBet {
        uint8 bet;
        uint256 round;
        bool claimed;
        bool exists;
    }

    struct RoundResult {
        uint256 round;
        uint8 result;
    }

    event RoundEnded(uint256 round, uint8 result);

    error RoundLost(uint8 userBet, uint8 roundResult, uint256 round);

    VRFCoordinatorV2Interface COORDINATOR;
    LinkTokenInterface LINKTOKEN;

    // Your subscription ID.
    uint64 s_subscriptionId;

    // Rinkeby coordinator. For other networks,
    // see https://docs.chain.link/docs/vrf-contracts/#configurations
    address vrfCoordinator = 0x6168499c0cFfCaCD319c818142124B7A15E857ab;

    // Rinkeby LINK token contract. For other networks,
    // see https://docs.chain.link/docs/vrf-contracts/#configurations
    address link = 0x01BE23585060835E02B77ef475b0Cc51aA1e0709;

    // The gas lane to use, which specifies the maximum gas price to bump to.
    // For a list of available gas lanes on each network,
    // see https://docs.chain.link/docs/vrf-contracts/#configurations
    bytes32 keyHash =
        0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc;

    // Depends on the number of requested values that you want sent to the
    // fulfillRandomWords() function. Storing each word costs about 20,000 gas,
    // so 100,000 is a safe default for this example contract. Test and adjust
    // this limit based on the network that you select, the size of the request,
    // and the processing of the callback request in the fulfillRandomWords()
    // function.
    uint32 callbackGasLimit = 100000;

    uint16 requestConfirmations = 3;

    uint32 numWords = 1;

    uint256 public s_requestId;
    address s_owner;

    mapping(address => mapping(uint256 => UserBet)) userBets;
    mapping(uint256 => uint8) results;

    using Counters for Counters.Counter;
    Counters.Counter private _currentRound;

    uint256 roundBets = 0;
    uint256 minRoundBets;

    uint256 betAmount = 0.01 ether;

    constructor(
        uint64 subscriptionId,
        address owner,
        uint256 _minRoundBets
    ) VRFConsumerBaseV2(vrfCoordinator) {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        LINKTOKEN = LinkTokenInterface(link);
        s_owner = owner;
        s_subscriptionId = subscriptionId;
        minRoundBets = _minRoundBets;
    }

    function shoot(uint8 bet) public payable {
        require(bet <= 2, "Invalid bet placed");
        require(msg.value == betAmount, "Invalid bet amount sent");
        require(
            !userBets[msg.sender][_currentRound.current()].exists,
            "Bet already placed for this round"
        );
        userBets[msg.sender][_currentRound.current()] = UserBet(
            bet,
            _currentRound.current(),
            false,
            true
        );
        if (++roundBets >= minRoundBets) {
            requestRandomWords();
        }
    }

    function claimPrize(uint256 round) public {
        require(round < _currentRound.current(), "Round not done yet");
        UserBet memory userBet = getUserBet(round);
        uint8 roundResult = getRoundResult(round);
        if (userBet.exists && userBet.bet == roundResult && !userBet.claimed) {
            // userBet.claimed = true;
            (userBets[msg.sender][round]).claimed = true;
            (bool sent, bytes memory data) = msg.sender.call{
                value: betAmount * 2
            }("");
            require(sent, "Failed to send Ether");
        } else {
            revert RoundLost(userBet.bet, roundResult, round);
        }
    }

    function getUserBets(address userAddress)
        public
        view
        returns (UserBet[] memory)
    {
        UserBet[] memory userBetsArray = new UserBet[](
            countUserBets(userAddress)
        );
        uint256 currentElement = 0;
        for (uint256 i; i <= _currentRound.current(); i++) {
            UserBet memory bet = getUserBet(i, userAddress);
            if (bet.exists) {
                userBetsArray[currentElement] = bet;
                currentElement++;
            }
        }
        return userBetsArray;
    }

    function getUserBets() public view returns (UserBet[] memory) {
        UserBet[] memory userBetsArray = new UserBet[](
            countUserBets(msg.sender)
        );
        uint256 currentElement = 0;
        for (uint256 i; i <= _currentRound.current(); i++) {
            UserBet memory bet = getUserBet(i);
            if (bet.exists) {
                userBetsArray[currentElement] = bet;
                currentElement++;
            }
        }
        return userBetsArray;
    }

    function countUserBets(address userAddress)
        internal
        view
        returns (uint256)
    {
        uint256 count = 0;
        for (uint256 i; i <= _currentRound.current(); ++i) {
            if (getUserBet(i, userAddress).exists) {
                ++count;
            }
        }
        return count;
    }

    function getUserBet(uint256 round, address userAddress)
        public
        view
        returns (UserBet memory)
    {
        return userBets[userAddress][round];
    }

    function getUserBet(uint256 round) public view returns (UserBet memory) {
        return userBets[msg.sender][round];
    }

    // Assumes the subscription is funded sufficiently.
    function requestRandomWords() internal {
        // Will revert if subscription is not set and funded.
        s_requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
    }

    function fulfillRandomWords(
        uint256, /* requestId */
        uint256[] memory randomWords
    ) internal override {
        uint8 result = uint8(randomWords[0] % 3);
        uint256 currentRound = _currentRound.current();
        results[currentRound] = result;
        _currentRound.increment();
        emit RoundEnded(currentRound, result);
    }

    function getRoundResult(uint256 round) public view returns (uint8) {
        require(round < _currentRound.current(), "Round not ran yet.");
        return results[round];
    }

    function getRoundResults() public view returns (RoundResult[] memory) {
        RoundResult[] memory roundResults = new RoundResult[](
            _currentRound.current()
        );
        for (uint256 i; i < _currentRound.current(); ++i) {
            uint8 roundResult = getRoundResult(i);
            roundResults[i] = RoundResult(i, roundResult);
        }
        return roundResults;
    }

    function getCurrentRound() public view returns (uint256) {
        return _currentRound.current();
    }

    modifier onlyOwner() {
        require(msg.sender == s_owner);
        _;
    }

    receive() external payable {}
}

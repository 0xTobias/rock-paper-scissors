import { useContractReader } from "eth-hooks";
import { ethers } from "ethers";
import React, { useState } from "react";
import { Button, Card, DatePicker, Divider, Input, Progress, Slider, Spin, Switch } from "antd";

/**
 * web3 props can be passed from '../App.jsx' into your local view component for use
 * @param {*} yourLocalBalance balance on current network
 * @param {*} readContracts contracts from current chain already pre-loaded using ethers contract module. More here https://docs.ethers.io/v5/api/contract/contract/
 * @returns react component
 **/
function Home({ yourLocalBalance, readContracts, tx, writeContracts, address }) {

  const [selectedOption, setSelectedOption] = useState();

  const options = [
    {
      id: 0,
      icon: "🪨",
      name: "Rock",
    },
    {
      id: 1,
      icon: "📰",
      name: "Paper",
    },
    {
      id: 2,
      icon: "✂️",
      name: "Scissors",
    },
  ]

  const getBetFromId = (id) => {
    const betInfo = options.find(op => op.id === id);
    return betInfo ? betInfo.name + " " + betInfo.icon : ""
  }

  const currentRound = useContractReader(readContracts, "RockPaperScissors", "getCurrentRound");
  const userBets = useContractReader(readContracts, "RockPaperScissors", "getUserBets(address)", [address]);
  const roundResults = useContractReader(readContracts, "RockPaperScissors", "getRoundResults");
  const roundResultsMap = roundResults && Object.assign({}, ...roundResults.map((round) => ({ [round.round]: round.result })));

  const shoot = async () => {
    const result = tx(writeContracts.RockPaperScissors.shoot(selectedOption, { value: ethers.utils.parseEther("0.01") }), update => {
    });
    console.log("awaiting metamask/web3 confirm result...", result);
    console.log(await result);
  }

  const claim = async (round) => {
    const result = tx(writeContracts.RockPaperScissors.claimPrize(round), update => {
    });
    console.log("awaiting metamask/web3 confirm result...", result);
    console.log(await result);
  }

  return (
    <div>
      <div style={{ border: "1px solid #cccccc", padding: 16, width: 400, margin: "auto", marginTop: 64 }}>
        <h2>🪨📰✂️</h2>
        <h4>Current round: {currentRound && currentRound.toNumber()}</h4>
        <div style={{ marginTop: "45px" }}>
          {options.map((op) =>
            <Button
              style={{
                height: "100px",
                width: "100px",
                marginLeft: "10px",
                marginRight: "10px",
                borderColor: (op.id === selectedOption) && "#40a9ff",
                color: (op.id === selectedOption) && "#40a9ff",
              }}
              onClick={() => { setSelectedOption(op.id) }}>
              <div style={{
                fontSize: "40px",
              }}>
                {op.icon}
              </div>
              <div>{op.name}</div>
            </Button>)}
          <div style={{ marginLeft: "10px", marginRight: "10px" }}>
            <Button onClick={shoot} type="primary" size="large" style={{ marginTop: "15px", width: "100%" }}>
              Shoot
            </Button>
          </div>
        </div>
      </div>
      <div style={{ border: "1px solid #cccccc", padding: 16, width: 400, margin: "auto", marginTop: 64 }}>
        <h2>Your bets</h2>
        <div>
          <div>
            <div className="user-bets-container" style={{ textAlign: "left" }}>
              <div className="bets-row">
                <span className="round bold">Round</span>
                <span className="bet bold">Your bet</span>
                <span className="result bold">Result</span>
                <span className="claim bold">Claim</span>
              </div>
              {userBets && userBets.map((bet) =>
                <div className="bets-row">
                  <span className="round">{bet.round.toNumber()}</span>
                  <span className="bet">{getBetFromId(bet.bet)}</span>
                  <span className="result">{roundResultsMap && getBetFromId(roundResultsMap[bet.round])}</span>
                  <span className="claim">{
                    (roundResultsMap && bet.bet === roundResultsMap[bet.round]) ?
                      <Button onClick={() => claim(bet.round)} type="primary" size="small" disabled={bet.claimed}>Claim</Button> : ""
                  }</span>
                </div>)}
            </div>
          </div>
        </div>
      </div>
    </div >
  );
}

export default Home;

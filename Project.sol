// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract StudyGroupBetting {

    struct Bet {
        address participant;
        uint256 betAmount;
        uint256 predictedScore;

        
    }

    mapping(address => Bet[]) public bets;
    mapping(uint256 => Bet[]) public quizBets;  // Mapping for storing bets for a specific quiz
    address public owner;
    uint256 public quizId;
    uint256 public poolBalance;
    bool public quizEnded;
    uint256 public correctScore;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    modifier quizNotEnded() {
        require(!quizEnded, "Quiz has already ended");
        _;
    }

    modifier quizEndedOnly() {
        require(quizEnded, "Quiz has not ended yet");
        _;
    }

    constructor() {
        owner = msg.sender;
        quizId = 0;
        poolBalance = 0;
        quizEnded = false;
    }

    // Function to place a bet on a specific quiz
    function placeBet(uint256 _predictedScore) external payable quizNotEnded {
        require(msg.value > 0, "Bet amount must be greater than zero");

        Bet memory newBet = Bet({
            participant: msg.sender,
            betAmount: msg.value,
            predictedScore: _predictedScore
        });

        bets[msg.sender].push(newBet);
        quizBets[quizId].push(newBet);
        poolBalance += msg.value;
    }

    // Function to end the quiz and set the correct score
    function endQuiz(uint256 _correctScore) external onlyOwner quizNotEnded {
        correctScore = _correctScore;
        quizEnded = true;
    }

    // Function to distribute the winnings to the winners
    function distributeWinnings() external onlyOwner quizEndedOnly {
        uint256 totalWinners = 0;
        uint256 totalWinnings = poolBalance;
        address[] memory winners = new address[](quizBets[quizId].length);
        uint256 winnerIndex = 0;

        // Identify winners
        for (uint256 i = 0; i < quizBets[quizId].length; i++) {
            if (quizBets[quizId][i].predictedScore == correctScore) {
                winners[winnerIndex] = quizBets[quizId][i].participant;
                totalWinners++;
                winnerIndex++;
            }
        }

        require(totalWinners > 0, "No winners in this quiz");

        // Calculate individual winnings
        uint256 winnerShare = totalWinnings / totalWinners;

        // Transfer winnings to winners
        for (uint256 i = 0; i < winnerIndex; i++) {
            payable(winners[i]).transfer(winnerShare);
        }

        // Reset for next quiz
        resetQuiz();
    }

    // Reset variables for the next quiz
    function resetQuiz() internal {
        quizId++;
        poolBalance = 0;
        quizEnded = false;
        delete quizBets[quizId];
    }

    // Function to withdraw contract balance by owner (in case of emergency)
    function withdraw(uint256 amount) external onlyOwner {
        require(amount <= address(this).balance, "Insufficient funds");
        payable(owner).transfer(amount);
    }

    // Fallback function to accept ether
    receive() external payable {}
}



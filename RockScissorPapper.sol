pragma solidity ^0.5.1;
    
contract RockScissorPapper {

    //Remark: oversimplified, does not count abort of players

    event Result(string msg);

    uint public state = 0;
    uint public min_deposit = 1000000000;
    
    // "0" - wait for 1st player to deposit => "1" (conditioned on 1st player deposited)  
    // "1" - wait for 2nd player to deposit => "2" (conditioned on 2nd player deposited)
    // "2" - wait for commitments => "3" (conditioned on both commiting)
    // "3" - wait for revealing commitments => "0" (conditioned on )

    address payable [2] public players;
    bytes32[2] public comms;
    
    // 1 - Rock
    // 2 - Scissor
    // 3 - Paper
    uint256[2] public actions; 
    


    // Deal with "0" and "1"
    function join() public payable {
        require (state == 0 || state == 1 && msg.value >= min_deposit);
        players[state] = msg.sender;
        state = state + 1;
        clear();
    }
    
    
    // Deal with "2"
    function commit(bytes32 cm) public {
        require (state == 2 && msg.sender == players[0] || msg.sender == players[1]);
        if (msg.sender == players[0]) {
            if (comms[0] == 0) { // Only give one chance of committing
                comms[0] = cm;
                if (comms[1] != 0) { // Move to next round if both commit
                    state = state + 1;
                }
            }
        } else {
            if (comms[1] == 0) { // Only give one chance of committing
                comms[1] = cm;
                if (comms[0] != 0) { // Move to next round if both commit
                    state = state + 1;
                }
            }
        }
    }
    
    
    // Deal with "3"
    function reveal(uint256 action, uint256 rnd) public payable {
        require (state == 3 && msg.sender == players[0] || msg.sender == players[1]);
        if (msg.sender == players[0]) {
            if (keccak256(abi.encodePacked(action, rnd)) == comms[0] && (action == 1 || action == 2 || action == 3)) {
                actions[0] = action;
                if (actions[1] != 0){
                   if (actions[0] != actions[1]) {
                       payout(actions[0], actions[1]);
                       state = 0;
                   } else {
                        emit Result("Dual");
                        state = 2;
                        clear();
                   }
                }
            } else { // 1st does not correctly open her commitment, pay 2nd
                players[1].transfer(address(this).balance); 
                state = 0;
            }
        } else {
            if (keccak256(abi.encodePacked(action, rnd)) == comms[1] && (action == 1 || action == 2 || action == 3)) {
                actions[1] = action;
                if (actions[0] != 0){
                   if (actions[0] != actions[1]) {
                       payout(actions[0], actions[1]);
                       state = 0;
                   } else {
                        emit Result("Dual");
                        state = 2;
                        clear();
                   }
                }
            } else { // 2nd does not correctly open her commitment, pay 1st
                players[0].transfer(address(this).balance);   
                state = 0;
            }
        }
    }
    
    
    function payout(uint256 a1, uint256 a2) public payable {
        if (a1==1 && a2==2) {
            players[0].transfer(address(this).balance);
            emit Result("1st wins");
        }
        if (a1==1 && a2==3) {
            players[1].transfer(address(this).balance); 
            emit Result("2nd wins");
        }
        if (a1==2 && a2==1) {
            players[1].transfer(address(this).balance); 
            emit Result("2nd wins");
        }
        if (a1==2 && a2==3) {
            players[0].transfer(address(this).balance);
            emit Result("1st wins");
        }
        if (a1==3 && a2==1) {
            players[0].transfer(address(this).balance);
            emit Result("1st wins");
        }
        if (a1==3 && a2==2) {
            emit Result("2nd wins");
            players[1].transfer(address(this).balance);
        }
    }
    
    
    function clear() private {
        comms[0] = 0; comms[1] = 0;
        actions[0] = 0; actions[1] = 0;
    }

}

package main

import (
	"encoding/json"
	"fmt"
	"strconv"

	"github.com/hyperledger/fabric/core/chaincode/shim"
	sc "github.com/hyperledger/fabric/protos/peer"
)

// Define the Smart Contract structure
type SmartContract struct {
}

type Token struct {
	Owner		string	`json:"Owner"`
	TotalSupply 	int	`json:"TotalSupply"`
	TokenName 	string	`json:"TokenName"`
	TokenSymbol 	string	`json:"TokenSymbol"`
	BalanceOf	map[string]int	`json:"BalanceOf"`
}

func (token *Token) initialSupply(){
	token.BalanceOf[token.Owner] = token.TotalSupply;
}

func (token *Token) transfer (_from string, _to string, _value int){
	if(token.BalanceOf[_from] >= _value){
		token.BalanceOf[_from] -= _value;
		token.BalanceOf[_to] += _value;
	}
}

func (token *Token) balance (_from string) int{
	return token.BalanceOf[_from]
}

func (token *Token) burn(_value int) {
	if(token.BalanceOf[token.Owner] >= _value){
		token.BalanceOf[token.Owner] -= _value;
		token.TotalSupply -= _value;
	}
}

func (token *Token) burnFrom(_from string, _value int) {
	if(token.BalanceOf[_from] >= _value){
		token.BalanceOf[_from] -= _value;
		token.TotalSupply -= _value;
	}
}

func (token *Token) mint(_value int) {

	token.BalanceOf[token.Owner] += _value;
	token.TotalSupply += _value;

}

func (s *SmartContract) Init(stub shim.ChaincodeStubInterface) sc.Response {
	return shim.Success(nil)
}

func (s *SmartContract) initLedger(stub shim.ChaincodeStubInterface, args []string) sc.Response {

	if len(args) != 3 {
                return shim.Error("Incorrect number of arguments. Expecting 2")
        }

	symbol:= args[0]
	name  := args[1]
	supply,_:= strconv.Atoi(args[2])

	token := &Token{
		Owner: "coinbase",
		TotalSupply: supply,
		TokenName: name,
		TokenSymbol: symbol,
		BalanceOf: map[string]int{}}

	token.initialSupply()

	tokenAsBytes, _ := json.Marshal(token)
	err := stub.PutState(symbol, tokenAsBytes)
	if err != nil {
		return shim.Error(err.Error())
	}
	fmt.Printf("Init %s \n", string(tokenAsBytes))

	return shim.Success(nil)
}

func (s *SmartContract) transfer(stub shim.ChaincodeStubInterface, args []string) sc.Response {

	if len(args) != 4 {
		return shim.Error("Incorrect number of arguments. Expecting 4")
	}
	_from 	:= args[1]
	_to	:= args[2]
	_amount,_	:= strconv.Atoi(args[3])
	if(_amount <= 0){
		return shim.Error("Incorrect number of amount")
	}

	tokenAsBytes,err := stub.GetState(args[0])
	if err != nil {
		return shim.Error(err.Error())
	}
	fmt.Printf("transferToken - begin %s \n", string(tokenAsBytes))

	token := Token{}

	json.Unmarshal(tokenAsBytes, &token)
	token.transfer(_from, _to, _amount)

	tokenAsBytes, err = json.Marshal(token)
	if err != nil {
		return shim.Error(err.Error())
	}
	err = stub.PutState(args[0], tokenAsBytes)
	if err != nil {
		return shim.Error(err.Error())
	}
	fmt.Printf("transferToken - end %s \n", string(tokenAsBytes))

	return shim.Success(nil)
}

func (s *SmartContract) getBalance(stub shim.ChaincodeStubInterface, args []string) sc.Response {

	if len(args) != 2 {
		return shim.Error("Incorrect number of arguments. Expecting 2")
	}

	tokenAsBytes,err := stub.GetState(args[0])
	if err != nil {
		return shim.Error(err.Error())
	}
	token := Token{}

	json.Unmarshal(tokenAsBytes, &token)
	amount := token.balance(args[1])
	value := strconv.Itoa(amount)
	fmt.Printf("%s balance is %s \n", args[1], value)
	//jsonVal, _ := json.Marshal(string(value))

	return shim.Success([]byte(value))
}

func (s *SmartContract) Invoke(stub shim.ChaincodeStubInterface) sc.Response {

	// Retrieve the requested Smart Contract function and arguments
	function, args := stub.GetFunctionAndParameters()
	// Route to the appropriate handler function to interact with the ledger appropriately
	if function == "balance" {
		return s.getBalance(stub, args)
	} else if function == "initLedger" {
		return s.initLedger(stub, args)
	} else if function == "transfer" {
		return s.transfer(stub, args)
	}

	return shim.Error("Invalid Smart Contract function name.")
}

// The main function is only relevant in unit test mode. Only included here for completeness.
func main() {

	// Create a new Smart Contract
	err := shim.Start(new(SmartContract))
	if err != nil {
		fmt.Printf("Error creating new Smart Contract: %s", err)
	}
}

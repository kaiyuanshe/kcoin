package main

import (
    "encoding/json"
    "fmt"
    "strconv"

    "github.com/hyperledger/fabric/core/chaincode/shim"
    sc "github.com/hyperledger/fabric/protos/peer"
    "bytes"
    "time"
    "strings"
)

// Define the Smart Contract structure
type SmartContract struct {
}

type Token struct {
    Owner       string         `json:"Owner"`
    TotalSupply int            `json:"TotalSupply"`
    TokenName   string         `json:"TokenName"`
    TokenSymbol string         `json:"TokenSymbol"`
    BalanceOf   map[string]int `json:"BalanceOf"`
}

func (token *Token) initialSupply() {
    token.BalanceOf[token.Owner] = token.TotalSupply;
}

func (token *Token) transfer(_from string, _to string, _value int) bool {
    if (token.BalanceOf[_from] >= _value) {
        token.BalanceOf[_from] -= _value;
        token.BalanceOf[_to] += _value;
        return true
    }
    return false
}

func (token *Token) balance(_from string) int {
    return token.BalanceOf[_from]
}

func (token *Token) burn(_value int) {
    if (token.BalanceOf[token.Owner] >= _value) {
        token.BalanceOf[token.Owner] -= _value;
        token.TotalSupply -= _value;
    }
}

func (token *Token) burnFrom(_from string, _value int) {
    if (token.BalanceOf[_from] >= _value) {
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

    if len(args) != 4 {
        return shim.Error("Incorrect number of arguments. Expecting 3")
    }

    symbol := args[0]
    name := args[1]
    owner := args[2]
    supply, _ := strconv.Atoi(args[3])

    if (len(symbol) == 0 || len(name) == 0 || len(owner) == 0) {
        return shim.Error("invalid parameters. The symbol, name and owner cannot be empty")
    }

    if (supply <= 0) {
        return shim.Error("Incorrect number of init supply, must be greater than 0")
    }

    exist, err0 := stub.GetState(symbol)
    if (err0 != nil) {
        return shim.Error(err0.Error())
    }
    if (exist != nil) {
        _msg := fmt.Sprintf("cannot init new token because token of name `%s` alreayd exists", symbol)
        fmt.Printf(_msg + " \n")
        return shim.Error(_msg)
    }

    token := &Token{
        Owner:       owner,
        TotalSupply: supply,
        TokenName:   name,
        TokenSymbol: symbol,
        BalanceOf:   map[string]int{}}

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
    _from := args[1]
    _to := args[2]
    _amount, _ := strconv.Atoi(args[3])
    if (_amount <= 0) {
        return shim.Error("Incorrect number of amount:" + args[3])
    }

    if (len(_from) == 0 || len(_to) == 0) {
        return shim.Error("Incorrect address. Both addresses must not be null or empty.")
    }

    tokenAsBytes, err := stub.GetState(args[0])
    if err != nil {
        return shim.Error(err.Error())
    }
    fmt.Printf("transferToken - begin %s \n", string(tokenAsBytes))

    token := Token{}

    json.Unmarshal(tokenAsBytes, &token)
    tr := token.transfer(_from, _to, _amount)
    if !tr {
        _msg := fmt.Sprintf("account %s doesn't have enough balance", _from)
        fmt.Printf(_msg + "\n")
        return shim.Error(_msg)
    }

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

    tokenAsBytes, err := stub.GetState(args[0])
    if err != nil {
        return shim.Error(err.Error())
    }
    token := Token{}

    json.Unmarshal(tokenAsBytes, &token)
    amount := token.balance(args[1])
    value := strconv.Itoa(amount)
    fmt.Printf("%s balance is %s \n", args[1], value)

    return shim.Success([]byte(value))
}

func (s *SmartContract) getBalanceList(stub shim.ChaincodeStubInterface, args []string) sc.Response {

    if len(args) < 2 {
        return shim.Error("Incorrect number of arguments. Expecting at least 2")
    }

    tokenAsBytes, err := stub.GetState(args[0])
    if err != nil {
        return shim.Error(err.Error())
    }
    token := Token{}
    m := make(map[string]int)

    json.Unmarshal(tokenAsBytes, &token)
    for i := 1; i < len(args); i++ {
        m[args[i]] = token.balance(args[i])
        fmt.Printf("%s balance is %s \n", args[i], m[args[i]])
    }
    balanceAsBytes, _ := json.Marshal(m)
    return shim.Success(balanceAsBytes)
}

func (s *SmartContract) batchHistoryQuery(stub shim.ChaincodeStubInterface, args []string) sc.Response {

    if len(args) < 1 {
        return shim.Error("Incorrect number of arguments. Expecting 1 or more")
    }

    var buffer bytes.Buffer
    buffer.WriteString("[")
    for i := 0; i < len(args); i++ {
        arr := strings.Split(args[i], "_")
        arg := [] string{arr[0], arr[1]}
        history := string(s.historyQuery(stub, arg).Payload)

        buffer.WriteString(history)
        fmt.Println("\n%s,for result:\n%s"+args[i],history)
        if i < len(args)-1 {
            buffer.WriteString(",")
        }
    }
    buffer.WriteString("]")

    return shim.Success(buffer.Bytes())
}

func (s *SmartContract) historyQuery(stub shim.ChaincodeStubInterface, args []string) sc.Response {

    if len(args) != 2 {
        return shim.Error("Incorrect number of arguments. Expecting 2")
    }

    it, err := stub.GetHistoryForKey(args[0])
    if err != nil {
        return shim.Error(err.Error())
    }
    var result, _ = getHistoryListResult(it, args[1])
    var buffer bytes.Buffer
    buffer.WriteString("{\"TotalBalance\":")
    buffer.WriteString("\"")
    buffer.Write(s.getBalance(stub, args).Payload)
    buffer.WriteString("\"")

    buffer.WriteString(",\"History\":")
    buffer.Write(result)

    buffer.WriteString("}")

    return shim.Success(buffer.Bytes())
}

func getHistoryListResult(resultsIterator shim.HistoryQueryIteratorInterface, eth_account string) ([]byte, error) {

    defer resultsIterator.Close()
    // buffer is a JSON array containing QueryRecords
    var buffer bytes.Buffer
    buffer.WriteString("[")

    bArrayMemberAlreadyWritten := false
    for resultsIterator.HasNext() {
        response, err := resultsIterator.Next()
        if err != nil {
            return nil, err
        }
        // filter history by eth_account
        tokenAsBytes := response.Value
        token := Token{}
        json.Unmarshal(tokenAsBytes, &token)
        supply, ok := token.BalanceOf[eth_account]
        if !ok {
            continue
        }

        // Add a comma before array members, suppress it for the first array member
        if bArrayMemberAlreadyWritten == true {
            buffer.WriteString(",")
        }
        //item, _ := json.Marshal(response.Value)
        //buffer.Write(item)
        // txid
        buffer.WriteString("{\"TxId\":")
        buffer.WriteString("\"")
        buffer.WriteString(response.TxId)
        buffer.WriteString("\"")

        //value
        // if it was a delete operation on given key, then we need to set the
        // corresponding value null. Else, we will write the response.Value
        //as-is (as the Value itself a JSON marble)
        if response.IsDelete {
            buffer.WriteString(", \"Value\":")
            buffer.WriteString("null")
        } else {
            buffer.WriteString(", \"Supply\":")
            buffer.WriteString(strconv.Itoa(supply))

            buffer.WriteString(", \"TokenSymbol\":")
            buffer.WriteString("\"")
            buffer.WriteString(token.TokenSymbol)
            buffer.WriteString("\"")
        }

        // time
        buffer.WriteString(", \"Timestamp\":")
        buffer.WriteString("\"")
        buffer.WriteString(time.Unix(response.Timestamp.Seconds, int64(response.Timestamp.Nanos)).String())
        buffer.WriteString("\"")

        buffer.WriteString("}")
        bArrayMemberAlreadyWritten = true
    }
    buffer.WriteString("]")
    return buffer.Bytes(), nil
}

func (s *SmartContract) Invoke(stub shim.ChaincodeStubInterface) sc.Response {

    // etrieve the requested Smart Contract function and arguments
    function, args := stub.GetFunctionAndParameters()
    fmt.Printf("Invoke request received, function: %s\n", function)
    fmt.Printf("Invoke request received, args: %s\n", args)
    var result sc.Response

    // Route to the appropriate handler function to interact with the ledger appropriately
    if function == "initLedger" {
        result = s.initLedger(stub, args)
    } else if function == "transfer" {
        result = s.transfer(stub, args)
    } else if function == "balance" {
        result = s.getBalance(stub, args)
    } else if function == "batchBalance" {
        result = s.getBalanceList(stub, args)
    } else if function == "historyQuery" {
        result = s.historyQuery(stub, args)
    } else if function == "batchHistoryQuery" {
        result = s.batchHistoryQuery(stub, args)
    } else {
        return shim.Error("Invalid Smart Contract function name.")
    }

    fmt.Printf("\n return result is %s \n", string(result.Payload))
    return result
}

// The main function is only relevant in unit test mode. Only included here for completeness.
func main() {

    // Create a new Smart Contract
    err := shim.Start(new(SmartContract))
    if err != nil {
        fmt.Printf("Error creating new Smart Contract: %s", err)
    }
}

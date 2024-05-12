#INCLUDE "TOTVS.CH"
#INCLUDE "PROTHEUS.CH"

/*
{
    "version": "0.0.1",
    "tables": [
        {
            "SA1": [
                {
                    "A1_FILIAL": "0101",
                    "A1_COD": "000001",
                    (...)
                },
                {
                    "A1_FILIAL": "0101",
                    "A1_COD": "000002",
                    (...)
                }
            ]
        },
        {
            "SB1": [
                {
                    "B1_FILIAL": "0101",
                    "B1_COD": "000002",
                    (...)
                },
                {
                    "B1_FILIAL": "0101",
                    "B1_COD": "000002",
                    (...)
                }
            ]
        }, 
        (...)
    ]
}
*/

User Function GJsonTab()

	Local bObject := {|| JsonObject():New()}
	Local oJson   := Eval(bObject)

	oJson["version"] := "0.0.1"
	oJson["tables"]  := {}

	aadd(oJson["tables"],GetJsonTab("DA0"))
	aadd(oJson["tables"],GetJsonTab("DA1"))

Return (oJson:ToJson())

/*
Exemplo
{
    "SA1": [
        {
            "A1_FILIAL": "0101",
            "A1_COD": "000001",
            (...)
        },
        {
            "A1_FILIAL": "0101",
            "A1_COD": "000002",
            (...)
        }
    ]
}
*/
Static Function GetJsonTab(cAlias)

	Local bObject := {|| JsonObject():New()}
	Local oJson   := Eval(bObject)
	Local aEstru  := (cAlias)->(DbStruct()) //[1] nome campo, [2] tipo ("C" (Caractere), "N" (Numérico), "L" (Lógico), "D" (Data) ou "M" (Memo)), [3] tamanho, [4] decimais
	Local nLim := 2 //limite registros

	dbselectarea(cAlias)
	(cAlias)->(dbgotop())

	oJson[cAlias] := {}

	while (cAlias)->(!eof()) .and. nLim > 0
		aadd(oJson[cAlias],GetJsonRow(cAlias,aEstru))
		nLim--
		(cAlias)->(dbskip())
	enddo

Return (oJson)
/*
{
    "A1_FILIAL": "0101",
    "A1_COD": "000001",
    (...)
}
*/
Static Function GetJsonRow(cAlias,aEstru)

	Local oJson := JsonObject():New()
	Local nX

	for nX := 1 to Len(aEstru)
		if !(SubStr(Alltrim(aEstru[nX][1]),4) $ "_SITUA,_HREXP,_MSEXP,USERLGA,USERLGI") //campos ignorados
			if aEstru[nX][2] == "D"
				oJson[aEstru[nX][1]] := DtoC(&(cAlias+"->"+aEstru[nX][1]))
			else
				oJson[aEstru[nX][1]] := &(cAlias+"->"+aEstru[nX][1])
			endif
		endif
	next nX

Return (oJson)


/*
{
    "branchId": "01",
    "code": "NAIR18",
    "name": "NAIR02",
    "shortName": "NAIR02",
    "type": 1,
    "strategicCustomerType": "F",
    "address": {
        "state": {
            "stateId": "SP"
        },
        "address": "AVENIDA SOUZA CRUZ",
        "city": {
            "cityDescription": "JARDIM ALVES CARMO"
        }
    }
}
*/

// CRIA O JSON QUE SERÁ ENVIADO NO CORPO (BODY) DA REQUISIÇÃO
//Static Function GetJson()
//
//	Local bObject := {|| JsonObject():New()}
//	Local oJson   := Eval(bObject)
//
//	oJson["code"]                               := "CLT024"
//	oJson["branchId"]                           := "01"
//	oJson["name"]                               := "MENIACX IMPORTAÇÕES CORP"
//	oJson["shortName"]                          := "MENIACX CORP"
//	oJson["type"]                               := 1
//	oJson["strategicCustomerType"]              := "F"
//	oJson["address"]                            := Eval(bObject)
//	oJson["address"]["state"]                   := Eval(bObject)
//	oJson["address"]["state"]["stateId"]        := "SP"
//	oJson["address"]["address"]                 := "AVENIDA SOUZA CRUZ"
//	oJson["address"]["city"]                    := Eval(bObject)
//	oJson["address"]["city"]["cityDescription"] := "JARDIM ALVES CARMO"
//
//
//Return (oJson:ToJson())



//--------
//RabbitMQ
//--------


//--> https://api.cloudamqp.com
//envia o JSON para o RabbitMQ
User Function SendRMQ()

	Local AMQP_ENDERECO := '172.24.42.4'
	Local AMQP_PORTA := 5672
	Local AMQP_USUARIO := 'jcopydxv'
	Local AMQP_SENHA := 'mQRqUgtmVnO43TyGSk4PCpf7UU3V0rIA'
	Local fixed_channel_id := 1

	Local oCarga   := Nil
	Local nI, nX
	Local cJSON := ""
	Local oProducer := Nil
	Local cExchange := 'cargaExchange'
	//Local cFila := 'carga'

	oCarga := JsonObject():New()
	cJSON := U_GJsonTab()
	oCarga:FromJson( cJSON )

	oProducer  := tAmqp():New( AMQP_ENDERECO, AMQP_PORTA, AMQP_USUARIO, AMQP_SENHA, fixed_channel_id ) //Cria um objeto tAMQP com um determinado AMQP Server.
	If Empty(oProducer:Error())

		oProducer:ExchangeDeclare( cExchange, "fanout", .F., .T., .F. )
		//oProducer:QueueDeclare( cFila, .T. /*bisDurable*/, .F. /*bisExclusive*/, .F. /*bisAutodelete*/ ) //Cria uma nova fila no AMQP Server.

		For nX:=1 to 3
			oProducer:QueueDeclare( 'PDV'+cValToChar(nX), .T. /*bisDurable*/, .F. /*bisExclusive*/, .F. /*bisAutodelete*/ ) //Cria uma nova fila no AMQP Server.
			oProducer:QueueBind( 'PDV'+cValToChar(nX), cExchange )
		Next nX

		If Empty(oProducer:Error())

			For nX:=1 To 10
				If ValType(oCarga) == "A"
					For nI := 1 To Len( oCarga )
						If ValType(oCarga[nI]) == "J"
							Conout("")
							Conout("CARGA -> " + cValToChar( nI ))
							Conout( oCarga[nI]:ToJson() )

							oProducer:BasicPublish( cExchange, '', .T., oCarga[nI]:ToJson() ) //Envia uma mensagem para o AMQP Server.
						EndIf
					Next nI
				ElseIf ValType(oCarga) == "J"
					Conout("")
					Conout("CARGA -> jReponse -> U_GJsonTab()")
					Conout( oCarga:ToJson() )

					oProducer:BasicPublish( cExchange, '', .T., oCarga:ToJson() ) //Envia uma mensagem para o AMQP Server.
				EndIf
			Next nX

		EndIf

	EndIf

	FreeObj( oProducer )
	FreeObj( oCarga )
Return

//recupera o JSON do RabbitMQ
User Function ReceiRMQ(cFila)

	Local AMQP_ENDERECO := '172.24.42.4'
	Local AMQP_PORTA := 5672
	Local AMQP_USUARIO := 'jcopydxv'
	Local AMQP_SENHA := 'mQRqUgtmVnO43TyGSk4PCpf7UU3V0rIA'
	Local fixed_channel_id := 1

	Local oConsumer := Nil
	Local nI
	Local oCarga := JsonObject():New()
	
	Default cFila := 'PDV1'

	oConsumer := TAMQP():New( AMQP_ENDERECO, AMQP_PORTA, AMQP_USUARIO, AMQP_SENHA, fixed_channel_id ) //Cria um objeto tAMQP com um determinado AMQP Server.

	If Empty(oConsumer:Error())

		oConsumer:QueueDeclare( cFila, .T., .F., .F. ) //Cria uma nova fila no AMQP Server.

		For nI := 1 To oConsumer:MessageCount()
			oConsumer:BasicConsume( cFila, .F. ) //Resgata uma mensagem no AMQP Server.

			oCarga:FromJson( oConsumer:Body )

			Conout("IMPORTANDO A CARGA -> " + cValToChar( nI ))
			Conout( oCarga:ToJson() )

			oConsumer:BasicAck( nI, .F. ) //Indica para a fila que voce recebeu e processou a mensagem com sucesso (acknowledge)
		Next nI

	EndIf

	FreeObj( oConsumer )
	FreeObj( oCarga )
Return



//--------
//Redis
//--------



//adiciona e recupera um JSON no Redis (via Append)
User Function ApndTstV()

	Local oRedisClient := Nil
	Local outParm      := Nil
	Local cCommand     := ''
	Local cParam   	   := ''

	oRedisClient:= tRedisClient():New()

	// Setup Redis connection
	oRedisClient:Connect("localhost", 6379, "")

	If oRedisClientent:lConnected
		// Set the field 'x' to the value 'aaa'
		cCommand := "set x ?"
		cParam   := U_GJsonTab()
		retVal := oRedisClient:Append(cCommand, cParam)

		ConOut("Return of ::Append(set) -- type '" + ValType(retVal) + "'")
		If (ValType(retVal) == 'O') .And. oRedisClient:lOk
			ConOut("Result: nReplyType " + cValToChar(retVal:nReplyType))
		Else
			ConOut("*** ERROR: Unexpected return of ::Append -- ValType() '" + ValType(retVal) + "'")
			Return .F.
		EndIf

		retVal := oRedisClient:GetReply(@outParm)

		// Will display .T., since ::GetReply() returns the status of the last ::Append()
		ConOut("Output of ::GetReply() " + cValToChar(outParm))

		// Will display the state of the Redis client object, after ::GetReply()
		If (ValType(retVal) == 'O') .And. oRedisClient:lOk
			ConOut("Return of ::GetReply(): nReplyType " + cValToChar(retVal:nReplyType))
		Else
			ConOut("*** ERROR: Unexpected return of ::GetReply -- ValType() '" + ValType(retVal) + "'")
			Return .F.
		EndIf

		// Just an empty line to separate matters
		ConOut("")

		// Get the value of field 'x'
		cCommand := "get x"
		retVal := oRedisClient:Append(cCommand)

		ConOut("Return of ::Append('" + cCommand + "') -- type ' " + ValType(retVal) + "'")
		If (ValType(retVal) == 'O') .And. oRedisClient:lOk
			ConOut("Return nReplyType: " + cValToChar(retVal:nReplyType))
		Else
			ConOut("*** ERROR:  Unexpected return of ::Append('" + cCommand + "') -- type ' " + ValType(retVal) + "'")
			Return .F.
		EndIf

		// Just an empty line to separate matters
		ConOut("")

		retVal := oRedisClient:GetReply(@outParm)

		If (ValType(retVal) == 'O') .And. oRedisClient:lOk
			ConOut("Return of ::GetReply(): nReplyType " + cValToChar(retVal:nReplyType))
		Else
			ConOut("*** ERROR: Unexpected return of ::GetReply -- ValType() '" + ValType(retVal) + "'")
			Return .F.
		EndIf

		ConOut("Result of ::GetReply(): type '" + ValType(outParm) + "'")
		ConOut("Result of ::GetReply(): '" + cValToChar(outParm) + "'")

		oRedisClient:Disconnect()
		FreeObj( oRedisClient )

		Return .T.
	EndIf

	FreeObj( oRedisClient )

Return .F.

//adiciona e recupera um JSON no Redis (via Exec)
User Function ExecSetGet()

	Local retVal := Nil
	Local cCommand := ''
	Local cParam   := ''
	Local cMsg := ''
	Local oRedisClient := Nil
	Local lRetVal := .T.
	Local key := DtoS(Date())+Left(Time(),2)+Substr(Time(),4,2)+Right(Time(),2)

	oRedisClient := tRedisClient():New()

	// Setup Redis connection
	lRetVal := oRedisClient:Connect("localhost", 6379, ""):lOk

	If .Not. lRetVal
		ConOut("Could not connect to Redis server")
		Return .F.
	EndIf

	cParam   := U_GJsonTab()
	cCommand := 'set '+key+' "'+cParam+'"'

	// Set the field
	oRedisClient:Exec(cCommand, cParam, @retVal)

	// If the execution wasn't fine
	If .Not. oRedisClient:lOk
		ConOut("Could not Exec(" + cCommand + ")")
		VarInfo("State of object: ", oRedisClient)
		oRdClient:Disconnect()
		Return .F.
	EndIf

	ConOut("Successful Exec('" + cCommand + "')")

	If ValType(retVal) != 'C'
		cMsg := cValToChar(retVal)
	Else
		cMsg := retVal
	EndIf

	ConOut("Exec() result: " + cMsg)
	VarInfo("State of the object: ", oRedisClient)


	// Get the value of field 'y'
	cCommand := 'get ' + key
	oRedisClient:Exec(cCommand, @retVal)

	// If the execution wasn't fine
	If .Not. oRedisClient:lOk
		ConOut("Could not Exec('" + cCommand + "')")
		VarInfo("State of object: ", oRedisCli)
		oRedisClient:Disconnect()
		Return .F.
	EndIf

	ConOut("Successful Exec('" + cCommand + "')")

	If ValType(retVal) != 'C'
		cMsg := cValToChar(retVal)
	Else
		cMsg := retVal
	EndIf

	ConOut("Exec() result: " + cMsg)
	VarInfo("State of the object: ", oRedisClient)

	oRedisClient:Disconnect()
	FreeObj( oRedisClient )

Return .T.

#INCLUDE "PROTHEUS.CH"
#INCLUDE "TOPCONN.CH"
#INCLUDE "FILEIO.CH"

Static cRedisServer     := SuperGetMV("MV_XREDEND",.F.,"127.0.0.1")  // Endereco do servidor do Redis
Static nRedisPort       := SuperGetMV("MV_XREDPOR",.F.,6379)         // Porta do servidor do Redis
Static cRedisAuth       := SuperGetMV("MV_XREDAUT",.F.,"")           // Autenticacao do Redis

Static cIpRabbitMQ		:= SuperGetMV("MV_XRMQIP ",.F.,"127.0.0.1") 	// Endereço do AMQP Server
Static nPortRabbitMQ	:= SuperGetMV("MV_XRMQPOR",.F.,5672)			// Porta do AMQP Server
Static cUserNameRMQ		:= SuperGetMV("MV_XRMQUSE",.F.,"cargatotvs")	// Usuário para logar na fila do AMQP Server
Static cPswRMQ			:= SuperGetMV("MV_XRMQPSW",.F.,"mQRqUgtmVnO43TyGSk4PCpf7UU3V0rIA") 	// Senha para logar na fila do AMQP Server
Static nChannelId		:= SuperGetMV("MV_XRMQCHA",.F.,1)				// Canal da comunicação com o AMQP Server
Static cNameExchange 	:= LOWER(SuperGetMV("MV_XRMQEXC",.F.,"cargatotvs")) // Nome da exchange do RabbitMQ

Static oRedis := Nil

#DEFINE PRT_ERROR(x)        ConOut(time() + " [Thr: " + Strzero(ThreadId(), 5) + "]" + " # ERROR # " + x) // LOG de erro
#DEFINE PRT_MSG(x)          ConOut(time() + " [Thr: " + Strzero(ThreadId(), 5) + "]" + "           " + x) // LOG de alerta/mensagem

#DEFINE ENTIRE		"1"  // carga inteira
#DEFINE INCREMENTAL	"2"  // carga incremental

//////////////////////////////////////////////////////////////////////////////////////////////////////////
/* Exemplo JSON 
{
    "version": "0.0.1",
    "tables": [
        {	
			"nametable": "SA1",
			"branches": "0101/0102/0103",
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
            "nametable": "SB1",
			"branches": "0101/0102/0103",
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
//////////////////////////////////////////////////////////////////////////////////////////////////////////

// Função para geração de carga no banco REDIS
User Function UREDISLR() //STFLOADRET

	Local cCmd := ""
	Local xRetCmd := Nil
	Local cParam := ""
	Local aParam := {}
	Local ckey := DtoS(Date())+Left(Time(),2)+Substr(Time(),4,2)+Right(Time(),2) //chave de tamanho 14: AAAAMMDDHHMMSS
	Local oJResponse := Nil
	//Local nLoadLimit := SuperGetMV("MV_LJILQTD", .F., 200)

	If RedisConnect()

		//Retorna todas as chaves do BD Redis
		cCmd := 'keys *'
		If .Not. ExecCmd(cCmd, @xRetCmd)
			//Return .F.
		EndIf

		//verifica se nao ultrapassou o limite de cargas MV_LJILQTD
		If (ValType(xRetCmd) == 'A') //.and. (Len(xRetCmd) < nLoadLimit)

			If .Not. ExistChave(ckey)
				oJResponse := ExportarCarga() //pega os registros a serem gravados
				If ValType(oJResponse) == "J" .and. Len(oJResponse:GetJSonObject('tables')) > 0
					cParam := oJResponse:ToJson()
					cCmd := 'set '+ckey+' ?' //Inclui uma chave e valor
					aParam := {cParam}
					If .Not. ExecCmdPar(cCmd, aParam, @xRetCmd)
						//Return .F. //TODO - voltar os registros do JSON, caso haja falha na exportação para o Redis: limpar o MSEXP
					EndIf
				EndIf
			EndIf

		Else
			PRT_ERROR("Limite de quantidade de cargas atingido. Não será possível gerar a carga. Verifique o parâmetro MV_LJILQTD ou exclua alguma carga ativa")
		EndIf

	EndIf

	RedisDisconnect()

	FreeObj( oJResponse )
	oJResponse := Nil

Return

//////////////////////////////////////////////////////////////////////////////////////////////////////////

//Função para geração de carga no banco RabbitMQ
User Function URABMQLR() //STFLOADRET

	Local oProducer
	Local aListPdvs := U_GListMD4()
	Local nX
	Local nLoadLimit := SuperGetMV("MV_LJILQTD", .F., 200)
	Local oJResponse := Nil

	PRT_MSG("oProducer  := tAmqp():New")
	oProducer  := tAmqp():New( cIpRabbitMQ, nPortRabbitMQ, cUserNameRMQ, cPswRMQ, nChannelId ) //Cria um objeto tAMQP com um determinado AMQP Server.
	If Empty(oProducer:Error())

		PRT_MSG("oProducer:ExchangeDeclare")
		oProducer:ExchangeDeclare( cNameExchange, "fanout", .F., .T., .F. ) //Cria uma nova exchange no AMQP Server.

		For nX:=1 to Len(aListPdvs)
			PRT_MSG("oProducer:QueueDeclare")
			oProducer:QueueDeclare( aListPdvs[nX], .T. /*bisDurable*/, .F. /*bisExclusive*/, .F. /*bisAutodelete*/ ) //Cria uma nova fila no AMQP Server.
			PRT_MSG("oProducer:QueueBind")
			oProducer:QueueBind( aListPdvs[nX], cNameExchange ) //Liga uma fila a uma exchange para que as mensagens fluam (sujeitas a vários critérios) da exchange (origem) para a fila (destino).
			If oProducer:MessageCount() >= nLoadLimit //Valida o limite de itens na fila
				PRT_ERROR("Limite de quantidade de cargas atingido. Não será possível gerar a carga. Verifique o parâmetro MV_LJILQTD ou exclua alguma carga ativa")
				Return .F. 
			EndIf
		Next nX

		PRT_MSG("oJResponse := ExportarCarga()")
		oJResponse := ExportarCarga() //pega os registros a serem gravados
		If ValType(oJResponse) == "J" .and. Len(oJResponse:GetJSonObject('tables')) > 0 .and. !Empty(oJResponse:ToJson())

			If Empty(oProducer:Error())
				PRT_MSG("oProducer:BasicPublish")
				oProducer:BasicPublish( cNameExchange, '', .T., oJResponse:ToJson() ) //Envia uma mensagem para o AMQP Server.
				If !Empty(oProducer:Error())
					PRT_ERROR("Erro na publicação da mensagem no servidor RabbitMQ: "+oProducer:Error())
				EndIf
			EndIf

		EndIf

	Else
		PRT_ERROR("Erro na conexão com o servidor RabbitMQ: "+oProducer:Error())
	EndIf
	
	//TODO - voltar os registros do JSON, caso haja falha na exportação para o RabbitMQ: limpar o MSEXP

	FreeObj( oJResponse )
	oJResponse := Nil

	FreeObj( oProducer )
	oProducer := Nil

Return

//Retorna a lista de HOSTS baseado na tabela MD4
User Function GListMD4()

	Local aList := {}

	MD4->(dbSetOrder(1)) //MD4_FILIAL+MD4_CODIGO
	If MD4->(dbSeek(xFilial("MD4"))) //Posiciona no primeiro registro com Filial + Codigo
		While MD4->(!Eof()) .AND. ( MD4->MD4_FILIAL == xFilial("MD4") )
			//Processa somente ambiente PDV
			If !Empty(MD4->MD4_AMBPAI)
				Aadd(aList, LOWER(AllTrim(MD4->MD4_CODIGO)+"_"+AllTrim(MD4->MD4_DESCRI)))
			EndIf
			MD4->(DbSkip())
		EndDo
	EndIf

Return aList

//////////////////////////////////////////////////////////////////////////////////////////////////////////

//Função de leitura de carga no banco Redis
User Function UREDISLP() //STFLoadPdv

	Local cCmd := ""
	Local xRetCmd := Nil
	Local aCargas := {}
	Local nX := 0
	Local cKeyUpd := ""
	Local nPos := 0
	Local oJResponse := Nil
	Local bObject := {|| JsonObject():New()}
	Local cJson := ""
	Local xRet

	VerParams() //ajusta parametros
	cKeyUpd := GetMv("MV_XREDLPD") //chave de tamanho 14: AAAAMMDDHHMMSS

	If RedisConnect()

		//Retorna todas as chaves do BD Redis
		cCmd := 'keys *'
		If .Not. ExecCmd(cCmd, @xRetCmd)
			//Return .F.
		EndIf

		If (ValType(xRetCmd) == 'A')
			aCargas := aClone(xRetCmd)
			xRetCmd := Nil
			ASORT(aCargas,,,{|x,y| x<y}) //orderm crescente

			nPos := aScan( aCargas, { |x| AllTrim(x) == AllTrim(cKeyUpd) } )
			If Empty(cKeyUpd) .or. (!Empty(cKeyUpd) .and. Len(aCargas)>=1 .and. cKeyUpd < aCargas[1])
				nPos := 1
			ElseIf nPos > 0 .and. nPos < Len(aCargas)
				nPos++
			ElseIf Len(aCargas) = 0
				PRT_MSG("Não existem cargas disponíveis a serem importadas.")
				RedisDisconnect()
				Return
			Else
				nPos := Len(aCargas)+1
				PRT_MSG("Todas as cargas ja foram importadas. Ultima carga importada: "+cKeyUpd+" (AAAAMMDDHHMMSS).")
			EndIf

			//faz a importação das cargas
			For nX := nPos to Len(aCargas)
				cKeyUpd := aCargas[nX]
				//Retorna todas as chaves do BD Redis
				cCmd := 'get '+cKeyUpd
				If .Not. ExecCmd(cCmd, @xRetCmd)
					//Return .F.
				EndIf

				If ValType(xRetCmd) != 'C'
					cJson := cValToChar(xRetCmd)
				Else
					cJson := xRetCmd
				EndIf

				oJResponse := Eval(bObject)
				xRet := oJResponse:FromJson(cJson)

				If ValType(xRet) == "U"
					//PRT_MSG("JsonObject populado com sucesso")
					If ImportarCarga(oJResponse)
						PutMvPar("MV_XREDLPD",cKeyUpd)
					Else
						PRT_ERROR("Não foi possível importar a carga: "+cKeyUpd+".")
						Exit //sai do For nX
					EndIf
				Else
					PRT_ERROR("Falha ao popular JsonObject. Erro: " + xRet)
					Exit //sai do For nX
				EndIf

			Next nX

		EndIf

	EndIf

	RedisDisconnect()

	FreeObj( oJResponse )
	oJResponse := Nil

Return

//////////////////////////////////////////////////////////////////////////////////////////////////////////

//Função de leitura de carga no banco RabbitMQ
User Function URABMQLP(cXFiliais) //STFLoadPdv

	Local nX := 1
	Local oJResponse := Nil
	Local bObject := {|| JsonObject():New()}
	Local cJson := ""
	Local xRet
	Local cRetAmb := Padr(SuperGetMv("MV_LJAMBIE", .F., ""), TamSx3("MD3_CODAMB")[1])
	Local cFila := '' //MD4_CODIGO + "_" + MD4_DESCRI

	If !Empty(cRetAmb)
		MD4->(dbSetOrder(1)) //MD4_FILIAL+MD4_CODIGO
		If MD4->(dbSeek(xFilial("MD4")+cRetAmb))
			cFila := LOWER(AllTrim(MD4->MD4_CODIGO)+"_"+AllTrim(MD4->MD4_DESCRI))
		Else
			PRT_ERROR("Não foi possível recuperar o nome da fila, favor revisar a configuração do Host (MD4).")
			Return .F.
		EndIf
	Else
		PRT_ERROR("Não existe configuração do Host, favor rodar wizard para configuração de um novo Host (MV_LJAMBIE).")
		Return .F.
	EndIf

	PRT_MSG("oConsumer := tAmqp():New")
	oConsumer := tAmqp():New( cIpRabbitMQ, nPortRabbitMQ, cUserNameRMQ, cPswRMQ, nChannelId ) //Cria um objeto tAMQP com um determinado AMQP Server.

	If Empty(oConsumer:Error())

		PRT_MSG("oConsumer:QueueDeclare")
		oConsumer:QueueDeclare( cFila, .T., .F., .F. ) //Cria uma nova fila no AMQP Server.
		PRT_MSG("oConsumer:BasicQos")
		oConsumer:BasicQos(0, 1, .F.) //Define o números de elementos da fila...

		//For nX := 1 To oConsumer:MessageCount()
		If oConsumer:MessageCount() > 0 
			oConsumer:ConsumeTimeOut := 60 //ajuste do timeout para 1min

			PRT_MSG("oConsumer:BasicConsume")
			oConsumer:BasicConsume( cFila, .F. ) //Resgata uma mensagem no AMQP Server.
			If !Empty(oConsumer:Error())
				PRT_ERROR("Falha ao resgatar uma mensagem no AMQP Server (RabbitMQ). Erro: " + oConsumer:Error())
				//Exit //sai do For nX
			EndIf
			cJson := oConsumer:Body

			If ValType(cJson) != 'C'
				cJson := cValToChar(cJson)
			Else
				cJson := cJson
			EndIf

			oJResponse := Eval(bObject)
			xRet := oJResponse:FromJson( cJson )

			If ValType(xRet) == "U"
				//PRT_MSG("JsonObject populado com sucesso")
				
				If !ImportarCarga(oJResponse,cXFiliais)
					PRT_ERROR("Não foi possível importar a carga.")
					//Exit //sai do For nX
				Else
					PRT_MSG("oConsumer:BasicAck")
					oConsumer:BasicAck( nX, .F. ) //Indica para a fila que voce recebeu e processou a mensagem com sucesso (acknowledge)
					If !Empty(oConsumer:Error())
						PRT_ERROR("Falha ao retornar processamento de mensagem com sucesso (acknowledge). Erro: " + oConsumer:Error())
						//Exit //sai do For nX
					EndIf
				EndIf
			Else
				PRT_ERROR("Falha ao popular JsonObject. Erro: " + xRet)
				//Exit //sai do For nX
			EndIf

		EndIf
		//Next nX

	Else
		PRT_ERROR("Erro na conexão com o servidor RabbitMQ: "+oConsumer:Error())
	EndIf

	FreeObj( oConsumer )
	oConsumer := Nil

	FreeObj( oJResponse )
	oJResponse := Nil

Return

//////////////////////////////////////////////////////////////////////////////////////////////////////////

User Function UREDISDL() //STFLoadDel

	Local aPDVs := {}
	Local nCount := 0
	Local bOldError
	Local lFindFun := .F.
	Local cCmd := ""
	Local cParam := ""
	Local xRetCmd := Nil
	Local aCargas := {}
	Local cLastOrder := PADL("",14,"0") //chave de tamanho 14: AAAAMMDDHHMMSS
	Local oServer := Nil //Objeto de conexao com o server

	//Lista todos Ambientes Replicacao (filhos) -> aPDVs
	MD4->(dbSetOrder(1)) //MD4_FILIAL+MD4_CODIGO
	//Posiciona no primeiro registro com Filial + Codigo
	If MD4->(dbSeek(xFilial("MD4")))
		While MD4->(!Eof()) .AND. ( MD4->MD4_FILIAL == xFilial("MD4") )
			//Processa somente ambiente PDV
			If !Empty(MD4->MD4_AMBPAI)
				Aadd(aPDVs, {MD4->MD4_CODIGO, MD4->MD4_DESCRI, PADL("",14,"0")/*[03]cLastOrder*/})
			EndIf
			MD4->(DbSkip())
		EndDo
	EndIf

	//Busca os dados de cada PDV para realizar a pesquisa das cargas processadas
	MD3->(dbSetOrder(1)) //MD3_FILIAL+MD3_CODAMB+MD3_TIPO
	If Len(aPDVs) > 0
		//oResult := LJILLoadResult()
		For nCount := 1 To Len(aPDVs) //Realiza a leitura de todos os PDVs encontrados
			If MD3->(dbSeek(xFilial("MD3") + aPDVs[nCount,1] + "R"))

				//Cria objeto da conexao RPC
				oServer := TRPC():New(AllTrim(MD3->MD3_NOMAMB))
				If oServer:Connect(AllTrim(MD3->MD3_IP), Val(MD3->MD3_PORTA))
					bOldError := ErrorBlock({|x| STFLoadError(x)}) //Muda code-block de erro
					//Este tratamento protege o JOB caso a comunicacao caia durante este processo de consulta. Do contrario o JOB ficaria inativo

					Begin Sequence

						oServer:CallProc("RPCSetType", 3) //Tipo de Licenca consumida
						oServer:CallProc("RPCSetEnv", MD3->MD3_EMP, MD3->MD3_FIL/*cFilAnt*/, Nil, Nil, "FRT", "", {"MBY"}) //Abre conexao com outra empresa

						PRT_MSG(" >> Conectando no ambiente PDV: ")
						PRT_MSG("    PDV : " + aPDVs[nCount,1]+" - "+AllTrim(aPDVs[nCount,2]) +"")
						PRT_MSG("    MD3_NOMAMB : "+AllTrim(MD3->MD3_NOMAMB)+" | MD3_IP : " + AllTrim(MD3->MD3_IP) + " | MD3_PORTA : " + MD3->MD3_PORTA + "")
						lFindFun := oServer:CallProc( 'FindFunction', 'U_UREDISLT')
						If lFindFun
							aPDVs[nCount][3] := oServer:CallProc( 'U_UREDISLT' ) //Pega a ordem da ultima carga baixada no ambiente
							If aPDVs[nCount][3] > cLastOrder
								cLastOrder := aPDVs[nCount][3] //neste momento guardo a maior carga já importada
							EndIf
						Else
							PRT_ERROR("JOB UREDISDL - Função UREDISLT não compilada no PDV " + aPDVs[nCount,1] + " - " + AllTrim(aPDVs[nCount,2]) + ".")
							PRT_ERROR("Detalhes da conexao RPC - Nome do Ambiente : " + AllTrim(MD3->MD3_NOMAMB) + " | IP : " + AllTrim(MD3->MD3_IP) + " | Porta : " + MD3->MD3_PORTA)
						EndIf
						oServer:CallProc("RpcClearEnv") //Limpa Thread
						oServer:Disconnect() //Encerra conexao

						Recover
						PRT_ERROR("JOB UREDISDL - Ocorreu um erro inesperado durante a consulta com o PDV " + aPDVs[nCount,1] + " - " + AllTrim(aPDVs[nCount,2]) + ". PDV pode estar off-line.")
						PRT_ERROR("Detalhes da conexao RPC - Nome do Ambiente : " + AllTrim(MD3->MD3_NOMAMB) + " | IP : " + AllTrim(MD3->MD3_IP) + " | Porta : " + MD3->MD3_PORTA )

					End Sequence

					ErrorBlock(bOldError) //Restaura rotina de erro anterior

				Else
					PRT_ERROR("JOB UREDISDL - Nao foi possivel estabelecer uma conexao com o PDV "+aPDVs[nCount,1]+" - "+AllTrim(aPDVs[nCount,2])+".")
					PRT_ERROR("Detalhes da conexao RPC - Nome do Ambiente : " + AllTrim(MD3->MD3_NOMAMB) + " | IP : " + AllTrim(MD3->MD3_IP) + " | Porta : " + MD3->MD3_PORTA )

					//Exit
				EndIf

			Else
				PRT_ERROR("JOB UREDISDL - Nao foi encontrado a conexao RPC (registro na tabela MD3) para o PDV "+aPDVs[nCount,1]+" - "+AllTrim(aPDVs[nCount,2])+".")
			EndIf

		Next nCount
	EndIf

	If cLastOrder <> PADL("",14,"0"); //se teve alguma carga baixada
		.and. Len(aPDVs) > 0

		If RedisConnect()

			xRetCmd := Nil
			cCmd := 'keys *' //Retorna todas as chaves do BD Redis
			If .Not. ExecCmd(cCmd, @xRetCmd)
				//Return .F.
			EndIf

			If (ValType(xRetCmd) == 'A')
				aCargas := aClone(xRetCmd)
				If Len(aCargas) <= 0
					PRT_MSG("Não existem cargas disponíveis no BD Redis.")
					RedisDisconnect()
					FreeObj( oServer )
					oServer := Nil
					Return
				EndIf

				xRetCmd := Nil
				ASORT(aCargas,,,{|x,y| x<y}) //orderm crescente

				cLastOrder := aCargas[Len(aCargas)] //neste momento guardo a maior carga disponível
				For nCount := 1 to Len(aPDVs)
					If aPDVs[nCount][3] < cLastOrder //guarda a [menor carga baixada]
						cLastOrder := aPDVs[nCount][3]
					EndIf
				Next nCount

				For nCount := 1 to Len(aCargas)
					If aCargas[nCount] <= cLastOrder //toda carga menor ou igual que a [menor carga baixada], sera excluida
						cParam += aCargas[nCount] + " "
					EndIf
				Next nCount
				cParam := AllTrim(cParam)

				If !Empty(cParam)
					xRetCmd := Nil
					cCmd := 'del ' + cParam //remove chaves especificas:  DEL key [key ...]
					If ExecCmd(cCmd, @xRetCmd)
						PRT_MSG(""+cValToChar(xRetCmd)+ " chaves removidas com sucesso.")
					EndIf
				EndIf

			EndIf
		EndIf

		RedisDisconnect()

	EndIf

	FreeObj( oServer )
	oServer := Nil

Return

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//Retorna a ultima carga importada
//////////////////////////////////////////////////////////////////////////////////////////////////////////
User Function UREDISLT()
	Local cLastOrder := GetMv("MV_XREDLPD",.F.,PADL("",14,"0")) //chave de tamanho 14: AAAAMMDDHHMMSS
	LjGrvLog("Carga", "Ultima carga processada " , cLastOrder )
Return cLastOrder

//////////////////////////////////////////////////////////////////////////////////////////////////////////

Static Function ExistChave(ckey)

	Local cCmd := ""
	Local xRetCmd := Nil

	//Retorna se a chave existe
	cCmd := 'exists '+ckey+''
	If .Not. ExecCmd(cCmd, @xRetCmd)
		Return .T.
	EndIf

	If(ValType(xRetCmd) == 'N')
		If(xRetCmd == 1) // 1 if the key exists
			PRT_MSG("ExistChave: the key exists - " + ckey + "")
			Return .T.
		Else // 0 if the key does not exists
			PRT_MSG("ExistChave: the key does note exists - " + ckey + "")
			Return .F.
		EndIf
	Else
		PRT_ERROR("ExistChave: " + ckey + " Tipo invalido: " + ValType(xRetCmd))
		VarInfo("ExistChave", xRetCmd)
		Return .T.
	EndIf

Return .T.

//////////////////////////////////////////////////////////////////////////////////////////////////////////

Static Function RedisConnect()

	If (oRedis == Nil)
		oRedis := tRedisClient():New()
		oRedis:Connect(cRedisServer, nRedisPort, cRedisAuth)
		If oRedis:isConnected()
			PRT_MSG("Redis conectado com sucesso.")
			Return .T.
		Else
			PRT_ERROR("Falha de conexao com o Redis.")
			oRedis:Disconnect()
			oRedis := Nil
			Return .F.
		EndIf
	Else
		Return .T.
	EndIf

Return .F.

//////////////////////////////////////////////////////////////////////////////////////////////////////////

Static Function ExecCmd(cCmd, xRetCmd)
	If .Not. oRedis:exec(cCmd, @xRetCmd):ok()
		PRT_ERROR('Cmd: "' + cCmd + '" erro: ' + Alltrim(Str(oRedis:nError)) + " | " + AllTrim(oRedis:cError))
		Return .F.
	EndIf
Return .T.

//////////////////////////////////////////////////////////////////////////////////////////////////////////

Static Function ExecCmdPar(cCmd, aParam, xRetCmd)
	Local nX := 1
	Local cExec := "oRedis:exec(cCmd, "
	For nX:=1 to Len(aParam)
		cExec += "aParam["+cValToChar(nX)+"], "
	Next nX
	cExec += "@xRetCmd):ok()"
	If .Not. &(cExec)
		PRT_ERROR('Cmd: "' + cCmd + '" erro: ' + Alltrim(Str(oRedis:nError)) + " | " + AllTrim(oRedis:cError))
		Return .F.
	EndIf
Return .T.

//////////////////////////////////////////////////////////////////////////////////////////////////////////

Static Function RedisDisconnect()
	If (oRedis <> Nil)
		oRedis:Disconnect()
		FreeObj( oRedis )
		oRedis := Nil
	EndIf
Return .T.

//////////////////////////////////////////////////////////////////////////////////////////////////////////

Static Function ExportarCarga(nType, cPathJson, cFilePref, aFiles)

	Local oTransferTables := Nil
	Local nCount := 0
	Local nQtdTab := 0

	Local bObject := {|| JsonObject():New()}
	Local oJson   := Nil
	Local oJsonTmp := Nil

	Local cServerIni := GetAdv97()
	Local cSecao := "General"
	Local cChave := "MaxStringSize"
	Local nPadrao := 1
	Local nMaxStrSize := GetPvProfileInt(cSecao, cChave, nPadrao, cServerIni) //1 Mb (valor mínimo padrão) -> 500 Mb (valor máximo permitido)

	/*
		1MB são 1.048.576 caracteres
		Vamos considerar que um único registro tenha 10.000 caracteres
	*/
	Local nTamRow := 10000 //número de caracteres por registro

	Default nType := INCREMENTAL
	Default cPathJson := ""
	Default cFilePref := ""
	Default aFiles := {}

	Private nLimRecord := Min(Int((nMaxStrSize*1048576) / nTamRow) , 10000)
	Private nRecord := 0
	Private nRecordsProcessed := 0

	If nType == INCREMENTAL
		oJson   := Eval(bObject)
		oJson["version"] := "0.0.1"
		oJson["tables"]  := {}
	else
		if nLimRecord < 10000 
			Msginfo("MaxStringSize configurado com valor menor que 100MB. Para carga completa recomendamos que seja no minimo 100MB. Processo abortado!")
			Return 0
		endif
	endif

	DbSelectArea( "MBU" )
	DbSetOrder(2) // MBU_FILIAL + MBU_TIPO
	If DbSeek(xFilial("MBU") + '1')
		While MBU->(!EOF()) .AND. MBU->MBU_FILIAL + MBU_TIPO == xFilial("MBU") + '1' .and. (nType == ENTIRE .OR. nRecord <= nLimRecord)
			If AllTrim(MBU->MBU_INTINC) == "2" //INCREMENTAIS (carga automática)
				//Retorno -> oTransferTables: Objeto do tipo RedisLoadTransferTables
				oTransferTables := U_UREDISL1( MBU->MBU_CODIGO ) //array de tabelas transferiveis para a carga (MBU_CODIGO)

				If nType == ENTIRE
					nQtdTab := Len( oTransferTables:aoTables)
					ProcRegua( nQtdTab )
				endif

				// Para cada tabela
				For nCount := 1 To Len( oTransferTables:aoTables )
					If nType == ENTIRE
						IncProc("Exportando tabela "+oTransferTables:aoTables[nCount]:cTable+"... ("+cValtoChar(nCount)+"/"+cValToChar(nQtdTab)+")")
					endif
					oJsonTmp := ExportComplete( oTransferTables:aoTables[nCount], nType, cPathJson, cFilePref, @aFiles)
					If nType == INCREMENTAL .AND. ValType(oJsonTmp) == "J"
						aadd( oJson["tables"], oJsonTmp )
					EndIf
					If nType == INCREMENTAL .AND. nRecord > nLimRecord
						Exit //sai do For
					EndIf
				Next nCount
			EndIf
			MBU->(DbSkip())
		End
	EndIf

	FreeObj( oJsonTmp )
	oJsonTmp := Nil

Return iif(nType == INCREMENTAL,oJson, len(aFiles)>0)

//////////////////////////////////////////////////////////////////////////////////////////////////////////

Static Function ExportComplete(oCompleteTable, nType, cPathJson, cFilePref, aFiles)

	Local aStruct			:= {}
	Local nCount			:= 0
	Local nCount2			:= 0
	Local aRecNos			:= {}
	Local nTotalRecords		:= 0
	Local oTempTable		:= Nil
	Local cTablePrefix		:= ""
	Local cMthIsMbOf		:= "MethIsMemberOf"
	Local lHasNewMet		:= Nil				//indica se o metodo MethIsMemberOf existe no binario
	Local cWhereRec			:= ""
	Local lSQLite 		    := AllTrim(Upper(GetSrvProfString("RpoDb",""))) == "SQLITE" //PDVM/Fat Client
	Local aBranches			:= {}
	Local cBranches 		:= ""
	Local nPos				:= 0

	Local bObject := {|| JsonObject():New()}
	Local oJson   := Nil
	Local oJsonEntire := Nil
	Local nSeqEntire := 0

	If ChkFile( oCompleteTable:cTable, .F. )

		// Abre a tabela de origem
		DbSelectArea( oCompleteTable:cTable )

		cTablePrefix := IIf( SubStr(oCompleteTable:cTable,1,1) == "S", SubStr(oCompleteTable:cTable,2,3), oCompleteTable:cTable )

		// Valida a existencia dos campos _MSEXP e _HREXP
		If nType == ENTIRE .OR. (oCompleteTable:cTable)->(ColumnPos(cTablePrefix + "_MSEXP")) > 0  .AND. (oCompleteTable:cTable)->(ColumnPos(cTablePrefix + "_HREXP")) > 0

			// Pega a estrutura do banco de dados
			aStruct := (oCompleteTable:cTable)->( DBStruct() )
			//Adiciona na estrutura o campo DEL pra poder controlar os registros deletados
			AADD(aStruct, {"DEL", "C", 1 , 0} )
			AADD(aStruct, {"REC", "N", 15, 0} )

			// Loop em todas as Filiais
			For nCount := 1 To Len( oCompleteTable:aBranches )

				//Analisando tabela a exportar

				// Cria a estrutura da tabela temporaria que sera usada como base para exportacao
				oTempTable := RedisLoadTempTableExport():New(oCompleteTable, oCompleteTable:aBranches[nCount], nType/*INCREMENTAL*/, "TABTMP")

				// Usamos a comparacao com Nil por causa que oTempTable so pode ser instanciada dentro do loop,
				// entao apos "lHasNewMet" ser atribuida pela primeira vez, a funcao MethIsMemberOf nao sera mais chamado
				If lHasNewMet == Nil
					If ExistFunc(cMthIsMbOf)
						lHasNewMet := &cMthIsMbOf.( oTempTable, "SetQtyRecSQL" )
					Else
						lHasNewMet := .F.
					EndIf
					//LjGrvLog( "Carga","O metodo SetQtyRecSQL(LOJA1170.PRW) EXISTE?", lHasNewMet)
				EndIf

				// alimenta a tabela com os dados
				oTempTable:CreateTempTable()

				// Se houver um Filtro, ele é aplicado sobre o result set (se existisse uma funcao que convertesse o filtro em uma expressao SQL, esse trecho nao seria necessario)
				If !Empty( oCompleteTable:cFilter ) .AND. !Empty(ALLTRIM(STRTran(oCompleteTable:cFilter,chr(13)+chr(10),"")))
					TABTMP->( DBSetFilter({|| &(oCompleteTable:cFilter)}, oCompleteTable:cFilter) )
					oTempTable:SetQtyRecords()
				ElseIf lHasNewMet
					// faz a contagem dos registros via Count(SQL)
					oTempTable:SetQtyRecSQL()
				Else
					oTempTable:SetQtyRecords()
				EndIf

				nTotalRecords := oTempTable:nQtyRecords

				// Exporta os registros
				Dbselectarea("TABTMP")
				TABTMP->( DbGoTop() )
				aRecNos := {}
				aBranches := {}

				If TABTMP->(!EoF())
					If ValType(oJson) <> "J"
						oJson := Eval(bObject)
						oJson["nametable"] := oCompleteTable:cTable
						oJson[oCompleteTable:cTable] := {}
					EndIf
				EndIf

				While TABTMP->(!EoF())

					//LjGrvLog("Carga", "Geracao TRB registro a registro")
					While TABTMP->(!EoF()) .and. nRecord <= nLimRecord
						nRecord++
						aadd(oJson[oCompleteTable:cTable],GetJsonRow(cTablePrefix,aStruct))
						//Atualiza os campos MSEXP do registro exportado
						Dbselectarea("TABTMP")
						Aadd(aRecNos,TABTMP->REC)
						nPos := aScan( aBranches, { |x| x == TABTMP->&(cTablePrefix+"_FILIAL") } )
						If nPos <= 0
							Aadd(aBranches,TABTMP->&(cTablePrefix+"_FILIAL"))
						EndIf
						TABTMP->( DbSkip() )
						nRecordsProcessed++
					End

					cBranches := ""
					For nPos:=1 to Len(aBranches)
						cBranches += aBranches[nPos]+"/"
					Next nPos
					If ValType(oJson) == "J" .and. ValType(oJson["branches"]) == "C" .and. !Empty(oJson["branches"])
						cBranches := oJson["branches"]+"/"+cBranches
					EndIf
					cBranches := SubStr(cBranches,1,Len(cBranches)-1)

					If ValType(oJson) == "J"
						oJson["branches"] := cBranches
					EndIf
				
					If nType == ENTIRE .AND. nRecord > nLimRecord

						oJsonEntire   := Eval(bObject)
						oJsonEntire["version"] := "0.0.1"
						oJsonEntire["tables"]  := {}

						aadd( oJsonEntire["tables"], oJson )
					
						MEMOWRITE( cPathJson+cFilePref+"_"+oCompleteTable:cTable+iif(nSeqEntire>0,"_"+STRZERO(nSeqEntire,3),"")+".json", oJsonEntire:ToJson() )
						aadd(aFiles, cPathJson+cFilePref+"_"+oCompleteTable:cTable+iif(nSeqEntire>0,"_"+STRZERO(nSeqEntire,3),"")+".json")

						nSeqEntire++

						FreeObj( oJson )
						oJson := Nil
						FreeObj( oJsonEntire )
						oJsonEntire := Nil

						aBranches := {}
						aRecNos := {}
						nRecord := 0

						oJson := Eval(bObject)
						oJson["nametable"] := oCompleteTable:cTable
						oJson[oCompleteTable:cTable] := {}

					else
						EXIT //sai pela limitação de registros para carga incremental	
					endif

				enddo

				TABTMP->( DbCloseArea() )

				//Atualiza os campos MSEXP de TODOS registros exportados
				//oTempTable:UpdateMSEXP()
				If nType == INCREMENTAL
					If Len(aRecNos) > 0
						cWhereRec := "AND R_E_C_N_O_ IN ("
						For nCount2 := 1 to Len(aRecNos)
							//oTempTable:UpdateRecno(aRecNos[nCount2])
							cWhereRec += iif(lSQLite,"'"," ")+cValToChar(aRecNos[nCount2])+iif(lSQLite,"',",",")
						Next nCount2
						cWhereRec := SubStr(cWhereRec,1,Len(cWhereRec)-1) + ")"
						DO CASE
						CASE Lower(GetClassName( oTempTable:oTable )) == Lower("RedisLoadCompleteTable")
							oTempTable:UpdMSEXPCompleteTable(cWhereRec)
						CASE Lower(GetClassName( oTempTable:oTable )) == Lower("RedisLoadSpecialTable")
							oTempTable:UpdMSEXPSpecialTable(cWhereRec)
						ENDCASE
					EndIf
				endif

				If nType == INCREMENTAL .AND. nRecord > nLimRecord
					Exit //sai do For
				EndIf

			Next nCount

			If nType == ENTIRE .AND. nRecord > 0
				oJsonEntire   := Eval(bObject)
				oJsonEntire["version"] := "0.0.1"
				oJsonEntire["tables"]  := {}

				aadd( oJsonEntire["tables"], oJson )
			
				MEMOWRITE( cPathJson+cFilePref+"_"+oCompleteTable:cTable+iif(nSeqEntire>0,"_"+STRZERO(nSeqEntire,3),"")+".json", oJsonEntire:ToJson() )
				aadd(aFiles, cPathJson+cFilePref+"_"+oCompleteTable:cTable+iif(nSeqEntire>0,"_"+STRZERO(nSeqEntire,3),"")+".json")

				FreeObj( oJson )
				oJson := Nil
				FreeObj( oJsonEntire )
				oJsonEntire := Nil

				aBranches := {}
				aRecNos := {}
				nRecord := 0

				oJson := Eval(bObject)
				oJson["nametable"] := oCompleteTable:cTable
				oJson[oCompleteTable:cTable] := {}
			endif

			(oCompleteTable:cTable)->( DbCloseArea() )
		Else
			PRT_ERROR("Campos necessários para a Carga Incremental não existem. Verifique se os campos " + cTablePrefix + "_MSEXP" + " e " + cTablePrefix + "_HREXP existem.")
		EndIf
	Else
		PRT_ERROR("Não foi possível abrir a tabela "+oCompleteTable:cTable+". Ela pode estar aberta de modo exclusivo por outro programa.")
	EndIf

Return (oJson)

//////////////////////////////////////////////////////////////////////////////////////////////////////////

Static Function GetJsonRow(cTablePrefix,aStruct)

	Local oJson := JsonObject():New()
	Local nX
	Local lX3_POSLGT := SX3->(ColumnPos("X3_POSLGT")) > 0
	Local cTypeDB := TCGetDB()
	Local nAux := 0

	For nX := 1 To Len(aStruct)
		If aStruct[nX][1] == cTablePrefix + "_MSEXP"
			oJson[aStruct[nX][1]] := DtoS(dDataBase)
		ElseIf aStruct[nX][1] == cTablePrefix + "_HREXP"
			oJson[aStruct[nX][1]] := Left(Time(),8)
		ElseIf Alltrim(aStruct[nX][1]) <> cTablePrefix + "_SITUA" .and.  Alltrim(aStruct[nX][1]) <> cTablePrefix + "_USERGI" .and. Alltrim(aStruct[nX][1]) <> cTablePrefix + "_USERGA" //campos ignorados
			//a verificacao do GetSx3Cache eh para saber se o registro pode entrar na carga.
			//Util quando se utiliza campo memo, que tem um tamanho consideravel e lerdeia a geracao da carga.
			//Verifica se eh campo MEMO Real
			If lX3_POSLGT .And. aStruct[nX][2] == "M" .AND. GetSx3Cache(aStruct[nX][1],"X3_POSLGT") <> "2"
				If "MSSQL" $ cTypeDB
					oJson[aStruct[nX][1]] := TABTMP->(FieldGet(ColumnPos( aStruct[nX][1]) ))
				ElseIf "DB2" $ cTypeDB
					nAux := TABTMP->((ColumnPos( aStruct[nX][1]) ))
					If nAux > 0	// Há campos memo não encontrados na tabela DB2.
						oJson[aStruct[nX][1]] := TABTMP->(FieldGet( nAux ))
					EndIf
				EndIf
			Else
				//If !Empty(TABTMP->(FieldGet(ColumnPos( aStruct[nX][1]) ))) //somente os campos preenchidos
				If aStruct[nX][2] == "D"
					oJson[aStruct[nX][1]] := DtoC(TABTMP->(FieldGet(ColumnPos( aStruct[nX][1]) )))
				Else
					oJson[aStruct[nX][1]] := TABTMP->(FieldGet(ColumnPos( aStruct[nX][1]) ))
				EndIf
				//EndIf
			EndIf

			If !(aStruct[nX][2] == "N" .or. aStruct[nX][2] == "L") .and. Empty(AllTrim(oJson[aStruct[nX][1]])) //reduzir tamanho da STRING do JSON
				//If aStruct[nX][2] == "N"
				//	oJson[aStruct[nX][1]] := 0
				//ElseIf aStruct[nX][2] == "L"
				//	oJson[aStruct[nX][1]] := .F.
				//Else
				oJson[aStruct[nX][1]] := ""
				//EndIf
			EndIf

		EndIf

	Next nX

Return (oJson)

//////////////////////////////////////////////////////////////////////////////////////////////////////////

Static Function VerParams()

	Local cAliasSX6 := GetNextAlias() // apelido para o arquivo de trabalho
	Local lOpen   	:= .F. // valida se foi aberto a tabela

	// abre o dicionário SIX
	OpenSXs(NIL, NIL, NIL, NIL, cEmpAnt, cAliasSX6, "SX6", NIL, .F.)
	lOpen := Select(cAliasSX6) > 0

	// caso aberto, posiciona no topo
	If !(lOpen)
		Return .F.
	EndIf

	DbSelectArea(cAliasSX6)
	(cAliasSX6)->( DbSetOrder( 1 ) ) //X6_FIL+X6_VAR
	(cAliasSX6)->( DbGoTop() )

	If !(cAliasSX6)->( DbSeek( cFilAnt + "MV_XREDLPD") )
		RecLock(cAliasSX6,.T.)
		(cAliasSX6)->&("X6_FIL") := cFilAnt
		(cAliasSX6)->&("X6_VAR") := "MV_XREDLPD"
		(cAliasSX6)->&("X6_TIPO") := "C"
		(cAliasSX6)->&("X6_DESCRIC") := "Chave sequencial da importação da carga."
		(cAliasSX6)->&("X6_DESC1") := "Chave de tamanho 14: AAAAMMDDHHMMSS"
		(cAliasSX6)->&("X6_CONTEUD") := ""
		(cAliasSX6)->&("X6_PROPRI")	:= "U"
		(cAliasSX6)->( MsUnLock() )
	EndIf

Return .T.

//////////////////////////////////////////////////////////////////////////////////////////////////////////

Static Function ImportarCarga(oJCarga,cXFiliais)

	Local aStruct := {}
	Local cTable := ""
	Local aBranches := ""
	Local nPos := 0
	Local cBranchUsed := ""
	Local cBranchRow := ""
	Local oJTables
	Local oJRows
	Local nX := 0, nY := 0, nZ := 0, nW := 0
	Local nIndice := 1
	Local cChave := "", cChvRow := ""
	Local aChave := {}
	Local aChvRow := {}
	Local lInclui := .T.
	Local cTablePrefix := ""
	Local cX2Unico := ""
	Local aIndex := {}
	Local aXFilais := {}
	Local aIndexEsp := {}
	Default cXFiliais := cFilAnt

	aadd(aIndexEsp, {"F2B",3}) //F2B_FILIAL+F2B_ID
	aadd(aIndexEsp, {"CJ2",3}) //CJ2_FILIAL+CJ2_ID //só reenviar
	aadd(aIndexEsp, {"CIN","CIN_FILIAL+CIN_ID"}) //nao vai usar indice
	aadd(aIndexEsp, {"F27",3}) //F27_FILIAL+F27_ID
	aadd(aIndexEsp, {"F28",4}) //F28_FILIAL+F28_ID
	aadd(aIndexEsp, {"DA1",2}) //DA1_FILIAL+DA1_CODPRO+DA1_CODTAB+DA1_ITEM

	aXFilais := StrToKArr(cXFiliais,"/")

	For nX := 1 to Len(oJCarga["tables"])
		oJTables := oJCarga["tables"][nX]
		If ValType(oJTables["nametable"]) == "C"
			cTable := oJTables["nametable"]
			If ValType(oJTables["branches"]) == "C"
				aBranches := StrTokArr2(oJTables["branches"],"/",.T.)
				If ChkFile(cTable,.F.)
					
					//valida se possui registros da filial
					nPos := 0
					for nY := 1 to len(aXFilais)
						cBranchUsed := xFilial(cTable, aXFilais[nY])
						nPos := aScan( aBranches, { |x| x == cBranchUsed } )
						if nPos > 0
							EXIT
						endif
					next nX
					If nPos <= 0
						PRT_MSG("A tabela "+cTable+" não possui registros da filial "+cBranchUsed+".")
						Loop //vai para a proxima tabela (For nX)
					EndIf

					cTablePrefix := IIf( SubStr(cTable,1,1) == "S", SubStr(cTable,2,3), cTable )
					DbSelectArea(cTable)

					nIndice := 1
					if (nY := aScan(aIndexEsp, {|x| x[1]==cTable })) > 0
						nIndice := iif(valtype(aIndexEsp[nY][2])=+"N",aIndexEsp[nY][2],-1)
					else
						cX2Unico := FWX2Unico(cTable) 
						if !empty(cX2Unico)
							aIndex := FWSIXUtil():GetAliasIndexes( cTable  ) 
							For nY := 1 to len(aIndex)
								if Alltrim(UPPER(cX2Unico)) == Alltrim(UPPER((cTable)->(IndexKey(nY))))
									nIndice := nY
									EXIT
								endif
							next nY
						endif
					endif

					//nao vai usar indice
					if nIndice > 0
						(cTable)->(DbSetOrder(nIndice))
						cChave := (cTable)->(IndexKey(nIndice))
						cChave := UPPER(cChave)
						cChave := StrTran(cChave, 'DTOS', '')
						cChave := StrTran(cChave, 'STR', '')
						cChave := StrTran(cChave, '(', '')
						cChave := StrTran(cChave, ')', '')
					else	
						CChave := aIndexEsp[nY][2]
					endif
					If !Empty(cChave)
						aChave := StrTokArr2(cChave,"+")
						//cConCh := (cTable)->&(cChave)
						aStruct := (cTable)->(DBStruct()) // Pega a estrutura do banco de dados
						For nY := 1 to Len(oJTables[cTable])

							oJRows := oJTables[cTable][nY]

							//valida se o registro é da filial corrente
							If ValType(oJRows[cTablePrefix+"_FILIAL"]) == "C"
								If Empty(oJRows[cTablePrefix+"_FILIAL"]) //para reduzir tamanho da STRING, quando caracter vazio, vem apenas com ""
									cBranchRow := Space(TamSx3(cTablePrefix+"_FILIAL")[1])
								Else
									cBranchRow := oJRows[cTablePrefix+"_FILIAL"]
								EndIf
								for nZ := 1 to len(aXFilais)
									cBranchUsed := xFilial(cTable, aXFilais[nZ])
									if (cBranchUsed == cBranchRow) //se devo importar o registro
										EXIT
									endif
								next nZ
								If .Not. (cBranchUsed == cBranchRow)
									Loop //vai para o proximo registro (For nY)
								EndIf
							EndIf

							cChvRow := ""
							aChvRow := {}
							For nZ := 1 to Len(aChave)
								If ValType(oJRows[aChave[nZ]]) == "C"
									If Empty(oJRows[aChave[nZ]]) //para reduzir tamanho da STRING, quando caracter vazio, vem apenas com ""
										cChvRow += Space(TamSx3(aChave[nZ])[1])
										aadd(aChvRow, Space(TamSx3(aChave[nZ])[1]))
									ElseIf GetSx3Cache(aChave[nZ],"X3_TIPO") == "D"
										cChvRow += DtoS(CtoD(oJRows[aChave[nZ]]))
										aadd(aChvRow, DtoS(CtoD(oJRows[aChave[nZ]])) )
									Else
										cChvRow += oJRows[aChave[nZ]]
										aadd(aChvRow, oJRows[aChave[nZ]] )
									EndIf
								Else //
									PRT_ERROR("O campo ["+aChave[nZ]+"] da chave ["+cChave+"], indice ["+cValToChar(nIndice)+"], para a tabela "+cTable+" não existe no JSON.")
									cChvRow := ""
									//Exit //sai do For nZ
									Return .F.
								EndIf
							Next nZ

							If !Empty(cChvRow)
									
								If ValType(oJRows["DEL"]) == "C" .and. oJRows["DEL"] == "*" //deleta registro
									If nIndice > 0 .AND. (cTable)->(DbSeek(cChvRow)) //se o registro existe, deleta
										If Reclock(cTable, .F.)
											(cTable)->(DbDelete())
											(cTable)->(MsUnlock())
										EndIf
									elseif nIndice < 0 .AND. MyQrySeek(cTable, aChave, aChvRow) //por query
										If Reclock(cTable, .F.)
											(cTable)->(DbDelete())
											(cTable)->(MsUnlock())
										EndIf
									EndIf
								Else //altera ou inclui registro
									if nIndice > 0 
										lInclui := !((cTable)->(DbSeek(cChvRow)))
									elseif nIndice < 0
										lInclui := !(MyQrySeek(cTable, aChave, aChvRow))
									endif
									PRT_MSG("cTable: "+cTable)
									PRT_MSG("cChvRow: "+cChvRow)
									PRT_MSG("lInclui: "+IIF(lInclui,".T.",".F")+"")
									If Reclock(cTable, lInclui)
										For nW := 1 to Len(aStruct)
											If ValType(oJRows[aStruct[nW][1]]) == "C" .or. ;
													ValType(oJRows[aStruct[nW][1]]) == "N" .or. ;
													ValType(oJRows[aStruct[nW][1]]) == "L"
												If aStruct[nW][2] == "D"
													(cTable)->&(aStruct[nW][1]) := CtoD(oJRows[aStruct[nW][1]])
												Else
													If aStruct[nW][2] == "C"
														(cTable)->&(aStruct[nW][1]) := SubStr(oJRows[aStruct[nW][1]],1,aStruct[nW][3])
													ElseIf aStruct[nW][2] == "N"
														nTamPic := Iif(aStruct[nW][4]>0,aStruct[nW][3]-(aStruct[nW][4]+1),aStruct[nW][3])
														nTamDec := aStruct[nW][4]
														lPositivo := (oJRows[aStruct[nW][1]]>=0)
														If abs(oJRows[aStruct[nW][1]]) > val(replicate('9',nTamPic-iif(lPositivo,0,1))+'.'+replicate('9',nTamDec))
															(cTable)->&(aStruct[nW][1]) := val(replicate('9',nTamPic-iif(lPositivo,0,1))+'.'+replicate('9',nTamDec))*(iif(lPositivo,1,-1))
														Else
															(cTable)->&(aStruct[nW][1]) := oJRows[aStruct[nW][1]]
														EndIf
													Else
														(cTable)->&(aStruct[nW][1]) := oJRows[aStruct[nW][1]]
													EndIf
												EndIf
											EndIf
										Next nW
										(cTable)->(MsUnlock())
									EndIf
								EndIf
							EndIf

						Next nY
					Else
						PRT_ERROR("Não foi possível obter a chave (IndexKey) da tabela "+cTable+".")
						Return .F.
					EndIf
				Else
					PRT_ERROR("Não foi possível abrir a tabela "+cTable+". Ela pode estar aberta de modo exclusivo por outro programa.")
					Return .F.
				EndIf
			Else
				PRT_ERROR("Não foi encontrado o rótulo (label) no JSON com as filiais da tabela <branches>")
				Return .F.
			EndIf
		Else
			PRT_ERROR("Não foi encontrado o rótulo (label) no JSON com nome da tabela <nametable>")
			Return .F.
		EndIf
	Next nX

	FreeObj( oJTables )
	oJTables := Nil

	FreeObj( oJRows )
	oJRows := Nil

Return .T.

//posiciona no registro a partir da query
Static Function MyQrySeek(cTable, aChave, aChvRow)

	Local nX
	Local lRet := .F.
	Local cQry
	
	cQry := " SELECT R_E_C_N_O_"
	cQry += " FROM "+RetSqlName(cTable)+" "
	cQry += " WHERE "
	cQry += " D_E_L_E_T_ = ' ' "
	For nX := 1 to len(aChave)
		cQry += " AND "+aChave[nX]+" = '"+aChvRow[nX]+"' "
	Next nX
	
	If Select("QRYTAB") > 0
		QRYTAB->(DbCloseArea())
	EndIf
	cQry := ChangeQuery(cQry)
	TcQuery cQry New Alias "QRYTAB" // Cria uma nova area com o resultado do query
	QRYTAB->(DbGoTop())
	
	if QRYTAB->(!Eof()) 
		(cTable)->(DbGoTo(QRYTAB->R_E_C_N_O_))
		lRet := .T.
	endif

	If Select("QRYTAB") > 0
		QRYTAB->(DbCloseArea())
	EndIf

Return lRet

//Função para geração de carga completa em arquivos JSON
User Function CGCLOADR(lOther) //U_CGCLOADR(.T.)

	Local lOk := .F.
	Local aFiles := {}
	Local nX := 1
	Local cPathJson := ""//"C:\Temp\"
	Local cFilePref	:= "cargacompleta_"+dtos(date())+StrTran(Time(),":")
	Default lOther := .F.

	if !TelaGerarCarga(@cPathJson)
		Return
	endif

	//pega os registros a serem gravados
	if lOther
		Processa({|lEnd| lOk := OtherExpCarga(ENTIRE, cPathJson, cFilePref, @aFiles) }, NIL, NIL, .T.)
	else
		Processa({|lEnd| lOk := ExportarCarga(ENTIRE, cPathJson, cFilePref, @aFiles) }, NIL, NIL, .T.)
	endif
	
	if lOk
		nX := FZip(cPathJson+cFilePref+".zip",aFiles, cPathJson)
		If nX <> 0
			MsgInfo("Não foi possível compactar o arquivo de carga!")
		Else
			MsgInfo("Arquivo de carga ["+cFilePref+".zip] criado com sucesso!")
		Endif

		for nX := 1 to len(aFiles)
			if FILE(aFiles[nX])
				FErase(aFiles[nX])
			ENDIF
		next nX
	endif

Return

/*/{Protheus.doc} TelaGerarCarga
Tela para gerar carga
@author Danilo Brito
@since 24/09/2018
@version 1.0
@return Nil
@type function
/*/
Static Function TelaGerarCarga(cPathJson)

	Local aSay := {}
	Local aBut := {}
	Local lOk		:= .F.
	Local cArquivo	:= ""

	//texto da tela
	aAdd(aSay, "Esta rotina tem por objetivo gerar arquivo de carga de dados completo.")
	aAdd(aSay, "O arquivo gerado poderá ser importado nos hosts inferiores (CentralPDV e PDVs).")
	aAdd(aSay, "Antes de iniciar a geração do arquivo, é indicado parar o JOB de Carga automática")
	aAdd(aSay, "dos hosts inferiores (CentralPDV e PDVs) que irão receber a carga, para evitar")
	aAdd(aSay, "concorrencia de registros alterados durante o processamento.")
	aAdd(aSay, "Selecione uma pasta para a geração do arquivo de carga.")
	aAdd(aSay, "Obs. Esse processo pode demorar alguns minutos.")

	//botoes da tela
	aAdd(aBut, {14, .T., {|| cArquivo := RetFolder()} })		// Abrir pasta
	aAdd(aBut, {01, .T., {|| iif(empty(cArquivo),MsgInfo("Selecione uma pasta para geração do arquivo de carga!","Pasta"),(lOk := .T., FechaBatch())) } })	// Confirma
	aAdd(aBut, {02, .T., {|| (lOk := .F., FechaBatch())} })	// Cancela

	//abre tela
	FormBatch("Geração de Carga Completa", aSay, aBut)

	if lOk
		cPathJson := cArquivo
	endif

Return lOk

Static Function RetFolder()

	Local cArquivo := cGetFile( "Selecione Diretoriro | " , OemToAnsi( "Selecione Diretorio" ) , NIL , "C:\" , .F. , GETF_LOCALHARD+GETF_RETDIRECTORY )

	if empty(cArquivo)
		Return ""
	endif
	
	//tiro a ultima barra pra validar existencia do diretorio
	iif((substr(cArquivo,Len(cArquivo),1)=iif(IsSrvUnix(),"/","\")), cArquivo:=SubStr(cArquivo,1,len(cArquivo)-1), )

	if !File(cArquivo)
		MsgInfo("Pasta selecionada não existe!")
		Return ""
	endif
	
	//adiciono a ultima barra para uso na rotina
	iif((substr(cArquivo,Len(cArquivo),1)<>iif(IsSrvUnix(),"/","\")), cArquivo:=cArquivo+iif(IsSrvUnix(),"/","\"), )

Return cArquivo

//Função de leitura de carga no banco RabbitMQ
User Function CGCLOADP(lForce) //U_CGCLOADP(.T.)

	Local lOk := .T.
	Local cFile 
	Local cISCPDV       := GetPvProfString("CPDV", "ISCPDV", "", GetAdv97()) // Felipe Sousa - 25/01/2024 - Verifico se é central PDV
	Local cCOMCPDV      := GetPvProfString("CPDV", "COMCPDV", "", GetAdv97()) // Felipe Sousa - 25/01/2024 - Verifico se é PDV
	//Local cIsCPDV := GetPvProfString("CONEXAOPDV", "CONECTADO", "", GetAdv97())
	Local cIsRMQ := GetPvProfString("STFLoadPdv", "Parm1", "", GetAdv97())
	Local cXFiliais := GetPvProfString("STFLoadPdv", "Parm5", "", GetAdv97())

	Default lForce := .F.
	
	if empty(cXFiliais)
		cXFiliais := GetPvProfString("STFLoadPdv", "Parm3", "", GetAdv97())
	endif

	if !lForce .AND. !(cISCPDV == "1" .OR. cCOMCPDV == "1")
		MsgInfo("Não permitido importação de carga em ambientes que não são PDV ou CentralPDV.")
		Return lOk
	endif

	if !lForce .AND. cIsRMQ <> "URABMQLP"
		MsgInfo("Não permitido importação de carga em ambientes que não estão configurados a carga RabbitMQ.")
		Return lOk
	endif

	if !lForce .AND. empty(cXFiliais)
		MsgInfo("Não encontrado configuração de filiais do host para o processamento da carga!")
		Return lOk
	endif

	if lForce 
		cXFiliais := cFilAnt
	endif

	if !TelaCarregaCarga(@cFile)
		Return
	endif

	if empty(cFile)
		Return
	endif

	//pega os registros a serem gravados
	Processa({|lEnd| lOk := ProcCarregamento(cFile, cXFiliais) }, NIL, NIL, .T.)

Return lOk

/*/{Protheus.doc} TelaGerarCarga
Tela para gerar carga
@author Danilo Brito
@since 24/09/2018
@version 1.0
@return Nil
@type function
/*/
Static Function TelaCarregaCarga(cFileCarga)

	Local aSay := {}
	Local aBut := {}
	Local lOk		:= .F.
	Local cArquivo	:= ""

	//texto da tela
	aAdd(aSay, "Esta rotina tem por objetivo Importar arquivo de carga de dados completo.")
	aAdd(aSay, "O arquivo gerado poderá ser importado nos hosts inferiores (CentralPDV e PDVs).")
	aAdd(aSay, "Antes de iniciar a geração do arquivo, é indicado parar o JOB de Carga automática")
	aAdd(aSay, "deste host, para evitar concorrencia de registros alterados durante o processamento.")
	aAdd(aSay, "")
	aAdd(aSay, "Selecione o arquivo de carga para o processamento.")
	aAdd(aSay, "Obs. Esse processo pode demorar alguns minutos.")

	//botoes da tela
	aAdd(aBut, {14, .T., {|| cArquivo := RetFile() } })		// Abrir pasta
	aAdd(aBut, {01, .T., {|| iif(empty(cArquivo),MsgInfo("Selecione um arquivo para geração do arquivo de carga!","Pasta"),(lOk := .T., FechaBatch())) } })	// Confirma
	aAdd(aBut, {02, .T., {|| (lOk := .F., FechaBatch())} })	// Cancela

	//abre tela
	FormBatch("Importação de Carga Completa", aSay, aBut)

	if lOk
		cFileCarga := cArquivo
	endif

Return lOk

Static Function ProcCarregamento(cFile, cXFiliais)

	Local lOk := .T.
	Local cTable
	Local cQry
	Local nX := 1
	Local oJResponse := Nil
	Local bObject := {|| JsonObject():New()}
	Local cJson := ""
	Local xRet := 1
	Local cPathJson
	Local aFileList
	Local nQtdFiles
	Local cLastTable := "XXXXXX"

	cPathJson := SubStr(cFile, 1, RAt("\",cFile))
	aFileList := FListZip(cFile, @xRet)

	if xRet == 0
		nQtdFiles := len(aFileList)
		ProcRegua( (nQtdFiles * 3) + 1 )

		IncProc("Descompactando arquivo da carga ...")
						
		xRet := FUnZip(cFile,cPathJson)

		if xRet == 0
			For nX := 1 to nQtdFiles

				IncProc("Lendo Arquivo JSON tabela "+SubStr(aFileList[nX][1],AT("_",aFileList[nX][1],28)+1,3)+"... ("+cValToChar(nX)+"/"+cValToChar(nQtdFiles)+")")

				// Le a string JSON do arquivo do disco 
				cJson := readfile(cPathJson+aFileList[nX][1])

				If ValType(cJson) != 'C'
					cJson := cValToChar(cJson)
				EndIf

				oJResponse := Eval(bObject)
				xRet := oJResponse:FromJson( cJson )

				If ValType(xRet) == "U"
					cTable:= oJResponse["tables"][1]["nametable"]
					DbSelectArea(cTable)

					IncProc("Limpando Tabela "+cTable+"... ("+cValToChar(nX)+"/"+cValToChar(nQtdFiles)+")")

					if cTable <> cLastTable
						cQry := "DELETE FROM " + RetSQLName(cTable) + " " + CRLF
						If TCSqlExec(cQry) < 0
							MsgInfo("Não foi possível limpar tabela "+cTable+". " + TCSqlError())
							lOk := .F.
							Exit //sai do For nX
						EndIf
					endif

					cLastTable := cTable

					IncProc("Importando Tabela "+cTable+"... ("+cValToChar(nX)+"/"+cValToChar(nQtdFiles)+")")
					If !ImportarCarga(oJResponse,cXFiliais)
						MsgInfo("Não foi possível importar a carga.")
						lOk := .F.
						Exit //sai do For nX
					EndIf
				Else
					MsgInfo("Falha ao popular JsonObject. Erro: " + xRet)
					lOk := .F.
					Exit //sai do For nX
				EndIf

				FreeObj( oJResponse )
				oJResponse := Nil

			next nX

			for nX := 1 to len(aFileList)
				if FILE(cPathJson+aFileList[nX][1])
					FErase(cPathJson+aFileList[nX][1])
				ENDIF
			next nX

			if lOk
				MsgInfo("Importação da carga realizada com sucesso!")	
			endif
		else
			MsgInfo("Erro ao descompactar arquivo ZIP da carga")
			lOk := .F.
		endif

	else
		MsgInfo("Erro ao obter lista de arquivos da carga")
		lOk := .F.
	endif


Return lOk

Static Function RetFile()

	Local cArquivo := cGetFile("Arquivos zip (*.zip)|*.zip", "Abrir arquivo", 1, "C:\", .F., nOR( GETF_LOCALHARD, GETF_LOCALFLOPPY ), .T., .T.)

	if !empty(cArquivo)
		if !File(alltrim(cArquivo))
			MsgInfo("Arquivo não pode ser localizado.","Atençao")
			return("")
		endif
	endif

Return cArquivo

Static Function ReadFile(cFile)

	Local cBuffer := ''
	Local nH , nTam

	nH := Fopen(cFile)

	IF nH != -1
		nTam := fSeek(nH,0,2)
		fSeek(nH,0)
		cBuffer := space(nTam)
		fRead(nH,@cBuffer,nTam)
		fClose(nH)
	Else
		MsgStop("Falha na abertura do arquivo ["+cFile+"]","FERROR "+cValToChar(Ferror()))
	Endif

Return cBuffer


Static Function OtherExpCarga(nType, cPathJson, cFilePref, aFiles)

	Local oTransferTables := Nil
	Local nCount := 0
	Local nQtdTab := 0
	Local aRet      := {}
	Local aParamBox := {}

	Local bObject := {|| JsonObject():New()}
	Local oJson   := Nil
	Local oJsonTmp := Nil

	Local cServerIni := GetAdv97()
	Local cSecao := "General"
	Local cChave := "MaxStringSize"
	Local nPadrao := 1
	Local nMaxStrSize := GetPvProfileInt(cSecao, cChave, nPadrao, cServerIni) //1 Mb (valor mínimo padrão) -> 500 Mb (valor máximo permitido)

	/*
		1MB são 1.048.576 caracteres
		Vamos considerar que um único registro tenha 10.000 caracteres
	*/
	Local nTamRow := 10000 //número de caracteres por registro

	Default nType := INCREMENTAL
	Default cPathJson := ""
	Default cFilePref := ""
	Default aFiles := {}

	Private nLimRecord := Min(Int((nMaxStrSize*1048576) / nTamRow) , 10000)
	Private nRecord := 0
	Private nRecordsProcessed := 0

	If nType == INCREMENTAL
		oJson   := Eval(bObject)
		oJson["version"] := "0.0.1"
		oJson["tables"]  := {}
	else
		if nLimRecord < 10000 
			Msginfo("MaxStringSize configurado com valor menor que 100MB. Para carga completa recomendamos que seja no minimo 100MB. Processo abortado!")
			Return 0
		endif
	endif

	AADD(aParamBox,{11,"Tabelas","",".T.",".T.",.t.}) // Descricao
	AADD(aParamBox,{11,"Filiais","",".T.",".T.",.t.}) // Descricao

	If ParamBox(aParamBox,"Parametro",@aRet,,,,,,,,.f.) // Parametro
		if empty(aRet[01])
			Return 0
		endif
		aoTables := StrToKarr(aRet[01]," ") 
	EndIf

	//Retorno -> oTransferTables: Objeto do tipo RedisLoadTransferTables
	oTransferTables := MontaTranfTable( aoTables , aRet[02]) //array de tabelas transferiveis para a carga (MBU_CODIGO)

	If nType == ENTIRE
		nQtdTab := Len( oTransferTables:aoTables)
		ProcRegua( nQtdTab )
	endif

	// Para cada tabela
	For nCount := 1 To Len( oTransferTables:aoTables )
		If nType == ENTIRE
			IncProc("Exportando tabela "+oTransferTables:aoTables[nCount]:cTable+"... ("+cValtoChar(nCount)+"/"+cValToChar(nQtdTab)+")")
		endif
		oJsonTmp := ExportComplete( oTransferTables:aoTables[nCount], nType, cPathJson, cFilePref, @aFiles)
		If nType == INCREMENTAL .AND. ValType(oJsonTmp) == "J"
			aadd( oJson["tables"], oJsonTmp )
		EndIf
		If nType == INCREMENTAL .AND. nRecord > nLimRecord
			Exit //sai do For
		EndIf
	Next nCount

	FreeObj( oJsonTmp )
	oJsonTmp := Nil

Return iif(nType == INCREMENTAL,oJson, len(aFiles)>0)


Static Function MontaTranfTable( aoTables , cXFiliais)
	
	Local nX, nY
	Local oTransferTables	:= RedisLoadTransferTables():New()
	Local oTempTable		:= Nil
	Local aBranches			:= {}
	Local aTmpFil			:= {}

	Default cXFiliais := cFilAnt

	for nX := 1 to len(aoTables)
	
		oTempTable := Nil

		oTempTable := RedisLoadCompleteTable():New( aoTables[nX] )
		aBranches := {}
		aTmpFil := StrToKArr(cXFiliais," ")
		
		for nY := 1 to len(aTmpFil)
			if !empty(aTmpFil[nY]) .AND. FWFilExist(,aTmpFil[nY])
				aAdd( aBranches, xFilial(aoTables[nX], aTmpFil[nY]) )
			endif
		next nY
				
		oTempTable:aBranches := aBranches
		oTempTable:cFilter := ""
		oTempTable:cQtyRecords := 0
		
		aAdd( oTransferTables:aoTables, oTempTable )

	next nX

Return oTransferTables

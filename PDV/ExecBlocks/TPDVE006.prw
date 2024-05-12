#INCLUDE "PROTHEUS.CH"
#INCLUDE "TBICONN.CH"
#INCLUDE "TOPCONN.CH"

/*/{Protheus.doc} TPDVE006
Rotina que recebe a conexao RPC para listar os titulos NCC/RA do cliente

@author pablo
@since 04/05/2019
@version 1.0
@return ${return}, ${return_description}

@type function
/*/
User Function TPDVE006(cCliente, cLojaCli, cBusca, lSaque, cPlaca, cCPFMotor, lConfCash)

	Local aArea     := GetArea()
	Local aAreaSE1  := SE1->(GetArea())
	Local lAchouSE1 := .F.
	Local aNccs     := {}
	Local lReqCliPad := SuperGetMv("MV_XRQCPAD",,.F.) //permite requsição para cliente padrao? 
	Local lVldNCC    := SuperGetMV("MV_LJVLNCC",,.F.) // Indica se valida vencimento da NCC
	Local cMoeda	:= SuperGetMV("MV_MOEDA1")
	Local dDataValid := dDataBase
	Local cLog := ''

	Default cBusca    := "*"
	Default lSaque    := .F. //se retorna somente requisição de saque
	Default cPlaca    := ""
	Default cCPFMotor := ""
	Default lConfCash := .F.

	//conout("TPDVE006 - INICIO")

	cAliasSE1 := "NCCFILSE1"

	If Select(cAliasSE1) > 0
		(cAliasSE1)->( DbCloseArea() )
	Endif

	cQuery := "SELECT SE1.E1_CLIENTE, SE1.E1_LOJA, SE1.E1_TIPO, SE1.E1_STATUS, SE1.R_E_C_N_O_ RECSE1"
	cQuery += 	" FROM " + RetSQLName("SE1") + " SE1"

	//cQuery += " LEFT JOIN " + RetSQLName("U57") +" U57"
	//cQuery += 	" ON (SE1.E1_XCODBAR = U57.U57_PREFIX+U57.U57_CODIGO+U57.U57_PARCEL"
	//cQuery += 	" AND U57.D_E_L_E_T_ = SE1.D_E_L_E_T_"

	//cQuery += " LEFT JOIN " + RetSQLName("U56") +" U56"
	//cQuery += 	" ON U56.U56_FILIAL  = U57.U57_FILIAL"
	//cQuery += 	" AND U56.U56_PREFIX = U57.U57_PREFIX"
	//cQuery += 	" AND U56.U56_CODIGO = U57.U57_CODIGO"
	//cQuery += 	" AND U56.U56_CODCLI = SE1.E1_CLIENTE"
	//cQuery += 	" AND U56.U56_LOJA   = SE1.E1_LOJA"
	//cQuery += 	" AND U56.U56_FILAUT LIKE '%"+AllTrim(cFilAnt)+"%'"
	//cQuery += 	" AND U56.D_E_L_E_T_ = U57.D_E_L_E_T_"

	cQuery += " WHERE SE1.D_E_L_E_T_ = ' '" //E1_FILIAL  = '"+xFilial("SE1")+"'" -> todas filiais

	If lReqCliPad .AND. !Empty(cBusca) .and. cBusca <> "*" //so mostro creditos do consumidor, caso for informado o numero do titulo ou requisiçao
		cQuery += " AND ((SE1.E1_CLIENTE = '"+cCliente+"' AND SE1.E1_LOJA    = '"+cLojaCli+"') "
		cQuery += GetCliPads() //pega clientes padrao das filiais
		cQuery += " )"
	else
		cQuery += " AND SE1.E1_CLIENTE = '"+cCliente+"'"
		cQuery += " AND SE1.E1_LOJA    = '"+cLojaCli+"'"
	endif
	cQuery += " AND SE1.E1_TIPO IN ('RA ', 'NCC')" //recebimento antecipado ou nota de credito
	cQuery += " AND SE1.E1_SALDO   > 0" //E1_STATUS  = 'A' -> A=Em Aberto

	If !Empty(cBusca) .and. cBusca <> "*" //Cód. Barras / Núm. Título
		cQuery += " AND (RTRIM(LTRIM(SE1.E1_XCODBAR)) = '" + AllTrim(cBusca) + "' OR RTRIM(LTRIM(SE1.E1_NUM)) = '" + AllTrim(cBusca) + "') "
	EndIf

	If lVldNCC //Verifica se usa validade na NCC. Se usar Valida
		cQuery += " AND SE1.E1_VENCREA >= '" + DtoS(dDataValid) + "'"
	EndIf

	cQuery += " ORDER BY SE1.E1_FILIAL, SE1.E1_NUM, SE1.E1_PARCELA, SE1.E1_TIPO "

	//conout("TPDVE006 - cquery " + cQuery)

	cQuery := ChangeQuery(cQuery)
	TcQuery cQuery NEW Alias &(cAliasSE1)
	
	DbSelectArea(cAliasSE1)
	lAchouSE1 := (cAliasSE1)->( !EoF() )

	If lAchouSE1

		U56->(DbSetOrder(1)) //U56_FILIAL+U56_PREFIX+U56_CODIGO
		U57->(DbSetOrder(1)) //U57_FILIAL+U57_PREFIX+U57_CODIGO+U57_PARCEL
		cLog := ""
		While !(cAliasSE1)->(EOF()) //.AND. (cAliasSE1)->E1_CLIENTE == cCliente .AND. (cAliasSE1)->E1_LOJA == cLojaCli //.AND. (cAliasSE1)->E1_STATUS == "A"

			SE1->(DbGoTo((cAliasSE1)->RECSE1))

			//-- valida filiais autorizadas
			If !Empty(SE1->E1_XCODBAR)
				If U56->(DbSeek(xFilial("U56")+SubStr(SE1->E1_XCODBAR,1,TamSx3("U56_PREFIX")[1]+TamSx3("U56_CODIGO")[1]))) .and. !(AllTrim(cFilAnt)$U56->U56_FILAUT)
					//conout("TPDVE006 - Requisição permitida somente para as filiais: "+U56->U56_FILAUT+".")
					(cAliasSE1)->(dbSkip())
					Loop
				EndIf
			EndIf

			//-- valida dados do saque
			If lSaque
				//conout("TPDVE006 - Validação de requisição de saque.")
				If !Empty(SE1->E1_XCODBAR)

					If U57->(DbSeek(xFilial("U57")+SE1->E1_XCODBAR))
						//If Empty(U57->U57_XGERAF) .OR. U57->U57_XGERAF == "F"
							If U57->U57_TUSO = 'S' //S - USO PARA SAQUE
								If Empty(U57->U57_PLACA) .or. (U57->U57_PLACA = cPlaca)
									If Empty(U57->U57_MOTORI) .or. (U57->U57_MOTORI = cCPFMotor)
										//OK - REQUISICAO PODE SER UTILIZADA
										//conout("TPDVE006 - OK - REQUISICAO PODE SER UTILIZADA.")
									Else
										cLog += "Requisição: "+SE1->E1_XCODBAR + CRLF + "Saque permitido somente para o CPF: "+U57->U57_MOTORI+"." + CRLF + CRLF
										//conout("TPDVE006 - Saque permitido somente para o CPF: "+U57->U57_MOTORI+".")
										(cAliasSE1)->(dbSkip())
										Loop
									EndIf
								Else
									cLog += "Requisição: "+SE1->E1_XCODBAR + CRLF + "Saque permitido somente para a placa: "+U57->U57_PLACA+"." + CRLF + CRLF
									//conout("TPDVE006 - Saque permitido somente para a placa: "+U57->U57_PLACA+".")
									(cAliasSE1)->(dbSkip())
									Loop
								EndIf
							Else
								cLog += "Requisição: "+SE1->E1_XCODBAR + CRLF + "Requisição não é do tipo saque: 'U57_TUSO = S'." + CRLF + CRLF
								//conout("TPDVE006 - Requisição não é do tipo saque: U57_TUSO = S.")
								(cAliasSE1)->(dbSkip())
								Loop
							EndIf
						//Else
						//	cLog += "Requisição: "+SE1->E1_XCODBAR + CRLF + "Requisição com pendência financeira, não pode ser utilizada." + CRLF + CRLF
						//	EndIf
						//	//conout("TPDVE006 - Requisição com pendência financeira, não pode ser utilizada.")
						//	(cAliasSE1)->(dbSkip())
						//	Loop
						//EndIf
					Else
						cLog += "Requisição: "+SE1->E1_XCODBAR + CRLF + "Não encontrado requisição correspondente." + CRLF + CRLF
						//conout("TPDVE006 - Não encontrado requisição correspondente.")
						(cAliasSE1)->(dbSkip())
						Loop
					EndIf
				Else
					//conout("TPDVE006 - Titulo não esta amarrado a uma requisição. Não pode ser sacado.")
					(cAliasSE1)->(dbSkip())
					Loop
				EndIf
			EndIf

			/*
				Posicoes de aNCCs

				aNCCs[x,1]  = .F.	// Caso a NCC seja selecionada, este campo recebe TRUE
				aNCCs[x,2]  = SE1->E1_SALDO
				aNCCs[x,3]  = SE1->E1_NUM
				aNCCs[x,4]  = SE1->E1_EMISSAO
				aNCCs[x,5]  = SE1->(Recno())
				aNCCs[x,6]  = SE1->E1_SALDO
				aNCCs[x,7]  = cMoeda
				aNCCs[x,8]  = SE1->E1_MOEDA
				aNCCs[x,9]  = SE1->E1_PREFIXO
				aNCCs[x,10] = SE1->E1_PARCELA
				aNCCs[x,11] = SE1->E1_TIPO
				aNCCs[x,12] = SE1->E1_XPLACA
				aNCCs[x,13] = SE1->E1_XMOTOR
				aNCCs[x,14] = SE1->E1_FILIAL
				aNCCs[x,15] = SE1->E1_XCODBAR
			*/

			AAdd(aNccs, {.F.				, SE1->E1_SALDO 	, SE1->E1_NUM			    , SE1->E1_EMISSAO	,;
	 					 SE1->(Recno())		, SE1->E1_SALDO 	, cMoeda					, SE1->E1_MOEDA	  	,;
	  					 SE1->E1_PREFIXO	, SE1->E1_PARCELA	, SE1->E1_TIPO 				, SE1->E1_XPLACA	,;
	  					 SE1->E1_XMOTOR		, SE1->E1_FILIAL    , SE1->E1_XCODBAR} )

		(cAliasSE1)->(dbSkip())
		EndDo
		If lConfCash .and. !Empty(cLog)
			AVISO("Atenção", cLog, {"Fechar"},3,,,,.T.)
		EndIf
	EndIf

	(cAliasSE1)->( DbCloseArea() )

	//conout("TPDVE006 - " + varinfo("",aNccs))
	//conout("TPDVE006 - FIM ")

	RestArea(aAreaSE1)
	RestArea(aArea)

Return(aNccs)


//Varre o cliente padrão de todas filiais do grupo cEmpAnt, e monta query
Static Function GetCliPads()

	Local cRet := ""
	Local aArea		:= GetArea()						// Salva posicionamento atual
	Local cCliPad	:= "" //SuperGetMV("MV_CLIPAD")			// Cliente padrao
	Local cLojaPad	:= "" //SuperGetMV("MV_LOJAPAD")		// Loja do cliente padrao
	Local aFilPesq   := FWLoadSM0()
	Local nX
	Local bGetMvFil := {|cPar,cFil| SuperGetMV(cPar,,,cFil) }

	For nX := 1 To Len(aFilPesq) //varre o cliente padrão de todas filiais do grupo

		If cEmpAnt == aFilPesq[nX][1]

			cCliPad	 := Eval(bGetMvFil, "MV_CLIPAD", aFilPesq[nX][2]) // Cliente padrao
			cLojaPad := Eval(bGetMvFil, "MV_LOJAPAD", aFilPesq[nX][2]) // Loja do cliente padrao

			cRet += "OR (SE1.E1_CLIENTE = '"+cCliPad+"' AND SE1.E1_LOJA = '"+cLojaPad+"') "

		EndIf

	Next nX

	RestArea(aArea)

Return cRet

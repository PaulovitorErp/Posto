#INCLUDE 'PROTHEUS.CH'
#INCLUDE 'FWMVCDEF.CH'
#INCLUDE 'TOPCONN.CH'
#INCLUDE 'RWMAKE.CH'
#INCLUDE 'TBICONN.CH'

/*/{Protheus.doc} TRETE023
Job para geração/estorno de financeiro das requisições incluidas no PDV - OFF-LINE

- GERAÇÂO DE FINANCEIRO REQUISICOES PRE PAGA DO TIPO DEPOSITO NO PDV
- GERAÇÂO DE FINANCEIRO REQUISICOES POS PAGA DO TIPO SAQUE (SAQUE NO PDV ou VALE MOTORISTA)
- ESTORNO DE REQUISICOES POS PAGA (SAQUE NO PDV)
- ESTORNO DE REQUISICOES PRE PAGA (DEPOSITO NO PDV)
- ESTORNO DE REQUISICOES PRE PAGA (SAQUE NO PDV)

@author Totvs GO
@since 02/05/2019
@version 1.0
@return Nil
@type function
/*/
User Function TRETE023(cChavU57, cMsgErro)

	Local lGerou 		:= .T.
	Local aArea    		:= {}
	Local aAreaU56, aAreaU57, aAreaSA6, aAreaSE1, aAreaSE5
	Local cNatNdc  		:= ""
	Local cNatNcc  		:= ""
	Local aParcS   		:= {}
	Local cParc    		:= ""
	Local cTpSE1   		:= "RP" //Requisição Pós-Paga
	Local cPfRqSaq  	:= "RPS" // Prefixo de Titulo de Requisicoes de Saque
	Local nX :=0, nI:=0
	Local cSimbMoeda 	:= ""
	Local cQry		 	:= ""
	Local cBanco	 	:= ""
	Local cAgencia   	:= ""
	Local cConta     	:= ""
	Local aRecU57Mail	:= {} //guarda os recnos das requisições que vao gerar email
	Local _ddatabase	:= CTOD("")
	Local lExistSE1		:= .F.
	
	Default cChavU57 	:= ""
	Default cMsgErro 	:= ""

	Private cErroExec	:= ""

	//Conout(">> INICIO TRETE023 - GERA/ESTORNA FINANCEIRO REQUISIÇÕES")

	cNatNdc    := SuperGetMV( "MV_XNATNDC", .T., "OUTROS" )
	cNatNcc    := SuperGetMV( "MV_XNATRPS", .T., "OUTROS" )
	cParc      := PADL( "0", TAMSX3("E1_PARCELA")[1], "0" )
	cSimbMoeda := SuperGetMV( "MV_SIMB1" )
	cPfRqSaq   := AllTrim(SuperGetMV("MV_XPRFXRS", .T., "RPS")) // Prefixo de Titulo de Requisicoes de Saque

	If Select("QRYU57")>0
		QRYU57->(DbCloseArea())
	EndIf

	cQry := " SELECT U57_FILIAL, U57_XGERAF, U57_FILSAQ, U57_FILDEP, U57_PREFIX, U57_CODIGO, U57_PARCEL, U57_VALOR, U57_CHTROC, U57_XOPERA, U57_OPEDEP, U56_TIPO, U57_DATAMO"
	cQry += " FROM "+RetSqlName("U57")+" U57"
	cQry += " INNER JOIN "+RetSqlName("U56")+" U56"
	cQry += 	" ON  U56.D_E_L_E_T_ = ' ' AND U56.U56_FILIAL = U57.U57_FILIAL"
	cQry += 	" AND U56.U56_PREFIX = U57.U57_PREFIX"
	cQry += 	" AND U56.U56_CODIGO = U57.U57_CODIGO"
	cQry += " WHERE U57.D_E_L_E_T_ = ' '"
	cQry += " AND (U57.U57_FILSAQ = '" + cFilAnt + "' OR U57.U57_FILDEP = '" + cFilAnt + "')"
	if !empty(cChavU57) //Quando vem da conferencia
		cQry += " AND U57.U57_XGERAF IN ('C','Z')" //PENDENTE A GERACAO DO FINANCEIRO CONFERENCIA e PENDENTE DE ESTORNO DO FINANCEIRO CONFERENCIA
		cQry += " AND (U57.U57_PREFIX+U57.U57_CODIGO+U57.U57_PARCEL) = '" + cChavU57 + "' " //PEGO SO A REQUISICAO PASSADA POR PARAMETRO
	else
		cQry += " AND U57.U57_XGERAF IN ('P','X')" //PENDENTE A GERACAO DO FINANCEIRO e PENDENTE DE ESTORNO DO FINANCEIRO
		cQry += " AND ((U56.U56_TIPO = '1')" //PRE-PAGA (DEPOSITO NO PDV)
		cQry += " OR (U57.U57_TUSO = 'S' AND U56.U56_TIPO = '2'))" //POS-PAGA DO TIPO SAQUE
	endif
	//cQry += " AND U57_PREFIX = 'P0701' AND U57_CODIGO = '01401192'" //TODO: debug requisição especificqa
	cQry += " ORDER BY U56.U56_TIPO, U57.U57_FILSAQ, U57.U57_FILDEP, U57.U57_PREFIX, U57.U57_CODIGO"

	cQry := ChangeQuery(cQry)
	TcQuery cQry New Alias "QRYU57" // cria uma nova area com o resultado do query

	DbSelectArea("QRYU57")
	QRYU57->(DbGoTop())

	If QRYU57->(Eof())
		lGerou := .F.
	EndIf

	While QRYU57->(!Eof())

		aArea := GetArea()
		aAreaU56 := U56->(GetArea())
		aAreaU57 := U57->(GetArea())
		aAreaSA6 := SA6->(GetArea())
		aAreaSE1 := SE1->(GetArea())
		aAreaSE5 := SE5->(GetArea())

		DbSelectArea("SA6")
		SA6->(DbSetOrder(1)) //A6_FILIAL+A6_COD+A6_AGENCIA+A6_NUMCON

		DbSelectArea("U56")
		U56->(DbSetOrder(1)) //U56_FILIAL+U56_PREFIX+U56_CODIGO

		DbSelectArea("U57")
		U57->(DbSetOrder(1)) //U57_FILIAL+U57_PREFIX+U57_CODIGO+U57_PARCEL

		//backup da database do sistema
		_ddatabase := ddatabase

		//Conout("")
		//Conout(">> CODIGO:" + QRYU57->(U57_CODIGO))
		//Conout(">> CODIGO DE BARRAS: " + QRYU57->(U57_PREFIX+U57_CODIGO+U57_PARCEL))
		//Conout(">> STATUS (U57_XGERAF): " + QRYU57->U57_XGERAF)
		//Conout("")
		If (QRYU57->U57_XGERAF == 'P' .OR. QRYU57->U57_XGERAF == 'C')
			If QRYU57->U56_TIPO == '1' .and. !Empty(QRYU57->U57_FILDEP)
				//Conout(">> GERAÇÂO DE FINANCEIRO REQUISICOES PRE PAGA DO TIPO DEPOSITO NO PDV")
			ElseIf QRYU57->U56_TIPO == '2'
				//Conout(">> GERAÇÂO DE FINANCEIRO REQUISICOES POS PAGA DO TIPO SAQUE NO PDV (VALE MOTORISTA)")
			EndIf
		ElseIf (QRYU57->U57_XGERAF == 'X' .OR. QRYU57->U57_XGERAF == 'Z')
			If QRYU57->U56_TIPO == '2'
				//Conout(">> ESTORNO DE REQUISICOES POS PAGA DO TIPO SAQUE NO PDV (VALE MOTORISTA)")
			ElseIf QRYU57->U56_TIPO == '1' .and. !Empty(U57->U57_FILDEP)
				//Conout(">> ESTORNO DE REQUISICOES PRE PAGA DO TIPO DEPOSITO NO PDV")
			ElseIf QRYU57->U56_TIPO == '1' .and. Empty(U57->U57_FILDEP)
				//Conout(">> ESTORNO DE REQUISICOES PRE PAGA DO TIPO SAQUE NO PDV")
			EndIf
		EndIf
		//Conout("")

		If U57->(DbSeek(QRYU57->(U57_FILIAL+U57_PREFIX+U57_CODIGO+U57_PARCEL))) .and. U56->(DbSeek(QRYU57->(U57_FILIAL+U57_PREFIX+U57_CODIGO)))

			//Ajusto a database do sistema para a data do movimento.
			If !Empty(U57->U57_DATAMO)
				ddatabase := U57->U57_DATAMO
			Else
				ddatabase := _ddatabase
			EndIf

			//Pendente de Financeiro
			//--------------------------------
			// Pendente a Geração  Financeiro
			//--------------------------------
			If (U57->U57_XGERAF == 'P' .OR. U57->U57_XGERAF == 'C')

				//-------------------------------------------------------
				// ORIGEM SAQUE => gera financeiro da requisição POS-PAGA
				// GERA OS SEGUINTES TITULOS:
				// 1- NCC e baixa no banco caixa
				// 2- RPS com vencimento futuro
				//-------------------------------------------------------
				If U56->U56_TIPO == '2'

					lGerou := .T.

					BeginTran()
					//Conout(" ============ U56_TIPO == '2' ORIGEM SAQUE => gera financeiro da requisição POS-PAGA ============= ")

					//Geração dos NCC's, conforme as parcelas U57 e baixa no caixa informado
					If U57->U57_VALOR > 0

						SA6->(DbSetOrder(1))
						If SA6->(DbSeek(xFilial("SA6")+U57->U57_XOPERA)) //posiciona no banco do caixa (operador) que finalizou a venda
							cBanco		:= SA6->A6_COD
							cAgencia  	:= SA6->A6_AGENCIA
							cConta    	:= SA6->A6_NUMCON
						Else
							cBanco		:= Space(TAMSX3("A6_COD")[1])
							cAgencia  	:= Space(TAMSX3("A6_AGENCIA")[1])
							cConta    	:= Space(TAMSX3("A6_NUMCON")[1])
						EndIf

						dDtMov	:= U57->U57_DATAMO
						cParcel := U57->U57_PARCEL //Space(TAMSX3("U57_PARCEL")[1])
						nCont   := 0
						lExistSE1	:= .F.

						DbSelectArea("SE1")
						SE1->(DbSetOrder(1)) //E1_FILIAL+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO
						While SE1->(DbSeek(xFilial("SE1")+cPfRqSaq+SubStr(U57->U57_PREFIX,1,1)+U57->U57_CODIGO+cParcel+"NCC")) .and. nCont < 999
							If AllTrim(SE1->E1_XCODBAR) <> AllTrim(U57->U57_PREFIX + U57->U57_CODIGO + U57->U57_PARCEL)
								cParcel := Soma1(cParcel)
							Else //ja existe NCC para a parcela da requisição
								lExistSE1 := .T.
								Exit
							EndIf
							nCont++
						EndDo

						If !lExistSE1

							aFin040 := {}
							AADD(aFin040, {"E1_FILIAL"	,xFilial("SE1")		,Nil } )
							AADD(aFin040, {"E1_PREFIXO"	,cPfRqSaq          	,Nil } ) //Requisição Pós-Paga Saque
							AADD(aFin040, {"E1_NUM"		,SubStr(U57->U57_PREFIX,1,1) + U57->U57_CODIGO ,Nil } ) //
							AADD(aFin040, {"E1_PARCELA"	,cParcel			,Nil } )
							AADD(aFin040, {"E1_TIPO"	,"NCC"      		,Nil } )
							AADD(aFin040, {"E1_NATUREZ"	,cNatNcc			,Nil } )
							AADD(aFin040, {"E1_PORTADO" ,cBanco				,Nil } )
							AADD(aFin040, {"E1_AGEDEP"  ,cAgencia			,Nil } )
							AADD(aFin040, {"E1_CONTA"   ,cConta	   			,Nil } )
							AADD(aFin040, {"E1_CLIENTE"	,U56->U56_CODCLI	,Nil } )
							AADD(aFin040, {"E1_LOJA"	,U56->U56_LOJA		,Nil } )
							If SE1->(FieldPos("E1_DTLANC")) > 0
								AADD(aFin040, {"E1_DTLANC"	,dDataBase			,Nil } )
							EndIf
							AADD(aFin040, {"E1_EMISSAO"	,dDataBase			    ,Nil } )
							AADD(aFin040, {"E1_VENCTO"	,dDataBase			    ,Nil } )
							AADD(aFin040, {"E1_VENCREA"	,DataValida(dDataBase)	,Nil } )
							AADD(aFin040, {"E1_VALOR"	,(U57->U57_VALOR)	    ,Nil } )
							AADD(aFin040, {"E1_ORIGEM" 	,"TRETE023"			    ,Nil } )
							AADD(aFin040, {"E1_XCODBAR"	,AllTrim(U57->U57_PREFIX + U57->U57_CODIGO + U57->U57_PARCEL) ,Nil } ) //codigo de barras da requisição == chave do registro U57
							If SE1->(FieldPos("E1_XPLACA")) > 0
								AADD( aFin040, {"E1_XPLACA"	 , U57->U57_PLACA  ,Nil})
							endif
							If SE1->(FieldPos("E1_XMOTOR")) > 0
								AADD( aFin040, {"E1_XMOTOR"	 , U57->U57_MOTORI  ,Nil})
							endif
							If SE1->(FieldPos("E1_XPDV")) > 0
								AADD( aFin040, {"E1_XPDV"	 , U57->U57_XPDV   ,Nil})
							endif
							If SE1->(FieldPos("E1_XMOTIV")) > 0
								AADD( aFin040, {"E1_XMOTIV"	, U57->U57_MOTIVO	,Nil } )
							EndIf

							lMsErroAuto := .F. // variavel interna da rotina automatica
							lMsHelpAuto := .T.

							//Posiciono a SM0 antes da baixa, pois está vindo desposicionada
							SM0->(DbGoTop())
							While SM0->(!Eof())
								If (AllTrim(SM0->M0_CODFIL) == AllTrim(cFilAnt)) .and. (AllTrim(SM0->M0_CODIGO) == AllTrim(cEmpAnt))
									Exit
								EndIf
								SM0->(DbSkip())
							EndDo

							//Chama a funcao de gravacao automatica do FINA040
							MSExecAuto({|x,y| FINA040(x,y)}, aFin040, 3)

							If lMsErroAuto
								If isBlind()
									cErroExec := MostraErro("\temp")
									//Conout(" ============ ERRO =============")
									//Conout(cErroExec)
									cErroExec := ""
								Else
									MostraErro()
								EndIf
								cMsgErro := "Falha ao gerar titulo NCC!"
								lGerou := .F.
							Else
								//Conout(" ============ NCC -> CODBAR: "+U57->U57_PREFIX+U57->U57_CODIGO+U57->U57_PARCEL+" --- GERADO COM SUCESSO!!! ============= ")
								lGerou := U_TRETE23B(cBanco, cAgencia, cConta, dDtMov) //realiza a baixa no caixa
								if !lGerou
									cMsgErro := "Falha ao baixar titulo NCC no caixa do operador!"
								endif
							EndIf
						Else
							//Conout(" ============ A CHAVE DA NCC JA EXISTE: "+U57->U57_PREFIX+U57->U57_CODIGO+U57->U57_PARCEL+"!!! ============= ")
						EndIf
					EndIf

					//Geração dos RPS, conforme a condição de pagamento da requisição
					If lGerou

						If U57->U57_VALOR > 0 .and. !Empty(U56->U56_CONDSA)
							DbSelectArea("SE4")
							SE4->(DbSetOrder(1))
							If !SE4->(DbSeek(xFilial("SE4")+U56->U56_CONDSA))
								//Conout(" ============ ERRO: Não existe a condição de pagamento (tabela SE4) com o codigo "+U56->U56_CONDSA+" cadastrada.  ============ "  )
								cMsgErro := "Não existe a condição de pagamento (tabela SE4) com o codigo "+U56->U56_CONDSA+" cadastrada."
								lGerou := .F.
							Else
								aParcS := condicao(U57->U57_VALOR, U56->U56_CONDSA, 0.00, ddatabase, 0.00, {},,0) //gera aParcS
							EndIf
						EndIf

						//parcelas de pagamento do saque
						cParc    := PADL( "0", TAMSX3("E1_PARCELA")[1], "0" )
						For nI:=1 to Len(aParcS)
							cParc := soma1(cParc)
							nCont   := 0
							lExistSE1	:= .F.

							DbSelectArea("SE1")
							SE1->(DbSetOrder(1)) //E1_FILIAL+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO
							While SE1->(DbSeek(xFilial("SE1")+cPfRqSaq+SubStr(U56->U56_PREFIX,1,1)+U56->U56_CODIGO+cParc+cTpSE1)) .and. nCont < 999
								If AllTrim(SE1->E1_XCODBAR) <> AllTrim(U57->U57_PREFIX + U57->U57_CODIGO + U57->U57_PARCEL)
									cParc := Soma1(cParc)
								Else //ja existe NCC para a parcela da requisição
									lExistSE1 := .T.
									Exit
								EndIf
								nCont++
							EndDo

							If !lExistSE1

								aFin040 := {}
								AADD(aFin040, {"E1_FILIAL"	,xFilial("SE1")		,Nil } )
								AADD(aFin040, {"E1_PREFIXO"	,cPfRqSaq        	,Nil } ) //RPS - Requisição Pós-Paga do tipo Saque
								AADD(aFin040, {"E1_NUM"		,SubStr(U56->U56_PREFIX,1,1)+U56->U56_CODIGO    ,Nil } ) //
								AADD(aFin040, {"E1_PARCELA"	,cParc          	,Nil } )
								AADD(aFin040, {"E1_TIPO"	,cTpSE1      		,Nil } ) //RP
								AADD(aFin040, {"E1_NATUREZ"	,cNatNdc			,Nil } )
								AADD(aFin040, {"E1_CLIENTE"	,U56->U56_CODCLI	,Nil } )
								AADD(aFin040, {"E1_LOJA"	,U56->U56_LOJA		,Nil } )
								If SE1->(FieldPos("E1_DTLANC")) > 0
									AADD(aFin040, {"E1_DTLANC"	,dDataBase			,Nil } )
								EndIf
								AADD(aFin040, {"E1_EMISSAO"	,dDataBase			,Nil } )
								AADD(aFin040, {"E1_VENCTO"	,aParcS[nI][1]		,Nil } )
								AADD(aFin040, {"E1_VENCREA"	,DataValida(aParcS[nI][1])	,Nil } )
								AADD(aFin040, {"E1_VALOR"	,aParcS[nI][2]		,Nil } )
								AADD(aFin040, {"E1_ORIGEM" 	,"TRETE023"			,Nil } )
								if SE1->(FieldPos("E1_XCOND")) > 0
									AADD( aFin040, {"E1_XCOND"   , U56->U56_CONDSA  ,Nil})
								endif
								if SE1->(FieldPos("E1_XDTFATU")) > 0
									AADD( aFin040, {"E1_XDTFATU" , U_TRETE014(U56->U56_CONDSA,aParcS[nI][1]), Nil } )
								endif
								If SE1->(FieldPos("E1_XPLACA")) > 0
									AADD( aFin040, {"E1_XPLACA"	 , U57->U57_PLACA  ,Nil})
								endif
								If SE1->(FieldPos("E1_XMOTOR")) > 0
									AADD( aFin040, {"E1_XMOTOR"	 , U57->U57_MOTORI  ,Nil})
								endif
								If SE1->(FieldPos("E1_XPDV")) > 0
									AADD( aFin040, {"E1_XPDV"	 , U57->U57_XPDV   ,Nil})
								endif
								AADD( aFin040, {"E1_XCODBAR" ,AllTrim(U57->U57_PREFIX+U57->U57_CODIGO+U57->U57_PARCEL) ,Nil } ) //codigo de barras da requisição == chave do registro U57
								If SE1->(FieldPos("E1_XMOTIV")) > 0
									AADD( aFin040, {"E1_XMOTIV"	, U57->U57_MOTIVO	,Nil } )
								EndIf

								lMsErroAuto := .F. // variavel interna da rotina automatica
								lMsHelpAuto := .T.

								//Posiciono a SM0 antes da baixa, pois está vindo desposicionada
								SM0->(DbGoTop())
								While SM0->(!Eof())
									If (AllTrim(SM0->M0_CODFIL) == AllTrim(cFilAnt)) .and. (AllTrim(SM0->M0_CODIGO) == AllTrim(cEmpAnt))
										Exit
									EndIf
									SM0->(DbSkip())
								EndDo

								//  Chama a funcao de gravacao automatica do FINA040                         
								MSExecAuto({|x,y| FINA040(x,y)}, aFin040, 3)

								If lMsErroAuto
									If isBlind()
										cErroExec := MostraErro("\temp")
										//Conout(" ============ ERRO ============= ")
										//Conout(cErroExec)
										cErroExec := ""
									Else
										MostraErro()
									EndIf
									lGerou := .F.
									cMsgErro := "Falha ao incluir titulo RP para cliente!"
								Else
									//Conout(" ============ NDC: "+U57->U57_PREFIX+U57->U57_CODIGO+cParc+" --- GERADO COM SUCESSO!!! ============= ")
								EndIf
							EndIf
						Next nI
					EndIf

					// se tudo ok
					If lGerou
						Reclock("U57",.F.)
							U57->U57_XGERAF	:= "G"
						U57->(MsUnlock())
					Else
						DisarmTransaction()
					EndIf

					EndTran()

					//tratamento para inclusao do motorista, a partir do campo CPF informado no saque
					If U57->(FieldPos("U57_NOMMOT")) > 0 .AND. !empty(U57->U57_MOTORI) .AND. len(Alltrim(U57->U57_MOTORI))==11
						AddMotoris(U57->U57_MOTORI, U57->U57_NOMMOT)
					EndIf

				//----------------------------------------------------------
				// ORIGEM DEPOSITO => gera financeiro da requisição PRE-PAGA
				// GERA OS SEGUINTES TITULOS:
				// 1- RA do deposito feito no PDV
				//----------------------------------------------------------
				ElseIf !Empty(U57->U57_FILDEP) //U57->U56_TIPO == '1'

					//Conout(" ============ U56_TIPO == '1' ORIGEM DEPOSITO => gera financeiro da requisição PRE-PAGA ============= ")
					//ajusto a data do deposito 
					If !Empty(U57->U57_DATDEP)
						ddatabase := U57->U57_DATDEP
					Endif

					If U_TRETE23C()
						aadd(aRecU57Mail, U57->(RECNO()) )
						Reclock("U57",.F.)
						U57->U57_XGERAF	:= "F" //Alterado de G para F, para permitir uso no PDV
						U57->(MsUnlock())

						//tratamento para inclusao do motorista, a partir do campo CPF informado no saque
						If U57->(FieldPos("U57_NOMMOT")) > 0 .AND. !empty(U57->U57_MOTORI) .AND. len(Alltrim(U57->U57_MOTORI))==11
							AddMotoris(U57->U57_MOTORI, U57->U57_NOMMOT)
						EndIf
					EndIf

				EndIf

			//--------------------------------
			// Pendente o Estorno Financeiro
			//--------------------------------
			ElseIf (U57->U57_XGERAF == 'X' .OR. U57->U57_XGERAF == 'Z')

				BeginTran()

				lGerou 	  := .F.
				lDeposito := !Empty(U57->U57_FILDEP) .and. Empty(U57->U57_FILSAQ)

				//--------------------------------------------------------------------
				// ORIGEM DEPOSITO OU SAQUE => gera estorno financeiro da requisição PRE-PAGA
				//--------------------------------------------------------------------
				If U56->U56_TIPO == '1' //.and. !Empty(U57->U57_FILDEP)
					//Conout(" >> ORIGEM "+iif(lDeposito,"DEPOSITO","SAQUE PRE PAGO")+" => gera estorno financeiro da requisição PRE-PAGA ")
					//Conout(" >> Título: E1_XCODBAR = '" + AllTrim(U57->U57_PREFIX+U57->U57_CODIGO+U57->U57_PARCEL) + "'")
					lGerou := GeraEstSE1(U56->U56_TIPO,lDeposito, ,@cMsgErro)

				//------------------------------------------------------------------
				// ORIGEM SAQUE POS PAGO => gera estorno financeiro da requisição POS-PAGA
				//------------------------------------------------------------------
				ElseIf U56->U56_TIPO == '2'
					//Conout(" >> ORIGEM SAQUE (VALE MOTORISTA) => gera estorno financeiro da requisição POS-PAGA ")
					//Conout(" >> Título: E1_XCODBAR = '" + AllTrim(U57->U57_PREFIX+U57->U57_CODIGO+U57->U57_PARCEL) + "'")
					lGerou := GeraEstSE1(U56->U56_TIPO,lDeposito, ,@cMsgErro)

				EndIf

				If lGerou //gerou o estorno

					//se depósito ou pos-paga (saque ou vale motorista)
					If lDeposito .or. U56->U56_TIPO=="2"

						Reclock("U57",.F.)
						U57->U57_XGERAF	:= "D" //D-Deletado
						U57->(MsUnlock())

						//RecLock("U56")
						//U56->(DbDelete())
						//U56->(MsUnlock())

						//RecLock("U57")
						//U57->(DbDelete())
						//U57->(MsUnlock())

					ElseIf  !Empty(U57->U57_FILSAQ) //Saque ou Vale Motorista

						// limpo os dados do saque, mas não exclui a requisição
						Reclock("U57",.F.)
							U57->U57_TITULO := Space(TamSx3("U57_TITULO")[1])
							if !Empty(U57->U57_FILDEP) //se era saque sobre um deposito PDV
								U57->U57_XGERAF := "F" //volto para status F de deposito OK
							else
								U57->U57_XGERAF	:= Space(TamSx3("U57_XGERAF")[1])
							endif
							U57->U57_MOTIVO	:= Space(TamSx3("U57_MOTIVO")[1])
							U57->U57_FILSAQ	:= Space(TamSx3("U57_FILSAQ")[1])
							U57->U57_XOPERA := Space(TamSx3("U57_XOPERA")[1])
							U57->U57_XPDV	:= Space(TamSx3("U57_XPDV")[1])
							U57->U57_XESTAC	:= Space(TamSx3("U57_XESTAC")[1])
							U57->U57_XNUMMO	:= Space(TamSx3("U57_XNUMMO")[1])
							U57->U57_XHORA  := Space(TamSx3("U57_XHORA")[1])
							U57->U57_DATAMO := CTOD("")
							U57->U57_CHTROC := 0
						U57->(MsUnlock())

					EndIf

				Else
					DisarmTransaction()

					//Conout(" >> Erro ao estornar requisição.")
					//Conout(" >> cMsgErro: " + cMsgErro)
					//erro ao estornar a requisição
					//retirado pois na irá sumir da conferencia ao tentar estornar e nao conseguir.
					/*Reclock("U57",.F.)
					U57->U57_TITULO := 'ERRO ESTORNAR > U57_XGERAF = X'
					U57->U57_XGERAF := '?'
					U57->(MsUnlock()) */

				EndIf

				EndTran()

			EndIf
		
		Else
			//Conout(" >> Não encontrou a tabela U57 e/ou U56")

		EndIf

		//restaura o backup da database do sistema
		ddatabase := _ddatabase

		If !Empty(aArea)
			RestArea(aAreaSE5)
			RestArea(aAreaSE1)
			RestArea(aAreaU56)
			RestArea(aAreaU57)
			RestArea(aAreaSA6)
			RestArea(aArea)
		EndIf

		QRYU57->(DbSkip())
	EndDo

	//-----------------------------------------------------
	// FAZENDO NOVO LAÇO PARA QUE ERROS NO ENVIO DO EMAIL 
	// NAO COMPROMETA A GERAÇÃO DO FINANCEIRO             
	//-----------------------------------------------------
	For nX := 1 to Len(aRecU57Mail)

		aArea := GetArea()
		aAreaU56 := U56->(GetArea())
		aAreaU57 := U57->(GetArea())
		aAreaSA6 := SA6->(GetArea())
		aAreaSE1 := SE1->(GetArea())
		aAreaSE5 := SE5->(GetArea())

		U57->(DbGoTo(aRecU57Mail[nX])) //posiciona no U57

		If U56->(DbSeek(U57->(U57_FILIAL+U57_PREFIX+U57_CODIGO)))
			If U56->U56_TIPO <> '2' //ORIGEM SAQUE => gera financeiro da requisição POS-PAGA
				If EnvioEmail()
					//Reclock("U57",.F.)
					//U57->U57_XGERAF := "E" //flag email enviado
					//U57->(MsUnlock())
				EndIf
			EndIf
		endif

		If !Empty(aArea)
			RestArea(aAreaSE5)
			RestArea(aAreaSE1)
			RestArea(aAreaU56)
			RestArea(aAreaU57)
			RestArea(aAreaSA6)
			RestArea(aArea)
		EndIf

	Next nX

	//Conout(">> FIM TRETE023 - GERA/ESTORNA FINANCEIRO REQUISIÇÕES")

	If Select("QRYU57")>0
		QRYU57->(DbCloseArea())
	EndIf

Return lGerou

//-----------------------------------------------------------------------------------
// Baixa o titulo NCC no caixa (banco) -> BaixaSE1(cBanco, cAgencia, cNumCon)
//-----------------------------------------------------------------------------------
User Function TRETE23B(cBanco, cAgencia, cNumCon, dDtMov)

	Local aBaixa 			:= {}
	Local lGerou			:= .F.
	Local lRet 				:= .T.
	Local cBkpSM0 			:= SM0->(Recno())
	Local cBkpFunNam := FunName()

	Private lMsHelpAuto		:= .T.
	Private lMsErroAuto 	:= .F.
	Default dDtMov			:= dDataBase
	
	//Posiciono a SM0 antes da baixa, pois está vindo desposicionada
	SM0->(DbGoTop())
	While SM0->(!Eof())
		If (AllTrim(SM0->M0_CODFIL) == AllTrim(cFilAnt)) .and. (AllTrim(SM0->M0_CODIGO) == AllTrim(cEmpAnt))
			Exit
		EndIf
	 	SM0->(DbSkip())
	EndDo

	aBaixa := {;
		{"E1_PREFIXO"   ,SE1->E1_PREFIXO		,Nil},;
		{"E1_NUM"       ,SE1->E1_NUM			,Nil},;
		{"E1_PARCELA"   ,SE1->E1_PARCELA		,Nil},;
		{"E1_TIPO"      ,SE1->E1_TIPO			,Nil},;
		{"E1_CLIENTE" 	,SE1->E1_CLIENTE 		,Nil},;
		{"E1_LOJA" 		,SE1->E1_LOJA 			,Nil},;
		{"AUTMOTBX"     ,"DEB" /*"NOR" -> Motivo da Baixa*/,Nil},;
		{"AUTBANCO"     ,cBanco 				,Nil},;
		{"AUTAGENCIA"   ,cAgencia 				,Nil},;
		{"AUTCONTA"     ,cNumCon 				,Nil},;
		{"AUTDTBAIXA"   ,dDtMov					,Nil},;
		{"AUTDTCREDITO" ,dDtMov					,Nil},;
		{"AUTHIST"      ,"SAQUE NO PDV"         ,Nil},;
		{"AUTJUROS"     ,0                      ,Nil,.T.},;
		{"AUTVALREC"    ,SE1->E1_SALDO			,Nil}}

	If SE1->E1_SALDO > 0
		SetFunName("FINA070") //ADD Danilo, para ficar correto campo E5_ORIGEM (relatorios e rotinas conciliacao)					
		MSExecAuto({|x,y| Fina070(x,y)}, aBaixa, 3) //Baixa conta a receber
		SetFunName(cBkpFunNam)
	Else
		//Conout(" ============ ERRO =============")
		//Conout("O valor do saldo de saque <E1_SALDO> esta zerado!")
		lRet := .F.
	EndIf

	If lMsErroAuto
		If IsBlind()
			cErroExec := MostraErro("\temp")
			//Conout(" ============ ERRO =============")
			//Conout(cErroExec)
			cErroExec := ""
		Else
			MostraErro()
		EndIf
		lRet := .F.
	ElseIf SE1->E1_SALDO > 0
		//Conout(" ============ ERRO =============")
		//Conout("Não foi baixado o valor total contido no campo E1_SALDO!")
		lRet := .F.
	ElseIf lRet
		lGerou := .T.

		//atualiza a SE5
		//Conout(" ============  ATUALIZA O MOVIMENTO DA SE5 - DADOS DO CAIXA: Numero do PDV, Estacao, Codigo do Movimento e Hora  ============ ")

		DbSelectArea("SE5")
		//SE5->(DbSetOrder(7)) //E5_FILIAL+E5_PREFIXO+E5_NUMERO+E5_PARCELA+E5_TIPO+E5_CLIFOR+E5_LOJA+E5_SEQ+E5_RECPAG
		//If SE5->(DbSeek(xFilial("SE5")+SE1->(E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO+E1_CLIENTE+E1_LOJA+'01'+'P')))
		RecLock("SE5",.F.)
			SE5->E5_XPDV 	:= U57->U57_XPDV
			SE5->E5_XESTAC 	:= U57->U57_XESTAC
			SE5->E5_NUMMOV  := U57->U57_XNUMMO
			SE5->E5_XHORA 	:= U57->U57_XHORA
		SE5->(MsUnLock())
		//EndIf
	EndIf

	If lGerou
		//Conout(" ============ TÍTULO: "+SE1->(E1_PREFIXO+SE1->E1_NUM+SE1->E1_PARCELA+SE1->E1_TIPO)+" --- BAIXADO COM SUCESSO!!! =============")
	EndIf

	SM0->(DbGoTo(cBkpSM0))

Return(lRet)

//-----------------------------------------------------------------------------------
// Gera o RA do deposito feito no PDV
//-----------------------------------------------------------------------------------
User Function TRETE23C()

	Local aArea     := GetArea()
	Local aAreaU56  := GetArea()
	Local aAreaU57  := GetArea()
	Local aAreaSE1  := GetArea()
	Local aAreaSE5  := GetArea()
	Local cNatRa	:= SuperGetMV( "MV_XNATRA" , .T./*lHelp*/, "OUTROS" /*cPadrao*/ )
	Local lRet 		:= .T.
	Local lTemSE1 	:= .F.

	//considera que ja estaja posicionado sobre o registro da requisição (U56) e sobre a parcela (U57)
	DbSelectArea("U56")
	DbSelectArea("U57")

	DbSelectArea("SE1")
	SE1->(DbSetOrder(1)) //E1_FILIAL+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO

	cParcel := U57->U57_PARCEL //Space(TAMSX3("U57_PARCEL")[1])
	nCont   := 0

	//Posiciono a SM0 antes da baixa, pois está vindo desposicionada
	SM0->(DbGoTop())
	While SM0->(!Eof())
		If (AllTrim(SM0->M0_CODFIL) == AllTrim(cFilAnt)) .and. (AllTrim(SM0->M0_CODIGO) == AllTrim(cEmpAnt))
			Exit
		EndIf
	 	SM0->(DbSkip())
	EndDo

	//posiciono no banco: erro --->  - cBancoAdt   :=C33 < -- Invalido
	SA6->(DbSetOrder(1)) //A6_FILIAL+A6_COD+A6_AGENCIA+A6_NUMCON
	If SA6->(DbSeek(xFilial("SA6")+U56->U56_BANCO+U56->U56_AGENCI+U56->U56_NUMCON)) //posiciona no banco do caixa (operador) que fez deposito
		cBanco		:= SA6->A6_COD
		cAgencia  	:= SA6->A6_AGENCIA
		cConta    	:= SA6->A6_NUMCON
	EndIf

	While SE1->(DbSeek(xFilial("SE1")+"RPR"+SubStr(U57->U57_PREFIX,1,1)+U57->U57_CODIGO+cParcel+"RA ")) .and. nCont < 999
		If AllTrim(SE1->E1_XCODBAR) <> AllTrim(U57->U57_PREFIX + U57->U57_CODIGO + U57->U57_PARCEL)
			cParcel := Soma1(cParcel)
		Else //ja existe RA para a parcela da requisição
			Exit
			lTemSE1 := .T.
		EndIf
		nCont++
	EndDo

	If !lTemSE1

		aFin040 := {}

		AADD( aFin040, {"E1_FILIAL"  , xFilial("SE1")  ,Nil})
		AADD( aFin040, {"E1_PREFIXO" , "RPR"           ,Nil}) //REQUISICAO PRE PAGA
		AADD( aFin040, {"E1_NUM"     , SubStr(U57->U57_PREFIX,1,1) + U57->U57_CODIGO ,Nil})
		AADD( aFin040, {"E1_PARCELA" , cParcel 		   ,Nil})
		AADD( aFin040, {"E1_TIPO"    , "RA "           ,Nil})
		AADD( aFin040, {"E1_NATUREZ" , cNatRa          ,Nil})
		AADD( aFin040, {"E1_PORTADO" , U56->U56_BANCO  ,Nil})
		AADD( aFin040, {"E1_AGEDEP"  , U56->U56_AGENCI ,Nil})
		AADD( aFin040, {"E1_CONTA"   , U56->U56_NUMCON ,Nil})
		AADD( aFin040, {"CBCOAUTO"   , U56->U56_BANCO  ,Nil}) //-> E1_PORTADO
		AADD( aFin040, {"CAGEAUTO"   , U56->U56_AGENCI ,Nil}) //-> E1_AGEDEP
		AADD( aFin040, {"CCTAAUTO"   , U56->U56_NUMCON ,Nil}) //-> E1_CONTA
		AADD( aFin040, {"E1_CLIENTE" , U56->U56_CODCLI ,Nil})
		AADD( aFin040, {"E1_LOJA"    , U56->U56_LOJA   ,Nil})
		If SE1->(FieldPos("E1_DTLANC")) > 0
			AADD( aFin040, {"E1_DTLANC"	 , U57->U57_DATDEP ,Nil})
		EndIf
		AADD( aFin040, {"E1_EMISSAO" , U57->U57_DATDEP     ,Nil})
		AADD( aFin040, {"E1_VENCTO"  , U57->U57_DATDEP     ,Nil})
		AADD( aFin040, {"E1_VENCREA" , DataValida(U57->U57_DATDEP) ,Nil})
		AADD( aFin040, {"E1_VALOR"   , U57->U57_VALOR  ,Nil})
		AADD( aFin040, {"E1_ORIGEM"  , "TRETE023"      ,Nil})
		AADD( aFin040, {"E1_HIST"  	 , "DEPOSITO NO PDV",Nil})
		AADD( aFin040, {"E1_XCODBAR" , AllTrim(U57->U57_PREFIX+U57->U57_CODIGO+U57->U57_PARCEL) ,Nil } ) //codigo de barras da requisição == chave do registro U57
		If SE1->(FieldPos("E1_XPLACA")) > 0
			AADD( aFin040, {"E1_XPLACA"	 , U57->U57_PLACA  ,Nil})
		endif
		If SE1->(FieldPos("E1_XMOTOR")) > 0
			AADD( aFin040, {"E1_XMOTOR"	 , U57->U57_MOTORI  ,Nil})
		endif
		If SE1->(FieldPos("E1_XPDV")) > 0
			AADD( aFin040, {"E1_XPDV"	 , U57->U57_PDVDEP  ,Nil})
		endif
		If SE1->(FieldPos("E1_XMOTIV")) > 0
			AADD( aFin040, {"E1_XMOTIV"	, U57->U57_MOTIVO	,Nil } )
		EndIf

		//Assinatura de variáveis que controlarão a inserção automática da RA			;
		lMsErroAuto := .F.
		lMsHelpAuto := .T.

		//Posiciono a SM0 antes da baixa, pois está vindo desposicionada
		SM0->(DbGoTop())
		While SM0->(!Eof())
			If (AllTrim(SM0->M0_CODFIL) == AllTrim(cFilAnt)) .and. (AllTrim(SM0->M0_CODIGO) == AllTrim(cEmpAnt))
				Exit
			EndIf
			SM0->(DbSkip())
		EndDo

		//Invocando rotina automática para criação da RA								;
		MSExecAuto({|x,y| Fina040(x,y)}, aFin040, 3)

		//Quando houver erros, exibí-los em tela										 ;
		If lMsErroAuto
			If isBlind()
				cErroExec := MostraErro("\temp")
				Conout(" ============ ERRO =============")
				Conout(cErroExec)
				cErroExec := ""
				lRet := .F.
			Else
				MostraErro()
			EndIf
		Else

			//Conout(" ============ RA: "+SE1->E1_FILIAL+SE1->E1_PREFIXO+SE1->E1_NUM+cParcel+" --- GERADO COM SUCESSO!!! =============")

			//atualiza a SE5
			//Conout(" ============  ATUALIZA O MOVIMENTO DA SE5 - DADOS DO CAIXA: Numero do PDV, Estacao, Codigo do Movimento e Hora  ============ ")

			//DbSelectArea("SE5")
			//SE5->(DbSetOrder(7)) //E5_FILIAL+E5_PREFIXO+E5_NUMERO+E5_PARCELA+E5_TIPO+E5_CLIFOR+E5_LOJA+E5_SEQ+E5_RECPAG
			//If SE5->(DbSeek(xFilial("SE5")+SE1->(E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO+E1_CLIENTE+E1_LOJA+'01'+'P')))
			/*	RecLock("SE5",.F.)
			SE5->E5_XPDV 	:= U57->U57_PDVDEP
			SE5->E5_XESTAC 	:= U57->U57_ESTDEP
			SE5->E5_NUMMOV  := U57->U57_NUMDEP
			SE5->E5_XHORA 	:= U57->U57_HORDEP
			SE5->(MsUnLock())*/
			//EndIf
		EndIf

		//Altera o status da requisição para Liberado
		RecLock("U56")
			U56->U56_STATUS := "L"
		U56->(MsUnlock())

	Else
		If AllTrim(SE1->E1_XCODBAR) <> AllTrim(U57->U57_PREFIX + U57->U57_CODIGO + U57->U57_PARCEL)
			//Conout(" ============ A CHAVE DO RA JA EXISTE: "+U57->U57_PREFIX+U57->U57_CODIGO+U57->U57_PARCEL+"!!! ============= ")
			lRet := .F.
		Else
			//atualiza a SE5
			//Conout(" ============  ATUALIZA O MOVIMENTO DA SE5 - DADOS DO CAIXA: Numero do PDV, Estacao, Codigo do Movimento e Hora  ============ ")

			DbSelectArea("SE5")
			SE5->(DbSetOrder(7)) //E5_FILIAL+E5_PREFIXO+E5_NUMERO+E5_PARCELA+E5_TIPO+E5_CLIFOR+E5_LOJA+E5_SEQ+E5_RECPAG
			SE5->(DbSeek(xFilial("SE5")+SE1->(E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO+E1_CLIENTE+E1_LOJA)))
			While SE5->(E5_FILIAL+E5_PREFIXO+E5_NUMERO+E5_PARCELA+E5_TIPO+E5_CLIFOR+E5_LOJA) == (xFilial("SE5")+SE1->(E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO+E1_CLIENTE+E1_LOJA))
				If SE5->E5_RECPAG == 'P'
					RecLock("SE5",.F.)
					SE5->E5_XPDV 	:= U57->U57_PDVDEP
					SE5->E5_XESTAC 	:= U57->U57_ESTDEP
					SE5->E5_NUMMOV  := U57->U57_NUMDEP
					SE5->E5_XHORA 	:= U57->U57_HORDEP
					SE5->(MsUnLock())
				EndIf
				SE5->(DbSkip())
			EndDo

			//Altera o status da requisição para Liberado
			RecLock("U56")
				U56->U56_STATUS := "L"
			U56->(MsUnlock())

		EndIf
	EndIf

	RestArea(aAreaSE1)
	RestArea(aAreaSE5)
	RestArea(aAreaU56)
	RestArea(aAreaU57)
	RestArea(aArea)

Return(lRet)

//---------------------------------------------------------------
// Metodo para envio de e-mail
//---------------------------------------------------------------
Static Function EnvioEmail()
	Local lRet 	:= .F.
	Local lMail	:= .T.

	//Conout(" ============  ENVIO DE REQUISIÇÃO POR E-MAIL. CÓDIGO: "+ U57->U57_PREFIX + U57->U57_CODIGO + U57->U57_PARCEL+"  ============ ")
	If U_TRETR010(lMail,U56->(U56_FILIAL+U56_PREFIX+U56_CODIGO),U57->U57_PARCEL)
		lRet := .T.
		//Conout(" ============  E-MAIL ENVIADO COM SUCESSO!!!   ============ ")
	EndIf

Return(lRet)

//-----------------------------------------------------------------------------------
// GeraEstSE1 -> gera o estorno do financeiro da requisição
// nOpc == '1' ORIGEM DEPOSITO => gera estorno financeiro da requisição PRE-PAGA
// nOpc == '2' ORIGEM SAQUE    => gera estorno financeiro da requisição POS-PAGA
//-----------------------------------------------------------------------------------
Static Function GeraEstSE1(nOpc,lDeposito, lChqTroc, cMsgErro)

	Local aArea			:= GetArea()
	Local aAreaSE1  	:= SE1->(GetArea())
	Local cTpSE1   		:= "RP " //Requisição Pós-Paga
	Local cParc 		:= PADL( "0", TAMSX3("E1_PARCELA")[1], "0" )
	Local lRet 			:= .T.
	Local cPfRqSaq  	:= AllTrim(SuperGetMV("MV_XPRFXRS", .T., "RPS")) // Prefixo de Titulo de Requisicoes de Saque
	Local cPulaLinha  	:= chr(13)+chr(10)

	Default lDeposito 	:= !Empty(U57->U57_FILDEP) .and. Empty(U57->U57_FILSAQ) //.F.
	Default lChqTroc 	:= .T. //se exclui cheque troco também

	// ORIGEM DEPOSITO OU SAQUE => gera estorno financeiro da requisição PRE-PAGA
	//Conout(" >> GeraEstSE1 -> gera o estorno do financeiro da requisição")
	If nOpc == '1'

		DbSelectArea("SE1")
		SE1->(DbSetOrder(1)) //E1_FILIAL+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO

		cQry := "select SE1.R_E_C_N_O_ AS SE1RECNO" + cPulaLinha
		cQry += " from " + RetSqlName("SE1") + " SE1" + cPulaLinha
		cQry += " where SE1.D_E_L_E_T_ <> '*'" + cPulaLinha
		cQry += " and SE1.E1_FILIAL = '" + xFilial("SE1") + "'" + cPulaLinha
		cQry += " and E1_PREFIXO = '" + "RPR" + "'" + cPulaLinha
		cQry += " and E1_TIPO IN ('NCC','RA ')" + cPulaLinha
		cQry += " and E1_XCODBAR = '" + AllTrim(U57->U57_PREFIX+U57->U57_CODIGO+U57->U57_PARCEL) + "'" + cPulaLinha
		//cQry += " and E1_SALDO > 0" + cPulaLinha

		If Select("QRYSE1") > 0
			QRYSE1->(DbCloseArea())
		EndIf

		cQry := ChangeQuery(cQry)
		TcQuery cQry New Alias "QRYSE1" // Cria uma nova area com o resultado do query

		QRYSE1->(dbGoTop())

		If QRYSE1->(!Eof())
			While QRYSE1->(!Eof())

				SE1->(DbGoTo(QRYSE1->SE1RECNO))

				If AllTrim(SE1->E1_XCODBAR) == AllTrim(U57->U57_PREFIX+U57->U57_CODIGO+U57->U57_PARCEL)
					If lDeposito //deposito no PDV
						//exclui o titulo
						If !(lRet := ExcTitSE1())
							cMsgErro := "Falha ao excluir titulo " + SE1->E1_TIPO
							Exit
						EndIf
					Else //deposito aprovado na retaguarda
						//exclui o cheque troco
						If lChqTroc .AND. (U57->U57_CHTROC > 0) .and. !(lRet := ExcCheTro(1))
							cMsgErro := "Falha ao excluir cheque troco."
							Exit
						EndIf
						//cancela a baixa
						If !(lRet := CancBxSE1())
							cMsgErro := "Falha ao estornar baixa do titulo " + SE1->E1_TIPO
							Exit
						EndIf
					EndIf
				EndIf
				QRYSE1->(DbSkip())
			EndDo
		EndIf

		If Select("QRYSE1") > 0
			QRYSE1->(DbCloseArea())
		EndIf

	//ORIGEM SAQUE => gera estorno financeiro da requisição POS-PAGA
	ElseIf nOpc == '2'

		//exclui o cheque troco
		If lChqTroc .AND. (U57->U57_CHTROC > 0)
			cMsgErro := "Falha ao excluir cheque troco."
			lRet := ExcCheTro(1)
		EndIf

		//EXCLUINDO AS NCC
		if lRet
			DbSelectArea("SE1")
			SE1->(DbSetOrder(1)) //E1_FILIAL+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO

			cQry := "select SE1.R_E_C_N_O_ AS SE1RECNO" + cPulaLinha
			cQry += " from " + RetSqlName("SE1") + " SE1" + cPulaLinha
			cQry += " where SE1.D_E_L_E_T_ <> '*'" + cPulaLinha
			cQry += " and SE1.E1_FILIAL = '" + xFilial("SE1") + "'" + cPulaLinha
			cQry += " and E1_PREFIXO = '" + IIF(U57->U57_TUSO=="S",cPfRqSaq,"RPC") + "'" + cPulaLinha
			cQry += " and E1_TIPO = '" + "NCC" + "'" + cPulaLinha
			cQry += " and E1_XCODBAR = '" + AllTrim(U57->U57_PREFIX+U57->U57_CODIGO+U57->U57_PARCEL) + "'" + cPulaLinha
			//cQry += " and E1_SALDO > 0" + cPulaLinha

			If Select("QRYSE1") > 0
				QRYSE1->(DbCloseArea())
			EndIf

			cQry := ChangeQuery(cQry)
			TcQuery cQry New Alias "QRYSE1" // Cria uma nova area com o resultado do query

			QRYSE1->(dbGoTop())

			If QRYSE1->(!Eof())
				While QRYSE1->(!Eof())

					SE1->(DbGoTo(QRYSE1->SE1RECNO))

					If AllTrim(SE1->E1_XCODBAR) == AllTrim(U57->U57_PREFIX+U57->U57_CODIGO+U57->U57_PARCEL)
						//cancela a baixa
						If !(lRet := CancBxSE1())
							cMsgErro := "Falha ao estornar baixa do titulo " + SE1->E1_TIPO
							Exit
						EndIf
						//exclui o titulo
						If !(lRet := ExcTitSE1())
							cMsgErro := "Falha ao excluir titulo " + SE1->E1_TIPO
							Exit
						EndIf
					EndIf

					QRYSE1->(DbSkip())
				EndDo
			EndIf
		endif

		//EXCLUINDO OS TITULOS RP
		if lRet
			cParc := soma1(cParc)
			cQry := "select SE1.R_E_C_N_O_ AS SE1RECNO" + cPulaLinha
			cQry += " from " + RetSqlName("SE1") + " SE1" + cPulaLinha
			cQry += " where SE1.D_E_L_E_T_ <> '*'" + cPulaLinha
			cQry += " and SE1.E1_FILIAL = '" + xFilial("SE1") + "'" + cPulaLinha
			cQry += " and E1_PREFIXO = '" + IIF(U57->U57_TUSO=="S",cPfRqSaq,"RPC") + "'" + cPulaLinha
			cQry += " and E1_TIPO = '" + cTpSE1 + "'" + cPulaLinha
			cQry += " and E1_XCODBAR = '" + AllTrim(U57->U57_PREFIX+U57->U57_CODIGO+U57->U57_PARCEL) + "'" + cPulaLinha
			//cQry += " and E1_SALDO > 0" + cPulaLinha

			If Select("QRYSE1") > 0
				QRYSE1->(DbCloseArea())
			EndIf

			cQry := ChangeQuery(cQry)
			TcQuery cQry New Alias "QRYSE1" // Cria uma nova area com o resultado do query

			QRYSE1->(dbGoTop())

			If QRYSE1->(!Eof())
				While QRYSE1->(!Eof())

					SE1->(DbGoTo(QRYSE1->SE1RECNO))

					If AllTrim(SE1->E1_XCODBAR) == AllTrim(U57->U57_PREFIX+U57->U57_CODIGO+U57->U57_PARCEL)
						//exclui o titulo
						If !(lRet := ExcTitSE1())
							cMsgErro := "Falha ao excluir titulo " + SE1->E1_TIPO
							Exit
						EndIf
					EndIf
					QRYSE1->(DbSkip())
				EndDo
			EndIf

			If Select("QRYSE1") > 0
				QRYSE1->(DbCloseArea())
			EndIf
		endif

	EndIf

	RestArea(aAreaSE1)
	RestArea(aArea)

	If lRet
		//Conout(" >> GeraEstSE1 -> estorno realizado com sucesso!")
	EndIf

Return(lRet)

//-----------------------------------------------------------------------------------
// CancBxSE1 -> função para cancelar baixa do SE1 posicionado
//-----------------------------------------------------------------------------------
Static Function CancBxSE1()

	Local lRet := .T.
	Local aFin070 := {}

	// Cancela a Baixa

	AADD( aFin070, {"E1_FILIAL"  , SE1->E1_FILIAL	, Nil})
	AADD( aFin070, {"E1_PREFIXO" , SE1->E1_PREFIXO	, Nil})
	AADD( aFin070, {"E1_NUM"     , SE1->E1_NUM 		, Nil})
	AADD( aFin070, {"E1_PARCELA" , SE1->E1_PARCELA	, Nil})
	AADD( aFin070, {"E1_TIPO"    , SE1->E1_TIPO		, Nil})

	//Remove a conciliação do titulo;
	DbSelectArea("SE5")
	SE5->(DbSetOrder(7)) //E5_FILIAL+E5_PREFIXO+E5_NUMERO+E5_PARCELA+E5_TIPO+E5_CLIFOR+E5_LOJA+E5_SEQ+E5_RECPAG
	If SE5->(DbSeek(xFilial("SE5")+SE1->(E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO+E1_CLIENTE+E1_LOJA)))
		While SE5->(E5_FILIAL+E5_PREFIXO+E5_NUMERO+E5_PARCELA+E5_TIPO+E5_CLIFOR+E5_LOJA) == (xFilial("SE5")+SE1->(E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO+E1_CLIENTE+E1_LOJA))
			If SE5->E5_RECPAG == 'P' .and. SE5->E5_RECONC == 'x'
				RecLock("SE5",.F.)
				SE5->E5_RECONC := " "
				SE5->(MsUnLock())
			EndIf
			SE5->(DbSkip())
		EndDo
	EndIf

	//Assinatura de variáveis que controlarão a exclusão automática do título;
	lMsErroAuto := .F.
	lMsHelpAuto := .T.

	//Posiciono a SM0 antes da baixa, pois está vindo desposicionada
	SM0->(DbGoTop())
	While SM0->(!Eof())
		If (AllTrim(SM0->M0_CODFIL) == AllTrim(cFilAnt)) .and. (AllTrim(SM0->M0_CODIGO) == AllTrim(cEmpAnt))
			Exit
		EndIf
	 	SM0->(DbSkip())
	EndDo

	//rotina automática para exclusão da baixa do título;
	MSExecAuto({|x,y| Fina070(x,y)}, aFin070, 6)

	//Quando houver erros, exibí-los em tela;
	If lMsErroAuto
		if !IsBlind()
			MostraErro()
		else
			cErroExec := MostraErro("\temp")
			//Conout(" ============ ERRO =============")
			//Conout(cErroExec)
			cErroExec := ""
		endif
		lRet := .F.
	EndIf

Return lRet

//-------------------------------------------------------------------
// ExcTitSE1 -> exclui o título da SE1
//-------------------------------------------------------------------
Static Function ExcTitSE1()

	Local lRet := .T.
	Local aFin040 := {}

	Private lMsErroAuto := .F.
	Private lMsHelpAuto := .T.

	AADD( aFin040, {"E1_FILIAL"  , SE1->E1_FILIAL  	,Nil})
	AADD( aFin040, {"E1_PREFIXO" , SE1->E1_PREFIXO 	,Nil})
	AADD( aFin040, {"E1_NUM"     , SE1->E1_NUM	   	,Nil})
	AADD( aFin040, {"E1_PARCELA" , SE1->E1_PARCELA	,Nil})
	AADD( aFin040, {"E1_TIPO"    , SE1->E1_TIPO  	,Nil})
	If SE1->E1_TIPO = "RA "
		AADD( aFin040, {"CBCOAUTO"   , SE1->E1_PORTADO  ,Nil}) //-> E1_PORTADO
		AADD( aFin040, {"CAGEAUTO"   , SE1->E1_AGEDEP   ,Nil}) //-> E1_AGEDEP
		AADD( aFin040, {"CCTAAUTO"   , SE1->E1_AGEDEP   ,Nil}) //-> E1_AGEDEP
	EndIf

	//Assinatura de variáveis que controlarão a exclusão automática do título;
	lMsErroAuto := .F.
	lMsHelpAuto := .T.

	//Posiciono a SM0 antes da baixa, pois está vindo desposicionada
	SM0->(DbGoTop())
	While SM0->(!Eof())
		If (AllTrim(SM0->M0_CODFIL) == AllTrim(cFilAnt)) .and. (AllTrim(SM0->M0_CODIGO) == AllTrim(cEmpAnt))
			Exit
		EndIf
	 	SM0->(DbSkip())
	EndDo

	//Invocando rotina automática para exclusao 									;
	MSExecAuto({|x,y| Fina040(x,y)}, aFin040, 5)

	//Quando houver erros, exibí-los em tela										 ;
	If lMsErroAuto
		if !IsBlind()
			MostraErro()
		else
			cErroExec := MostraErro("\temp")
			//Conout(" ============ ERRO =============")
			//Conout(cErroExec)
			cErroExec := ""
		endif
		lRet := .F.
	EndIf

Return lRet

//-------------------------------------------------------------------
// ExcCheTro -> exclui o cheque troco utilizado
//-------------------------------------------------------------------
Static Function ExcCheTro(nOpc)

	Local lRet := .F.
	Local cUF2_CODBAR := U57->U57_PREFIX+U57->U57_CODIGO+U57->U57_PARCEL
	Default nOpc := 0

	If lRet := U_TRETE29I("","",cUF2_CODBAR,,.T.,.T.) //estorna o financeiro do cheque troco
		If nOpc == 1
			lRet := U_TRETE29D( cUF2_CODBAR ) //ajusta movimentação bancaria da baixa (desconsiderando o cheque troco)
		EndIf
	EndIf

Return lRet

//--------------------------------------------------------------------------
// Rotina | TRETE23D      | Autor | Pablo Cavalcante    | Data | 04.09.2014
//--------------------------------------------------------------------------
// Descr. | Rotina faz transferencia e baixa(saque) do titulo de credito
//        |
//--------------------------------------------------------------------------
// Uso    | Totvs GO
//--------------------------------------------------------------------------
User Function TRETE23D(nRecNo,cBanco,cAgencia,cNumCon,cCPF,cPlaca,cMotivo,cPdv,cEstacao,cNumMov,nValSaq,nChTroco,dDatMov,cHoraMov,cVendedor,cNomMot)
	
	Local aRet := {-1,"","","","","",Nil,Nil} //{"E1_SALDO","U56_REQUIS","U56_CARGO","E1_XCODBAR","E1_CLIENTE","E1_LOJA"}
	Local lRet := .T.
	Local cChv := ""
	Default dDatMov := ddatabase
	Default cHoraMov := Time()
	Default cVendedor := Space(TamSX3("A3_COD")[1])

	//realiza a baixa do titulo
	DbSelectArea("SE1")
	SE1->(DbGoTo(nRecNo))
	If SE1->(!Eof())

		BeginTran() //controle de transação

		cChv := SE1->(E1_CLIENTE+E1_LOJA+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO) //backup da chave do titulo

		If xFilial("SE1") <> SE1->E1_FILIAL //verifica se o titulo é de outra filial, caso sim, inicia o processo de transferencia
			If AllTrim(SE1->E1_TIPO) == 'RA' .OR. (SE1->E1_VALOR <> SE1->E1_SALDO)
				lRet := U_TRETE31C(nRecNo,@cChv) //Executa a transferencia do RA para a filial corrente
			Else
				lRet := U_TRETE31D(nRecNo,,@cChv) //Executa a tranferencia do titulo para a filial corrente
			EndIf
		EndIf

		SE1->(DbSetOrder(2)) //E1_FILIAL+E1_CLIENTE+E1_LOJA+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO
		If lRet .and. SE1->(DbSeek(xFilial("SE1")+cChv)) //(AllTrim(SE1->E1_TIPO) == 'RA' .OR. SE1->(DbSeek(xFilial("SE1")+cChv)))

			lRet := U_TRETE23B(cBanco,cAgencia,cNumCon) //realiza a baixa do titulo posicionado, na filial corrente

			If lRet

				//atualiza os dados do titulo: saldo e dados de saque
				aRet[1] := SE1->E1_SALDO
				aRet[4] := SE1->E1_XCODBAR
				aRet[5] := SE1->E1_CLIENTE
				aRet[6] := SE1->E1_LOJA

				Reclock("SE1",.F.)
				If SE1->(FieldPos("E1_XMOTOR")) > 0
					SE1->E1_XMOTOR  := cCPF
				EndIf
				If SE1->(FieldPos("E1_XPLACA")) > 0
					SE1->E1_XPLACA  := cPlaca
				EndIf
				If SE1->(FieldPos("E1_XMOTIV")) > 0
					SE1->E1_XMOTIV  := cMotivo
				EndIf
				SE1->(MsUnLock())

				//atualiza o status da requisicao na retaguarda para usada
				If !Empty(SE1->E1_XCODBAR)
					DbSelectArea("U57")
					U57->(DbSetOrder(1))
					If U57->(DbSeek(xFilial("U57")+alltrim(SE1->E1_XCODBAR)))

						Reclock("U57",.F.)

							U57->U57_XOPERA := cBanco
							U57->U57_XGERAF := 'G'
							U57->U57_FILSAQ := cFilAnt
							U57->U57_MOTIVO := cMotivo
							U57->U57_XPDV   := cPdv
							U57->U57_XESTAC := cEstacao
							U57->U57_XNUMMO	:= cNumMov
							U57->U57_DATAMO	:= dDatMov
							U57->U57_XHORA	:= cHoraMov
							U57->U57_VALSAQ := nValSaq
							U57->U57_CHTROC := nChTroco
							U57->U57_MOTORI := cCPF

							//Grava Vendedor
							If U57->(FieldPos("U57_VEND")) > 0
								U57->U57_VEND := cVendedor
							EndIf

							//Grava Nome Motorista
							If U57->(FieldPos("U57_NOMMOT")) > 0
								U57->U57_NOMMOT := cNomMot 
							EndIf

						U57->(MsUnLock())

						aRet[8] := CopiaReg("U57")

						//realiza a impressao dos dados de saque na impresso fiscal
						DbSelectArea("U56")
						If U56->(DbSeek(U57->(U57_FILIAL+U57_PREFIX+U57_CODIGO)))
							aRet[2] := U56->U56_REQUIS
							aRet[3] := U56->U56_CARGO

							aRet[7] := CopiaReg("U56")
						EndIf

						//tratamento para inclusao do motorista, a partir do campo CPF informado no saque
						If U57->(FieldPos("U57_NOMMOT")) > 0 .AND. !empty(U57->U57_MOTORI) .AND. len(Alltrim(U57->U57_MOTORI))==11
							AddMotoris(U57->U57_MOTORI, U57->U57_NOMMOT)
						EndIf

					EndIf
				EndIf

			Else
				DisarmTransaction()
			EndIf
		Else
			DisarmTransaction()
		EndIf

		EndTran()

	EndIf

Return(aRet)

//gera array com dados do registro a ser copiado
Static Function CopiaReg(cTabelaAux)

	Local nX
	Local aRetReg := {}
	Local aEstru := (cTabelaAux)->(DbStruct())

	for nX := 1 to Len(aEstru)
		if !(SubStr(Alltrim(aEstru[nX][1]),4) $ "_SITUA,_HREXP,_MSEXP,_XINDEX")
			aadd(aRetReg, {aEstru[nX][1], &(cTabelaAux+"->"+aEstru[nX][1]) })
		endif
	next nX

Return aRetReg

/*/{Protheus.doc} AddMotoris
Funcao para gravacao do motorista a partir CPF informado no cupom
@author Danilo Brito
@since 24/09/2018
@version 1.0
@return Nil
@param cCGCMot, CPF do Motorista
@param cNomeMot, nome do Motorista
@type function
/*/
Static Function AddMotoris(cCGCMot, cNomeMot)

	Local aArea := GetArea()
	Local aCampos := {}
	Local nOpc := 3 //inclusao
	Private lMsErroAuto := .F.

	if empty(cNomeMot)
		cNomeMot := "NAO INFORMADO"
	endif

	DbSelectArea("DA4")
	DA4->(DbSetOrder(3)) //DA4_FILIAL+DA4_CGC
	if DA4->(DbSeek(xFilial("DA4")+SubStr(cCGCMot,1,TamSX3("DA4_CGC")[1])))
		nOpc := 4 //alteracao
		aadd(aCampos, {"DA4_COD", DA4->DA4_COD } )
	endif

	aadd(aCampos, {"DA4_NOME"	, SubStr(cNomeMot,1,TamSX3("DA4_NOME")[1]) } )
	aadd(aCampos, {"DA4_NREDUZ"	, SubStr(cNomeMot,1,TamSX3("DA4_NREDUZ")[1]) } )
	aadd(aCampos, {"DA4_CGC"	, SubStr(cCGCMot,1,TamSX3("DA4_CGC")[1]) } )

	//chama a gravaçao execauto MVC
	lMsErroAuto := .F.
	FWMVCRotAuto(FWLoadModel("OMSA040"),"DA4",nOpc,{{"OMSA040_DA4",aCampos}},,.T.)

	RestArea(aArea)

Return

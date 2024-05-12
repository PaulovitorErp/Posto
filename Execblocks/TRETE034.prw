#INCLUDE "protheus.ch"
#INCLUDE "fwmvcdef.ch"
#INCLUDE "TOPCONN.CH"
#INCLUDE "TOTVS.CH"
#INCLUDE "TBICONN.CH"

/*/{Protheus.doc} TRETE034
JOB para gerar financeiro de VALE SERVIÇO
@author Maiki
@since 10/06/2019
@version 1.0
@return Nil
@param _cXEmp, , descricao
@param _cXFil, , descricao
@param _cCodVale, , descricao
@type function
/*/
User function TRETE034(_cAmbient, _cCodVale, _lInclui, _lExclui)

	Local cQry			:= ""
	Local lOk 			:= .T.
	Local dBkpData

	Default _cAmbient	:= ""
	Default _cCodVale	:= ""
	Default _lInclui 	:= .T.
	Default _lExclui 	:= .T.

	//Conout(">> INICIO TPDVA06B - GERA FINANCEIRO VALE SERVICO")

	dBkpData := dDataBase

	DbSelectArea("UIC")
	DbSelectArea("SA3")
	SA3->(DbSetOrder(1))

	DbSelectArea("UH8")
	UH8->(DbSetOrder(1)) // UH8_FILIAL+UH8_FORNEC+UH8_LOJA

	if _lInclui

		If Select("T_UIC")>0
			T_UIC->(DbCloseArea())
		EndIf

		cQry := " SELECT R_E_C_N_O_"
		cQry += " FROM " + RetSqlName("UIC")
		cQry += " WHERE UIC_FILIAL = '"+xFilial("UIC")+"'"
		cQry += " AND D_E_L_E_T_ <> '*'"
		cQry += " AND UIC_PROCES = '2'" // Não processados financeiro
		cQry += " AND UIC_STATUS = 'A'" // A=Aberto;C=Cancelado

		If !Empty(_cAmbient+_cCodVale)
			cQry += "   AND UIC_AMB = '" + _cAmbient + "' AND UIC_CODIGO = '" + _cCodVale + "' AND UIC_PROCBX = 'C'"
		Else
			cQry += "   AND UIC_PROCBX <> 'C'"
		EndIf
		cQry := ChangeQuery(cQry)

		TcQuery cQry New Alias "T_UIC" // Cria uma nova area com o resultado do query

		While T_UIC->(!EOF())

			UIC->(DbGoTo(T_UIC->R_E_C_N_O_))
			lOk := .T.

			// Ajusta o valor para evitar erro no execauto de inclusão e baixa
			If UIC->UIC_PRCPRO < 0.01

				RecLock("UIC",.F.)
				UIC->UIC_PRCPRO := 0.01
				UIC->(MsUnlock())
			EndIf

			dDataBase := UIC->UIC_DATA

			lOk := .T.

			BeginTran()

			If UIC->UIC_PROCES == '2' // Não processado

				//Conout("=> TPDVA06B: INCLUSÃO SE1 VALE " + UIC->UIC_AMB + UIC->UIC_CODIGO)

				If GeraSe1Vl(iif(UIC->UIC_TIPO == "R", 1 , 2)) // Gera título a receber
					UH8->(DbGoTop())
					If UH8->(DbSeek(xFilial("UH8")+UIC->UIC_FORNEC+UIC->UIC_LOJAF))
						If UH8->UH8_TITAPG == "N" // Não Gera título a pagar
							//se não gera titulo a pagar, considera processado
							RecLock("UIC", .F.)
							UIC->UIC_PROCES := "1"
							UIC->(MsUnlock())
						else
							//Conout("=> TPDVA06B: INCLUSÃO SE2 VALE " + UIC->UIC_AMB + UIC->UIC_CODIGO)

							If GeraSe2Vl() // Gera título a pagar
								RecLock("UIC", .F.)
								UIC->UIC_PROCES := "1"
								UIC->(MsUnlock())
							Else
								lOk := .F.
								DisarmTransaction()
							EndIf
						EndIf
					else
						If !IsBlind()
							MsgAlert("Falha ao encontrar fornecedor do prestador de serviço (UH8)!","Falha")
						endif
						//Conout("=> TPDVA06B: VALE "+UIC->UIC_AMB+UIC->UIC_CODIGO+" -> FALHA AO ENCONTRAR UH8 PRESTADOR ")
						lOk := .F.
						DisarmTransaction()
					EndIf
				Else
					lOk := .F.
					DisarmTransaction()
				EndIf
			EndIf

			EndTran()

			T_UIC->(DbSkip())
		EndDo

		T_UIC->(DbCloseArea())
	endif

	// Processando os deletados
	if _lExclui

		cQry := " SELECT * "
		cQry += " FROM "+RetSqlName("UIC")+""
		cQry += " WHERE UIC_FILIAL = '"+xFilial("UIC")+"'"
		cQry += " AND D_E_L_E_T_ = ' '" //não deletados
		cQry += " AND UIC_STATUS = 'C'" // A=Aberto;C=Cancelado
		If !Empty(_cAmbient+_cCodVale)
			cQry += " AND UIC_AMB = '" + _cAmbient + "' AND UIC_CODIGO = '"+_cCodVale+"' AND UIC_PROCEX = 'C'"
		Else
			cQry += " AND UIC_PROCEX = ''" // Não processados
		EndIf
		cQry := ChangeQuery(cQry)

		TcQuery cQry New Alias "T_UIC" // Cria uma nova area com o resultado do query

		While T_UIC->(!Eof())

			dDataBase := STOD(T_UIC->UIC_DATA)

			lOk := .T.

			BeginTran()

			// Localiza os títulos a pagar gerados, para exclusão
			Dbselectarea("SE2")
			SE2->(Dbsetorder(1)) //E2_FILIAL+E2_PREFIXO+E2_NUM+E2_PARCELA+E2_TIPO+E2_FORNECE+E2_LOJA
			SE2->(DbSeek(xFilial("SE2")+T_UIC->UIC_AMB+PadR(T_UIC->UIC_CODIGO,TamSX3("E2_NUM")[1])))
			While SE2->(!EOF()) .And. SE2->E2_FILIAL+SE2->E2_PREFIXO+SE2->E2_NUM == xFilial("SE2")+T_UIC->UIC_AMB+PadR(T_UIC->UIC_CODIGO,TamSX3("E2_NUM")[1])
				//Conout("=> TPDVA06B: EXCLUI SE2 BAIXA VALE " + T_UIC->UIC_AMB+T_UIC->UIC_CODIGO)
				if SE2->E2_TIPO == "VLS"
					If SE2->E2_SALDO == 0 .OR. !ExcSE2() // Exclui parcela
						If !Empty(_cAmbient+_cCodVale)	//conferencia de caixa
							MsgAlert("Não foi possível excluir titulo a pagar referente ao vale serviço!","Atenção")
						endif
						lOk := .F.
						DisarmTransaction()
						Exit
					EndIf
				endif
				SE2->(DbSkip())
			EndDo

			If lOk

				// Localiza título para exclusão
				DbSelectArea("SE1")
				SE1->(DbSetOrder(1)) //E1_FILIAL+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO
				SE1->(DbSeek(xFilial("SE1")+T_UIC->UIC_AMB+PadR(T_UIC->UIC_CODIGO,TamSX3("E1_NUM")[1]) ))
				While SE1->(!EOF()) .AND. SE1->E1_FILIAL+SE1->E1_PREFIXO+SE1->E1_NUM == xFilial("SE1")+T_UIC->UIC_AMB+PadR(T_UIC->UIC_CODIGO,TamSX3("E1_NUM")[1])
					//Conout("=> TPDVA06B: EXCLUI SE1 VALE " + T_UIC->UIC_AMB+T_UIC->UIC_CODIGO)
					if SE1->E1_TIPO == "VLS"
						If !ExcSE1(iif(T_UIC->UIC_TIPO == "R", 1, 2)) //excluiu parcela
							If !Empty(_cAmbient+_cCodVale)	//conferencia de caixa
								MsgAlert("Não foi possível excluir titulo a receber referente ao vale serviço!","Atenção")
							endif
							lOk := .F.
							DisarmTransaction()
							EXIT
						EndIf
					endif

					SE1->(DbSkip())
				EndDo
			EndIf

			If lOk
				SET DELETED OFF //Desabilita filtro do campo D_E_L_E_T_

				UIC->(DbGoTo(T_UIC->R_E_C_N_O_))

				RecLock("UIC", .F.)
				UIC->UIC_PROCEX := "*"
				UIC->(MsUnlock())

				SET DELETED ON //Habilita filtro do campo D_E_L_E_T_
			EndIf

			EndTran()

			T_UIC->(DbSkip())
		EndDo

		T_UIC->(DbCloseArea())

	endif

	dDataBase := dBkpData

	//Conout(">> FIM TPDVA06B - GERA FINANCEIRO VALE SERVICO")

Return lOk

//------------------------------------------------------
// Gera titulo SE1 do vale
//------------------------------------------------------
Static Function GeraSe1Vl(nTipo)

	Local aArea     := GetArea()
	Local aAreaSE1  := SE1->(GetArea())
	Local lRet 		:= .T.
	Local cParcela	:= Space(TamSX3("E1_PARCELA")[1])
	Local cTipo		:= "VLS" //Pré Ou Pós-Pago
	Local cNatur	:= SuperGetMv("MV_XNATVSR",.F.,"OUTROS")
	Local aFin040 	:= {}
	Local cCondPg	:= ""
	Local aParc		:= {}
	Local nX		:= 0

	If nTipo == 2 // Se Pós-Pago

		cNatur := SuperGetMv("MV_XNATVSO",.F.,"OUTROS")

		SA1->(DbSetOrder(1)) 
		if SA1->(DbSeek(xFilial("SA1")+UIC->UIC_CLIENT+UIC->UIC_LOJAC ))
			If !Empty(SA1->A1_XCDVLSP)
				cCondPg	:= SA1->A1_XCDVLSP
			EndIf
		endif

		If Empty(cCondPg)
			cCondPg := SuperGetMv("MV_XCDPVSO",.F.,"001")
		EndIf
	EndIf

	If Empty(cCondPg)
		aParc := {{dDatabase,UIC->UIC_PRCPRO}}
	Else
		aParc := Condicao(UIC->UIC_PRCPRO,cCondPg,0.00,dDatabase,0.00,{},,0)
	EndIf

	if len(aParc) == 1 //deve ter somente uma parcela

		//Verifica se a parcela ja existe
		DbSelectArea("SE1")
		SE1->(DbSetOrder(1)) //E1_FILIAL+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO
		if !SE1->(DbSeek(xFilial("UIC")+UIC->UIC_AMB+PadR(UIC->UIC_CODIGO,TamSX3("E1_NUM")[1])+cParcela+cTipo))

			aFin040 := {}

			AAdd(aFin040,{"E1_FILIAL"  , xFilial("SE1")  			,Nil})
			AAdd(aFin040,{"E1_PREFIXO" , UIC->UIC_AMB        		,Nil})
			AAdd(aFin040,{"E1_NUM"     , UIC->UIC_CODIGO 			,Nil})
			AAdd(aFin040,{"E1_PARCELA" , cParcela		 			,Nil})
			AAdd(aFin040,{"E1_TIPO"    , cTipo           			,Nil})
			AAdd(aFin040,{"E1_NATUREZ" , cNatur          			,Nil})

			If !Empty(UIC->UIC_BANCO)
				AAdd(aFin040,{"E1_PORTADO" , UIC->UIC_BANCO				,Nil})
			EndIf
			If !Empty(UIC->UIC_AG)
				AAdd(aFin040,{"E1_AGEDEP"  , UIC->UIC_AG				,Nil})
			EndIf
			If !Empty(UIC->UIC_CONTA)
				AAdd(aFin040,{"E1_CONTA"   , UIC->UIC_CONTA  			,Nil})
			EndIf

			AAdd(aFin040,{"E1_CLIENTE" , UIC->UIC_CLIENT 			,Nil})
			AAdd(aFin040,{"E1_LOJA"    , UIC->UIC_LOJAC  			,Nil})

			If SE1->(FieldPos("E1_DTLANC")) > 0
				AAdd(aFin040,{"E1_DTLANC"	 , dDataBase				,Nil})
			EndIf

			AAdd(aFin040,{"E1_EMISSAO" , dDataBase       			,Nil})
			AAdd(aFin040,{"E1_VENCTO"  , aParc[1][1]    			,Nil})
			AAdd(aFin040,{"E1_VENCREA" , DataValida(aParc[1][1])	,Nil})
			AAdd(aFin040,{"E1_VALOR"   , aParc[1][2] 				,Nil})
			AAdd(aFin040,{"E1_VEND1"   , UIC->UIC_VEND				,Nil})

			If SE1->(FieldPos("E1_XPLACA")) > 0
				AAdd(aFin040,{"E1_XPLACA"  , UIC->UIC_PLACA 			,Nil})
			endif
			If SE1->(FieldPos("E1_XMOTOR")) > 0
				AAdd(aFin040,{"E1_XMOTOR"  , UIC->UIC_MOTORI 			,Nil})
			endif
			AAdd(aFin040,{"E1_ORIGEM"  ,"TRETE034"					,Nil})

			if SE1->(FieldPos("E1_XCOND")) > 0
				If nTipo == 2 .And. !Empty(cCondPg) // Se Pós-Pago
					AAdd(aFin040,{"E1_XCOND"   , cCondPg					,Nil})
					AAdd(aFin040,{"E1_XDTFATU" , U_TRETE014(cCondPg, aParc[1][1]) ,Nil})
				EndIf
			endif

			//Assinatura de variáveis que controlarão a inserção automática da RA
			lMsErroAuto := .F.
			lMsHelpAuto := .F.

			//Invocando rotina automática para criação da RA
			MSExecAuto({|x,y| Fina040(x,y)}, aFin040, 3)

			//Quando houver erros, exibí-los em tela
			If lMsErroAuto

				If !IsBlind()
					MostraErro()
				Else
					cErroExec := MostraErro("\temp")
					//Conout("=> TPDVA06B: ERRO INCLUSÃO SE1 VALE")
					//Conout(cErroExec)
					cErroExec := ""
				EndIf
				lRet := .F.

			ElseIf nTipo == 1 // Se Pré-Pago, baixa o título

				//Conout("=> TPDVA06B: BAIXA TITULO VALE " + UIC->UIC_AMB+UIC->UIC_CODIGO)
				If !BaixaSE1(UIC->UIC_BANCO,UIC->UIC_AG,UIC->UIC_CONTA)
					lRet := .F.
				EndIf

			EndIf
		else
			//Conout("=> TPDVA06B: TITULO JA EXISTENTE! VALE " + UIC->UIC_AMB+UIC->UIC_CODIGO)

			If nTipo == 1 .AND. SE1->E1_SALDO > 0 // Se Pré-Pago, baixa o título
				//Conout("=> TPDVA06B: BAIXA TITULO VALE " + UIC->UIC_AMB+UIC->UIC_CODIGO)
				If !BaixaSE1(UIC->UIC_BANCO,UIC->UIC_AG,UIC->UIC_CONTA)
					lRet := .F.
				EndIf
			EndIf
		endif
	else
		If !IsBlind()
			MsgAlert("Condição de pagamento não deve gerar mais de uma parcela!","Falha")
		endif
		//Conout("=> TPDVA06B: CONDIÇÃO DE PAGAMENTO NÃO DEVE GERAR MAIS DE UMA PARCELA! VALE " + UIC->UIC_AMB+UIC->UIC_CODIGO)
		lRet := .F.
	endif

	RestArea(aAreaSE1)
	RestArea(aArea)

Return(lRet)

//------------------------------------------------------
// faz a baixa do titulo a receber
//------------------------------------------------------
Static Function BaixaSE1(cBanco,cAgencia,cNumCon)

	Local lRet 		:= .T.
	Local _aBaixa 	:= {}
	Local cBkpFunNam := FunName()
	Local cMotBxVls := SuperGetMV("TP_MOTBXVS",,"DEB") //define motivo de baixa para vale serviço
	
	Private lMsErroAuto := .F.
	Private lMsHelpAuto := .F.

	_aBaixa := {;
		{"E1_FILIAL"    ,SE1->E1_FILIAL			,Nil},;
		{"E1_PREFIXO"   ,SE1->E1_PREFIXO		,Nil},;
		{"E1_NUM"       ,SE1->E1_NUM			,Nil},;
		{"E1_PARCELA"   ,SE1->E1_PARCELA		,Nil},;
		{"E1_TIPO"      ,SE1->E1_TIPO			,Nil},;
		{"E1_CLIENTE" 	,SE1->E1_CLIENTE 		,Nil},;
		{"E1_LOJA" 		,SE1->E1_LOJA 			,Nil},;
		{"AUTMOTBX"     ,cMotBxVls				,Nil},;
		{"AUTBANCO"     ,cBanco 				,Nil},;
		{"AUTAGENCIA"   ,cAgencia 				,Nil},;
		{"AUTCONTA"     ,cNumCon 				,Nil},;
		{"AUTDTBAIXA"   ,dDataBase				,Nil},;
		{"AUTDTCREDITO" ,dDataBase				,Nil},;
		{"AUTHIST"      ,"BAIXA VALE SEVICO"    ,Nil},;
		{"AUTJUROS"     ,0                      ,Nil,.T.},;
		{"AUTVALREC"    ,SE1->E1_SALDO			,Nil}}

	SetFunName("FINA070") //ADD Danilo, para ficar correto campo E5_ORIGEM (relatorios e rotinas conciliacao)					
	MSExecAuto({|x,y| Fina070(x,y)}, _aBaixa, 3) //Baixa conta a receber
	SetFunName(cBkpFunNam)

	If lMsErroAuto

		If !IsBlind()
			MostraErro()
		Else
			cErroExec := MostraErro("\temp")
			//Conout(" ============ ERRO =============")
			//Conout(cErroExec)
			cErroExec := ""
		EndIf

		lRet := .F.
	EndIf

Return lRet

//------------------------------------------------------
// gera finenceiro contas a pagar
//------------------------------------------------------
Static Function GeraSe2Vl()

	Local aArea     := GetArea()
	Local aAreaSE1  := SE2->(GetArea())
	Local lRet 		:= .T.
	Local cParcela	:= Space(TamSX3("E1_PARCELA")[1])
	Local cTipo		:= "VLS"
	Local cNatur	:= SuperGetMv("MV_XNATVSP",.F.,"OUTROS")
	Local cNatTx	:= SuperGetMv("MV_XNATVST",.F.,"OUTROS")
	Local cCCusto	:= SuperGetMv("MV_XCCDVSP",.F.,"01010101")
	Local nDias		:= SuperGetMv("MV_XDIASVS",.F.,1)
	Local aTitPag 	:= {}

	//Assinatura de variáveis que controlarão a inserção automática da RA
	Private lMsErroAuto := .F.
	Private lMsHelpAuto := .F.

	DbSelectarea("SE2")
	SE2->(DbSetOrder(1)) // E2_FILIAL+E2_PREFIXO+E2_NUM+E2_PARCELA+E2_TIPO+E2_FORNECE+E2_LOJA
	if !SE2->(DbSeek(xFilial("UIC")+UIC->UIC_AMB+PadR(UIC->UIC_CODIGO,TamSX3("E1_NUM")[1])+cParcela+cTipo))

		AAdd(aTitPag,{"E2_FILIAL"	, xFilial("SE2")				,Nil})
		AAdd(aTitPag,{"E2_PREFIXO"	, UIC->UIC_AMB					,Nil})
		AAdd(aTitPag,{"E2_NUM"		, UIC->UIC_CODIGO				,Nil})
		AAdd(aTitPag,{"E2_PARCELA"	, cParcela						,Nil})
		AAdd(aTitPag,{"E2_TIPO"		, cTipo							,Nil})
		AAdd(aTitPag,{"E2_NATUREZ"	, cNatur						,Nil})
		AAdd(aTitPag,{"E2_FORNECE"	, UIC->UIC_FORNEC				,Nil})
		AAdd(aTitPag,{"E2_LOJA"		, UIC->UIC_LOJAF				,Nil})
		AAdd(aTitPag,{"E2_EMISSAO"	, dDataBase						,Nil})
		AAdd(aTitPag,{"E2_VENCTO"	, dDataBase+nDias				,Nil})
		AAdd(aTitPag,{"E2_VENCREA"	, DataValida(dDataBase+nDias)	,Nil})
		AAdd(aTitPag,{"E2_VALOR"	, UIC->UIC_PRCPRO				,Nil})
		AAdd(aTitPag,{"E2_CCD"		, cCCusto						,Nil})
		AAdd(aTitPag,{"E2_ORIGEM" 	, "TRETE034"					,Nil})
		If SE2->(FieldPos("E2_XPRODUT")) > 0
			AAdd(aTitPag,{"E2_XPRODUT" 	, UIC->UIC_PRODUT				,Nil})
		endif
		If SE2->(FieldPos("E2_XDESCRI")) > 0
			AAdd(aTitPag,{"E2_XDESCRI" 	, UIC->UIC_DESCRI				,Nil})
		endif

		//Invocando rotina automática para criação da RA
		MSExecAuto({|x,y| FINA050(x,y)}, aTitPag, 3)

		//Quando houver erros, exibí-los em tela
		If lMsErroAuto

			If !IsBlind()
				MostraErro()
			Else
				cErroExec := MostraErro("\temp")
				//Conout(" ============ ERRO =============")
				//Conout(cErroExec)
				cErroExec := ""
			EndIf

			lRet := .F.
		Else

			// Gerando PA da Taxa
			DbSelectArea("UH8")
			UH8->(DbSetOrder(1)) // UH8_FILIAL+UH8_FORNEC+UH8_LOJA
			If UH8->(DbSeek(xFilial("UH8")+UIC->UIC_FORNEC+UIC->UIC_LOJAF))
				If UH8->UH8_TXADM > 0
					//forço reposicionar
					SE2->(DbSetOrder(1)) // E2_FILIAL+E2_PREFIXO+E2_NUM+E2_PARCELA+E2_TIPO+E2_FORNECE+E2_LOJA
					If SE2->(DbSeek(xFilial("SE2")+UIC->UIC_AMB+PadR(UIC->UIC_CODIGO,TamSX3("E1_NUM")[1])+cParcela+cTipo))

						aTitPag := {}

						AAdd(aTitPag,{"E2_FILIAL"	, xFilial("SE2")							,Nil})
						AAdd(aTitPag,{"E2_TIPO"		, "AB-"										,Nil})
						AAdd(aTitPag,{"E2_NATUREZ"	, cNatTx									,Nil})
						AAdd(aTitPag,{"E2_VALOR"	, UIC->UIC_PRCPRO * UH8->UH8_TXADM / 100	,Nil})
						AAdd(aTitPag,{"E2_ORIGEM"  	, "TRETE034"								,Nil})

						//Assinatura de variáveis que controlarão a inserção automática da RA
						lMsErroAuto := .F.
						lMsHelpAuto := .F.

						//Invocando rotina automática para criação da RA
						MSExecAuto({|x,y| FINA050(x,y)}, aTitPag, 3)

						//Quando houver erros, exibí-los em tela
						If lMsErroAuto

							If !IsBlind()
								MostraErro()
							Else
								cErroExec := MostraErro("\temp")
								//Conout(" ============ ERRO =============")
								//Conout(cErroExec)
								cErroExec := ""
							EndIf

							lRet := .F.
						EndIf
					EndIf

				EndIf
			EndIf
		EndIf
	else
		//Conout("=> TPDVA06B: TITULO JA EXISTENTE! VALE " + UIC->UIC_AMB+UIC->UIC_CODIGO)
	endif

	RestArea(aAreaSE1)
	RestArea(aArea)

Return(lRet)

//------------------------------------------------------
// Exclusao do titulo a receber
//------------------------------------------------------
Static Function ExcSE1(nTipo)

	Local nX, nY
	Local lRet 		:= .T.
	Local aFin040 	:= {}

	// Cancela baixa apenas de pré
	If nTipo==1 .And. !Empty(SE1->E1_BAIXA)
		//Conout("=> TPDVA06B: CANCELA BAIXA SE1 VALE " + UIC->UIC_AMB+UIC->UIC_CODIGO)
		If !CancBxSE1()
			Return(.F.)
		EndIf
	EndIf

	if nTipo==2 .AND. SE1->E1_SALDO == 0
		//Conout("=> TPDVA06B: VALE " + UIC->UIC_AMB+UIC->UIC_CODIGO + " -> O Titulo VLS ja está baixado!")
		Return(.F.)
	endif

	//Assinatura de variáveis que controlarão a inserção automática da RA
	Private lMsErroAuto := .F.
	Private lMsHelpAuto := .T.

	AAdd(aFin040,{"E1_FILIAL"  , SE1->E1_FILIAL  	,Nil})
	AAdd(aFin040,{"E1_PREFIXO" , SE1->E1_PREFIXO 	,Nil})
	AAdd(aFin040,{"E1_NUM"     , SE1->E1_NUM	   	,Nil})
	AAdd(aFin040,{"E1_PARCELA" , SE1->E1_PARCELA	,Nil})
	AAdd(aFin040,{"E1_TIPO"    , SE1->E1_TIPO  		,Nil})
	if Alltrim(SE1->E1_TIPO) == "RA"
		AADD( aFin040, {"CBCOAUTO" , SE1->E1_PORTADO  ,Nil})
		AADD( aFin040, {"CAGEAUTO" , SE1->E1_AGEDEP ,Nil})
		AADD( aFin040, {"CCTAAUTO" , SE1->E1_CONTA  ,Nil})
	endif

	//Invocando rotina automática para exclusao
	MSExecAuto({|x,y| Fina040(x,y)}, aFin040, 5)

	//Quando houver erros, exibí-los em tela
	If lMsErroAuto

		If !IsBlind()
			MostraErro()
		Else
			cErroExec := MostraErro("\temp")
			//Conout(" ============ ERRO =============")
			//Conout(cErroExec)
			cErroExec := ""
		Endif

		lRet := .F.
	EndIf

Return lRet

//------------------------------------------------------
// Cancela Baixa Contas a Receber
//------------------------------------------------------
Static Function CancBxSE1()

	Local lRet := .T.
	Local aFin070 := {}

	AAdd(aFin070,{"E1_FILIAL"  , SE1->E1_FILIAL		,Nil})
	AAdd(aFin070,{"E1_PREFIXO" , SE1->E1_PREFIXO	,Nil})
	AAdd(aFin070,{"E1_NUM"     , SE1->E1_NUM 		,Nil})
	AAdd(aFin070,{"E1_PARCELA" , SE1->E1_PARCELA	,Nil})
	AAdd(aFin070,{"E1_TIPO"    , SE1->E1_TIPO		,Nil})

	//Assinatura de variáveis que controlarão a exclusão automática do título
	lMsErroAuto := .F.
	lMsHelpAuto := .F.

	//rotina automática para exclusão da baixa do título
	MSExecAuto({|x,y| Fina070(x,y)}, aFin070, 6)

	//Quando houver erros, exibí-los em tela
	If lMsErroAuto

		If !IsBlind()
			MostraErro()
		Else
			cErroExec := MostraErro("\temp")
			//Conout(" ============ ERRO =============")
			//Conout(cErroExec)
			cErroExec := ""
		EndIf

		lRet := .F.
	EndIf

Return lRet

//------------------------------------------------------
// Exclui titulo contas a pagar
//------------------------------------------------------
Static Function ExcSE2()

	Local nX, nY
	Local lRet		:= .T.
	Local aFin050	:= {}

	//Assinatura de variáveis que controlarão a inserção automática da RA
	Private lMsErroAuto := .F.
	Private lMsHelpAuto := .T.

	AAdd(aFin050,{"E2_FILIAL"  , SE2->E2_FILIAL  	,Nil})
	AAdd(aFin050,{"E2_PREFIXO" , SE2->E2_PREFIXO 	,Nil})
	AAdd(aFin050,{"E2_NUM"     , SE2->E2_NUM	   	,Nil})
	AAdd(aFin050,{"E2_PARCELA" , SE2->E2_PARCELA	,Nil})
	AAdd(aFin050,{"E2_TIPO"    , SE2->E2_TIPO  		,Nil})

	//Invocando rotina automática para exclusao
	MSExecAuto({|x,y,Z| Fina050(x,y,Z)}, aFin050,,5)

	//Quando houver erros, exibí-los em tela
	If lMsErroAuto

		If !IsBlind()
			MostraErro()
		Else
			cErroExec := MostraErro("\temp")
			//Conout(" ============ ERRO =============")
			//Conout(cErroExec)
			cErroExec := ""
		EndIf

		lRet := .F.
	EndIf

Return lRet

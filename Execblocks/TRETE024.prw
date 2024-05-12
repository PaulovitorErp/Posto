#INCLUDE 'PROTHEUS.CH'
#INCLUDE 'FWMVCDEF.CH'
#INCLUDE 'TOPCONN.CH'
#INCLUDE 'RWMAKE.CH'
#INCLUDE 'TBICONN.CH'

/*/{Protheus.doc} TRETE024
Job para geração/estorno de financeiro das compensações incluidas pelo PDV - OFF-LINE
U_TRETE024("C000000EQ")
@author Totvs TBC
@since 02/05/2019
@version 1.0
@return Nil
@type function
/*/
User Function TRETE024(_cNumCmp, _cMsgErro)

	Local cQry := ""
	Local lRet := .F.
	Local cBKPData

	Default _cNumCmp	:= ""
	Default _cMsgErro	:= ""

	//Conout(">> INICIO TRETE024 - GERA/ESTORNA FINANCEIRO COMPENSAÇÃO")

	cBKPData := dDataBase

	DbSelectArea("UC0")
	DbSelectArea("UC1")

	DbSelectArea("SA3")
	SA3->(DbSetOrder(1))

	cQry := " SELECT * "
	cQry += " FROM " + RetSqlName("UC0") + " "
	cQry += " WHERE UC0_FILIAL = '" + xFilial("UC0") + "' "
	cQry += "   AND D_E_L_E_T_ <> '*' "
	cQry += "   AND (UC0_GERFIN = 'N' OR UC0_ESTORN = 'X' "+iif(empty(_cNumCmp),"","OR UC0_GERFIN = 'R' ")+" )"
	if empty(_cNumCmp) //processa as comepensações do PDV
		cQry += "   AND SUBSTRING(UC0_NUM, 1, 1) <> 'C' " //pega todas menos as de ajuste de conferencia
		cQry += " AND UC0_GERFIN <> 'R' " //não processa os incluidos pela retaguarda
	else //processa as compensações da conferência (retaguarda)
		cQry += "   AND UC0_NUM = '"+ _cNumCmp +"' " //pega so aquela compensação
		cQry += " AND (UC0_GERFIN = 'R' OR UC0_ESTORN = 'X')"
	endif
	cQry := ChangeQuery(cQry)

	TcQuery cQry New Alias "T_UC0" // Cria uma nova area com o resultado do query

	While T_UC0->(!Eof())

		UC0->(DbGoTo(T_UC0->R_E_C_N_O_))

		dDataBase := UC0->UC0_DATA

		if T_UC0->UC0_GERFIN $ 'N,R' // se entrar aqui é para gerar financeiro
			GerarFinComp(@_cMsgErro)
		elseif T_UC0->UC0_ESTORN == 'X'
			EstFinComp(@_cMsgErro)
		endif

		T_UC0->(DbSkip())
	enddo

	T_UC0->(DbCloseArea())

	dDataBase := cBKPData

	if empty(_cMsgErro)
		lRet := .T.
	endif

	//Conout(">> FIM TRETE024 - GERA/ESTORNA FINANCEIRO COMPENSAÇÃO")

Return lRet

//-------------------------------------------------------------------
// Faz a geração das parcelas de entrada e saída
//-------------------------------------------------------------------
Static Function GerarFinComp(_cMsgErro)

	Local lFinOK		:= .T.
	Local aFin040 		:= {}
	Local cFinProp
	Local aDadosSEF		:= {}
	Local cPrefixComp 	:= SuperGetMv( "MV_XPFXCOM" , .F. , "CMP",)
	Local cXCNATCC  	:= SuperGetMv( "MV_XCNATCC" , .F. , "CARTAO",)
	Local cXCNATCD  	:= SuperGetMv( "MV_XCNATCD" , .F. , "CARTAO",)
	Local cXCNATCF 		:= SuperGetMv( "MV_XCNATCF" , .F. , "OUTROS",)
	Local cXCNATCH 		:= SuperGetMv( "MV_XCNATCH" , .F. , "CHEQUE",)
	Local cNatDinh		:= SuperGetMv( "MV_XCNATDI"	, .F. , "DINHEIRO",)
	Local cNatVLH  		:= SuperGetMV( "MV_XCNATVL" , .F. , "VALE",)
	Local cChvSE1		:= ""
	Local cCodBar		:= ""
	Local lAux			:= .F.
	Local nValTaxAdm 	:= 0
	Local aAdmValTax
	Local nTamE1Parc	:= TamSX3("E1_PARCELA")[1]

	Local cBanco    	:= ""
	Local cAgencia  	:= ""
	Local cNumCon   	:= ""

	cCodBar := UC0->UC0_FILIAL+UC0->UC0_NUM

	//GERA NCC DO DINHEIRO E FAZ BAIXA NO CAIXA QUE FEZ A VENDA
	if UC0->UC0_VLDINH > 0
		aFin040		:= {}

		//Conout("== COMPENSACAO " + UC0->UC0_NUM + ": INCLUIR NCC DINHEIRO ")

		AADD( aFin040, {"E1_FILIAL"  , xFilial("SE1")  ,Nil})
		AADD( aFin040, {"E1_PREFIXO" , cPrefixComp     ,Nil}) //COMPENSAÇÃO
		AADD( aFin040, {"E1_NUM"     , UC0->UC0_NUM	   ,Nil})
		AADD( aFin040, {"E1_PARCELA" , ""			   ,Nil})
		AADD( aFin040, {"E1_TIPO"    , "NCC"		   ,Nil}) //NCC pois é um crédito que o cliente vai sacar
		AADD( aFin040, {"E1_CLIENTE" , UC0->UC0_CLIENT ,Nil})
		AADD( aFin040, {"E1_LOJA"    , UC0->UC0_LOJA   ,Nil})
		If SE1->(FieldPos("E1_DTLANC")) > 0
			AADD( aFin040, {"E1_DTLANC"	 , UC0->UC0_DATA   ,Nil})
		EndIf
		AADD( aFin040, {"E1_EMISSAO" , UC0->UC0_DATA   ,Nil})
		AADD( aFin040, {"E1_VENCTO"  , UC0->UC0_DATA   ,Nil})
		AADD( aFin040, {"E1_VENCREA" , DataValida(UC0->UC0_DATA),Nil})
		AADD( aFin040, {"E1_VALOR"   , UC0->UC0_VLDINH ,Nil})
		AAdd( aFin040, {"E1_VEND1"   	 , UC0->UC0_VEND   ,Nil})
		AADD( aFin040, {"E1_NATUREZ" , cNatDinh        ,Nil})
		If SE1->(FieldPos("E1_XPLACA")) > 0
			AADD( aFin040, {"E1_XPLACA"	 , UC0->UC0_PLACA  ,Nil})
		endif
		If SE1->(FieldPos("E1_XPDV")) > 0
			AADD( aFin040, {"E1_XPDV"	 , UC0->UC0_PDV	   ,Nil})
		endif
		AADD( aFin040, {"E1_XCODBAR" , cCodBar		   ,Nil})
		AADD( aFin040, {"E1_ORIGEM"  , "TRETE024"      ,Nil})

		cBanco    := UC0->UC0_OPERAD
		cAgencia  := Posicione("SA6",1,xFilial("SA6")+UC0->UC0_OPERAD,"A6_AGENCIA")
		cNumCon   := Posicione("SA6",1,xFilial("SA6")+UC0->UC0_OPERAD,"A6_NUMCON")

		//Verifico a existencia do titulo de dinheiro
		cChvSE1 := xFilial("SE1")+PadR(cPrefixComp,TamSx3("E1_PREFIXO")[1])+UC0->UC0_NUM+Space(nTamE1Parc)+"NCC"
		if Empty(Posicione("SE1", 1, cChvSE1 , "E1_NUM"))
			if IncSE1(aFin040, {}, cChvSE1)	//se fez inclusão do NCC
				//Conout("== COMPENSACAO " + UC0->UC0_NUM + ": NCC DINHEIRO INCLUIDO COM SUCESSO ")
				if !empty(cAgencia) .AND. BaixaSE1(cBanco, cAgencia, cNumCon, cChvSE1)
					RecLock("SE5",.F.)
					SE5->E5_XPDV 	:= UC0->UC0_PDV
					SE5->E5_XESTAC 	:= UC0->UC0_ESTACA
					SE5->E5_NUMMOV  := UC0->UC0_NUMMOV
					SE5->E5_XHORA 	:= UC0->UC0_HORA
					SE5->(MsUnLock())
					//Conout("== COMPENSACAO " + UC0->UC0_NUM + ": NCC DINHEIRO BAIXADO COM SUCESSO ")
				else
					lFinOK := .F.
					_cMsgErro := "Falha ao baixar titulo de saída em dinheiro."
				endif
			else
				lFinOK := .F.
				_cMsgErro := "Falha ao gerar titulo de saída em dinheiro."
			endif
		else
			//Conout("== COMPENSACAO " + UC0->UC0_NUM + ": NCC DINHEIRO JÁ EXISTE ")
			if SE1->E1_SALDO > 0 //se tem saldo ainda
				if !empty(cAgencia) .AND. BaixaSE1(cBanco, cAgencia, cNumCon, cChvSE1)
					RecLock("SE5",.F.)
					SE5->E5_XPDV 	:= UC0->UC0_PDV
					SE5->E5_XESTAC 	:= UC0->UC0_ESTACA
					SE5->E5_NUMMOV  := UC0->UC0_NUMMOV
					SE5->E5_XHORA 	:= UC0->UC0_HORA
					SE5->(MsUnLock())
					//Conout("== COMPENSACAO " + UC0->UC0_NUM + ": NCC DINHEIRO BAIXADO COM SUCESSO ")
				else
					lFinOK := .F.
					_cMsgErro := "Falha ao baixar titulo de saída em dinheiro."
				endif
			endif
		endif
	endif

	//GERAR NCC do VALE HAVER
	if UC0->UC0_VLVALE > 0
		//Conout("== COMPENSACAO "+UC0->UC0_NUM+": INCLUIR NCC VALE HAVER " )
		//se nao encontrar titulo igual
		if Empty(Posicione("SE1",1, xFilial("SE1")+PadR(UC0->UC0_ESTACA,TamSx3("E1_PREFIXO")[1])+UC0->UC0_NUM+PadR("VLH",nTamE1Parc)+"NCC" , "E1_NUM"))
			U_IncVlHav(UC0->UC0_VLVALE, UC0->UC0_NUM, UC0->UC0_CLIENT, UC0->UC0_LOJA, UC0->UC0_DATA, UC0->UC0_ESTACA, UC0->UC0_PDV, cNatVLH )
			//Conout("== COMPENSACAO "+UC0->UC0_NUM+": NCC VALE HAVER INCLUIDO COM SUCESSO! " )
		else
			//Conout("== COMPENSACAO "+UC0->UC0_NUM+": NCC VALE HAVER JÁ EXISTE! " )
		endif
	endif

	//INCLUINDO PARCELAS QUE ENTRARAM
	DbSelectArea("UC1")
	UC1->(DbSetOrder(1))
	UC1->(DbSeek(xFilial("UC1")+UC0->UC0_NUM))
	While UC1->(!Eof()) .AND. UC1->UC1_FILIAL+UC1->UC1_NUM == xFilial("UC1")+UC0->UC0_NUM

		//Conout("== COMPENSACAO "+UC0->UC0_NUM+": GERANDO PARCELA DO TIPO " + UC1->UC1_FORMA)

		lAux := .F.
		//verifico se ja existe a parcela
		DbSelectArea("SE1")
		SE1->(DbSetOrder(1))
		SE1->(DbSeek(xFilial("SE1")+PadR(cPrefixComp,TamSx3("E1_PREFIXO")[1])+UC1->UC1_NUM))
		while SE1->(!Eof()) .AND. SE1->(E1_FILIAL+E1_PREFIXO+E1_NUM) == xFilial("SE1")+PadR(cPrefixComp,TamSx3("E1_PREFIXO")[1])+UC1->UC1_NUM
			if SE1->E1_XCODBAR+SE1->E1_TIPO == UC1->UC1_FILIAL+UC1->UC1_NUM+Alltrim(UC1->UC1_SEQ)+UC1->UC1_FORMA
				lAux := .T.
				EXIT
			endif
			SE1->(DbSkip())
		Enddo

		//chama inclusão, somente se nao encontrar titulo da parcela
		if !lAux

			cParcela := StrZero(Val(UC1->UC1_SEQ), nTamE1Parc)
			While !Empty(Posicione("SE1",1, xFilial("SE1")+PadR(cPrefixComp,TamSx3("E1_PREFIXO")[1])+UC0->UC0_NUM+cParcela+UC1->UC1_FORMA, "E1_NUM"))
				cParcela := Soma1(cParcela)
			Enddo

			cChvSE1 := xFilial("SE1")+PadR(cPrefixComp,TamSx3("E1_PREFIXO")[1])+UC0->UC0_NUM+cParcela+UC1->UC1_FORMA

			aFin040		:= {}
			aDadosSEF	:= {}

			AADD( aFin040, {"E1_FILIAL"  , xFilial("SE1")  ,Nil})
			AADD( aFin040, {"E1_PREFIXO" , cPrefixComp     ,Nil}) //COMPENSAÇÃO
			AADD( aFin040, {"E1_NUM"     , UC1->UC1_NUM	   ,Nil})
			AADD( aFin040, {"E1_PARCELA" , cParcela		   ,Nil})
			AADD( aFin040, {"E1_TIPO"    , UC1->UC1_FORMA  ,Nil})
			If SE1->(FieldPos("E1_DTLANC")) > 0
				AADD( aFin040, {"E1_DTLANC"	 , UC0->UC0_DATA   ,Nil})
			EndIf
			AADD( aFin040, {"E1_EMISSAO" , UC0->UC0_DATA   ,Nil})
			if SE1->(FieldPos("E1_XCOND")) > 0 .AND. UC1->(FieldPos("UC1_CONDPG"))
				AADD( aFin040, {"E1_XCOND"   , UC1->UC1_CONDPG  ,Nil})
			endif

			if alltrim(UC1->UC1_FORMA) == "CH" //se cheque

				AADD( aFin040, {"E1_CLIENTE" , UC0->UC0_CLIENT ,Nil})
				AADD( aFin040, {"E1_LOJA"    , UC0->UC0_LOJA   ,Nil})
				AADD( aFin040, {"E1_VALOR"	 , UC1->UC1_VALOR  ,Nil})
				AADD( aFin040, {"E1_VENCTO"  , UC1->UC1_VENCTO ,Nil})
				AADD( aFin040, {"E1_VENCREA" , DataValida(UC1->UC1_VENCTO),Nil})
				if SE1->(FieldPos("E1_XDTFATU")) > 0 .AND. UC1->(FieldPos("UC1_CONDPG"))
					AADD( aFin040, {"E1_XDTFATU" , U_TRETE014(UC1->UC1_CONDPG, UC1->UC1_VENCTO), Nil } )
				endif

				AADD( aFin040, {"E1_NUMCART" , UC1->UC1_NUMCH  ,Nil})
				AADD( aFin040, {"E1_BCOCHQ"  , UC1->UC1_BANCO  ,Nil})
				AADD( aFin040, {"E1_AGECHQ"  , UC1->UC1_AGENCI ,Nil})
				AADD( aFin040, {"E1_CTACHQ"  , UC1->UC1_CONTA  ,Nil})

				SA1->(DbSetOrder(3)) //A1_FILIAL+A1_CGC
				SA1->(DbSeek(xFilial("SA1")+UC1->UC1_CGC))
				AADD( aFin040, {"E1_EMITCHQ" , SA1->A1_NOME ,Nil})
				if SE1->(FieldPos("E1_XCODEMI")) > 0
					AADD( aFin040, {"E1_XCGCEMI" , UC1->UC1_CGC ,Nil})
					AADD( aFin040, {"E1_XCODEMI" , SA1->A1_COD  ,Nil})
					AADD( aFin040, {"E1_XLOJEMI" , SA1->A1_LOJA ,Nil})
				endif
				AADD( aFin040, {"E1_NATUREZ" , PadR(cXCNATCH, TamSX3("E1_NATUREZ")[1]) ,Nil})

				//MONTANDO SEF DO CHEQUE
				AADD( aDadosSEF, {"EF_FILIAL"   , xFilial("SEF")   ,Nil})
				AADD( aDadosSEF, {"EF_FILORIG"   , cFilAnt   		,Nil})
				AADD( aDadosSEF, {"EF_BANCO"    , UC1->UC1_BANCO   ,Nil})
				AADD( aDadosSEF, {"EF_AGENCIA"  , UC1->UC1_AGENCI  ,Nil})
				AADD( aDadosSEF, {"EF_CONTA"    , UC1->UC1_CONTA   ,Nil})
				AADD( aDadosSEF, {"EF_NUM"    	, UC1->UC1_NUMCH   ,Nil})
				AADD( aDadosSEF, {"EF_VALOR"   	, UC1->UC1_VALOR   ,Nil})
				AADD( aDadosSEF, {"EF_VALORBX" 	, UC1->UC1_VALOR   ,Nil})
				AADD( aDadosSEF, {"EF_DATA"   	, UC0->UC0_DATA    ,Nil})
				AADD( aDadosSEF, {"EF_VENCTO"   , UC1->UC1_VENCTO  ,Nil})
				AADD( aDadosSEF, {"EF_PREFIXO"  , cPrefixComp	   ,Nil})
				AADD( aDadosSEF, {"EF_TITULO"   , UC1->UC1_NUM     ,Nil})
				AADD( aDadosSEF, {"EF_PARCELA"  , cParcela		   ,Nil})
				AADD( aDadosSEF, {"EF_TIPO"   	, UC1->UC1_FORMA   ,Nil})
				AADD( aDadosSEF, {"EF_BENEF"   	, SM0->M0_NOMECOM  ,Nil})
				AADD( aDadosSEF, {"EF_CLIENTE"  , UC0->UC0_CLIENT  ,Nil})
				AADD( aDadosSEF, {"EF_LOJACLI"  , UC0->UC0_LOJA    ,Nil})
				AADD( aDadosSEF, {"EF_CPFCNPJ"  , UC1->UC1_CGC     ,Nil})
				AADD( aDadosSEF, {"EF_EMITENT"  , SA1->A1_NOME	   ,Nil})
				AADD( aDadosSEF, {"EF_CART"   	, "R"			   ,Nil})
				AADD( aDadosSEF, {"EF_ORIGEM"   , "FINA040"	   	   ,Nil}) //alterado para funcionar corretamente a rotina de baixa de cheques
				AADD( aDadosSEF, {"EF_RG"   	, UC1->UC1_RG	   ,Nil})
				AADD( aDadosSEF, {"EF_TERCEIR"  , .T.			   ,Nil})
				AADD( aDadosSEF, {"EF_TEL"   	, UC1->UC1_TEL1    ,Nil})
				AADD( aDadosSEF, {"EF_COMP"   	, UC1->UC1_COMPEN  ,Nil})
				if SEF->(FieldPos("EF_XCODEMI")) > 0 .AND. SEF->(FieldPos("EF_XLOJEMI")) > 0
					AADD( aDadosSEF, {"EF_XCODEMI"  , SA1->A1_COD   ,Nil})
					AADD( aDadosSEF, {"EF_XLOJEMI"  , SA1->A1_LOJA  ,Nil})
				endif
				if SEF->(FieldPos("EF_XCMC7")) > 0
					AADD( aDadosSEF, {"EF_XCMC7"   	, UC1->UC1_CMC7    ,Nil})
				endif
				if SEF->(FieldPos("EF_XPDV")) > 0
					AADD( aDadosSEF, {"EF_XPDV"   	, UC0->UC0_PDV    ,Nil})
				endif

			elseif alltrim(UC1->UC1_FORMA) $ "CCP/CDP" //se Cartao

				cFinProp := Posicione("SAE",1,xFilial("SAE")+UC1->UC1_ADMFIN, "AE_FINPRO" )
				//TODO tratat busca do cliente da SAE para incluir titulo
				if cFinProp == "S"
					AADD( aFin040, {"E1_CLIENTE" , UC0->UC0_CLIENT ,Nil})
					AADD( aFin040, {"E1_LOJA"    , UC0->UC0_LOJA   ,Nil})
				else
					AADD( aFin040, {"E1_CLIENTE" , PadR(SAE->AE_COD, TamSX3("A1_COD")[1]) ,Nil})
					AADD( aFin040, {"E1_LOJA"    , '01'	,Nil})
				endif

				//BUSCANDO TAXA ADM FINANCEIRA PARA CARTAO
				nValTaxAdm := 0
				If ExistFunc("LJ7_TXADM") .AND. MEN->(ColumnPos("MEN_TAXADM")) > 0
					//LJ7_TxAdm(cCodAdmin, nParc, nValCC)
					//UC1_COMPEN tem o numero de parcelas
					aAdmValTax := LJ7_TxAdm( SAE->AE_COD, iif(empty(UC1->UC1_COMPEN),1,Val(UC1->UC1_COMPEN)), UC1->UC1_VALOR )
					If Len(aAdmValTax) > 0
						nValTaxAdm := aAdmValTax[3]
					EndIf
				EndIf
				If nValTaxAdm == 0
					nValTaxAdm := SAE->AE_TAXA
				EndIf

				AADD( aFin040, {"E1_VALOR"   , (UC1->UC1_VALOR * (100 - nValTaxAdm) / 100)  ,Nil})
				AADD( aFin040, {"E1_VLRREAL" , UC1->UC1_VALOR  ,Nil})
				AADD( aFin040, {"E1_VENCTO"  , (UC1->UC1_VENCTO + SAE->AE_DIAS) ,Nil})
				AADD( aFin040, {"E1_VENCREA" , DataValida((UC1->UC1_VENCTO + SAE->AE_DIAS)),Nil})
				if SE1->(FieldPos("E1_XDTFATU")) > 0 .AND. UC1->(FieldPos("UC1_CONDPG"))
					AADD( aFin040, {"E1_XDTFATU" , U_TRETE014(UC1->UC1_CONDPG, (UC1->UC1_VENCTO + SAE->AE_DIAS)) ,Nil } )
				endif

				AADD( aFin040, {"E1_NSUTEF"  , UC1->UC1_NSUDOC ,Nil})
				AADD( aFin040, {"E1_CARTAUT" , UC1->UC1_CODAUT ,Nil})
				AADD( aFin040, {"E1_NATUREZ" , iif(UC1->UC1_FORMA=="CCP",cXCNATCC,cXCNATCD)     ,Nil})

			elseif alltrim(UC1->UC1_FORMA) == "CF" //se Carta frete

				SA1->(DbSetOrder(3)) //A1_FILIAL+A1_CGC
				if SA1->(DbSeek(xFilial("SA1")+UC1->UC1_CGC))
					AADD( aFin040, {"E1_CLIENTE" , SA1->A1_COD ,Nil})
					AADD( aFin040, {"E1_LOJA"    , SA1->A1_LOJA ,Nil})
				endif

				AADD( aFin040, {"E1_VALOR"   , UC1->UC1_VALOR  ,Nil})
				AADD( aFin040, {"E1_VLRREAL" , UC1->UC1_VALOR  ,Nil})
				AADD( aFin040, {"E1_VENCTO"  , UC1->UC1_VENCTO ,Nil})
				AADD( aFin040, {"E1_VENCREA" , DataValida(UC1->UC1_VENCTO),Nil})
				if SE1->(FieldPos("E1_XDTFATU")) > 0 .AND. UC1->(FieldPos("UC1_CONDPG"))
					AADD( aFin040, {"E1_XDTFATU" , U_TRETE014(UC1->UC1_CONDPG, UC1->UC1_VENCTO) ,Nil } )
				endif
				AADD( aFin040, {"E1_NUMCART" , PadR(UC1->UC1_CFRETE,TamSx3("E1_NATUREZ")[1]) ,Nil})
				AADD( aFin040, {"E1_NATUREZ" , PadR(cXCNATCF,TamSx3("E1_NATUREZ")[1]) ,Nil})
				AADD( aFin040, {"E1_HIST"    , PadR(UC1->UC1_OBS,TamSx3("E1_HIST")[1]) ,Nil})

			endif
			AAdd( aFin040, {"E1_VEND1"   	 , UC0->UC0_VEND   ,Nil})

			If SE1->(FieldPos("E1_XPLACA")) > 0
				AADD( aFin040, {"E1_XPLACA"	 , UC0->UC0_PLACA  ,Nil})
			endif
			If SE1->(FieldPos("E1_XPDV")) > 0
				AADD( aFin040, {"E1_XPDV"	 , UC0->UC0_PDV	   ,Nil})
			endif
			AADD( aFin040, {"E1_XCODBAR" , cCodBar+UC1->UC1_SEQ,Nil})//UC0_FILIAL+UC0_NUM+UC1_SEQ
			AADD( aFin040, {"E1_ORIGEM"  , "TRETE024"      ,Nil})

			if IncSE1(aFin040, aDadosSEF, cChvSE1)
				//Conout("== COMPENSACAO "+UC0->UC0_NUM+": GERANDO PARCELA DO TIPO " + UC1->UC1_FORMA + " INCLUIDO COM SUCESSO!")
			else
				lFinOK := .F.
				_cMsgErro := "Falha ao gerar titulo(s) de entrada da compensação."
			endif
		else
			//Conout("== COMPENSACAO "+UC0->UC0_NUM+": GERANDO PARCELA DO TIPO " + UC1->UC1_FORMA + " JÁ EXISTE!")
		endif

		UC1->(DbSkip())
	Enddo

	if lFinOK //se tudo ok, verifico cheques troco
		//altera status do financeiro da copensação
		Reclock("UC0", .F.)
		UC0->UC0_GERFIN := "S"
		UC0->(MsUnlock())
		//Conout("== COMPENSACAO "+UC0->UC0_NUM+": FINANCEIRO GERADO COM SUCESSO!")
	else
		//altera status do financeiro da compensação para ERRO
		Reclock("UC0", .F.)
		UC0->UC0_GERFIN := "E"
		UC0->(MsUnlock())
	endif

	if !empty(_cMsgErro)
		//Conout("== COMPENSACAO "+UC0->UC0_NUM+" - ERRO: " + _cMsgErro)
	endif

	DbCommitAll()

Return

//-------------------------------------------------------------------
// INCLUI UM SE1
//-------------------------------------------------------------------
Static Function IncSE1(aFin040, aDadosSEF, cChavSE1)

	Local nX, nY
	Local lRet := .F.

	//Assinatura de variáveis que controlarão a inserção automática da RA			;
	Private lMsErroAuto := .F.
	Private lMsHelpAuto := .T.

	//Invocando rotina automática para criação da RA								;
	MSExecAuto({|x,y| Fina040(x,y)}, aFin040, 3)

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
	endif

	//verifico se o titulo foi incluido mesmo (as vezes mesmo lMsErroAuto sendo true, o titulo foi incluido)
	SE1->(DbSetOrder(1))
	if SE1->(DbSeek(cChavSE1))
		lRet := .T.
	endif

	if lRet //se foi gerado o titulo corretamente

		//Gravando SEF do titulo de cheque
		If alltrim(SE1->E1_TIPO) == "CH" .AND. Len(aDadosSEF)>0
			DbSelectArea("SEF")
			SEF->(DbSetOrder(3)) //EF_FILIAL+EF_PREFIXO+EF_TITULO+EF_PARCELA+EF_TIPO+EF_NUM+EF_SEQUENC
			If !SEF->(DbSeek(xFilial("SEF")+ SE1->E1_PREFIXO + SE1->E1_NUM + SE1->E1_PARCELA + SE1->E1_TIPO + SE1->E1_NUMCART ))
				Reclock("SEF", .T.) //inclui
				For nX := 1 to len(aDadosSEF)
					SEF->&(aDadosSEF[nX][1]) := aDadosSEF[nX][2]
				Next nX
				SEF->(MsUnlock())

				//ponto de entrada para manipular campos da SEF ou SE1 referente a cheques
				//Já posicionado em ambas tabelas SE1 e SEF
				If ExistBlock("TPINCSEF")
					ExecBlock("TPINCSEF",.F.,.F.,{"2"}) //Parametros; 1=Venda (gravabatch); 2=Compensação; 3=Conferencia Caixa
				EndIf
			EndIf
		EndIf

	EndIf

Return lRet

/*
-----------------------------------------------------------------------------------
BaixaSE1 -> função para baixar o SE1 posicionado
-----------------------------------------------------------------------------------
*/
Static Function BaixaSE1(cBanco, cAgencia, cNumCon, cChavSE1)
	Local lRet 		:= .F.
	Local _aBaixa 	:= {}
	Local dDtFin	:= GetMV("MV_DATAFIN")
	Local cBkpFunNam := FunName()

	Private lMsErroAuto := .F.
	Private lMsHelpAuto := .F.

	iif(ddatabase<dDtFin,PutMvPar("MV_DATAFIN",ddatabase),)

	BeginTran()

	_aBaixa := {;
	{"E1_FILIAL"    ,SE1->E1_FILIAL 		,Nil},;
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
	{"AUTDTBAIXA"   ,dDataBase				,Nil},;
	{"AUTDTCREDITO" ,dDataBase				,Nil},;
	{"AUTHIST"      ,"COMPENSACAO PDV"      ,Nil},;
	{"AUTJUROS"     ,0                      ,Nil,.T.},;
	{"AUTVALREC"    ,SE1->E1_SALDO			,Nil}}

	SetFunName("FINA070") //ADD Danilo, para ficar correto campo E5_ORIGEM (relatorios e rotinas conciliacao)					
	MSExecAuto({|x,y| Fina070(x,y)}, _aBaixa, 3) //Baixa conta a receber
	SetFunName(cBkpFunNam)

	If lMsErroAuto
		DisarmTransaction()
		if !IsBlind()
			MostraErro()
		else
			cErroExec := MostraErro("\temp")
			//Conout(" ============ ERRO =============")
			//Conout(cErroExec)
			cErroExec := ""
		endif
	EndIf

	EndTran()

	//verifico se o titulo foi baixado mesmo (as vezes mesmo lMsErroAuto sendo true, o titulo foi baixado)
	SE1->(DbSetOrder(1))
	if SE1->(DbSeek(cChavSE1)) .AND. SE1->E1_SALDO == 0
		lRet := .T.
	endif

	iif(ddatabase<dDtFin,PutMvPar("MV_DATAFIN",dDtFin),)

Return lRet

//-------------------------------------------------------------------
// Faz a geração das parcelas de entrada e saída
//-------------------------------------------------------------------
Static Function EstFinComp(_cMsgErro)

	Local cChavCH	:= ""
	Local cPrefixComp 	:= SuperGetMv( "MV_XPFXCOM" , .F. , "CMP",)
	Local lOK := .T.
	Local nTamE1Parc	:= TamSX3("E1_PARCELA")[1]

	BeginTran()

	DbSelectArea("SE1")
	SE1->(DbSetOrder(1))

	//EXCLUIR NCC do VALE HAVER
	if UC0->UC0_VLVALE > 0
		//Conout("== COMPENSACAO "+UC0->UC0_NUM+": EXCLUINDO NCC VALE HAVER " )

		if SE1->(DbSeek(xFilial("SE1")+UC0->UC0_ESTACA+UC0->UC0_NUM+SubStr("VLH",1,nTamE1Parc)+"NCC" ))
			//chama Exclusao do titulo
			if !ExcSE1(0,"")
				_cMsgErro := "Não foi possível excluir Vale Haver. Verifique se o mesmo está baixado."
				lOK := .F.
				DisarmTransaction()
			endif
		else
			_cMsgErro := "Vale Haver não encontrado: " + xFilial("SE1")+UC0->UC0_ESTACA+UC0->UC0_NUM+SubStr("VLH",1,nTamE1Parc)+"NCC"
			//Conout("Não posicionou no titulo: " + xFilial("SE1")+UC0->UC0_ESTACA+UC0->UC0_NUM+SubStr("VLH",1,nTamE1Parc)+"NCC" )
		endif

	endif

	//EXCLUIR BAIXA NO CAIXA QUE FEZ A COMPENSAÇÃO E EXCLUIR NCC DO DINHEIRO
	if lOK .AND. UC0->UC0_VLDINH > 0
		//Conout("== COMPENSACAO " + UC0->UC0_NUM + ": EXCLUINDO NCC DINHEIRO ")
		if SE1->(DbSeek(xFilial("SE1")+PadR(cPrefixComp,TamSx3("E1_PREFIXO")[1])+UC0->UC0_NUM+Space(nTamE1Parc)+"NCC" ))
			if !empty(SE1->E1_BAIXA)
				if CancBxSE1()
					//chama Exclusao do titulo
					if !ExcSE1(0,"")
						_cMsgErro := "Não foi possível excluir titulo de Dinheiro."
						lOK := .F.
						DisarmTransaction()
					endif
				else
					_cMsgErro := "Não foi possível excluir movimento de baixa do Dinheiro."
					lOK := .F.
					DisarmTransaction()
				endif
			endif
		else
			//Conout("Não posicionou no titulo: " + xFilial("SE1")+PadR(cPrefixComp,TamSx3("E1_PREFIXO")[1])+UC0->UC0_NUM+Space(nTamE1Parc)+"NCC" )
		endif
	endif

	if lOK
		//EXCLUIR PARCELAS QUE ENTRARAM
		DbSelectArea("UC1")
		UC1->(DbSetOrder(1))
		UC1->(DbSeek(xFilial("UC1")+UC0->UC0_NUM))
		While UC1->(!Eof()) .AND. UC1->UC1_FILIAL+UC1->UC1_NUM == xFilial("UC1")+UC0->UC0_NUM

			//Conout("== COMPENSACAO "+UC0->UC0_NUM+": EXCLUINDO PARCELA DO TIPO " + UC1->UC1_FORMA)

			SE1->(DbSetOrder(1))
			SE1->(DbSeek(xFilial("SE1")+PadR(cPrefixComp,TamSx3("E1_PREFIXO")[1])+UC1->UC1_NUM ))
			While SE1->(!Eof())	.AND. SE1->(E1_FILIAL+E1_PREFIXO+E1_NUM) == xFilial("SE1")+PadR(cPrefixComp,TamSx3("E1_PREFIXO")[1])+UC1->UC1_NUM

				if SE1->E1_XCODBAR+SE1->E1_TIPO == UC1->UC1_FILIAL+UC1->UC1_NUM+Alltrim(UC1->UC1_SEQ)+UC1->UC1_FORMA
					cChavCH := ""
					//se cheque, pega chave
					If Alltrim(SE1->E1_TIPO) == "CH"
						//SEF INDICE 3 - EF_FILIAL+EF_PREFIXO+EF_TITULO+EF_PARCELA+EF_TIPO+EF_NUM+EF_SEQUENC
						cChavCH := xFilial("SEF") + SE1->E1_PREFIXO + SE1->E1_NUM + SE1->E1_PARCELA + SE1->E1_TIPO + SE1->E1_NUMCART
					EndIf

					//chama Exclusao do titulo
					if !ExcSE1(cChavCH)
						_cMsgErro := "Não foi possível excluir titulo do tipo "+Alltrim(SE1->E1_TIPO)+". Verifique se o mesmo está baixado. "
						lOK := .F.
						DisarmTransaction()
					endif
				endif

				SE1->(DbSkip())
			Enddo

			UC1->(DbSkip())
		Enddo
	endif

	//SOLICITA EXCLUSAO DOS CHEQUES TROCO
	if lOK .AND. UC0->UC0_VLCHTR > 0
		DbSelectArea("UF2")
		UF2->(DbSetOrder(3)) //UF2_FILIAL+UF2_DOC+UF2_SERIE+UF2_PDV
		If UF2->(DbSeek(xFilial("UF2")+UC0->UC0_NUM+PadR(cPrefixComp,TamSx3("E1_PREFIXO")[1])))
			While UF2->(!Eof()) .AND. UF2->UF2_FILIAL+UF2->UF2_DOC+UF2->UF2_SERIE == xFilial("UF2")+UC0->UC0_NUM+PadR(cPrefixComp,TamSx3("E1_PREFIXO")[1])
				Reclock("UF2", .F.)
					UF2->UF2_XGERAF := "E" //estorno com replica
				UF2->(MsUnlock())
				//Conout("== COMPENSACAO " + UC0->UC0_NUM + ": SOLICITADO ESTORNO CHEQUE TROCO "+UF2->UF2_BANCO+UF2->UF2_AGENCI+UF2->UF2_CONTA+UF2->UF2_NUM)
				UF2->(DbSkip())
			EndDo
		EndIf
	endif

	if lOK
		//altera status do estorno da compensação
		Reclock("UC0", .F.) //altera status
		UC0->UC0_ESTORN := "S"
		UC0->(MsUnlock())

		DbCommitAll()
	endif

	EndTran()

Return

//-------------------------------------------------------------------
// EXCLUI UM SE1
//-------------------------------------------------------------------
Static Function ExcSE1(cChaveCH)

	Local nX, nY
	Local lRet := .T.
	Local aFin040 := {}
	Local cChavE1 := SE1->E1_FILIAL+SE1->E1_PREFIXO+SE1->E1_NUM+SE1->E1_PARCELA+SE1->E1_TIPO

	//Assinatura de variáveis que controlarão a inserção automática da RA			;
	Private lMsErroAuto := .F.
	Private lMsHelpAuto := .T.

	AADD( aFin040, {"E1_FILIAL"  , SE1->E1_FILIAL  	,Nil})
	AADD( aFin040, {"E1_PREFIXO" , SE1->E1_PREFIXO 	,Nil})
	AADD( aFin040, {"E1_NUM"     , SE1->E1_NUM	   	,Nil})
	AADD( aFin040, {"E1_PARCELA" , SE1->E1_PARCELA	,Nil})
	AADD( aFin040, {"E1_TIPO"    , SE1->E1_TIPO  	,Nil})

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
	EndIf

	SE1->(DbSetOrder(1))
	if SE1->(DbSeek(cChavE1)) //se encontrar o titulo.. é pq nao conseguiu excluir
		lRet := .F.
	else

		//se nao deletou o cheque no padrão, força exclusao
		if !empty(cChaveCH)
			DbSelectArea("SEF")
			SEF->(DbSetOrder(3)) //EF_FILIAL+EF_PREFIXO+EF_TITULO+EF_PARCELA+EF_TIPO+EF_NUM+EF_SEQUENC
			SEF->(DbSeek(cChaveCH))
			While SEF->(!Eof()) .and. SEF->(EF_FILIAL + EF_PREFIXO + EF_TITULO + EF_PARCELA + EF_TIPO + EF_NUM) == cChaveCH
				RecLock("SEF",.F.)
				SEF->(DbDelete())
				SEF->(MsUnLock())
				SEF->(DbSkip())
			EndDo
		endif

	endif

Return lRet

/*
-----------------------------------------------------------------------------------
CancBxSE1 -> função para cancelar baixa do SE1 posicionado
-----------------------------------------------------------------------------------
*/
Static Function CancBxSE1()

	Local lRet := .T.
	Local aFin070 := {}
	Local cChvE1 := SE1->E1_FILIAL+SE1->E1_PREFIXO+SE1->E1_NUM+SE1->E1_PARCELA+SE1->E1_TIPO

	// Cancela a Baixa

	AADD( aFin070, {"E1_FILIAL"  , SE1->E1_FILIAL	, Nil})
	AADD( aFin070, {"E1_PREFIXO" , SE1->E1_PREFIXO	, Nil})
	AADD( aFin070, {"E1_NUM"     , SE1->E1_NUM 		, Nil})
	AADD( aFin070, {"E1_PARCELA" , SE1->E1_PARCELA	, Nil})
	AADD( aFin070, {"E1_TIPO"    , SE1->E1_TIPO		, Nil})

	//Assinatura de variáveis que controlarão a exclusão automática do título;
	lMsErroAuto := .F.
	lMsHelpAuto := .F.

	//rotina automática para exclusão da baixa do título;
	MSExecAuto({|x,y| Fina070(x,y)}, aFin070, 6)

	//Quando houver erros, exibí-los em tela;
	If lMsErroAuto
		//DisarmTransaction()
		if !IsBlind()
			MostraErro()
		else
			cErroExec := MostraErro("\temp")
			//Conout(" ============ ERRO =============")
			//Conout(cErroExec)
			cErroExec := ""
		endif
	EndIf

	SE1->(DbSetOrder(1))
	if SE1->(DbSeek(cChvE1))
		if SE1->E1_SALDO == 0 //verifica se realmente foi cancelada a baixa
			lRet := .F.
		endif
	endif

Return lRet

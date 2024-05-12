#INCLUDE "TOTVS.CH"
#INCLUDE "stpos.ch"
#INCLUDE "poscss.ch"
#INCLUDE "topconn.ch"
#INCLUDE "FWMVCDEF.CH" 

//########  Variaveis das Telas  #############

//Dinheiro
Static oPnlDIN		:= Nil  //Painel pagamento dinheiro
Static oDINVlrRec	:= Nil 	//Objeto de Get Valor Recebido
Static nDINVlrRec 	:= 0 	//Variavel do Get Valor Recebido
Static oDINVlrSal	:= Nil 	//Objeto do Get Valor do Saldo
Static nDINVlrSal	:= 0 	//Variavel do Get Valor do Saldo
Static oDINBtnOk	:= Nil  //Botão confirma tela dinheiro
Static oDINBtnCan	:= Nil  //Botão cancela tela dinheiro

//Cartao CC/CD
Static oPnlCC
Static oCCVlrRec	:= Nil 	//Objeto de Get Valor Recebido
Static nCCVlrRec 	:= 0 	//Variavel do Get Valor Recebido
Static oCCVlrSal	:= Nil 	//Objeto do Get Valor do Saldo
Static nCCVlrSal	:= 0 	//Variavel do Get Valor do Saldo
Static oCCBtnOk		:= Nil  //Botão confirma tela cartao
Static oCCBtnCan	:= Nil  //Botão cancela tela cartao
Static oCCListGdNeg	:= Nil //Objeto TListBox das negociações
Static aMyRede		:= {}
Static aMyBandei	:= {}
Static aMyAdmFin 	:= {}
Static cCardForma	:= ""
Static oRedeAut		:= Nil
Static cRedeAut  	:= Space(TamSx3("MDE_CODIGO")[1])
Static oBandeira	:= Nil
Static cBandeira 	:= Space(TamSx3("MDE_CODIGO")[1])
Static oCCAdmFin	:= Nil
Static cCCAdmFin   	:= Space(TamSx3("AE_COD")[1])
Static oNsuDoc		:= Nil
Static cNsuDoc		:= Space(TAMSx3("L4_NSUTEF")[1])
Static oAutoriz		:= Nil
Static cAutoriz		:= Space(TAMSx3("L4_AUTORIZ")[1])
Static oCCDataTran	:= Nil
Static dCCDataTran  := CtoD("")
Static oCCParcelas	:= Nil
Static nCCParcelas 	:= 1
Static lMyContTef 	:= .F. // Se ira utilizar a contingencia de passar no POS

//Carta Frete
Static oPnlCF		:= Nil  
Static oCFVlrRec	:= Nil 	//Objeto de Get Valor Recebido
Static nCFVlrRec 	:= 0 	//Variavel do Get Valor Recebido
Static oCFVlrSal	:= Nil 	//Objeto do Get Valor do Saldo
Static nCFVlrSal	:= 0 	//Variavel do Get Valor do Saldo
Static oCFBtnOk		:= Nil  //Botão confirma tela carta frete
Static oCFBtnCan	:= Nil  //Botão cancela tela carta frete
Static oCFListGdNeg	:= Nil //Objeto TListBox das negociações
Static oCodCF		:= Nil
Static cCodCF		:= Space(TAMSx3("A1_COD")[1])
Static oLojCF		:= Nil
Static cLojCF		:= Space(TAMSx3("A1_LOJA")[1])
Static oCFrete		:= Nil
Static cCFrete		:= Space(TAMSx3("L4_NUMCART")[1])
Static oNomeEmiCF	:= Nil
Static cNomeEmiCF	:= Space(TAMSx3("A1_NOME")[1])
Static oObserv		:= Nil
Static cObserv		:= Space(TAMSx3("L4_OBS")[1])
Static oCFAdmFin	:= Nil
Static cCFAdmFin   	:= Space(TamSx3("AE_COD")[1])
Static oCFDataTran	:= Nil
Static dCFDataTran  := CtoD("")
Static oCFParcelas	:= Nil
Static nCFParcelas 	:= 1
Static bSavKeyF3	:= Nil

//Convenios e NP
Static oPnlNP		:= Nil  
Static oNPVlrRec	:= Nil 	//Objeto de Get Valor Recebido
Static nNPVlrRec 	:= 0 	//Variavel do Get Valor Recebido
Static oNPVlrSal	:= Nil 	//Objeto do Get Valor do Saldo
Static nNPVlrSal	:= 0 	//Variavel do Get Valor do Saldo
Static oNPBtnOk		:= Nil  //Botão confirma tela convenios
Static oNPBtnCan	:= Nil  //Botão cancela tela convenios
Static oNPListGdNeg	:= Nil //Objeto TListBox das negociações
Static oNPAdmFin	:= Nil
Static cNPAdmFin   	:= Space(TamSx3("AE_COD")[1])
Static oNPDataTran	:= Nil
Static dNPDataTran  := CtoD("")
Static oNPParcelas	:= Nil
Static nNPParcelas 	:= 1
Static oSayTitConv  := Nil
Static cConvForma	:= ""

//Cheques
Static oPnlCH		:= Nil  
Static oPnlCHAux	:= Nil  
Static oCHVlrRec	:= Nil 	//Objeto de Get Valor Recebido
Static nCHVlrRec 	:= 0 	//Variavel do Get Valor Recebido
Static oCHVlrSal	:= Nil 	//Objeto do Get Valor do Saldo
Static nCHVlrSal	:= 0 	//Variavel do Get Valor do Saldo
Static oCHBtnOk		:= Nil  //Botão confirma tela cheque
Static oCHBtnCan	:= Nil  //Botão cancela tela cheque
Static oCHBtAOk		:= Nil  //Botão confirma tela auxiliar cheque
Static oCHBtACan	:= Nil  //Botão cancela tela auxiliar cheque
Static oCHBtAImp	:= Nil  //Botão imprimir tela auxiliar cheque
Static oCHListGdNeg	:= Nil //Objeto TListBox das negociações
Static oCHDataTran	:= Nil
Static dCHDataTran  := CtoD("")
Static oCHParcelas	:= Nil
Static nCHParcelas 	:= 1
Static aCheques		:= {}
Static nChqAct		:= 0
Static aObjChq		:= {}

//Credito
Static oPnlCR		:= Nil  
Static oCRVlrRec	:= Nil 	//Objeto de Get Valor Recebido
Static nCRVlrRec 	:= 0 	//Variavel do Get Valor Recebido
Static oCRVlrSal	:= Nil 	//Objeto do Get Valor do Saldo
Static nCRVlrSal	:= 0 	//Variavel do Get Valor do Saldo
Static oCRBtnOk		:= Nil  //Botão confirma tela cheque
Static oCRBtnCan	:= Nil  //Botão cancela tela cheque
Static oCRListGdNeg	:= Nil
Static oCRBusca
Static cCRBusca		:= space(40)
Static aNCCsCli		:= Nil // Array com todas as NCCs do cliente
Static aNCCPay		:= {}
Static oSayConn
Static cSayConn 	:= "Retaguarda OFF-LINE"
Static oSemaforo 	:= Nil 	//Objeto semaforo de conexao com retaguarda

//PIX ou Pagamento Digiral
Static oPnlPIX		:= Nil  //Painel pagamento Pix
Static oPIXVlrRec	:= Nil 	//Objeto de Get Valor Recebido
Static nPIXVlrRec 	:= 0 	//Variavel do Get Valor Recebido
Static oPIXVlrSal	:= Nil 	//Objeto do Get Valor do Saldo
Static nPIXVlrSal	:= 0 	//Variavel do Get Valor do Saldo
Static oPIXAdmFin	:= Nil
Static cPIXAdmFin   	:= Space(TamSx3("AE_COD")[1])
Static oPIXDataTran	:= Nil
Static dPIXDataTran  := CtoD("")
Static oPIXParcelas	:= Nil
Static nPIXParcelas 	:= 1
Static oPIXBtnOk	:= Nil  //Botão confirma tela Pix
Static oPIXBtnCan	:= Nil  //Botão cancela tela Pix
Static cPIXForma	:= ""

Static aNewGdNeg	:= {}  //Array para substituir o MsNewGetDados antigo (oNewGDNeg)
Static nNewGdNeg	:= 0   //nAt para substituir o MsNewGetDados antigo (oNewGDNeg)
Static aRecebtos	:= {}  // Composição do recebimento e desconto por negociação de pagamento
Static aRecebtosBKP := {}  // Backup do aRecebtos
Static nAtaReceb	:= 0   // nAt do aRecebtos selecionado ('posicionado')
Static nPercent		:= 0   // Percentual recebido
Static aItensGrid	:= {}  // Vetor com dados dos itens do grid oNewGDNeg (aListGdNeg)
Static aFieldGrid   := {"SALDO","U44_DESCRI","U44_FORMPG","U44_CONDPG","U25_ADMFIN","U25_EMITEN","EXCECAO","TOTALNEG","ORIGINAL","DESCONTO"}
Static aEmpLinGd	:= {0, space(tamsx3("U44_DESCRI")[1]), space(tamsx3("U44_FORMPG")[1]), space(tamsx3("U44_CONDPG")[1]),;
						space(tamsx3("U25_ADMFIN")[1]),space(tamsx3("U25_EMITEN")[1]), "LBNO", 0, 0, 0, .F.}
Static nVlrDescTot  := 0   // Controle de limite de desconto por período

Static oCssCombo    := "TComboBox { font: bold; font-size: 13px; text-align: right; color: #656565; background-color: #FFFFFF; border: 1px solid #9C9C9C; border-radius: 4px; padding: 4px; } TComboBox:focus{border: 2px solid #0080FF;} TComboBox:disabled {color:#656565; background-color: #EEEEEE;} TComboBox:drop-down {color:#000000; background-color: #FFFFFF; border-left: 0px; border-radius: 4px; background-image: url(rpo:fwskin_combobox_arrow.png);background-repeat: none;background-position: center;}"

Static lAddCmp := .F.
Static oAddCmp := Nil
Static oBtnCmpS
Static oBtnCmpN

Static lAddPromo := .F.
Static oAddPromo := Nil
Static oBtnPromoS
Static oBtnPromoN
Static lActPromo := SuperGetMv("TP_PROFLEX",,.F.)
Static aBkpProdPro := {}
Static nTotRecebi

Static bCancTela := Nil

/*/{Protheus.doc} TPDVE004
Rotina de substituição das telas de forma de pagamento

@author TBC
@since 26/10/2018
@version 1.0
@return Nil

@type function
/*/
User Function TPDVE004(cForma,oPnlAdconal)

	Local SIMBDIN := Alltrim(SuperGetMV("MV_SIMB1",,"R$"))
	Local cFPConv := SuperGetMv("TP_FPGCONV",,"")
	Local lAborta := .F.
	Local cParForma := ""
	Local lContTef := Iif(FindFunction("STIGetContTef"),STIGetContTef(),.F.) //Se ira utilizar a contingencia de passar no POS
	Local oPanelMVC		:= STIGetPanel()

	if bCancTela <> Nil
		Eval(bCancTela)
	endif

	If lActPromo

		lAddPromo := STDGPBasket("SL1","L1_XUSAPRO")=="S" .AND. !empty(STDGPBasket("SL1","L1_XCHVPRO"))

		if oAddPromo == Nil
			DoBkpProdPro() //faz backup 
			oPnlX := STIGetPan()
			oAddPromo := TSay():New((oPanelMVC:nHeight/4.2566),POSHOR_1 * 19.5, {|| "Usa Promoflex?" }, oPnlX,,,,,,.T.,,,80,8) 
			oAddPromo:SetCSS( POSCSS (GetClassName(oAddPromo), CSS_LABEL_FOCAL )) 
			oBtnPromoS := TButton():New((oPanelMVC:nHeight/4.2566)+10,(POSHOR_1 * 19.5),"SIM", oPnlX,{|| U_TPDVE04C(.T.) },025,013,,,,.T.,,,,{|| .T. })
			oBtnPromoN := TButton():New((oPanelMVC:nHeight/4.2566)+10,(POSHOR_1 * 19.5)+25,"NÃO", oPnlX,{|| U_TPDVE04C(.F.) },025,013,,,,.T.,,,,{|| .T. })
			U_TPDVE04C(lAddPromo)

		elseif lAddPromo .AND. STDGPBasket("SL1","L1_XDESPRO") > 0
			//tratamento para se clicar no botão limpa pagamentos do padrão
			STBTaxAlt( "NF_DESCTOT", STDGPBasket("SL1","L1_XDESPRO") )
		endif

	endif

	if oAddCmp == Nil .AND. SuperGetMV("TP_ACTCMP",,.F.) .AND. UC0->(FieldPos("UC0_DOC")) > 0
		U_TRETA37B("CMPPDV", "COMPENSACAO DE VALORES PDV")
		cUsrCmp := U_VLACESS2("CMPPDV", RetCodUsr())
		If cUsrCmp == Nil .OR. Empty(cUsrCmp)
		Else
			oPnlX := STIGetPan()
			oAddCmp := TSay():New(POSVERT_BTNFOCAL,POSHOR_1+LARGBTN+5, {|| "Vinc. Compensação?" }, oPnlX,,,,,,.T.,,,80,8) 
			oAddCmp:SetCSS( POSCSS (GetClassName(oAddCmp), CSS_LABEL_FOCAL )) 
			oBtnCmpS := TButton():New(POSVERT_BTNFOCAL+10,POSHOR_1+LARGBTN+5,"&SIM", oPnlX,{|| U_TPDVE04B(.T.) },030,013,,,,.T.,,,,{|| .T. })
			oBtnCmpN := TButton():New(POSVERT_BTNFOCAL+10,POSHOR_1+LARGBTN+35,"&NÃO", oPnlX,{|| U_TPDVE04B(.F.) },030,013,,,,.T.,,,,{|| .T. })
			U_TPDVE04B(lAddCmp)
		EndIf
	endif

	if Alltrim(cForma) $ "CC/CD" .AND. lContTef //se vem de contingencia TEF
		STIClnVar(Nil, .F.)
	else
		STIClnVar(Nil, .T.)
	endif

	If STBCalcSald("1") == 0 //Se o saldo da venda zerou, entao nao abre mais nenhuma forma de pagamento
		STIPayCancel() //ja cancela
		STIClnVar(oPnlAdconal, .T.)
	ElseIf Alltrim(cForma) == SIMBDIN //dinheiro
		lAborta := !STIPayCash(cForma, oPnlAdconal)
	ElseIf Alltrim(cForma) $ "CC/CD" //cartões
		lAborta := !STIPayCard(cForma, oPnlAdconal)
	ElseIf Alltrim(cForma) $ "CH" //cheques
		lAborta := !STIPayCheck(cForma, oPnlAdconal)
	ElseIf Alltrim(cForma) $ "CF" //carta frete
		If SuperGetMV("TP_ACTCF",,.F.) //se habilitado
			lAborta := !STIPayCFrete(cForma, oPnlAdconal)
		Else
			lAborta := .T.
			cParForma := "TP_ACTCF"
		EndIf
	ElseIf Alltrim(cForma) $ "NP" //nota a prazo
		If SuperGetMV("TP_ACTNP",,.F.) //se habilitado
			lAborta := !STIPayConv(cForma, oPnlAdconal)
		Else
			lAborta := .T.
			cParForma := "TP_ACTNP"
		EndIf
	ElseIf Alltrim(cForma) $ "CT" //CTF
		If SuperGetMV("TP_ACTCT",,.F.) //se habilitado
			lAborta := !STIPayConv(cForma, oPnlAdconal)
		Else
			lAborta := .T.
			cParForma := "TP_ACTCT"
		EndIf
	ElseIf Alltrim(cForma) $ cFPConv //convenios
		lAborta := !STIPayConv(cForma, oPnlAdconal)
	ElseIf AllTrim(cForma) $ "NB" //NB - Nota de Crédito Cód. Barras
		lAborta := !STIPayCredit(cForma, oPnlAdconal)
	ElseIf AllTrim(cForma) $ "PX/PD" //Pix ou Pagamento digital
		lAborta := !STIPayPix(cForma, oPnlAdconal)
	EndIf

	If lAborta
		STIPayCancel()
		STIClnVar(oPnlAdconal, .T.,.F.)
		If !Empty(cParForma)
			STFMessage(ProcName(),"STOP","Forma de Pagamento não habilitada. Ver parametro " + cParForma )
			STFShowMessage(ProcName())
		EndIf
	else
		//aplico o desconto do promoflex
		if lAddPromo .AND. STDGPBasket("SL1","L1_XDESPRO") > 0 .AND. nTotRecebi == 0
			STFMessage(ProcName(),"STOP","Desconto Promoflex de R$ "+Alltrim(Transform(STDGPBasket("SL1","L1_XDESPRO"),PesqPict("SL1","L1_XDESPRO")))+" aplicado!")
			STFShowMessage(ProcName())
		endif
	EndIf

Return

//--------------------------------------------------------------
// Aplica CSS no botão tipo Radio 
//--------------------------------------------------------------
User Function TPDVE04B(_lAddCmp)

	Local cCssBtn

	if _lAddCmp != Nil
		lAddCmp := _lAddCmp

		if oBtnCmpS <> Nil
			if lAddCmp // SIM

				//deixo botão SIM azul
				cCssBtn := POSCSS(GetClassName(oBtnCmpS), CSS_BTN_FOCAL )
				cCssBtn:= StrTran(cCssBtn, "border-radius: 6px;", "border-top-left-radius: 8px; border-bottom-left-radius: 8px;")
				oBtnCmpS:SetCss(cCssBtn)

				//deixo botão NAO branco
				cCssBtn := POSCSS(GetClassName(oBtnCmpN), CSS_BTN_NORMAL )
				cCssBtn:= StrTran(cCssBtn, "border-radius: 6px;", "border-top-right-radius: 8px; border-bottom-right-radius: 8px;")
				cCssBtn:= StrTran(cCssBtn, "font: bold large;", "")
				oBtnCmpN:SetCss(cCssBtn)

			else //NAO

				//deixo botão SIM branco
				cCssBtn := POSCSS(GetClassName(oBtnCmpS), CSS_BTN_NORMAL )
				cCssBtn:= StrTran(cCssBtn, "border-radius: 6px;", "border-top-left-radius: 8px; border-bottom-left-radius: 8px;")
				cCssBtn:= StrTran(cCssBtn, "font: bold large;", "")
				oBtnCmpS:SetCss(cCssBtn)

				//deixo botão NAO azul
				cCssBtn := POSCSS(GetClassName(oBtnCmpN), CSS_BTN_FOCAL )
				cCssBtn:= StrTran(cCssBtn, "border-radius: 6px;", "border-top-right-radius: 8px; border-bottom-right-radius: 8px;")
				oBtnCmpN:SetCss(cCssBtn)

			endif

			oBtnCmpS:Refresh()
			oBtnCmpN:Refresh()
		endif
	endif

Return lAddCmp

//--------------------------------------------------------------
// Aplica CSS no botão tipo Radio 
//--------------------------------------------------------------
User Function TPDVE04C(_lAddPromo)

	Local cCssBtn
	Local oModelCesta
	Local nI

	if _lAddPromo != Nil
		lAddPromo := _lAddPromo

		if oBtnPromoS <> Nil

			if lAddPromo // SIM

				STIZeraPay(.T.,.F.)
				nTotRecebi := 0

				oModelCesta := STDGPBModel()
				oModelCesta := oModelCesta:GetModel("SL2DETAIL")

				//restauro preço padrão nos itens da cesta
				For nI := 1 To oModelCesta:Length()
					oModelCesta:GoLine(nI)
					If !oModelCesta:IsDeleted(nI)
						STBTaxAlt( "IT_PRCUNI", aBkpProdPro[nI][4], nI )
						STBTaxAlt( "IT_VALMERC", aBkpProdPro[nI][5], nI )
						STBTaxAlt( "IT_DESCONTO", 0, nI )

						/*/
							Atualiza Total
						/*/
						STFRefTot()

						/*/
							Atualizar valores da cesta se o item já foi registrado.
						/*/
						STBRefshItBasket( nI ) // OBS: Caso for Antes de registrar já atualiza no registro de item
					Endif
				Next nI

				if Empty(STDGPBasket("SL1","L1_XCODPRO"))
					if U_TPDVE016(5) //abre tela promoflex
						if !Empty(STDGPBasket("SL1","L1_XCODPRO")) //se confirmou a tela, chamo WS Promoflex
							FWMsgRun(, {|oSay| U_TPDVE016(2, oSay, oModelCesta) }, "Conectando com PromoFlex", "Calculando o desconto para o codigo: " + STDGPBasket("SL1","L1_XCODPRO") )
							lAddPromo := !empty(STDGPBasket("SL1","L1_XCHVPRO"))
						endif
					else
						lAddPromo := .F.
					endif
				endif

				if lAddPromo
					//deixo botão SIM azul
					cCssBtn := POSCSS(GetClassName(oBtnPromoS), CSS_BTN_FOCAL )
					cCssBtn:= StrTran(cCssBtn, "border-radius: 6px;", "border-top-left-radius: 8px; border-bottom-left-radius: 8px;")
					oBtnPromoS:SetCss(cCssBtn)

					//deixo botão NAO branco
					cCssBtn := POSCSS(GetClassName(oBtnPromoN), CSS_BTN_NORMAL )
					cCssBtn:= StrTran(cCssBtn, "border-radius: 6px;", "border-top-right-radius: 8px; border-bottom-right-radius: 8px;")
					cCssBtn:= StrTran(cCssBtn, "font: bold large;", "")
					oBtnPromoN:SetCss(cCssBtn)
					
					STDSPBasket("SL1","L1_XUSAPRO","S")
				else //cancelo uso do promoflex
					//deixo botão SIM branco
					cCssBtn := POSCSS(GetClassName(oBtnPromoS), CSS_BTN_NORMAL )
					cCssBtn:= StrTran(cCssBtn, "border-radius: 6px;", "border-top-left-radius: 8px; border-bottom-left-radius: 8px;")
					cCssBtn:= StrTran(cCssBtn, "font: bold large;", "")
					oBtnPromoS:SetCss(cCssBtn)

					//deixo botão NAO azul
					cCssBtn := POSCSS(GetClassName(oBtnPromoN), CSS_BTN_FOCAL )
					cCssBtn:= StrTran(cCssBtn, "border-radius: 6px;", "border-top-right-radius: 8px; border-bottom-right-radius: 8px;")
					oBtnPromoN:SetCss(cCssBtn)
					
					STDSPBasket("SL1","L1_XUSAPRO","N")
				endif

				//aplico o desconto do promoflex
				if lAddPromo .AND. STDGPBasket("SL1","L1_XDESPRO") > 0
					STBTaxAlt( "NF_DESCTOT", STDGPBasket("SL1","L1_XDESPRO") )
					STFMessage(ProcName(),"STOP","Desconto Promoflex de R$ "+Alltrim(Transform(STDGPBasket("SL1","L1_XDESPRO"),PesqPict("SL1","L1_XDESPRO")))+" aplicado!")
					STFShowMessage(ProcName())
				endif

			else //NAO

				//deixo botão SIM branco
				cCssBtn := POSCSS(GetClassName(oBtnPromoS), CSS_BTN_NORMAL )
				cCssBtn:= StrTran(cCssBtn, "border-radius: 6px;", "border-top-left-radius: 8px; border-bottom-left-radius: 8px;")
				cCssBtn:= StrTran(cCssBtn, "font: bold large;", "")
				oBtnPromoS:SetCss(cCssBtn)

				//deixo botão NAO azul
				cCssBtn := POSCSS(GetClassName(oBtnPromoN), CSS_BTN_FOCAL )
				cCssBtn:= StrTran(cCssBtn, "border-radius: 6px;", "border-top-right-radius: 8px; border-bottom-right-radius: 8px;")
				oBtnPromoN:SetCss(cCssBtn)

				STDSPBasket("SL1","L1_XUSAPRO","N")
				STIZeraPay(.T.,.F.)
				nTotRecebi := 0
				
			endif

			oBtnPromoS:Refresh()
			oBtnPromoN:Refresh()
		endif
	endif

Return lAddPromo

Static Function DoBkpProdPro() 
	
	Local nI
	Local oModelCesta := STDGPBModel()
	
	oModelCesta := oModelCesta:GetModel("SL2DETAIL")

	aBkpProdPro := {}

	//restauro preço padrão nos itens da cesta
	For nI := 1 To oModelCesta:Length()
		oModelCesta:GoLine(nI)
		//[01] L2_ITEM / [02] L2_PRODUTO / [03] L2_QUANT / [04] PRC UNITARIO (PADRÃO) / [05] PRC TOTAL
		AAdd(aBkpProdPro, {oModelCesta:GetValue("L2_ITEM"),oModelCesta:GetValue("L2_PRODUTO"),oModelCesta:GetValue("L2_QUANT"), oModelCesta:GetValue("L2_VRUNIT"), oModelCesta:GetValue("L2_VLRITEM")}) //adiciona produto
	Next nI

Return

//----------------------------------------------------------
// Monta tela dinheiro
//----------------------------------------------------------
Static Function STIPayCash(cForma, oPnlAdconal)

	Local oBtn3
	Local oSay1, oSay2, oSay3
	Local nWidth, nHeight
	Local nTamBut := 80
	Local nTopPnl := 0
	Local oDlgPDV := STIGetDlg()
	Local oPanelMVC
	Local bActOK := {|| ValidaTela(cForma,oPnlAdconal,,oPnlDIN) }
	Local bActCanc := {|| oPnlDIN:Hide(), CancelCash(), STIPayCancel(), STIClnVar(oPnlAdconal, .T.)}

	STIBtnDeActivate()
	U_SetWBtnNF(.F.)

	oPnlAdconal:nWidth += 6
	oPnlAdconal:nLeft -= 3

	nWidth := oPnlAdconal:nWidth/2
	nHeight := oPnlAdconal:nHeight/2

	If nWidth < 260 //tratamento para resolução 1024
		nTamBut := 70
	EndIf

	nDINVlrSal := 0 //STBCalcSald("1")*(1-nPerDesc)
	nDINVlrRec := 0 //STBCalcSald("1")*(1-nPerDesc)
	
	if oPnlDIN == Nil
		oPanelMVC := STIGetPanel()
		nTopPnl := (oPanelMVC:nHeight/4.807) + 70

		oPnlDIN := TPanel():New(nTopPnl,oPnlAdconal:nLeft-8,"",oDlgPDV,NIL,.T.,.F.,,,nWidth,nHeight,.T.,.F.)
		//oPnlDIN:Align := CONTROL_ALIGN_ALLCLIENT
		oPnlDIN:SetCSS( POSCSS (GetClassName(oPnlDIN), CSS_PANEL_CONTEXT ))

		@ 008, 007 SAY oSay1 PROMPT "Pagamento em Dinheiro" SIZE 200, 011 OF oPnlDIN COLORS 0, 16777215 PIXEL
		oSay1:SetCSS( POSCSS (GetClassName(oSay1), CSS_BREADCUMB ))

		@ 030, 007 SAY oSay2 PROMPT "Saldo a Pagar" SIZE 070, 008 OF oPnlDIN COLORS 0, 16777215 PIXEL
		oSay2:SetCSS( POSCSS (GetClassName(oSay2), CSS_LABEL_FOCAL ))

		oDINVlrSal := TGet():New( 040, 007,{|u| iif(PCount()>0,nDINVlrSal:=u,nDINVlrSal)},oPnlDIN,085, 015,PesqPict("SL4","L4_VALOR"),{|| .T. },,,,,,.T.,,,{|| .T. },,,,.T.,.F.,,"oDINVlrSal",,,,.F.,.T.)
		oDINVlrSal:SetCSS( POSCSS (GetClassName(oDINVlrSal), CSS_GET_FOCAL ))
		oDINVlrSal:lCanGotFocus := .F.

		@ 030, 097 SAY oSay3 PROMPT "Valor do Pagamento" SIZE 070, 008 OF oPnlDIN COLORS 0, 16777215 PIXEL
		oSay3:SetCSS( POSCSS (GetClassName(oSay3), CSS_LABEL_FOCAL ))

		oDINVlrRec := TGet():New( 040, 097,{|u| iif(PCount()>0,nDINVlrRec:=u,nDINVlrRec)},oPnlDIN,085, 015,PesqPict("SL4","L4_VALOR"),{|| ValidValor(cForma) },,,,,,.T.,,,{|| .T. },,,,.F.,.F.,,"oDINVlrRec",,,,.F.,.T.)
		oDINVlrRec:SetCSS( POSCSS (GetClassName(oDINVlrRec), CSS_GET_FOCAL ))

		// BOTAO CONFIRMAR
		oDINBtnOk := TButton():New( nHeight-35,;
								nWidth-nTamBut-5,;
								"&Confirmar Pagamento"+CRLF+"(ALT+C)",;
								oPnlDIN	,;
								bActOK,; //fazer gravação nos componentes do totvs pdv, ou preparar retorno para PE
								nTamBut,;
								025,;
								,,,.T.,;
								,,,{|| .T.})
		oDINBtnOk:SetCSS( POSCSS (GetClassName(oDINBtnOk), CSS_BTN_FOCAL ))

		// BOTAO CANCELAR
		oDINBtnCan := TButton():New( nHeight-35,;
								nWidth-(2*nTamBut)-10,;
								"C&ancelar Pagamento"+CRLF+"(ALT+A)",;
								oPnlDIN	,;
								bActCanc,;
								nTamBut,;
								025,;
								,,,.T.,;
								,,,{|| .T.})
		oDINBtnCan:SetCSS( POSCSS (GetClassName(oDINBtnCan), CSS_BTN_ATIVO ))

		// BOTAO DESCONTOS
		oBtn3 := TButton():New( nHeight-35,;
								007,;
								"Aplicar &Descontos"+CRLF+"(ALT+D)",;
								oPnlDIN	,;
								{|| STIDetDesc(cForma) },;
								nTamBut,;
								025,;
								,,,.T.,;
								,,,{|| .T.})
		oBtn3:SetCSS( POSCSS (GetClassName(oBtn3), CSS_BTN_NORMAL ))
	Else
		oDINBtnOk:bAction := bActOK
		oDINBtnCan:bAction := bActCanc
		oPnlDIN:Show()
	Endif

	bCancTela := bActCanc

	LoadValues(cForma)
	DoRefreshNeg(cForma)
	oDINVlrRec:SetFocus()
	oDlgPDV:Refresh()

Return .T.

//----------------------------------------------------------
// Monta tela convênios (nota a prazo)
//----------------------------------------------------------
Static Function STIPayConv(cForma, oPnlAdconal)

	Local oBtn3
	Local oSay2, oSay3
	Local nWidth, nHeight
	Local nTamBut := 80
	Local cDsForma := Capital(Alltrim(Posicione("SX5",1,xFilial("SX5")+'24'+cForma,"X5_DESCRI")))
	Local nTopPnl := 0
	Local oDlgPDV := STIGetDlg()
	Local oPanelMVC
	Local bActOK := {|| ValidaTela(cForma,oPnlAdconal,,oPnlNP) }
	Local bActCanc := {|| oPnlNP:Hide(), STIPayCancel(), STIClnVar(oPnlAdconal, .T.)}

	STIBtnDeActivate()
	U_SetWBtnNF(.F.)

	aMyAdmFin := STDAdmFinan(Alltrim(cForma)) //busco adm fin da forma (funçao padrao)
	If Empty(aMyAdmFin)
		STFMessage(ProcName(),"STOP","Não há Adm.Financeira cadastrada para forma " + cForma +"."  )
		STFShowMessage(ProcName())
		Return .F.
	EndIf

	if empty(cDsForma)
		STFMessage(ProcName(),"STOP","Inclua a forma " + cForma +" na tabela 24 da SX5."  )
		STFShowMessage(ProcName())
		Return .F.
	endif

	//ajustando tamanho do painel
	oPnlAdconal:nWidth += 6
	oPnlAdconal:nLeft -= 3
	nWidth := oPnlAdconal:nWidth/2
	nHeight := oPnlAdconal:nHeight/2
	If nWidth < 260 //tratamento para resolução 1024
		nTamBut := 70
	EndIf

	nNPVlrSal := 0 //STBCalcSald("1")*(1-nPerDesc)
	nNPVlrRec := 0 //STBCalcSald("1")*(1-nPerDesc)
	cConvForma := cForma

	aSize(aNewGdNeg, 0) //deleto todas as linhas
	Aadd(aNewGdNeg, aClone(aEmpLinGd) )
	nNewGdNeg := 1

	if oPnlNP == Nil
		oPanelMVC := STIGetPanel()
		nTopPnl := (oPanelMVC:nHeight/4.807) + 70

		oPnlNP := TPanel():New(nTopPnl,oPnlAdconal:nLeft-8,"",oDlgPDV,NIL,.T.,.F.,,,nWidth,nHeight,.T.,.F.)
		//oPnlNP:Align := CONTROL_ALIGN_ALLCLIENT
		oPnlNP:SetCSS( POSCSS (GetClassName(oPnlNP), CSS_PANEL_CONTEXT ))

		@ 000, 007 SAY oSayTitConv PROMPT "Pagamento em "+cDsForma SIZE 200, 011 OF oPnlNP COLORS 0, 16777215 PIXEL
		oSayTitConv:SetCSS( POSCSS (GetClassName(oSayTitConv), CSS_BREADCUMB ))

		@ 012, 007 SAY oSay2 PROMPT "Negociações de Pagamento do cliente" SIZE 300, 008 OF oPnlNP COLORS 0, 16777215 PIXEL
		oSay2:SetCSS( POSCSS (GetClassName(oSay2), CSS_LABEL_FOCAL ))

		//Cria listbox com as negociaçoes (para ficar no padrao totvs pdv)
		oNPListGdNeg := TListBox():Create(oPnlNP, 022, 007, Nil, {''}, nWidth-13, nHeight-95,,,,,.T.,,/*{|| LoadSelNeg(cConvForma) }*/ )
		oNPListGdNeg:bSetGet := {|u| iif(PCount()>0,LoadSelNeg(cConvForma, oNPListGdNeg),) }
		oNPListGdNeg:bLDBLClick := {|| DoRefreshNeg(cConvForma), oNPVlrRec:SetFocus()}
		oNPListGdNeg:SetCSS( POSCSS (GetClassName(oNPListGdNeg), CSS_LISTBOX ))

		@ nHeight-68, 010 SAY oSay3 PROMPT "Saldo a Pagar" SIZE 70, 008 OF oPnlNP COLORS 0, 16777215 PIXEL
		oSay3:SetCSS( POSCSS (GetClassName(oSay3), CSS_LABEL_FOCAL ))

		oNPVlrSal := TGet():New( nHeight-58, 007,{|u| iif(PCount()>0,nNPVlrSal:=u,nNPVlrSal)},oPnlNP,85, 015,PesqPict("SL4","L4_VALOR"),{|| .T. },,,,,,.T.,,,{|| .T. },,,,.T.,.F.,,"oNPVlrSal",,,,.F.,.T.)
		oNPVlrSal:SetCSS( POSCSS (GetClassName(oNPVlrSal), CSS_GET_FOCAL ))
		oNPVlrSal:lCanGotFocus := .F.

		@ nHeight-68, 100 SAY oSay4 PROMPT "Valor do Pagamento" SIZE 70, 008 OF oPnlNP COLORS 0, 16777215 PIXEL
		oSay4:SetCSS( POSCSS (GetClassName(oSay4), CSS_LABEL_FOCAL ))

		oNPVlrRec := TGet():New( nHeight-58, 097,{|u| iif( PCount()==0,nNPVlrRec,nNPVlrRec:=u)},oPnlNP,85, 015,PesqPict("SL4","L4_VALOR"),{|| ValidValor(cConvForma) },,,,,,.T.,,,{|| .T. },,,,.F.,.F.,,"oNPVlrRec",,,,.F.,.T.)
		oNPVlrRec:SetCSS( POSCSS (GetClassName(oNPVlrRec), CSS_GET_FOCAL ))

		//crio gets para compatiblidade da funçao padrao ao confirmar
		dNPDataTran := dDataBase
		@ 001, 001 MSGET oNPDataTran VAR dNPDataTran SIZE 060, 013 OF oPnlNP COLORS 0, 16777215 WHEN .F. PIXEL
		oNPDataTran:Hide()
		nNPParcelas := 1
		@ 001, 001 MSGET oNPParcelas VAR nNPParcelas SIZE 040, 013 OF oPnlNP COLORS 0, 16777215 WHEN .F. HASBUTTON PIXEL
		oNPParcelas:Hide()

		If Len(aMyAdmFin) > 1
			@ nHeight-68, 190 SAY oSay5 PROMPT "Adm.Financeira" SIZE 70, 008 OF oPnlNP COLORS 0, 16777215 PIXEL
			oSay5:SetCSS( POSCSS (GetClassName(oSay5), CSS_LABEL_FOCAL ))
		EndIf

		cNPAdmFin := aMyAdmFin[1]
		oNPAdmFin := TComboBox():New(nHeight-58, 187, {|u| If(PCount()>0,cNPAdmFin:=u,cNPAdmFin)}, aMyAdmFin , 085, 018, oPnlNP, Nil,/*bChange*/,/*bValid*/,,,.T.,,Nil,Nil,{|| (Len(aMyAdmFin) > 1) } )
		oNPAdmFin:SetCSS(oCssCombo)
		If !Len(aMyAdmFin) > 1
			oNPAdmFin:Hide()
		EndIf

		// BOTAO CONFIRMAR
		oNPBtnOk := TButton():New( nHeight-35,;
								nWidth-nTamBut-5,;
								"&Confirmar Pagamento"+CRLF+"(ALT+C)",;
								oPnlNP	,;
								bActOK,; //fazer gravação nos componentes do totvs pdv, ou preparar retorno para PE
								nTamBut,;
								025,;
								,,,.T.,;
								,,,{|| .T.})
		oNPBtnOk:SetCSS( POSCSS (GetClassName(oNPBtnOk), CSS_BTN_FOCAL ))

		// BOTAO CANCELAR
		oNPBtnCan := TButton():New( nHeight-35,;
								nWidth-(2*nTamBut)-10,;
								"C&ancelar Pagamento"+CRLF+"(ALT+A)",;
								oPnlNP	,;
								bActCanc,;
								nTamBut,;
								025,;
								,,,.T.,;
								,,,{|| .T.})
		oNPBtnCan:SetCSS( POSCSS (GetClassName(oNPBtnCan), CSS_BTN_ATIVO ))

		// BOTAO DESCONTOS
		oBtn3 := TButton():New( nHeight-35,;
								007,;
								"Aplicar &Descontos"+CRLF+"(ALT+D)",;
								oPnlNP	,;
								{|| STIDetDesc(cConvForma) },;
								nTamBut,;
								025,;
								,,,.T.,;
								,,,{|| .T.})
		oBtn3:SetCSS( POSCSS (GetClassName(oBtn3), CSS_BTN_NORMAL ))
	
	else
		oNPAdmFin:SetItems(aMyAdmFin)
		oNPAdmFin:Select(1)
		oNPAdmFin:Refresh()
		oNPListGdNeg:GoTop()
		oNPListGdNeg:SetItems({''})
		oNPBtnOk:bAction := bActOK
		oNPBtnCan:bAction := bActCanc
		oSayTitConv:SetText( "Pagamento em "+cDsForma )
		oPnlNP:Show()
	endif

	LoadValues(cForma)
	DoRefreshNeg(cForma)

	If Empty(oNPListGdNeg:GetSelText()) //se nao achou negociação, cancelo a tela
		STFMessage(ProcName(),"STOP","Cliente não habilitado para essa forma de pagamento!" )
		STFShowMessage(ProcName())
		oPnlNP:Hide()
		Return .F.
	Else
		oNPListGdNeg:GoTop()
		oNPListGdNeg:SetFocus()
	EndIf

	bCancTela := bActCanc

Return .T.

//----------------------------------------------------------
// Monta tela Carta Frete
//----------------------------------------------------------
Static Function STIPayCFrete(cForma, oPnlAdconal)

	Local oBtn3
	Local oSay1, oSay2, oSay3
	Local nWidth, nHeight
	Local nTamBut := 80
	Local cDsForma := Capital(Alltrim(Posicione("SX5",1,xFilial("SX5")+'24'+cForma,"X5_DESCRI")))
	Local oDlgPDV := STIGetDlg()
	Local bActOK := {|| ValidaTela(cForma, oPnlAdconal,,oPnlCF) }
	Local bActCanc := {|| oPnlCF:Hide(), STIPayCancel(), STIClnVar(oPnlAdconal, .T.)}

	STIBtnDeActivate()
	U_SetWBtnNF(.F.)

	aMyAdmFin := STDAdmFinan(Alltrim(cForma)) //busco adm fin da forma (funçao padrao)
	If Empty(aMyAdmFin)
		STFMessage(ProcName(),"STOP","Não há Adm.Financeira cadastrada para forma " + cForma +"."  )
		STFShowMessage(ProcName())
		Return .F.
	EndIf

	nCFVlrSal := 0 //STBCalcSald("1")*(1-nPerDesc)
	nCFVlrRec := 0 //STBCalcSald("1")*(1-nPerDesc)

	//ajustando tamanho do painel
	oPnlAdconal:nWidth += 10
	oPnlAdconal:nLeft -= 3
	oPnlAdconal:nHeight += oPnlAdconal:nTop
	oPnlAdconal:nTop := 0
	nWidth := oPnlAdconal:nWidth/2
	nHeight := oPnlAdconal:nHeight/2
	If nWidth < 260 //tratamento para resolução 1024
		nTamBut := 70
	EndIf

	aSize(aNewGdNeg, 0) //deleto todas as linhas
	Aadd(aNewGdNeg, aClone(aEmpLinGd) )
	nNewGdNeg := 1

	if oPnlCF == Nil
		oPnlCF := TPanel():New( 071 ,oPnlAdconal:nLeft-8,"",oDlgPDV,NIL,.T.,.F.,,,nWidth,nHeight,.T.,.F.)
		//oPnlCF:Align := CONTROL_ALIGN_ALLCLIENT
		oPnlCF:SetCSS( POSCSS (GetClassName(oPnlCF), CSS_PANEL_CONTEXT ))

		@ 005, 007 SAY oSay1 PROMPT "Pagamento em "+cDsForma SIZE 200, 011 OF oPnlCF COLORS 0, 16777215 PIXEL
		oSay1:SetCSS( POSCSS (GetClassName(oSay1), CSS_BREADCUMB ))

		@ 020, 007 SAY oSay2 PROMPT "Negociações de Pagamento" SIZE 200, 008 OF oPnlCF COLORS 0, 16777215 PIXEL
		oSay2:SetCSS( POSCSS (GetClassName(oSay2), CSS_LABEL_FOCAL ))

		//Cria listbox com as negociaçoes (para ficar no padrao totvs pdv)
		oCFListGdNeg := TListBox():Create(oPnlCF, 030, 007, Nil, {''}, 140, nHeight-107,,,,,.T.,,/*{|| LoadSelNeg(cForma) }*/ )
		oCFListGdNeg:bSetGet := {|u| iif(PCount()>0,LoadSelNeg(cForma, oCFListGdNeg),) }
		oCFListGdNeg:bLDBLClick := {|| DoRefreshNeg(cForma), oCFVlrRec:SetFocus()}
		oCFListGdNeg:SetCSS( POSCSS (GetClassName(oCFListGdNeg), CSS_LISTBOX ))

		@ nHeight-68, 010 SAY oSay3 PROMPT "Saldo a Pagar" SIZE 70, 008 OF oPnlCF COLORS 0, 16777215 PIXEL
		oSay3:SetCSS( POSCSS (GetClassName(oSay3), CSS_LABEL_FOCAL ))
		oCFVlrSal := TGet():New( nHeight-58, 007,{|u| iif(PCount()>0,nCFVlrSal:=u,nCFVlrSal)},oPnlCF,85, 015,PesqPict("SL4","L4_VALOR"),{|| .T. },,,,,,.T.,,,{|| .T. },,,,.T.,.F.,,"oCFVlrSal",,,,.F.,.T.)
		oCFVlrSal:SetCSS( POSCSS (GetClassName(oCFVlrSal), CSS_GET_FOCAL ))
		oCFVlrSal:lCanGotFocus := .F.

		@ nHeight-68, 100 SAY oSay4 PROMPT "Valor do Pagamento" SIZE 70, 008 OF oPnlCF COLORS 0, 16777215 PIXEL
		oSay4:SetCSS( POSCSS (GetClassName(oSay4), CSS_LABEL_FOCAL ))
		oCFVlrRec := TGet():New( nHeight-58, 097,{|u| iif( PCount()==0,nCFVlrRec,nCFVlrRec:=u)},oPnlCF,85, 015,PesqPict("SL4","L4_VALOR"),{|| ValidValor(cForma) },,,,,,.T.,,,{|| .T. },,,,.F.,.F.,,"oCFVlrRec",,,,.F.,.T.)
		oCFVlrRec:SetCSS( POSCSS (GetClassName(oCFVlrRec), CSS_GET_FOCAL ))
		
		oCFVlrRec:cF3 := "TPDVA014"
		oCFVlrRec:bF3 := {|| oCFVlrRec:cText:=U_TPDVA014(cCodCF,cLojCF) }
		oCFVlrRec:bGotFocus := {|| bSavKeyF3 := SetKey(VK_F3), SetKey(VK_F3, {|| oCFVlrRec:cText:=U_TPDVA014(cCodCF,cLojCF) }) }
		oCFVlrRec:bLostFocus := {|| iif(Eval(oCFVlrRec:bValid),SetKey(VK_F3, bSavKeyF3),) }

		@ nHeight-56, 184 BITMAP oCalCFBMP RESOURCE "CALCULADORA.PNG" NOBORDER SIZE 012, 012 OF oPnlCF ADJUST PIXEL
		oCalCFBMP:ReadClientCoors(.T.,.T.)
		oCalCFBTN := THButton():New(nHeight-56, 182, "", oPnlCF, {|| oCFVlrRec:cText:=U_TPDVA014(cCodCF,cLojCF) }, 016, 016,,"Cálculo de Saldo Carta Frete (F3)")
		//SetKey(K_ALT_S,{|| oCFVlrRec:cText:=U_TPDVA014(cCodCF,cLojCF)})

		//@ 020, 152 SAY oSay2 PROMPT "CNPJ do Emitente" SIZE 080, 008 OF oPnlCF COLORS 0, 16777215 PIXEL
		//oSay2:SetCSS( POSCSS (GetClassName(oSay2), CSS_LABEL_FOCAL ))
		//oEmitCF := TGet():New( 030, 152,{|u| iif(PCount()>0,cEmitCF:=u,cEmitCF)},oPnlCF,100, 013,PesqPict("SA1","A1_CGC"),{|| VldEmitCF() .AND. oPnlCF:Refresh() },,,,,,.T.,,,{|| .T. },,,,.F.,.F.,,"oEmitCF",,,,.T.,.F.)
		//oEmitCF:SetCSS( POSCSS (GetClassName(oEmitCF), CSS_GET_NORMAL ))
		//TSearchF3():New(oEmitCF,400,250,"SA1","A1_CGC",{{"A1_NOME",2},{"A1_CGC",3},{"A1_COD",1}},"SA1->A1_MSBLQL<>'1' .and. A1_XEMICF='S'",{{"A1_NOME","A1_EST","A1_MUN"},{"A1_CGC","A1_NOME","A1_EST","A1_MUN"},{"A1_COD","A1_LOJA","A1_NOME","A1_EST","A1_MUN"}},,,0)

		@ 020, 152 SAY oSay2 PROMPT "Código" SIZE 100, 008 OF oPnlCF COLORS 0, 16777215 PIXEL
		oSay2:SetCSS( POSCSS (GetClassName(oSay2), CSS_LABEL_FOCAL ))
		oCodCF := TGet():New( 030, 152,{|u| iif(PCount()>0,cCodCF:=u,cCodCF)},oPnlCF, 055, 013, PesqPict("SA1","A1_COD"), {|| VldEmitCF() .AND. oPnlCF:Refresh() },,,,,,.T.,,,{|| .T. },,,,.F.,.F.,,"oCodCF",,,,.T.,.F.)
		oCodCF:SetCSS( POSCSS (GetClassName(oCodCF), CSS_GET_NORMAL ))

		@ 020, 207 SAY oSay2 PROMPT "Loja" SIZE 100, 008 OF oPnlCF COLORS 0, 16777215 PIXEL
		oSay2:SetCSS( POSCSS (GetClassName(oSay2), CSS_LABEL_FOCAL ))
		oLojCF := TGet():New( 030, 207,{|u| iif(PCount()>0,cLojCF:=u,cLojCF)},oPnlCF, 020, 013, PesqPict("SA1","A1_LOJA"), {|| VldEmitCF() .AND. oPnlCF:Refresh() },,,,,,.T.,,,{|| .T. },,,,.F.,.F.,,"oLojCF",,,,.T.,.F.)
		oLojCF:SetCSS( POSCSS (GetClassName(oLojCF), CSS_GET_NORMAL ))

		@ 047, 152 SAY oSay5 PROMPT "Nome do Emitente" SIZE 080, 010 OF oPnlCF COLORS 0, 16777215 PIXEL
		oSay5:SetCSS( POSCSS (GetClassName(oSay5), CSS_LABEL_FOCAL ))
		oNomeEmiCF := TGet():New( 57, 152,{|u| iif(PCount()>0,cNomeEmiCF:=u,cNomeEmiCF)},oPnlCF,nWidth-157, 013,,{|| .T./*bValid*/ },,,,,,.T.,,,{|| .T. },,,,.T.,.F.,,"oNomeEmiCF",,,,.T.,.F.)
		oNomeEmiCF:SetCSS( POSCSS (GetClassName(oNomeEmiCF), CSS_GET_NORMAL ))
		oNomeEmiCF:lCanGotFocus := .F.
		TSearchF3():New(oCodCF,400,250,"SA1","A1_COD",{{"A1_NOME",2},{"A1_CGC",3},{"A1_COD",1}},"SA1->A1_MSBLQL<>'1'"+iif(SA1->(FieldPos("A1_XEMICF"))>0," .AND. SA1->A1_XEMICF='S'",""),{{"A1_COD","A1_LOJA","A1_NOME","A1_EST","A1_MUN"},{"A1_COD","A1_LOJA","A1_CGC","A1_NOME","A1_EST","A1_MUN"},{"A1_COD","A1_LOJA","A1_NOME","A1_EST","A1_MUN"}},,,0,,{{oLojCF,"A1_LOJA"},{oNomeEmiCF,"A1_NOME"}})

		@ 74, 152 SAY oSay6 PROMPT "Numero Carta Frete" SIZE 100, 008 OF oPnlCF COLORS 0, 16777215 PIXEL
		oSay6:SetCSS( POSCSS (GetClassName(oSay6), CSS_LABEL_FOCAL ))
		oCFrete := TGet():New( 084, 152,{|u| iif(PCount()>0,cCFrete:=u,cCFrete)},oPnlCF,nWidth-157, 013,PesqPict("SL4","L4_NUMCART"),{|| .T./*bValid*/ },,,,,,.T.,,,{|| .T. },,,,.F.,.F.,,"oCFrete",,,,.T.,.F.)
		oCFrete:SetCSS( POSCSS (GetClassName(oCFrete), CSS_GET_NORMAL ))

		@ 101, 152 SAY oSay7 PROMPT "Observações" SIZE 100, 008 OF oPnlCF COLORS 0, 16777215 PIXEL
		oSay7:SetCSS( POSCSS (GetClassName(oSay7), CSS_LABEL_FOCAL ))
		oObserv := TGet():New( 111, 152,{|u| iif(PCount()>0,cObserv:=u,cObserv)},oPnlCF,nWidth-157, 013,"",{|| .T./*bValid*/ },,,,,,.T.,,,{|| .T. },,,,.F.,.F.,,"oObserv",,,,.T.,.F.)
		oObserv:SetCSS( POSCSS (GetClassName(oObserv), CSS_GET_NORMAL ))

		//crio gets para compatiblidade da funçao padrao ao confirmar
		dCFDataTran := dDataBase
		@ 001, 001 MSGET oCFDataTran VAR dCFDataTran SIZE 060, 013 OF oPnlCF COLORS 0, 16777215 WHEN .F. PIXEL
		oCFDataTran:Hide()
		nCFParcelas := 1
		@ 001, 001 MSGET oCFParcelas VAR nCFParcelas SIZE 040, 013 OF oPnlCF COLORS 0, 16777215 WHEN .F. HASBUTTON PIXEL
		oCFParcelas:Hide()

		cCFAdmFin := aMyAdmFin[1]
		oCFAdmFin := TComboBox():New(001, 001, {|u| If(PCount()>0,cCFAdmFin:=u,cCFAdmFin)}, aMyAdmFin , 122, 016, oPnlCF, Nil,/*bChange*/,/*bValid*/,,,.T.,,Nil,Nil,{|| .F. } )
		oCFAdmFin:Hide()

		// BOTAO CONFIRMAR
		oCFBtnOk := TButton():New( nHeight-35,;
								nWidth-nTamBut-5,;
								"&Confirmar Pagamento"+CRLF+"(ALT+C)",;
								oPnlCF	,;
								bActOK,; //fazer gravação nos componentes do totvs pdv, ou preparar retorno para PE
								nTamBut,;
								025,;
								,,,.T.,;
								,,,{|| .T.})
		oCFBtnOk:SetCSS( POSCSS (GetClassName(oCFBtnOk), CSS_BTN_FOCAL ))

		// BOTAO CANCELAR
		oCFBtnCan := TButton():New( nHeight-35,;
								nWidth-(2*nTamBut)-10,;
								"C&ancelar Pagamento"+CRLF+"(ALT+A)",;
								oPnlCF	,;
								bActCanc,;
								nTamBut,;
								025,;
								,,,.T.,;
								,,,{|| .T.})
		oCFBtnCan:SetCSS( POSCSS (GetClassName(oCFBtnCan), CSS_BTN_ATIVO ))

		// BOTAO DESCONTOS
		oBtn3 := TButton():New( nHeight-35,;
								007,;
								"Aplicar &Descontos"+CRLF+"(ALT+D)",;
								oPnlCF	,;
								{|| STIDetDesc(cForma) },;
								nTamBut,;
								025,;
								,,,.T.,;
								,,,{|| .T.})
		oBtn3:SetCSS( POSCSS (GetClassName(oBtn3), CSS_BTN_NORMAL ))
	Else
		oCFListGdNeg:GoTop()
		oCFListGdNeg:SetItems({''})
		oCFBtnOk:bAction := bActOK
		oCFBtnCan:bAction := bActCanc
		oPnlCF:Show()
	Endif

	LoadValues(cForma)
	DoRefreshNeg(cForma)

	If Empty(oCFListGdNeg:GetSelText()) //se nao achou negociação, cancelo a tela
		STFMessage(ProcName(),"STOP","Cliente não habilitado para essa forma de pagamento!" )
		STFShowMessage(ProcName())
		oPnlCF:Hide()
		Return .F.
	Else
		oCFListGdNeg:GoTop()
		oCFListGdNeg:SetFocus()
	EndIf

	bCancTela := bActCanc
	
	oDlgPDV:Refresh()

Return .T.

//----------------------------------------------------------
// Monta tela cartão
//----------------------------------------------------------
Static Function STIPayCard(cForma, oPnlAdconal)

	Local oBtn3
	Local oSay1, oSay2, oSay3, oSay4, oSay6, oSay7, oSay8, oSay9, oSay10, oSay11, oSay12
	Local cCssAux
	Local nWidth, nHeight
	Local nTamBut := 80
	Local lWhenParc := SuperGetMV("MV_XPARCPG",,.T.) //Define se a quantidade de parcelas será definida pela condição de pagamento ou não
	Local lContTef := Iif(FindFunction("STIGetContTef"),STIGetContTef(),.F.) //Se ira utilizar a contingencia de passar no POS //pega variavel contingencia tef do padrao
	Local oDlgPDV := STIGetDlg()
	Local bActOK := {|| lMyContTef := (!Empty(cNsuDoc) .or. !Empty(cAutoriz) .or. lContTef),;
								ValidaTela(cForma, oPnlAdconal, cCCAdmFin, oPnlCC)}
	Local bActCanc := {|| oPnlCC:Hide(), STIPayCancel(), STISetContTef(.F.), STIClnVar(oPnlAdconal, .T.) }
	Local lSelAdm := SuperGetMV("MV_XSELADM",,.F.) //Define se ao inves de selecionar OPERADORA + BANDEIRA (.F.), será selecionado ADM. FINANCEIRA (.T.)

	STIBtnDeActivate()
	U_SetWBtnNF(.F.)
	
	If lContTef .AND. !empty(aRecebtosBKP) //se está em contingência, restauro o aRecebtos
		aRecebtos[nAtaReceb] := aClone(aRecebtosBKP)
		AtuARecebtos() //validacao de campo -> CAMPO "RECEBIDO"
		aRecebtosBKP := {}
	EndIf

	//limpo as variaveis estaticas
	nCCVlrSal	:= 0
	nCCVlrRec	:= 0
	cCardForma	:= cForma
	cRedeAut	:= Space(TamSx3("MDE_CODIGO")[1])
	cBandeira	:= Space(TamSx3("MDE_CODIGO")[1])
	cCCAdmFin	:= Space(TamSx3("AE_COD")[1])
	cNsuDoc		:= Space(TamSx3("L4_NSUTEF")[1])
	cAutoriz	:= Space(TamSx3("L4_AUTORIZ")[1])
	dCCDataTran := CtoD("")
	nCCParcelas := 1

	aMyAdmFin := STDAdmFinan(Alltrim(cForma)) //busco adm fin da forma (funçao padrao)
	If Empty(aMyAdmFin)
		STFMessage(ProcName(),"STOP","Não há Adm.Financeira cadastrada para forma " + cForma +"."  )
		STFShowMessage(ProcName())
		Return .F.
	EndIf

	aMyRede := GetMDEAdm(1, aMyAdmFin) //busca redes relacionadas as adm encontradas
	aMyBandei	:= {}
	//adicionando opção em branco nos combobox
	If Empty(aMyAdmFin)
		aadd(aMyAdmFin, cCCAdmFin)
	Else
		aSize(aMyAdmFin, Len(aMyAdmFin)+1)
		aIns(aMyAdmFin,1)
		aMyAdmFin[1] := cCCAdmFin
	EndIf
	aadd(aMyBandei, cBandeira)

	//ajustando tamanho do painel
	oPnlAdconal:nWidth += 10
	oPnlAdconal:nLeft -= 3
	oPnlAdconal:nHeight += oPnlAdconal:nTop
	oPnlAdconal:nTop := 0
	nWidth := oPnlAdconal:nWidth/2
	nHeight := oPnlAdconal:nHeight/2
	If nWidth < 260 //tratamento para resolução 1024
		nTamBut := 70
	EndIf

	aSize(aNewGdNeg, 0) //deleto todas as linhas
	Aadd(aNewGdNeg, aClone(aEmpLinGd) )
	nNewGdNeg := 1

	if oPnlCC == Nil
		oPnlCC := TPanel():New( 071 ,oPnlAdconal:nLeft-8,"",oDlgPDV,NIL,.T.,.F.,,,nWidth,nHeight,.T.,.F.)
		//oPnlCC:Align := CONTROL_ALIGN_ALLCLIENT
		oPnlCC:SetCSS( POSCSS (GetClassName(oPnlCC), CSS_PANEL_CONTEXT ))

		@ 005, 007 SAY oSay1 PROMPT ("Pagamento em Cartão de "+iif(cCardForma=="CC","Crédito","Débito")) SIZE 200, 011 OF oPnlCC COLORS 0, 16777215 PIXEL
		oSay1:SetCSS( POSCSS (GetClassName(oSay1), CSS_BREADCUMB ))

		@ 020, 007 SAY oSay2 PROMPT "Negociações de Pagamento" SIZE 200, 008 OF oPnlCC COLORS 0, 16777215 PIXEL
		oSay2:SetCSS( POSCSS (GetClassName(oSay2), CSS_LABEL_FOCAL ))

		//Cria listbox com as negociaçoes (para ficar no padrao totvs pdv)
		oCCListGdNeg := TListBox():Create(oPnlCC, 030, 007, Nil, {''}, nWidth-140, nHeight-107,,,,,.T.,,/*{|| LoadSelNeg(cCardForma, oCCListGdNeg) }*/ )
		oCCListGdNeg:bSetGet := {|u| iif(PCount()>0,LoadSelNeg(cCardForma, oCCListGdNeg),) }
		oCCListGdNeg:bLDBLClick := {|| DoRefreshNeg(cCardForma), oCCVlrRec:SetFocus()}
		oCCListGdNeg:SetCSS( POSCSS (GetClassName(oCCListGdNeg), CSS_LISTBOX ))

		@ nHeight-68, 010 SAY oSay3 PROMPT "Saldo a Pagar" SIZE 70, 008 OF oPnlCC COLORS 0, 16777215 PIXEL
		oSay3:SetCSS( POSCSS (GetClassName(oSay3), CSS_LABEL_FOCAL ))

		oCCVlrSal := TGet():New( nHeight-58, 007,{|u| iif(PCount()>0,nCCVlrSal:=u,nCCVlrSal)},oPnlCC,85, 015,PesqPict("SL4","L4_VALOR"),{|| .T. },,,,,,.T.,,,{|| .T. },,,,.T.,.F.,,"oCCVlrSal",,,,.F.,.T.)
		oCCVlrSal:SetCSS( POSCSS (GetClassName(oCCVlrSal), CSS_GET_FOCAL ))
		oCCVlrSal:lCanGotFocus := .F.

		@ nHeight-68, 100 SAY oSay4 PROMPT "Valor do Pagamento" SIZE 70, 008 OF oPnlCC COLORS 0, 16777215 PIXEL
		oSay4:SetCSS( POSCSS (GetClassName(oSay4), CSS_LABEL_FOCAL ))

		oCCVlrRec := TGet():New( nHeight-58, 097,{|u| iif( PCount()==0,nCCVlrRec,nCCVlrRec:=u)},oPnlCC,85, 015,PesqPict("SL4","L4_VALOR"),{|| ValidValor(cCardForma) },,,,,,.T.,,,{|| .T. },,,,.F.,.F.,,"oCCVlrRec",,,,.F.,.T.)
		oCCVlrRec:SetCSS( POSCSS (GetClassName(oCCVlrRec), CSS_GET_FOCAL ))

		@ 020, nWidth-125 SAY oSay6 PROMPT "Operadora" SIZE 106, 010 OF oPnlCC COLORS 0, 16777215 PIXEL
		oSay6:SetCSS( POSCSS (GetClassName(oSay6), CSS_LABEL_FOCAL ))

		oRedeAut := TComboBox():New(030, nWidth-125, {|u| If(PCount()>0,cRedeAut:=u,cRedeAut)}, aMyRede , 060, 016, oPnlCC, Nil,{|| aMyBandei:=GetMDEAdm(2, aMyAdmFin, cRedeAut), oBandeira:SetItems(aMyBandei), iif(len(aMyBandei)==2,oBandeira:Select(2),), oBandeira:Refresh() },/*bValid*/,,,.T.,,Nil,Nil,{|| !lSelAdm } )
		oRedeAut:SetCSS(oCssCombo)

		@ 020, nWidth-60 SAY oSay7 PROMPT "Bandeira" SIZE 106, 010 OF oPnlCC COLORS 0, 16777215 PIXEL
		oSay7:SetCSS( POSCSS (GetClassName(oSay7), CSS_LABEL_FOCAL ))

		oBandeira := TComboBox():New(030, nWidth-60, {|u| If(PCount()>0,cBandeira:=u,cBandeira)}, aMyBandei , 057, 016, oPnlCC, Nil,{|| nX := GetMDEAdm(3, aMyAdmFin, cRedeAut, cBandeira), oCCAdmFin:Select(nX) },/*bValid*/,,,.T.,,Nil,Nil,{|| !lSelAdm } )
		oBandeira:SetCSS(oCssCombo)
		//oBandeira:SetCSS( POSCSS (GetClassName(oBandeira), CSS_GET_NORMAL ))

		@ 047, nWidth-125 SAY oSay8 PROMPT "Adm. Financeira" SIZE 120, 010 OF oPnlCC COLORS 0, 16777215 PIXEL
		oSay8:SetCSS( POSCSS (GetClassName(oSay8), CSS_LABEL_FOCAL ))

		oCCAdmFin := TComboBox():New(057, nWidth-125, {|u| If(PCount()>0,cCCAdmFin:=u,cCCAdmFin)}, aMyAdmFin , 122, 016, oPnlCC, Nil,/*bChange*/,/*bValid*/,,,.T.,,Nil,Nil,{|| lSelAdm } )
		//cCssAux := POSCSS (GetClassName(oCCAdmFin), CSS_GET_NORMAL )
		//cCssAux := StrTran(cCssAux,"transparent","#EEEEEE")
		//cCssAux := StrTran(cCssAux,"border: none;","")
		oCCAdmFin:SetCSS(oCssCombo)

		@ 074, nWidth-125 SAY oSay9 PROMPT "NSU" SIZE 070, 007 OF oPnlCC COLORS 0, 16777215 PIXEL
		oSay9:SetCSS( POSCSS (GetClassName(oSay9), CSS_LABEL_FOCAL ))

		@ 084, nWidth-125 MSGET oNsuDoc VAR cNsuDoc SIZE 060, 013 OF oPnlCC COLORS 0, 16777215 PIXEL PICTURE Replicate("N",len(cAutoriz))
		cCssAux := POSCSS (GetClassName(oNsuDoc), CSS_GET_NORMAL )
		cCssAux := StrTran(cCssAux,"transparent","#EEEEEE")
		cCssAux := StrTran(cCssAux,"border: none;","") // padding: 0px;
		oNsuDoc:SetCSS(cCssAux)

		@ 074, nWidth-60 SAY oSay10 PROMPT "Autorização" SIZE 057, 007 OF oPnlCC COLORS 0, 16777215 PIXEL
		oSay10:SetCSS( POSCSS (GetClassName(oSay10), CSS_LABEL_FOCAL ))

		@ 084, nWidth-60 MSGET oAutoriz VAR cAutoriz SIZE 057, 013 OF oPnlCC COLORS 0, 16777215 PIXEL PICTURE Replicate("N",len(cAutoriz))
		oAutoriz:SetCSS(cCssAux)

		@ 101, nWidth-125 SAY oSay11 PROMPT "Data" SIZE 070, 007 OF oPnlCC COLORS 0, 16777215 PIXEL
		oSay11:SetCSS( POSCSS (GetClassName(oSay11), CSS_LABEL_FOCAL ))

		@ 111, nWidth-125 MSGET oCCDataTran VAR DTOC(dCCDataTran) SIZE 060, 013 OF oPnlCC COLORS 0, 16777215 WHEN .F. PIXEL
		oCCDataTran:SetCSS(cCssAux)

		@ 101, nWidth-60 SAY oSay12 PROMPT "Parcelas" SIZE 057, 007 OF oPnlCC COLORS 0, 16777215 PIXEL
		oSay12:SetCSS( POSCSS (GetClassName(oSay12), CSS_LABEL_FOCAL ))

		@ 111, nWidth-60 MSGET oCCParcelas VAR nCCParcelas PICTURE "99" SIZE 040, 013 OF oPnlCC COLORS 0, 16777215 WHEN (cCardForma=="CC" .AND. !lWhenParc) HASBUTTON PIXEL
		oCCParcelas:SetCSS(cCssAux)

		// BOTAO CONFIRMAR
		oCCBtnOk := TButton():New( nHeight-35,;
								nWidth-nTamBut-5,;
								"&Confirmar Pagamento"+CRLF+"(ALT+C)",;
								oPnlCC	,;
								bActOK,;
								nTamBut,;
								025,;
								,,,.T.,;
								,,,{|| .T.})
		oCCBtnOk:SetCSS( POSCSS (GetClassName(oCCBtnOk), CSS_BTN_FOCAL ))

		// BOTAO CANCELAR
		oCCBtnCan := TButton():New( nHeight-35,;
								nWidth-(2*nTamBut)-10,;
								"C&ancelar Pagamento"+CRLF+"(ALT+A)",;
								oPnlCC	,;
								bActCanc,;
								nTamBut,;
								025,;
								,,,.T.,;
								,,,{|| .T.})
		oCCBtnCan:SetCSS( POSCSS (GetClassName(oCCBtnCan), CSS_BTN_ATIVO ))

		// BOTAO DESCONTOS
		oBtn3 := TButton():New( nHeight-35,;
								005,;
								"Aplicar &Descontos"+CRLF+"(ALT+D)",;
								oPnlCC	,;
								{|| STIDetDesc(cCardForma) },;
								nTamBut,;
								025,;
								,,,.T.,;
								,,,{|| .T.})
		oBtn3:SetCSS( POSCSS (GetClassName(oBtn3), CSS_BTN_NORMAL ))

	else
		oRedeAut:SetItems(aMyRede)
		oBandeira:SetItems(aMyBandei)
		oCCAdmFin:SetItems(aMyAdmFin)
		oCCListGdNeg:GoTop()
		oCCListGdNeg:SetItems({''})
		oCCBtnOk:bAction := bActOK
		oCCBtnCan:bAction := bActCanc
		oPnlCC:Show()
	endif

	bCancTela := bActCanc

	LoadValues(cForma)
	DoRefreshNeg(cForma)
	oCCListGdNeg:GoTop()
	oCCListGdNeg:SetFocus()
	oDlgPDV:Refresh()

Return .T.

//----------------------------------------------------------
// Monta tela Pix e Pagamentos digitais
//----------------------------------------------------------
Static Function STIPayPix(cForma, oPnlAdconal)

	Local oBtn3
	Local oSay1, oSay2, oSay3
	Local nWidth, nHeight
	Local nTamBut := 80
	Local nTopPnl := 0
	Local oDlgPDV := STIGetDlg()
	Local oPanelMVC
	Local bActOK := {|| ValidaTela(cForma, oPnlAdconal, cPIXAdmFin, oPnlPIX)}
	Local bActCanc := {|| oPnlPIX:Hide(), STIPayCancel(), STIClnVar(oPnlAdconal, .T.) }
	Local cDsForma := Capital(Alltrim(Posicione("SX5",1,xFilial("SX5")+'24'+cForma,"X5_DESCRI")))

	if (!STWChkTef("PD") .AND. AllTrim(cForma) == "PD") .OR. (!STWChkTef("PX") .AND. AllTrim(cForma) == "PX")
		//se não configurado TEF, tratar PIX ou PD como convenio para sair do padrão.
		STFMessage(ProcName(),"STOP","Forma de pagamento " + cForma +" não habilitada no TEF."  )
		STFShowMessage(ProcName())
		Return .F.
	endif

	aMyAdmFin := STDAdmFinan(Alltrim(cForma)) //busco adm fin da forma (funçao padrao)
	If Empty(aMyAdmFin)
		STFMessage(ProcName(),"STOP","Não há Adm.Financeira cadastrada para forma " + cForma +"."  )
		STFShowMessage(ProcName())
		Return .F.
	EndIf

	STIBtnDeActivate()
	U_SetWBtnNF(.F.)

	oPnlAdconal:nWidth += 6
	oPnlAdconal:nLeft -= 3

	nWidth := oPnlAdconal:nWidth/2
	nHeight := oPnlAdconal:nHeight/2

	If nWidth < 260 //tratamento para resolução 1024
		nTamBut := 70
	EndIf

	nPIXVlrSal := 0 //STBCalcSald("1")*(1-nPerDesc)
	nPIXVlrRec := 0 //STBCalcSald("1")*(1-nPerDesc)
	cPIXForma := cForma
	
	if oPnlPIX == Nil
		oPanelMVC := STIGetPanel()
		nTopPnl := (oPanelMVC:nHeight/4.807) + 70

		oPnlPIX := TPanel():New(nTopPnl,oPnlAdconal:nLeft-8,"",oDlgPDV,NIL,.T.,.F.,,,nWidth,nHeight,.T.,.F.)
		//oPnlPIX:Align := CONTROL_ALIGN_ALLCLIENT
		oPnlPIX:SetCSS( POSCSS (GetClassName(oPnlPIX), CSS_PANEL_CONTEXT ))

		@ 008, 007 SAY oSay1 PROMPT "Pagamento em "+cDsForma SIZE 200, 011 OF oPnlPIX COLORS 0, 16777215 PIXEL
		oSay1:SetCSS( POSCSS (GetClassName(oSay1), CSS_BREADCUMB ))

		@ 030, 007 SAY oSay2 PROMPT "Saldo a Pagar" SIZE 070, 008 OF oPnlPIX COLORS 0, 16777215 PIXEL
		oSay2:SetCSS( POSCSS (GetClassName(oSay2), CSS_LABEL_FOCAL ))

		oPIXVlrSal := TGet():New( 040, 007,{|u| iif(PCount()>0,nPIXVlrSal:=u,nPIXVlrSal)},oPnlPIX,085, 015,PesqPict("SL4","L4_VALOR"),{|| .T. },,,,,,.T.,,,{|| .T. },,,,.T.,.F.,,"oPIXVlrSal",,,,.F.,.T.)
		oPIXVlrSal:SetCSS( POSCSS (GetClassName(oPIXVlrSal), CSS_GET_FOCAL ))
		oPIXVlrSal:lCanGotFocus := .F.

		@ 030, 097 SAY oSay3 PROMPT "Valor do Pagamento" SIZE 070, 008 OF oPnlPIX COLORS 0, 16777215 PIXEL
		oSay3:SetCSS( POSCSS (GetClassName(oSay3), CSS_LABEL_FOCAL ))

		oPIXVlrRec := TGet():New( 040, 097,{|u| iif(PCount()>0,nPIXVlrRec:=u,nPIXVlrRec)},oPnlPIX,085, 015,PesqPict("SL4","L4_VALOR"),{|| ValidValor(cPIXForma) },,,,,,.T.,,,{|| .T. },,,,.F.,.F.,,"oPIXVlrRec",,,,.F.,.T.)
		oPIXVlrRec:SetCSS( POSCSS (GetClassName(oPIXVlrRec), CSS_GET_FOCAL ))

		//crio gets para compatiblidade da funçao padrao ao confirmar
		dPIXDataTran := dDataBase
		@ 001, 001 MSGET oPIXDataTran VAR dPIXDataTran SIZE 060, 013 OF oPnlPIX COLORS 0, 16777215 WHEN .F. PIXEL
		oPIXDataTran:Hide()
		nPIXParcelas := 1
		@ 001, 001 MSGET oPIXParcelas VAR nPIXParcelas SIZE 040, 013 OF oPnlPIX COLORS 0, 16777215 WHEN .F. HASBUTTON PIXEL
		oPIXParcelas:Hide()

		cPIXAdmFin := aMyAdmFin[1]
		oPIXAdmFin := TComboBox():New(001, 001, {|u| If(PCount()>0,cPIXAdmFin:=u,cPIXAdmFin)}, aMyAdmFin , 122, 016, oPnlPIX, Nil,/*bChange*/,/*bValid*/,,,.T.,,Nil,Nil,{|| .F. } )
		oPIXAdmFin:Hide()

		// BOTAO CONFIRMAR
		oPIXBtnOk := TButton():New( nHeight-35,;
								nWidth-nTamBut-5,;
								"&Confirmar Pagamento"+CRLF+"(ALT+C)",;
								oPnlPIX	,;
								bActOK,; //fazer gravação nos componentes do totvs pdv, ou preparar retorno para PE
								nTamBut,;
								025,;
								,,,.T.,;
								,,,{|| .T.})
		oPIXBtnOk:SetCSS( POSCSS (GetClassName(oPIXBtnOk), CSS_BTN_FOCAL ))

		// BOTAO CANCELAR
		oPIXBtnCan := TButton():New( nHeight-35,;
								nWidth-(2*nTamBut)-10,;
								"C&ancelar Pagamento"+CRLF+"(ALT+A)",;
								oPnlPIX	,;
								bActCanc,;
								nTamBut,;
								025,;
								,,,.T.,;
								,,,{|| .T.})
		oPIXBtnCan:SetCSS( POSCSS (GetClassName(oPIXBtnCan), CSS_BTN_ATIVO ))

		// BOTAO DESCONTOS
		oBtn3 := TButton():New( nHeight-35,;
								007,;
								"Aplicar &Descontos"+CRLF+"(ALT+D)",;
								oPnlPIX	,;
								{|| STIDetDesc(cPIXForma) },;
								nTamBut,;
								025,;
								,,,.T.,;
								,,,{|| .T.})
		oBtn3:SetCSS( POSCSS (GetClassName(oBtn3), CSS_BTN_NORMAL ))
	Else
		oPIXBtnOk:bAction := bActOK
		oPIXBtnCan:bAction := bActCanc
		oPnlPIX:Show()
	Endif

	bCancTela := bActCanc

	LoadValues(cForma)
	DoRefreshNeg(cForma)
	oPIXVlrRec:SetFocus()
	oDlgPDV:Refresh()

Return .T.

//----------------------------------------------------------
// Monta tela de Recebimento em Cheque
//----------------------------------------------------------
Static Function STIPayCheck(cForma, oPnlAdconal)

	Local oBtn3
	Local oSay1, oSay2, oSay3
	Local nWidth, nHeight
	Local nTamBut := 80
	Local oDlgPDV := STIGetDlg()
	Local bActOK := {|| VldCheck(1, nWidth, nHeight, nTamBut, oPnlAdconal) }
	Local bActCanc := {|| oPnlCH:Hide(), STIPayCancel(), STIClnVar(oPnlAdconal, .T.)}

	STIBtnDeActivate()
	U_SetWBtnNF(.F.)

	aCheques := {} //limpo o array de cheques a cada nova chamada

	//ajustando tamanho do painel
	oPnlAdconal:nWidth += 10
	oPnlAdconal:nLeft -= 3
	oPnlAdconal:nHeight += oPnlAdconal:nTop
	oPnlAdconal:nTop := 0
	nWidth := oPnlAdconal:nWidth/2
	nHeight := oPnlAdconal:nHeight/2
	If nWidth < 260 //tratamento para resolução 1024
		nTamBut := 70
	EndIf

	nCHVlrSal := 0 //STBCalcSald("1")*(1-nPerDesc)
	nCHVlrRec := 0 //STBCalcSald("1")*(1-nPerDesc)

	aSize(aNewGdNeg, 0) //deleto todas as linhas
	Aadd(aNewGdNeg, aClone(aEmpLinGd) )
	nNewGdNeg := 1

	if oPnlCH == Nil
		oPnlCH := TPanel():New( 071 ,oPnlAdconal:nLeft-8,"",oDlgPDV,NIL,.T.,.F.,,,nWidth,nHeight,.T.,.F.)
		//oPnlCH:Align := CONTROL_ALIGN_ALLCLIENT
		oPnlCH:SetCSS( POSCSS (GetClassName(oPnlCH), CSS_PANEL_CONTEXT ))

		oPnlCHAux := TPanel():New( 071 ,oPnlAdconal:nLeft-8,"",oDlgPDV,NIL,.T.,.F.,,,nWidth,nHeight,.T.,.F.)
		//oPnlCHAux:Align := CONTROL_ALIGN_ALLCLIENT
		oPnlCHAux:SetCSS( POSCSS (GetClassName(oPnlCHAux), CSS_PANEL_CONTENT ))
		oPnlCHAux:Hide()

		@ 005, 007 SAY oSay1 PROMPT "Pagamento em Cheque" SIZE 200, 011 OF oPnlCH COLORS 0, 16777215 PIXEL
		oSay1:SetCSS( POSCSS (GetClassName(oSay1), CSS_BREADCUMB ))

		@ 025, 007 SAY oSay2 PROMPT "Negociações de Pagamento do cliente" SIZE 300, 008 OF oPnlCH COLORS 0, 16777215 PIXEL
		oSay2:SetCSS( POSCSS (GetClassName(oSay2), CSS_LABEL_FOCAL ))

		//Cria listbox com as negociaçoes (para ficar no padrao totvs pdv)
		oCHListGdNeg := TListBox():Create(oPnlCH, 035, 007, Nil, {''}, nWidth-13, nHeight-107,,,,,.T.,,/*{|| LoadSelNeg(cForma) }*/)
		oCHListGdNeg:bSetGet := {|u| iif(PCount()>0,LoadSelNeg(cForma, oCHListGdNeg),) }
		oCHListGdNeg:bLDBLClick := {|| DoRefreshNeg(cForma), oCHVlrRec:SetFocus()}
		oCHListGdNeg:SetCSS( POSCSS (GetClassName(oCHListGdNeg), CSS_LISTBOX ))

		@ nHeight-68, 010 SAY oSay3 PROMPT "Saldo a Pagar" SIZE 70, 008 OF oPnlCH COLORS 0, 16777215 PIXEL
		oSay3:SetCSS( POSCSS (GetClassName(oSay3), CSS_LABEL_FOCAL ))

		oCHVlrSal := TGet():New( nHeight-58, 007,{|u| iif(PCount()>0,nCHVlrSal:=u,nCHVlrSal)},oPnlCH,85, 015,PesqPict("SL4","L4_VALOR"),{|| .T. },,,,,,.T.,,,{|| .T. },,,,.T.,.F.,,"oCHVlrSal",,,,.F.,.T.)
		oCHVlrSal:SetCSS( POSCSS (GetClassName(oCHVlrSal), CSS_GET_FOCAL ))
		oCHVlrSal:lCanGotFocus := .F.

		@ nHeight-68, 100 SAY oSay4 PROMPT "Valor do Pagamento" SIZE 70, 008 OF oPnlCH COLORS 0, 16777215 PIXEL
		oSay4:SetCSS( POSCSS (GetClassName(oSay4), CSS_LABEL_FOCAL ))

		oCHVlrRec := TGet():New( nHeight-58, 097,{|u| iif( PCount()==0,nCHVlrRec,nCHVlrRec:=u)},oPnlCH,85, 015,PesqPict("SL4","L4_VALOR"),{|| ValidValor(cForma) },,,,,,.T.,,,{|| .T. },,,,.F.,.F.,,"oCHVlrRec",,,,.F.,.T.)
		oCHVlrRec:SetCSS( POSCSS (GetClassName(oCHVlrRec), CSS_GET_FOCAL ))

		//crio gets para compatiblidade da funçao padrao ao confirmar
		dCHDataTran := dDataBase
		@ 001, 001 MSGET oCHDataTran VAR dCHDataTran SIZE 060, 013 OF oPnlCH COLORS 0, 16777215 WHEN .F. PIXEL
		oCHDataTran:Hide()
		nCHParcelas := 1
		@ 001, 001 MSGET oCHParcelas VAR nCHParcelas SIZE 040, 013 OF oPnlCH COLORS 0, 16777215 WHEN .F. HASBUTTON PIXEL
		oCHParcelas:Hide()

		// BOTAO CONFIRMAR
		oCHBtnOk := TButton():New( nHeight-35,;
								nWidth-nTamBut-5,;
								"&Confirmar Pagamento"+CRLF+"(ALT+C)",;
								oPnlCH	,;
								bActOK,;
								nTamBut,;
								025,;
								,,,.T.,;
								,,,{|| .T.})
		oCHBtnOk:SetCSS( POSCSS (GetClassName(oCHBtnOk), CSS_BTN_FOCAL ))

		// BOTAO CANCELAR
		oCHBtnCan := TButton():New( nHeight-35,;
								nWidth-(2*nTamBut)-10,;
								"C&ancelar Pagamento"+CRLF+"(ALT+A)",;
								oPnlCH	,;
								bActCanc,;
								nTamBut,;
								025,;
								,,,.T.,;
								,,,{|| .T.})
		oCHBtnCan:SetCSS( POSCSS (GetClassName(oCHBtnCan), CSS_BTN_ATIVO ))

		// BOTAO DESCONTOS
		oBtn3 := TButton():New( nHeight-35,;
								007,;
								"Aplicar &Descontos"+CRLF+"(ALT+D)",;
								oPnlCH	,;
								{|| STIDetDesc(cForma) },;
								nTamBut,;
								025,;
								,,,.T.,;
								,,,{|| .T.})
		oBtn3:SetCSS( POSCSS (GetClassName(oBtn3), CSS_BTN_NORMAL ))
	
	Else
		oCHListGdNeg:GoTop()
		oCHListGdNeg:SetItems({''})
		oCHBtnOk:bAction := bActOK
		oCHBtnCan:bAction := bActCanc
		oPnlCH:Show()
	EndIf

	LoadValues(cForma)
	DoRefreshNeg(cForma)

	If Empty(oCHListGdNeg:GetSelText()) //se nao achou negociação, cancelo a tela
		STFMessage(ProcName(),"STOP","Cliente não habilitado para essa forma de pagamento!" )
		STFShowMessage(ProcName())
		oPnlCH:Hide()
		Return .F.
	Else
		oCHListGdNeg:GoTop()
		oCHListGdNeg:SetFocus()
	EndIf

	bCancTela := bActCanc

Return .T.

//--------------------------------------------------------------------
// Monta tela de Recebimento com Credito (Vale Haver e Req. pre-paga)
//--------------------------------------------------------------------
Static Function STIPayCredit(cForma, oPnlAdconal)

	Local oBtn3
	Local oSay1, oSay2, oSay3
	Local nWidth, nHeight
	Local nTamBut := 80
	Local oDlgPDV := STIGetDlg()
	Local bActOK := {|| ValidaTela(cForma, oPnlAdconal,,oPnlCR)}
	Local bActCanc := {|| oPnlCR:Hide(), STIPayCancel(), STIClnVar(oPnlAdconal, .T.)}
	
	Local oCliModel 	:= STDGCliModel() 				// Model do Cliente
	Local cCliente  	:= oCliModel:GetValue("SA1MASTER","A1_COD")
	Local cLojaCli  	:= oCliModel:GetValue("SA1MASTER","A1_LOJA")
	Local cCliPadr		:= SuperGetMv("MV_CLIPAD") 		// Cliente padrao
	Local cLojaPad		:= SuperGetMV("MV_LOJAPAD") 	// Loja padrao
	Local lBlqCons		:= SuperGetMV("MV_XCRCLIP",,.F.) 	// Habilita bloqueio de CREDITO para cliente padrão (default .F.)
	Local bValidBusca	:= {|| FindCredCl(cCliente,cLojaCli,cCRBusca)}

	STIBtnDeActivate()
	U_SetWBtnNF(.F.)

	//ajustando tamanho do painel
	oPnlAdconal:nWidth += 10
	oPnlAdconal:nLeft -= 3
	oPnlAdconal:nHeight += oPnlAdconal:nTop
	oPnlAdconal:nTop := 0
	nWidth := oPnlAdconal:nWidth/2
	nHeight := oPnlAdconal:nHeight/2
	If nWidth < 260 //tratamento para resolução 1024
		nTamBut := 70
	EndIf

	nCRVlrSal := 0 //STBCalcSald("1")*(1-nPerDesc)
	nCRVlrRec := 0 //STBCalcSald("1")*(1-nPerDesc)

	if oPnlCR == Nil
		oPnlCR := TPanel():New( 071 ,oPnlAdconal:nLeft-8,"",oDlgPDV,NIL,.T.,.F.,,,nWidth,nHeight,.T.,.F.)
		//oPnlCR:Align := CONTROL_ALIGN_ALLCLIENT
		oPnlCR:SetCSS( POSCSS (GetClassName(oPnlCR), CSS_PANEL_CONTEXT ))

		@ 005, 007 SAY oSay1 PROMPT "Pagamento com Crédito" SIZE 200, 011 OF oPnlCR COLORS 0, 16777215 PIXEL
		oSay1:SetCSS( POSCSS (GetClassName(oSay1), CSS_BREADCUMB ))

		@ 025, 007 SAY oSay2 PROMPT "Cód. Barras / Núm. Título" SIZE 300, 008 OF oPnlCR COLORS 0, 16777215 PIXEL
		oSay2:SetCSS( POSCSS (GetClassName(oSay2), CSS_LABEL_FOCAL ))

		oCRBusca := TGet():New(035,007,{|u| iif( PCount()==0,cCRBusca,cCRBusca:=u)},oPnlCR,180,013,"!@",bValidBusca,,,,,,.T.,,,{|| .T.},,,,.F.,.F.,,"oCRBusca",,,,.F.,.T.)
		oCRBusca:SetCSS( POSCSS (GetClassName(oCRBusca), CSS_GET_FOCAL ))

		@ 035, nWidth-100 BITMAP oSemaforo RESOURCE "FRTOFFLINE" NOBORDER SIZE 016, 016 OF oPnlCR ADJUST PIXEL
		oSemaforo:ReadClientCoors(.T.,.T.)
		@ 038, nWidth-080 SAY oSayConn PROMPT cSayConn OF oPnlCR Color CLR_BLACK PIXEL
		oSayConn:SetCSS( POSCSS (GetClassName(oSayConn), CSS_LABEL_FOCAL ))

		//Cria listbox com as negociaçoes (para ficar no padrao totvs pdv)
		oCRListGdNeg := TListBox():Create(oPnlCR, 055, 007, Nil, {''}, nWidth-13, nHeight-127,,,,,.T.,,/*{|| LoadSelNeg(cForma) }*/)
		oCRListGdNeg:bSetGet := {|u| iif(PCount()>0,LoadSelNeg(cForma, oCRListGdNeg),) } //bloco de código que será executado na mudança do item selecionado
		oCRListGdNeg:bLDBLClick := {|| DoRefreshNeg(cForma), oCRVlrRec:SetFocus()} //bloco de código que será executado quando clicar duas vezes, com o botão esquerdo do mouse, sobre o objeto
		oCRListGdNeg:SetCSS( POSCSS (GetClassName(oCRListGdNeg), CSS_LISTBOX ))

		@ nHeight-68, 010 SAY oSay3 PROMPT "Saldo a Pagar" SIZE 70, 008 OF oPnlCR COLORS 0, 16777215 PIXEL
		oSay3:SetCSS( POSCSS (GetClassName(oSay3), CSS_LABEL_FOCAL ))

		oCRVlrSal := TGet():New( nHeight-58, 007,{|u| iif(PCount()>0,nCRVlrSal:=u,nCRVlrSal)},oPnlCR,85, 015,PesqPict("SL4","L4_VALOR"),{|| .T. },,,,,,.T.,,,{|| .T. },,,,.T.,.F.,,"oCRVlrSal",,,,.F.,.T.)
		oCRVlrSal:SetCSS( POSCSS (GetClassName(oCRVlrSal), CSS_GET_FOCAL ))
		oCRVlrSal:lCanGotFocus := .F.

		@ nHeight-68, 100 SAY oSay4 PROMPT "Valor do Pagamento" SIZE 70, 008 OF oPnlCR COLORS 0, 16777215 PIXEL
		oSay4:SetCSS( POSCSS (GetClassName(oSay4), CSS_LABEL_FOCAL ))

		oCRVlrRec := TGet():New( nHeight-58, 097,{|u| iif(PCount()>0,nCRVlrRec:=u,nCRVlrRec)},oPnlCR,85, 015,PesqPict("SL4","L4_VALOR"),{|| .T. },,,,,,.T.,,,{|| .T. },,,,.T.,.F.,,"oCRVlrRec",,,,.F.,.T.)
		oCRVlrRec:SetCSS( POSCSS (GetClassName(oCRVlrRec), CSS_GET_FOCAL ))

		// BOTAO CONFIRMAR
		oCRBtnOk := TButton():New( nHeight-35,;
								nWidth-nTamBut-5,;
								"&Confirmar Pagamento"+CRLF+"(ALT+C)",;
								oPnlCR	,;
								bActOK,;
								nTamBut,;
								025,;
								,,,.T.,;
								,,,{|| .T.})
		oCRBtnOk:SetCSS( POSCSS (GetClassName(oCRBtnOk), CSS_BTN_FOCAL ))

		// BOTAO CANCELAR
		oCRBtnCan := TButton():New( nHeight-35,;
								nWidth-(2*nTamBut)-10,;
								"C&ancelar Pagamento"+CRLF+"(ALT+A)",;
								oPnlCR	,;
								bActCanc,;
								nTamBut,;
								025,;
								,,,.T.,;
								,,,{|| .T.})
		oCRBtnCan:SetCSS( POSCSS (GetClassName(oCRBtnCan), CSS_BTN_ATIVO ))

		// BOTAO DESCONTOS
		oBtn3 := TButton():New( nHeight-35,;
								007,;
								"Aplicar &Descontos"+CRLF+"(ALT+D)",;
								oPnlCR	,;
								{|| STIDetDesc(cForma) },;
								nTamBut,;
								025,;
								,,,.T.,;
								,,,{|| .T.})
		oBtn3:SetCSS( POSCSS (GetClassName(oBtn3), CSS_BTN_NORMAL ))

	else
		oCRListGdNeg:GoTop()
		oCRListGdNeg:SetItems({''})
		oCRBtnOk:bAction := bActOK
		oCRBtnCan:bAction := bActCanc
		oCRBusca:bValid := bValidBusca
		oPnlCR:Show()
	endif

	// - Parametro MV_USACRED habilitado
	//Substr(SuperGetMV("MV_USACRED"),2,1) == "S"

	U44->(DbSetOrder(1)) //U44_FILIAL+U44_FORMPG+U44_CONDPG
	SX5->(DbSetOrder(1)) //X5_FILIAL+X5_TABELA+X5_CHAVE
	
	If !SX5->(DbSeek(xFilial("SX5")+"24"+"NB ")) 
		STFMessage(ProcName(),"STOP","Forma de pagamento 'NB - Crédito Cliente (NCC/RA)' não cadastrada na tabela 24 (SX5)." )
		STFShowMessage(ProcName())
		Return .F.

	ElseIf !U44->(DbSeek(xFilial("U44")+"NB "))
		STFMessage(ProcName(),"STOP","Forma de pagamento 'NB - Crédito Cliente (NCC/RA)' não cadastrada nas Negociações de Pagamento (U44)." )
		STFShowMessage(ProcName())
		Return .F.
	
	elseif U44->U44_PADRAO <> 'S'
		STFMessage(ProcName(),"STOP","Forma de pagamento 'NB - Crédito Cliente (NCC/RA)' deve estar configurada como padrão. (U44)." )
		STFShowMessage(ProcName())
		Return .F.

	ElseIf lBlqCons .and. (cCliente + cLojaCli == cCliPadr + cLojaPad)
		STFMessage(ProcName(),"STOP","Cliente padrão não habilitado para essa forma de pagamento." )
		STFShowMessage(ProcName())
		Return .F.

	Else
		LoadValues(cForma)
		DoRefreshNeg(cForma)
		AtuConnRet()
		oCRBusca:SetFocus()

		bCancTela := bActCanc
	EndIf

Return .T.

//--------------------------------------------------------------
// Monta grid de seleção das negociações pagamento
//--------------------------------------------------------------
Static Function DoGdPgtos(oPanel, nTop, nLeft, nWidth, nHeigth)

	Local oNewGD
	Local aHeaderEx 	:= {}
	Local aColsEx 		:= {}
	Local aFieldFill 	:= {}
	Local aAlterFields 	:= {}
	Local nLinMax       := 999  //quantidade delinha na getdados

	//{"SALDO","U44_DESCRI","U44_FORMPG","U44_CONDPG","U25_ADMFIN","U25_EMITEN","EXCECAO","TOTALNEG","ORIGINAL","DESCONTO"}

	aAdd(aHeaderEx, {"Saldo","SALDO",PesqPict("SLR","LR_VLRITEM"),TamSX3("LR_VLRITEM")[1],TamSX3("LR_VLRITEM")[2],"","€€€€€€€€€€€€€€","N","","","",""})
	aAdd(aFieldFill, 0)

	aadd(aHeaderEx, U_UAHEADER("U44_DESCRI") )
	aAdd(aFieldFill, "")

	aadd(aHeaderEx, U_UAHEADER("U44_FORMPG") )
	aAdd(aFieldFill, "")

	aadd(aHeaderEx, U_UAHEADER("U44_CONDPG") )
	aAdd(aFieldFill, "")

	aadd(aHeaderEx, U_UAHEADER("U25_ADMFIN") )
	aAdd(aFieldFill, "")

	aadd(aHeaderEx, U_UAHEADER("U25_EMITEN") )
	aAdd(aFieldFill, "")

	aAdd(aHeaderEx,{'Exceção?','EXCECAO','@BMP',2,0,'','€€€€€€€€€€€€€€','C','','','',''})
	aAdd(aFieldFill, "LBNO")

	aAdd(aHeaderEx, {"Tot. Negociação","TOTALNEG",PesqPict("SLR","LR_VLRITEM"),TamSX3("LR_VLRITEM")[1],TamSX3("LR_VLRITEM")[2],"","€€€€€€€€€€€€€€","N","","","",""})
	aAdd(aFieldFill, 0)

	aAdd(aHeaderEx, {"Vlr. Original","ORIGINAL",PesqPict("SLR","LR_VLRITEM"),TamSX3("LR_VLRITEM")[1],TamSX3("LR_VLRITEM")[2],"","€€€€€€€€€€€€€€","N","","","",""})
	aAdd(aFieldFill, 0)

	aAdd(aHeaderEx, {"Desconto","DESCONTO",PesqPict("SLR","LR_VALDESC"),TamSX3("LR_VALDESC")[1],TamSX3("LR_VALDESC")[2],"","€€€€€€€€€€€€€€","N","","","",""})
	aAdd(aFieldFill, 0)

	aadd(aFieldFill, .F.) //deletado
	aAdd(aColsEx, aFieldFill)

	oNewGD := MsNewGetDados():New( nTop, nLeft, nHeigth, nWidth, , "AllwaysTrue", "AllwaysTrue", "AllwaysTrue", aAlterFields, , nLinMax,, "", "AllwaysTrue", oPanel, aHeaderEx, aColsEx)
	//oNewGD:oBrowse:SetCSS( POSCSS("TGRID", CSS_BROWSE) ) //CSS do totvs pdv
	//oNewGD:oBrowse:nScrollType := 0 // mudo o tipo do scroll do grid para barra de rolagem

Return oNewGD

//--------------------------------------------------------------
// Função para carregar os valores nas variaveis da tela
//--------------------------------------------------------------
Static Function LoadValues(cForma)

	Local oMdl 		:= STISetMdlPay()			 //Get no objeto oModel: Resumo do Pagamento
	Local oModel	:= oMdl:GetModel('PARCELAS') //Get no model parcelas
	Local nI		:= 0		//Variavel de Loop
	Local nTotal	:= 0		//Soma os totais
	Local nPosMdl	:= 0		//Guarda a Posicao do model para restaurar ao final
	Local nVlrFor	:= 0		//Valor da forma autal ja inserido no pagamento
	Local lImpOrc 	:= ExistFunc("STBGFormImp") .And. STBIsImpOrc()
	Local cFPConv := SuperGetMv("TP_FPGCONV",,"")

	//carregar o total ja recebido
	If ValType(oModel) == "O"

		nPosMdl := oModel:GetLine() //:nLine
		For nI := 1 To oModel:Length()
			oModel:GoLine(nI)
			If !Empty(oModel:GetValue('L4_FORMA'))
			  	nTotal += oModel:GetValue('L4_VALOR')
			  	If Alltrim(cForma) $ oModel:GetValue('L4_FORMA')
					nVlrFor += oModel:GetValue('L4_VALOR') - oModel:GetValue('L4_TROCO')
				EndIf
			EndIf
		Next nI
		oModel:GoLine(nPosMdl)

	EndIf

	//se é importacao e nao colocou nenhuma forma, forço limpar formas para evitar erro.
	if lImpOrc .AND. nTotal <= 0
		STDSetNCCs("1",{}) //limpo pois estava dando errorlog
		STIZeraPay(.T.,.F.)
		nTotRecebi := 0
	endif

	//carregar grid de negociação e valores dos gets
	If Len(aRecebtos) <= 0 .or. nTotal <= 0
		STFMessage(ProcName(),"STOP","Carregando as Negociações de Pagamento... Aguarde...")
		STFShowMessage(ProcName())
		CarregaRecb(cForma)
		STFCleanInterfaceMessage()
	EndIf

	If Len(aRecebtos) > 0
		AtuARecebtos() //validacao de campo -> CAMPO "RECEBIDO"
		RefreshGridPg(cForma) //preenche vetor com dados: aItensGrid
		aItem := GetSelected(cForma) //função que retorna linha do acols selecionada, e ajusta a variável nAtAreceb
	EndIf

	If Alltrim(cForma) $ 'R$'
		If Len(aItensGrid) > 0

			//verifica se ja existe um pagamento incluido de dinheiro
			If nAtaReceb > 0 .and. aRecebtos[nAtaReceb][9] > 0
				aRecebtos[nAtaReceb][9]  := 0
				aRecebtos[nAtaReceb][16] := 0
				AtuARecebtos() //validacao de campo -> CAMPO "RECEBIDO"
				RefreshGridPg(cForma) //preenche vetor com dados: aItensGrid
			EndIf

			LoadSelNeg(cForma)
	    EndIf
	ElseIf AllTrim(cForma) $ 'NP|CT|'+cFPConv
		If Len(aItensGrid) > 0
			DoFiltrarNeg(aNewGdNeg,,oNPListGdNeg,cForma) //atualiza o aCols
			LoadSelNeg(cForma, oNPListGdNeg)
		EndIf

	ElseIf AllTrim(cForma) $ 'PX|PD' //Pix e Pagamento Digital
		If Len(aItensGrid) > 0
			LoadSelNeg(cForma)
	    EndIf
	ElseIf AllTrim(cForma) $ 'NB' //NB - Nota de Crédito Cód. Barras
		If Len(aItensGrid) > 0
			LoadSelNeg(cForma, oCRListGdNeg)
	    EndIf
	ElseIf AllTrim(cForma) $ 'CC|CD'
		If Len(aItensGrid) > 0
			DoFiltrarNeg(aNewGdNeg,,oCCListGdNeg,cForma) //atualiza o aCols
			LoadSelNeg(cForma, oCCListGdNeg)
		EndIf
	ElseIf AllTrim(cForma) $ 'CF'
		If Len(aItensGrid) > 0
			DoFiltrarNeg(aNewGdNeg,,oCFListGdNeg,cForma) //atualiza o aCols
			LoadSelNeg(cForma, oCFListGdNeg)
		EndIf
	ElseIf AllTrim(cForma) $ 'CH'
		If Len(aItensGrid) > 0
			DoFiltrarNeg(aNewGdNeg,,oCHListGdNeg,cForma) //atualiza o aCols
			LoadSelNeg(cForma, oCHListGdNeg)
		EndIf
	EndIf

Return

//---------------------------------------------------------------
// Cancela a forma de pagamento de dinheiro
//---------------------------------------------------------------
Static Function CancelCash()

	Local oMdl 		:= STISetMdlPay()			 //Get no objeto oModel: Resumo do Pagamento
	Local oModel	:= oMdl:GetModel('PARCELAS') //Get no model parcelas
	Local nI		:= 0		//Variavel de Loop
	Local nTotal	:= 0		//Soma os totais
	Local nPosMdl	:= 0		//Guarda a Posicao do model para restaurar ao final
	Local nVlrFor	:= 0		//Valor da forma autal ja inserido no pagamento
	Local cForma	:= "R$"

	//carregar o total ja recebido
	If ValType(oModel) == "O"

		nPosMdl := oModel:GetLine() //:nLine
		For nI := 1 To oModel:Length()
			oModel:GoLine(nI)
			If !Empty(oModel:GetValue('L4_FORMA'))
				nTotal += oModel:GetValue('L4_VALOR')
				If Alltrim(cForma) $ oModel:GetValue('L4_FORMA')
					nVlrFor += oModel:GetValue('L4_VALOR') - oModel:GetValue('L4_TROCO')
				EndIf
			EndIf
		Next nI
		oModel:GoLine(nPosMdl)

	EndIf

	if len(aRecebtos) > 0
		If Round(nVlrFor,2) > Round(aRecebtos[nAtaReceb][11],2)
			aRecebtos[nAtaReceb][9]  := Round(aRecebtos[nAtaReceb][11],2)
			aRecebtos[nAtaReceb][16] := Round(nVlrFor - aRecebtos[nAtaReceb][11],2)
		Else
			aRecebtos[nAtaReceb][9]  := Round(nVlrFor,2)
		EndIf
	endif
	AtuARecebtos() //validacao de campo -> CAMPO "RECEBIDO"

Return

//---------------------------------------------------------------
// Função atualiza o acols das negociações pelo aItensGrid
//---------------------------------------------------------------
Static Function DoFiltrarNeg(aColsEx, lRefresh, oListGdNeg, cForma)

	Local aLinTmp := {}
	Local nX
	Default lRefresh := .T.

	aSize(aColsEx, 0) //deleto todas as linhas

	//fazer loop
	If len(aItensGrid) > 0
		for nX := 1 to len(aItensGrid)
			aLinTmp := aClone(aItensGrid[nX])
			aadd(aLinTmp, .F.)
			aadd(aColsEx, aClone(aLinTmp))
		next nX
	EndIf

	If len(aColsEx) == 0
		Aadd(aColsEx, aClone(aEmpLinGd) )
	EndIf

	If lRefresh
		DoRefreshNeg(cForma)
	Endif

	AtuaListNeg(oListGdNeg)

Return .T.

//---------------------------------------------------------------
// Função que faz a atualização do listbox das negociações
//---------------------------------------------------------------
Static Function AtuaListNeg(oListGdNeg)

	Local nX := 0
	Local aListGdNeg := {}

	aListGdNeg := {}
	For nX:=1 to Len(aNewGdNeg)
		//R$ 00,00 / CARTAO CREDITO AVISTA / CC / 205
		aadd(aListGdNeg,;
						'R$ '+Alltrim(Transform(aNewGdNeg[nX][aScan(aFieldGrid,{|y| AllTrim(y)=="SALDO"})],PesqPict("SL1","L1_VLRLIQ")))+' / '+;
						AllTrim(aNewGdNeg[nX][aScan(aFieldGrid,{|y| AllTrim(y)=="U44_DESCRI"})])+' / '+;
						AllTrim(aNewGdNeg[nX][aScan(aFieldGrid,{|y| AllTrim(y)=="U44_FORMPG"})])+' / '+;
						AllTrim(aNewGdNeg[nX][aScan(aFieldGrid,{|y| AllTrim(y)=="U44_CONDPG"})]);
						)
	Next nX
	oListGdNeg:SetItems(aListGdNeg)

	oListGdNeg:Select(nNewGdNeg)
	oListGdNeg:nAt := nNewGdNeg

Return

//--------------------------------------------------------------
// Função para carregar dados da negociação de pagamento selecionada
//--------------------------------------------------------------
Static Function LoadSelNeg(cForma, oListGdNeg)

	Local aParc := {}
	Local aItem := {}
	Local nVlrSal := 0 
	Local nVlrRec := 0 
	Local dDataTran	:= CtoD("")
	Local nParcelas	:= 1
	Local cFPConv := SuperGetMv("TP_FPGCONV",,"")
	Local cCondU44 := ""
	Local cAdmFinU44 := ""
	Local nX := 0

	If !(oListGdNeg == Nil) .and. oListGdNeg:nAt > 0 .and. oListGdNeg:nAt <> nNewGdNeg
		nNewGdNeg := oListGdNeg:nAt //oListGdNeg:GetPos()
	EndIf

	//quando selecionar a negociação na grid, atualizar valores dos gets
	aItem := GetSelected(cForma) //nAtaReceb
	If Len(aItem)>0

		nVlrSal := round(aItem[aScan(aFieldGrid,{|y| AllTrim(y)=="SALDO"})],2)
	    nVlrRec := round(nVlrSal,2)

		cCondU44 := aItem[aScan(aFieldGrid,{|y| AllTrim(y)=="U44_CONDPG"})]
	    aParc := condicao(nVlrRec,cCondU44,0.00,dDatabase,0.00,{},,0)

	    If Len(aParc) > 0
		    dDataTran := aParc[01][01]
		    nParcelas := Len(aParc)
	    Else
	    	If Alltrim(cForma) = 'CC'
	    		dDataTran := dDataBase + Iif(ValType(SuperGetMV("MV_LJINTER",Nil,'')) <> 'N',30,SuperGetMV("MV_LJINTER"))
			ElseIf Alltrim(cForma) = 'CD'
				dDataTran := dDataBase
			EndIf
	    EndIf

	    If Alltrim(cForma) = 'NB' .and. aNCCsCli <> Nil .and. oCRListGdNeg <> Nil .and. Len(aNCCsCli)>=oCRListGdNeg:nAt .and. !Empty(oCRListGdNeg:GetSelText())
	    	nVlrRec := aNCCsCli[oCRListGdNeg:nAt][2]
	    EndIf

		if Alltrim(cForma) = 'R$'
			nDINVlrRec := nVlrRec
			nDINVlrSal := nVlrSal
		ElseIf Alltrim(cForma) $ 'CC/CD'
			nCCVlrRec := nVlrRec
			nCCVlrSal := nVlrSal
			dCCDataTran := dDataTran
			nCCParcelas := nParcelas
		ElseIf Alltrim(cForma) = 'CF'
	    	nVlrRec := 0
			nCFVlrRec := nVlrRec
			nCFVlrSal := nVlrSal
			dCFDataTran := dDataTran
			nCFParcelas := nParcelas
		ElseIf Alltrim(cForma) $ 'NP|CT|'+cFPConv
	    	nVlrRec := nVlrRec
			nNPVlrRec := nVlrRec
			nNPVlrSal := nVlrSal
			dNPDataTran := dDataTran
			nNPParcelas := nParcelas
			if U44->(FieldPos("U44_ADMFIN")) .AND. Alltrim(cForma) == "CT"
				cAdmFinU44 := Posicione("U44",1,xFilial("U44") + PadR(cForma,TamSx3("U44_FORMPG")[1]) + cCondU44, "U44_ADMFIN")
				oNPAdmFin:lReadOnly := .F.
				if !empty(cAdmFinU44)
					nX := aScan(aMyAdmFin, {|x| SubStr(x,1,TamSx3("AE_COD")[1]) == cAdmFinU44 })
					oNPAdmFin:Select(nX)
					oNPAdmFin:lReadOnly := .T.
				endif
			endif
		Elseif Alltrim(cForma) $ 'PX|PD'
			nPIXVlrRec := nVlrRec
			nPIXVlrSal := nVlrSal
			dPIXDataTran := dDataTran
			nPIXParcelas := nParcelas
		ElseIf Alltrim(cForma) $ 'CH'
			nCHVlrRec := nVlrRec
			nCHVlrSal := nVlrSal
			dCHDataTran := dDataTran
			nCHParcelas := nParcelas
		ElseIf Alltrim(cForma) $ 'NB'
			nCRVlrRec := nVlrRec
			nCRVlrSal := nVlrSal
		EndIf
		
		DoRefreshNeg(cForma)

	EndIf

Return

//---------------------------------------------------------------
// Faz Refresh da tela
//---------------------------------------------------------------
Static Function DoRefreshNeg(cForma)

	Local cFPConv := SuperGetMv("TP_FPGCONV",,"")

	If Alltrim(cForma) $ 'R$'
		If oDINVlrRec <> Nil
			oDINVlrRec:Refresh()
		EndIf
		If oDINVlrSal <> Nil
			oDINVlrSal:Refresh()
		EndIf
	endif

	If Alltrim(cForma) $ 'PX|PD'
		If oPIXVlrRec <> Nil
			oPIXVlrRec:Refresh()
		EndIf
		If oPIXVlrSal <> Nil
			oPIXVlrSal:Refresh()
		EndIf
		If oPIXDataTran <> Nil
			oPIXDataTran:Refresh()
		EndIf
		If oPIXParcelas <> Nil
			oPIXParcelas:Refresh()
		EndIf
	endif

	If Alltrim(cForma) $ 'CC/CD'
		If ValType(oCCListGdNeg) == "O"
			oCCListGdNeg:Refresh()
		EndIf
		If oCCVlrRec <> Nil
			oCCVlrRec:Refresh()
		EndIf
		If oCCVlrSal <> Nil
			oCCVlrSal:Refresh()
		EndIf
		If oCCDataTran <> Nil
			oCCDataTran:Refresh()
		EndIf
		If oCCParcelas <> Nil
			oCCParcelas:Refresh()
		EndIf
	endif

	If Alltrim(cForma) $ 'CF'
		If ValType(oCFListGdNeg) == "O"
			oCFListGdNeg:Refresh()
		EndIf
		If oCFVlrRec <> Nil
			oCFVlrRec:Refresh()
		EndIf
		If oCFVlrSal <> Nil
			oCFVlrSal:Refresh()
		EndIf
		If oCFDataTran <> Nil
			oCFDataTran:Refresh()
		EndIf
		If oCFParcelas <> Nil
			oCFParcelas:Refresh()
		EndIf
	endif

	If Alltrim(cForma) $ 'NP|CT|'+cFPConv
		If ValType(oNPListGdNeg) == "O"
			oNPListGdNeg:Refresh()
		EndIf
		If oNPVlrRec <> Nil
			oNPVlrRec:Refresh()
		EndIf
		If oNPVlrSal <> Nil
			oNPVlrSal:Refresh()
		EndIf
		If oNPAdmFin <> Nil
			oNPAdmFin:Refresh()
		EndIf
		If oNPDataTran <> Nil
			oNPDataTran:Refresh()
		EndIf
		If oNPParcelas <> Nil
			oNPParcelas:Refresh()
		EndIf
	endif

	If Alltrim(cForma) $ 'CH'
		If ValType(oCHListGdNeg) == "O"
			oCHListGdNeg:Refresh()
		EndIf
		If oCHVlrRec <> Nil
			oCHVlrRec:Refresh()
		EndIf
		If oCHVlrSal <> Nil
			oCHVlrSal:Refresh()
		EndIf
		If oCHDataTran <> Nil
			oCHDataTran:Refresh()
		EndIf
		If oCHParcelas <> Nil
			oCHParcelas:Refresh()
		EndIf
	endif

	If Alltrim(cForma) $ 'NB'
		If ValType(oCRListGdNeg) == "O"
			oCRListGdNeg:Refresh()
		EndIf
		If oCRVlrRec <> Nil
			oCRVlrRec:Refresh()
		EndIf
		If oCRVlrSal <> Nil
			oCRVlrSal:Refresh()
		EndIf
	endif

Return

//--------------------------------------------------------------
// Validação do campo valor da forma de pagamento
//--------------------------------------------------------------
Static Function ValidValor(cForma)

	Local lRet := .T.

Return lRet

//--------------------------------------------------------------
// busca as MDE relacionadas com a adm financeira.
// nTipo: 1=Retorna as Redes;2=Retorna as Bandeiras;3=Adm Encontrada
//--------------------------------------------------------------
Static Function GetMDEAdm(nTipo, aAdm, cRede, cBand)

	Local aArea := GetArea()
	Local xRet  := {}
	Local nX
	Local nTamCdAE := TamSX3("AE_COD")[1]
	Local nTamCdMDE := TamSX3("MDE_CODIGO")[1]
	Local cCodMDE
	Default cRede := ""
	Default cBand := ""

	If nTipo <> 3
		aadd(xRet, Space(nTamCdMDE))
	Else
		xRet := 1
	EndIf
	cRede := SubStr(cRede,1,nTamCdMDE)
	cBand := SubStr(cBand,1,nTamCdMDE)

	DbSelectArea("SAE")
	SAE->(DbSetOrder(1))
	For nX := 1 to len(aAdm)
		SAE->(DbSeek(xFilial("SAE")+ SubStr(aAdm[nX],1,nTamCdAE) ))
		If nTipo==1 .AND. !Empty(SAE->AE_REDEAUT)
			cCodMDE := Posicione("MDE",1,xFilial("MDE")+SAE->AE_REDEAUT,"MDE_CODIGO")
			If !Empty(cCodMDE) .AND. aScan(xRet, {|x| SubStr(x,1,nTamCdMDE)==cCodMDE }) == 0
				aadd(xRet, MDE->MDE_CODIGO + "- " + MDE->MDE_DESC)
			EndIf
		EndIf
		If nTipo==2 .AND. !Empty(cRede) .AND. SAE->AE_REDEAUT==cRede .AND. !Empty(SAE->AE_ADMCART)
			cCodMDE := Posicione("MDE",1,xFilial("MDE")+SAE->AE_ADMCART,"MDE_CODIGO")
			If !Empty(cCodMDE) .AND. aScan(xRet, {|x| SubStr(x,1,nTamCdMDE)==cCodMDE }) == 0
				aadd(xRet, MDE->MDE_CODIGO + "- " + MDE->MDE_DESC)
			EndIf
		EndIf
		If nTipo==3 .AND. !Empty(cRede) .AND. !Empty(cBand) .AND. SAE->AE_REDEAUT==cRede .AND. SAE->AE_ADMCART==cBand
			xRet := nX
			EXIT
		EndIf
	next nX

	//ordenando por codigo
	If nTipo==1 .OR. nTipo==2
		aSort(xRet)
	EndIf

	RestArea(aArea)

Return xRet

//--------------------------------------------------------------
// Validação da Tela de forma de pagamento
//--------------------------------------------------------------
Static Function ValidaTela(cForma, oPnlAdconal, cAdmFin, oPnlForm)

	Local nVlrRec := 0
	Local nVlrSal := 0
	Local lRet  := .T.
	Local aArea	:= GetArea()	// Salva area
	Local aSaveLines  := FWSaveRows() // Array de linhas salvas
	Local oMdl 		  := STISetMdlPay()	//Get no objeto oModel: Resumo do Pagamento
	Local oModelParce := oMdl:GetModel('PARCELAS') //Get no model parcelas
	Local oModelCesta := STDGPBModel()
	Local nPosMdl	  := 0		//Guarda a Posicao do model para restaurar ao final
	Local aParam 		:= {}	  						// Array de parametros

	Local nI := 0, nY := 0, nX := 0
	Local nDescItem := 0, nVrUnItem := 0
	Local cItem := "", cProduto := ""
	Local _nPercRec := 0, _nPercTot := 0, _lTDescon := .F.
	Local lPgTudo := .F. //pagou com o valor do saldo ou com valor maior que o saldo
	Local cTypeDesc := "V" //-- Tipo do desconto. P - Percentual , V - Valor
	Local cTime := "D" //-- Configuração se desconto antes ou depois de registrar o item. A - Antes , D - Depois
	Local lItemFiscal := .F.
	Local nPosPrd := 0
	Local aProdutos := {}

	Local lContTef
	Local cCondPg := "", nVrReceb := 0
	Local aL4Custom := {}
	Local nSldAntes := STBCalcSald("1")
	Local lFinVendaAut	:= SuperGetMv('MV_LJFCVDA',,1) == 1 //Se finaliza venda automaticamente caso saldo esteja zerado

	Local oMdlChq
	Local aRetChq := {}

	Local oMdlNCC       := Nil //Model do cash
	Local oListBox      := STIGetLstB() //Objeto list box da tela principal do pagamento
	Local oTotal  		:= STFGetTot() // Recebe o Objeto totalizador
	Local aNCCsUsadas   := STDGetNCCs("1")
	Local nNCCsUsadas   := STDGetNCCs("2")
	Local nPosNCC       := 0
	Local nValNCC       := 0
	Local cPrefixo      := ""
	Local cNum          := ""
	Local nRecNCC		:= 0
	Local nValorUsado   := 0
	Local nTotalVend	:= 0 // Valor total da venda
	Local cFPConv := SuperGetMv("TP_FPGCONV",,"")
	Local nTPCompNCC    := SuperGetMV("MV_LJCPNCC",,1)//Sobra compensacao de NCC/RA: 1 (Inclusão de novo título) 2 (Alteração do saldo) 3 (Baixa total da NCC) 4 (Saldo da NCC como troco)

	/*/ MV_XATUPRC - tipo de negociação no Totvs PDV: DESCONTO ou PREÇO UNITÁRIO
		.T. - Trabalha com preço maior que o preço de tabela (não tem desconto, ajuste preço unitário)
		.F. - Trabalha com desconto no preço de tabela (não ajusta preço unitário, trabalha com desconto)
	/*/
	Local lAltVrUnit := SuperGetMv("MV_XATUPRC",.T./*lHelp*/,.T./*uPadrao*/)

	Default cAdmFin := ""

	STFCleanMessage()
	STFCleanInterfaceMessage()

	//caso não tenha nenhuma NCC usada, zera o array de NCCs usadas
	If nNCCsUsadas <= 0 
		STDSetNCCs("1")
		STDSetNCCs("2")
		aNCCsUsadas := {}
	EndIf

	//atualizo var nVlrRec e nVlrSal
	If Alltrim(cForma) $ 'R$'
		oDINVlrSal:cText := Round(oDINVlrSal:cText,TamSx3("L1_VLRTOT")[2])
		oDINVlrRec:cText := Round(oDINVlrRec:cText,TamSx3("L1_VLRTOT")[2]) //A410Arred(oVlrRec:cText,"L1_VLRTOT") //arredonda o valor recebido (2 casas decimais)
		nVlrSal := oDINVlrSal:cText
		nVlrRec := oDINVlrRec:cText
	elseif Alltrim(cForma) $ 'CC/CD'
		oCCVlrSal:cText := Round(oCCVlrSal:cText,TamSx3("L1_VLRTOT")[2])
		oCCVlrRec:cText := Round(oCCVlrRec:cText,TamSx3("L1_VLRTOT")[2]) //A410Arred(oVlrRec:cText,"L1_VLRTOT") //arredonda o valor recebido (2 casas decimais)
		nVlrSal := oCCVlrSal:cText
		nVlrRec := oCCVlrRec:cText
	elseif Alltrim(cForma) $ 'CF'
		oCFVlrSal:cText := Round(oCFVlrSal:cText,TamSx3("L1_VLRTOT")[2])
		oCFVlrRec:cText := Round(oCFVlrRec:cText,TamSx3("L1_VLRTOT")[2]) //A410Arred(oVlrRec:cText,"L1_VLRTOT") //arredonda o valor recebido (2 casas decimais)
		nVlrSal := oCFVlrSal:cText
		nVlrRec := oCFVlrRec:cText
	ElseIf Alltrim(cForma) $ 'NP|CT|'+cFPConv
		oNPVlrSal:cText := Round(oNPVlrSal:cText,TamSx3("L1_VLRTOT")[2])
		oNPVlrRec:cText := Round(oNPVlrRec:cText,TamSx3("L1_VLRTOT")[2]) //A410Arred(oVlrRec:cText,"L1_VLRTOT") //arredonda o valor recebido (2 casas decimais)
		nVlrSal := oNPVlrSal:cText
		nVlrRec := oNPVlrRec:cText
	elseif Alltrim(cForma) $ 'PX|PD'
		oPIXVlrSal:cText := Round(oPIXVlrSal:cText,TamSx3("L1_VLRTOT")[2])
		oPIXVlrRec:cText := Round(oPIXVlrRec:cText,TamSx3("L1_VLRTOT")[2]) //A410Arred(oVlrRec:cText,"L1_VLRTOT") //arredonda o valor recebido (2 casas decimais)
		nVlrSal := oPIXVlrSal:cText
		nVlrRec := oPIXVlrRec:cText
	ElseIf Alltrim(cForma) $ 'CH'
		oCHVlrSal:cText := Round(oCHVlrSal:cText,TamSx3("L1_VLRTOT")[2])
		oCHVlrRec:cText := Round(oCHVlrRec:cText,TamSx3("L1_VLRTOT")[2]) //A410Arred(oVlrRec:cText,"L1_VLRTOT") //arredonda o valor recebido (2 casas decimais)
		nVlrSal := oCHVlrSal:cText
		nVlrRec := oCHVlrRec:cText
	ElseIf Alltrim(cForma) $ 'NB'
		oCRVlrSal:cText := Round(oCRVlrSal:cText,TamSx3("L1_VLRTOT")[2])
		oCRVlrRec:cText := Round(oCRVlrRec:cText,TamSx3("L1_VLRTOT")[2]) //A410Arred(oVlrRec:cText,"L1_VLRTOT") //arredonda o valor recebido (2 casas decimais)
		nVlrSal := oCRVlrSal:cText
		nVlrRec := oCRVlrRec:cText
	endif

	If nVlrRec <= 0 //independente da forma, verifico valor digitado
		STFMessage(ProcName(),"STOP", "Valor informado não pode ser negativo ou zerado: " + cValToChar(nVlrRec) )
		STFShowMessage(ProcName())
		Return .F.
	EndIf

	lPgTudo := (nVlrRec >= nVlrSal) //pagou com o valor do saldo ou com valor maior que o saldo

	//-- tratamento para cartão
	If Alltrim(cForma) $ 'CC/CD'

		If (lMyContTef .OR. !STWChkTef(cForma)) .and. (!Empty(cNsuDoc) .OR. !Empty(cAutoriz))
			If Empty(cCCAdmFin)
				STFMessage(ProcName(),"STOP", "Selecione uma Adm. Financeira para finalizar a venda!")
				STFShowMessage(ProcName())
				//Help(, , "CARTAO", , "Selecione uma Adm. Financeira para finalizar a venda!", 1, 0, , , , , , {""})
				Return .F.
			ElseIf Empty(cNsuDoc)
				STFMessage(ProcName(),"STOP", "Informe o NSU do comprovante.")
				STFShowMessage(ProcName())
				//Help(, , "CARTAO", , "Informe o NSU do comprovante.", 1, 0, , , , , , {""})
				Return .F.
			ElseIf Empty(cAutoriz)
				STFMessage(ProcName(),"STOP", "Informe o codigo de Autorização do comprovante.")
				STFShowMessage(ProcName())
				//Help(, , "CARTAO", , "Informe o codigo de Autorização do comprovante.", 1, 0, , , , , , {""})
				Return .F.
			Else
				SAE->(DbSetOrder(1))
				SAE->(DbSeek(xFilial("SAE")+cCCAdmFin ))
				If nCCParcelas <= 0 
					STFMessage(ProcName(),"STOP", "Numero de parcelas deve ser maior que zero!")
					STFShowMessage(ProcName())
					Return .F.
				ElseIf SAE->AE_PARCDE > 0 .AND. nCCParcelas < SAE->AE_PARCDE
					STFMessage(ProcName(),"STOP", "Numero mínimo de parcelas é de "+cValToChar(SAE->AE_PARCATE)+"!")
					STFShowMessage(ProcName())
					Return .F.
				ElseIf SAE->AE_PARCATE > 0 .AND. nCCParcelas > SAE->AE_PARCATE
					STFMessage(ProcName(),"STOP", "Numero máximo de parcelas é de "+cValToChar(SAE->AE_PARCATE)+"!")
					STFShowMessage(ProcName())
					Return .F.
				Endif
			EndIf
		EndIf
	EndIf

	//-- tratamento para Carta Frete
	If Alltrim(cForma) $ 'CF'
		If Empty(cCodCF) .or. Empty(cLojCF)
			STFMessage(ProcName(),"STOP", "Selecione um emitente de carta frete.")
			STFShowMessage(ProcName())
			Return .F.
		ElseIf Empty(cCFrete)
			STFMessage(ProcName(),"STOP", "Informe o número da carta frete.")
			STFShowMessage(ProcName())
			Return .F.
		EndIf		
	EndIf

	//-- tratamento para NB - Nota de Crédito Cód. Barras (RA ou NCC)
	If Alltrim(cForma) $ 'NB'

		If aNCCsCli == Nil .or. Empty(aNCCsCli) .or. (Len(aNCCsCli) == 0) .or. (oCRListGdNeg:nAt <= 0)
			// Tratamento para retorno vazio
			STFMessage( ProcName(), "STOP", "Nota de Crédito não selecionada..." )
			STFShowMessage(ProcName())
			STFCleanMessage(ProcName())
			Return .F.

		Else
			/*
					Posicoes de aNCCs
					aNCCs[x,1]  = .F.	// Caso a NCC seja selecionada, este campo recebe TRUE
					aNCCs[x,2]  = SE1->E1_SALDO
					aNCCs[x,3]  = SE1->E1_NUM
					aNCCs[x,4]  = SE1->E1_EMISSAO
					aNCCs[x,5]  = SE1->(Recno())
					aNCCs[x,6]  = SE1->E1_SALDO
					aNCCs[x,7]  = SuperGetMV("MV_MOEDA1")
					aNCCs[x,8]  = SE1->E1_MOEDA
					aNCCs[x,9]  = SE1->E1_PREFIXO
					aNCCs[x,10] = SE1->E1_PARCELA
					aNCCs[x,11] = SE1->E1_TIPO
					aNCCs[x,12] = SE1->E1_XPLACA
					aNCCs[x,13] = SE1->E1_XMOTOR
					aNCCs[x,14] = SE1->E1_FILIAL
					aNCCs[x,15] = SE1->E1_XCODBAR
			*/

			cPrefixo := aNCCsCli[oCRListGdNeg:nAt][9]
			cNum     := aNCCsCli[oCRListGdNeg:nAt][3]
			nRecNCC  := aNCCsCli[oCRListGdNeg:nAt][5]
			nPosNCC  := aScan( aNCCsUsadas, {|x| x[5] == nRecNCC })

			If nNCCsUsadas > 0 .AND. nPosNCC > 0 .AND. aNCCsUsadas[nPosNCC,9]+aNCCsUsadas[nPosNCC,3] == cPrefixo+cNum .AND. aNCCsUsadas[nPosNCC,1]
				STFMessage( ProcName(), "STOP", "Nota de Crédito já utilizada na venda!" )
				STFShowMessage(ProcName())
				Return .F.

			EndIf

			//faz transferencia do credito, caso seja de outra filial
			If AllTrim(aNCCsCli[oCRListGdNeg:nAt][14]) <> AllTrim(cFilAnt)

				CursorArrow()
				STFCleanInterfaceMessage()

				STFMessage(ProcName(),"STOP","Realizando tranferência de crédito entre filiais. Aguarde...")
				STFShowMessage(ProcName())

				CursorWait()

				aNCCsCli[oCRListGdNeg:nAt][1] := .T.
				aParam := {aClone(aNCCsCli[oCRListGdNeg:nAt])}
				aParam := {"U_TRETE031",aParam}
				aRet   := Nil
				If !STBRemoteExecute("_EXEC_RET", aParam,,, @aRet)

					// Tratamento do erro de conexao
					STFMessage(ProcName(), "ALERT", "Transferências de crédito: falha de comunicação com o Back-Office..." )
					STFShowMessage(ProcName())


					aNCCsCli[oCRListGdNeg:nAt][1] := .F.
					CursorArrow()
					Return .F.

				ElseIf ValType(aRet)=="A" .and. Len(aRet)>0 .and. aRet[2] .and. Len(aRet[1])>0

					// Transferencia realizada com sucesso...
					STFMessage(ProcName(), "ALERT", "Transferência de crédito entre filiais realizada com sucesso!" )
					STFShowMessage(ProcName())

					aNCCsCli[oCRListGdNeg:nAt] := aClone(aRet[1])

				Else

					// Tratamento para retorno vazio
					STFMessage(ProcName(), "ALERT", "Não foi possivel realizar a transferência de crédito entre filiais!" )
					STFShowMessage(ProcName())

					aNCCsCli[oCRListGdNeg:nAt][1] := .F.
					CursorArrow()
					Return .F.

				EndIf

				CursorArrow()

			EndIf

		EndIf
	EndIf

	GetSelected(cForma)

	oModelCesta := oModelCesta:GetModel("SL2DETAIL")

	For nI := 1 To oModelCesta:Length()
		oModelCesta:GoLine(nI)
		If !oModelCesta:IsDeleted(nI)
			nPosPrd := aScan(aProdutos, {|x| AllTrim(x[1]+x[2])==AllTrim(oModelCesta:GetValue("L2_ITEM")+oModelCesta:GetValue("L2_PRODUTO"))})
			If nPosPrd == 0 //aProdutos - [01] L2_ITEM / [02] L2_PRODUTO / [03] L2_QUANT / [04] PRC UNITARIO (PADRÃO) / [05] PRC USADO [06] DESCONTO
				AAdd(aProdutos, {oModelCesta:GetValue("L2_ITEM"),oModelCesta:GetValue("L2_PRODUTO"),oModelCesta:GetValue("L2_QUANT"),0,0,0}) //adiciona produto
			Else
				aProdutos[nPosPrd][3] += oModelCesta:GetValue("L2_QUANT") //soma qtd
			EndIf
		EndIf
	Next nI

	If nAtaReceb > 0

		aRecebtosBKP := aClone(aRecebtos[nAtaReceb]) //faz backup, caso na confirmação do pagamento ocorra erro

		cCondPg := aRecebtos[nAtaReceb][2]
		nVrReceb := nVlrRec

		If Round(nVlrRec,2) > Round(aRecebtos[nAtaReceb][11],2)
			aRecebtos[nAtaReceb][9]  += Round(aRecebtos[nAtaReceb][11],2)
			aRecebtos[nAtaReceb][16] := Round(nVlrRec - aRecebtos[nAtaReceb][11],2)
		Else
			aRecebtos[nAtaReceb][9]  += Round(nVlrRec,2)
		EndIf
		AtuARecebtos(,nAtaReceb) //validacao de campo -> CAMPO "RECEBIDO"

		SE4->(DbSetOrder(1)) //E4_FILIAL+E4_CODIGO
		If Empty(cCondPg) .or. !SE4->(DbSeek(xFilial("SE4")+cCondPg))
			STFMessage(ProcName(),"STOP", "Condição de pagamento não existente: "+cCondPg+"!")
			STFShowMessage(ProcName())
			Return .F.
		EndIf

	EndIf
	
	_nPercRec := 0
	_nPercTot := 0
	_lTDescon := .F.
	
	For nX:=1 to Len(aRecebtos)

		If aRecebtos[nX][9] > 0 //Vlr Recebido

			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³Percentual do recebimento da forma x cond. pgto (não pode ser maior do que 1)³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			_nPercRec := aRecebtos[nX][10]
			If (_nPercRec + _nPercTot) > 1
				_nPercRec := (1 - _nPercTot)
			EndIf
			_nPercTot += _nPercRec

			If _nPercRec > 0
				For nY:=1 to Len(aRecebtos[nX][5])
					cItem    := aRecebtos[nX][5][nY][1]
					cProduto := aRecebtos[nX][5][nY][2]
					nPosPrd  := aScan(aProdutos, {|x| AllTrim(x[1]+x[2])==AllTrim(cItem+cProduto)})
					If nPosPrd > 0

						aProdutos[nPosPrd][4] := Round( aRecebtos[nX][5][nY][4], TamSx3("L2_VRUNIT")[2] ) //preço padrão
						//aProdutos[nPosPrd][5] += Round( _nPercRec * Round( aRecebtos[nX][5][nY][5], TamSx3("L2_VRUNIT")[2] ), TamSx3("L2_VRUNIT")[2] )
						//aProdutos[nPosPrd][6] += Round( _nPercRec * ( Round( aRecebtos[nX][5][nY][3]*aRecebtos[nX][5][nY][4], TamSx3("LR_VLRITEM")[2] ) - Round( aRecebtos[nX][5][nY][3]*aRecebtos[nX][5][nY][5], TamSx3("LR_VLRITEM")[2] ) ),TamSx3("L2_VALDESC")[2])

						aProdutos[nPosPrd][5] += _nPercRec * aRecebtos[nX][5][nY][5]
						aProdutos[nPosPrd][6] += _nPercRec * ( ( aRecebtos[nX][5][nY][3]*aRecebtos[nX][5][nY][4] ) - ( aRecebtos[nX][5][nY][3]*aRecebtos[nX][5][nY][5] ) )

						//-> desconto => verifica se teve desconto
						//	(Utilizado [05] < Negociado [10]) .and. (Utilizado [05] < Padrao [04])
						_lTDescon := .F.
						If (aRecebtos[nX][5][nY][5] < aRecebtos[nX][5][nY][10]) .and. (aRecebtos[nX][5][nY][5] < aRecebtos[nX][5][nY][4])
							_lTDescon := .T.
						EndIf

					EndIf
					
				Next nY
			EndIf
		EndIf
	Next nX

	nDescTot := 0 //-- desconto total
	_nPercTot := iif(_nPercTot>1,1,_nPercTot)	
	nTotItens := 0 //carregar o total dos itens

	For nI := 1 To oModelCesta:Length()
		oModelCesta:GoLine(nI)
		If !oModelCesta:IsDeleted(nI)

			nDescItem := 0
			nVrUnItem := 0
			cItem    := oModelCesta:GetValue("L2_ITEM")
			cProduto := oModelCesta:GetValue("L2_PRODUTO")
			nPosPrd  := aScan(aProdutos, {|x| AllTrim(x[1]+x[2])==AllTrim(cItem + cProduto)})
			//aProdutos - [01] L2_ITEM / [02] L2_PRODUTO / [03] L2_QUANT / [04] PRC UNITARIO (PADRÃO) / [05] PRC USADO [06] DESCONTO
			If nPosPrd > 0
				nVrUnItem := Round(aProdutos[nPosPrd][4]*(1 - _nPercTot), TamSx3("L2_VLRITEM")[2]) + Round(aProdutos[nPosPrd][5], TamSx3("L2_VLRITEM")[2]) //LR_VRUNIT
				nDescItem := Round(aProdutos[nPosPrd][6], TamSx3("L2_VALDESC")[2]) //LR_VALDESC
			EndIf

			If cTime == "D"
				/*/
					Procura saber se o item é fiscal. Caso positivo deve mandar desconto para impressora fiscal
				/*/
				lItemFiscal := .F. //STDGPBasket( "SL2" , "L2_FISCAL" , nI )
			EndIf

			//lAltVrUnit -> MV_XATUPRC - tipo de negociação no Totvs PDV: DESCONTO ou PREÇO UNITÁRIO

			/*/
				-- tratamento para quanto trabalha com PREÇO UNITÁRIO
			/*/
			If lAltVrUnit .and. nVrUnItem > 0 .and. (nVrUnItem <> Round(oModelCesta:GetValue("L2_VRUNIT"),TamSx3("L2_VLRITEM")[2]))

				nPrice := Round(nVrUnItem, TamSx3("L2_VLRITEM")[2]) //STBTaxRet( nI, "IT_PRCUNI" )

				// Arredondamento
				nItemTotal := STBArred( nPrice * oModelCesta:GetValue("L2_QUANT"), , "L2_VLRITEM" )
				nTotItens += nItemTotal

				//Help(, , "STBArred", , "nPrice - "+U_XtoStrin(nPrice) + CRLF , 1, 0, , , , , , {"nItemTotal - "+U_XtoStrin(nItemTotal) + CRLF})

				STBTaxAlt( "IT_PRCUNI", nPrice, nI )
				STBTaxAlt( "IT_VALMERC", nItemTotal, nI )
				STBTaxAlt( "IT_DESCONTO", 0, nI )

				/*/
					Atualiza Total
				/*/
				STFRefTot()

				/*/
					Atualizar valores da cesta se o item já foi registrado.
				/*/
				STBRefshItBasket( nI ) // OBS: Caso for Antes de registrar já atualiza no registro de item

			/*/
				-- tratamento para quanto trabalha com DESCONTO
			/*/
			ElseIf !lAltVrUnit .and. nDescItem > 0 .and. STBTaxRet( nI, "IT_DESCONTO" ) <> nDescItem

				nTotItens += Round(oModelCesta:GetValue("L2_VLRITEM") - nDescItem,TamSx3("L2_VLRITEM")[2])

				/*/
					Aplica desconto no Item
				/*/
				STBIDApply(nI/*nItemLine*/, nDescItem, cTypeDesc/*cTypeDesc*/, lItemFiscal/*lItemFiscal*/, cTime, /*nItemTotal*/)
			Else
				
				//Quando não tem desconto ou preço negociado
				nPrice := Round(nVrUnItem, TamSx3("L2_VRUNIT")[2]) //STBTaxRet( nI, "IT_PRCUNI" )
				// Arredondamento
				nItemTotal := STBArred( nPrice * oModelCesta:GetValue("L2_QUANT"), , "L2_VLRITEM" )
				nTotItens += nItemTotal

			EndIf

			//Ao Aplicar o Desconto Ajusto a Base e o valor do ICMS
			If ExistFunc("STBAjusICM") 
				STBAjusICM() //função padrão -> STBItemRegistry.prw
			Else
				USTBAjusICMS() //copia da função padrão, pois na release 12.1.17 não existe essa função
			EndIf

		EndIf
	Next nI

	//carregar o total ja recebido
	nTotRecebi := 0
	If ValType(oModelParce) == "O"
		nPosMdl := oModelParce:GetLine() //:nLine
		For nI := 1 To oModelParce:Length()
			oModelParce:GoLine(nI)
			If !Empty(oModelParce:GetValue('L4_FORMA'))
				nTotRecebi += oModelParce:GetValue('L4_VALOR')
			EndIf
		Next nI
		oModelParce:GoLine(nPosMdl)
	EndIf
	
	nTotRecebi := nTotRecebi + nVlrSal   //total recebido

	/*/
		Aplica desconto total para não dar troco de centavos
	/*/ 
	If lPgTudo //pagou com o valor do saldo ou com valor maior que o saldo
		
		If nTotItens > nTotRecebi
			nDescTot := nTotItens - nTotRecebi //-- soma a diferença de centavos dos itens
		EndIf

		//Help(, , "NF_DESCTOT", , "nDescTot - "+U_XtoStrin(nDescTot) + CRLF , 1, 0, , , , , , {"nTotRecebi - "+U_XtoStrin(nTotRecebi) + CRLF + "nTotItens - "+U_XtoStrin(nTotItens) + CRLF})

		//-- Aplica o desconto no Total: STBTotDiscApply
		If nDescTot > 0 //ajuste dos centavos
			STBTaxAlt( "NF_DESCTOT", nDescTot )
		EndIf

	EndIf

	/*/ Atualiza Interface
		Sincroniza a Cesta com a interface
	/*/
	STIGridCupRefresh()

	/*/
		Chama as rotinas do confirmação padrão de pagamento
	/*/
	If Alltrim(cForma) $ 'R$'

		If STICSConfPay(oDINVlrRec, oPnlAdconal)
			// Limpa objetos da tela
			STIClnVar(oPnlAdconal, .T.)
			oPnlForm:Hide()
		Else
			lRet := .F.
		EndIf

	ElseIf Alltrim(cForma) $ 'CC/CD'

		//seta adm financeira, que é static no fonte padrao, e nao é passada na funçao STICCConfPay
		If FindFunction("STISetcAdmFin")
			STISetcAdmFin(cCCAdmFin)
		EndIf

		If !FindFunction("STBValFormPay") .or. STBValFormPay(cForma,nVlrRec,nCCParcelas)
			STISetContTef(lMyContTef)
			If USTICCConfPay(oCCDataTran, oCCVlrRec, oCCParcelas, oPnlAdconal, cForma , lMyContTef , cNsuDoc , cAutoriz, nCCParcelas)
				lContTef := Iif(FindFunction("STIGetContTef"),STIGetContTef(),.F.) //Se ira utilizar a contingencia de passar no POS //atualizo a variavel do padrão
				If lMyContTef .OR. !lContTef // Se tiver em contingencia do TEF não limpa os objetos
					// Limpa objetos da tela de cartão
					STIClnVar(oPnlAdconal, .T.)
					oPnlForm:Hide()
				EndIf
			Else
				lRet := .F.
			EndIf

		Else
			lRet := .F.
		EndIf

	ElseIf Alltrim(cForma) $ 'NP|CT|'+cFPConv

		aParc := condicao(nVlrRec,cCondPg,0.00,dDatabase,0.00,{},,0)
			
		nNPParcelas := Len(aParc) //número de parcelas
		If oNPParcelas <> Nil
			oNPParcelas:Refresh()
		EndIf

		dNPDataTran := aParc[01][01] //vecimento primeira parcela
		If oNPDataTran <> Nil
			oNPDataTran:Refresh()
		EndIf

		If STIFiConfPay(oNPDataTran, oNPVlrRec, oNPParcelas, oNPAdmFin, oPnlAdconal, ,cForma)
			STIClnVar(oPnlAdconal, .T.)
			oPnlForm:Hide()
		Else
			lRet := .F.
		EndIf

	ElseIf Alltrim(cForma) $ 'PX|PD'

		//seta adm financeira, que é static no fonte padrao, e nao é passada na funçao STICCConfPay
		If FindFunction("STISetcAdmFin")
			STISetcAdmFin(cPIXAdmFin)
		EndIf

		If !FindFunction("STBValFormPay") .or. STBValFormPay(cForma,nVlrRec,nPIXParcelas)
			If USTICCConfPay(oPIXDataTran, oPIXVlrRec, oPIXParcelas, oPnlAdconal, cForma , .F. , "" , "", nPIXParcelas)
				// Limpa objetos da tela de pix
				STIClnVar(oPnlAdconal, .T.)
				oPnlForm:Hide()
			Else
				lRet := .F.
			EndIf
		Else
			lRet := .F.
		EndIf

	ElseIf Alltrim(cForma) $ 'CF'

		If !Empty(Posicione("SA1",1,xFilial("SA1")+cCodCF+cLojCF,"A1_XCONDCF"))
			cCondPg := Posicione("SA1",1,xFilial("SA1")+cCodCF+cLojCF,"A1_XCONDCF")
		EndIf

		aParc := condicao(nVlrRec,cCondPg,0.00,dDatabase,0.00,{},,0)

		nCFParcelas := Len(aParc) //número de parcelas
		If oCFParcelas <> Nil
			oCFParcelas:Refresh()
		EndIf
		dCFDataTran := aParc[01][01] //vecimento primeira parcela
		If oCFDataTran <> Nil
			oCFDataTran:Refresh()
		EndIf

		cEmitCF := Posicione("SA1",1,xFilial("SA1")+cCodCF+cLojCF,"A1_CGC")
		aadd(aL4Custom, {"L4_CGC", cEmitCF})
		aadd(aL4Custom, {"L4_NUMCART", cCFrete })
		aadd(aL4Custom, {"L4_OBS", cObserv })		

		If STIFiConfPay(oCFDataTran, oCFVlrRec, oCFParcelas, oCFAdmFin, oPnlAdconal, ,cForma)
			STIClnVar(oPnlAdconal, .T.)
			oPnlForm:Hide()
		Else
			lRet := .F.
		EndIf

	ElseIf Alltrim(cForma) $ 'CH'

		oMdl := ModelCheck()
		oMdlChq := oMdl:GetModel("CHECKMASTER")
		oMdlChq:DeActivate()
		oMdlChq:Activate()
		oMdlChq:LoadValue("L4_FILIAL"	,xFilial("SL1"))
		oMdlChq:LoadValue("L4_DATA"		,dCHDataTran )
		oMdlChq:LoadValue("L4_VALOR"	,nVlrRec )
		oMdlChq:LoadValue("L4_PARCELAS"	,nCHParcelas )

		For nX:=1 to len(aCheques)
			aadd(aRetChq, {aClone(aCheques[nX])})
		next nX

		//confirma o pagamento de cheque
		STWSetCkRet(aRetChq)
		STWConChk()

	ElseIf Alltrim(cForma) $ 'NB' //NB - Nota de Crédito Cód. Barras

		nTotalVend := oTotal:GetValue("L1_VLRTOT")
		nValNCC    := aNCCsCli[oCRListGdNeg:nAt][2]

		//MV_LJCPNCC = 4 (Saldo da NCC como troco)

		//venda com crédito não gera troco
		If nTPCompNCC <> 4 .and. nValNCC > nTotalVend // Caso o valor total da NCC selecionada seja maior que o valor total da venda, sera setado o valor total da venda.
			nValorUsado := nTotalVend
		Else
			nValorUsado := nValNCC
		EndIf

		aNCCsCli[oCRListGdNeg:nAt][1] := .T.
		Aadd(aNCCsUsadas, aNCCsCli[oCRListGdNeg:nAt])
		STDSetNCCs("1",aNCCsUsadas)
		STDSetNCCs("2",nValorUsado)

		nNCCsUsadas := nNCCsUsadas + nValorUsado

		If nNCCsUsadas > 0

			/* Cria estrutura do model */
			oModelNCC := ModelNCCBC()
			oMdlNCC   := oModelNCC:GetModel("NCCBCMASTER")

			/* Desativa e ativa o model */
			oMdlNCC:DeActivate()
			oMdlNCC:Activate()

			/* Inclui o valor no model */
			oMdlNCC:LoadValue("L4_DATA", dDataBase)
			oMdlNCC:LoadValue("L4_VALOR", nNCCsUsadas)

			/* Adiciona o pagamento de credito */
			STIAddPay("CR", oMdlNCC, 1, Nil, Nil, nNCCsUsadas)

		EndIf

	EndIf

	//gravando campos complementares na SL4
	If lRet .AND. nSldAntes <> STBCalcSald("1") //se o saldo pendente mudou, é pq add a forma
		
		If SL4->(FieldPos("L4_XCOND")) > 0
			aadd(aL4Custom, {"L4_XCOND", cCondPg})
		EndIf

		If SL4->(FieldPos("L4_XCODLIB")) > 0
			For nY:=1 to Len(aRecebtos[nAtaReceb][5])
				If !Empty(aRecebtos[nAtaReceb][5][nY][16])
					cCodLib := aRecebtos[nAtaReceb][5][nY][16]
					aadd(aL4Custom, {"L4_XCODLIB", cCodLib})
					Exit //sai do For nY
				EndIf
			Next nY
		EndIf

		//OBS.: não irá funcionar corretamente para cartão caso parametro MV_LJFCVDA esteja habilitado
		If Len(aL4Custom) > 0
			SetL4Custom(cForma, cCondPg, aL4Custom, nVrReceb)
		EndIf
		
		If Alltrim(cForma) == 'CH' .OR. Alltrim(cForma) $ 'NB' // Limpa objetos da tela
			if ValType(oPnlAdconal) == "O"
				oPnlAdconal:Hide()
			endif
			if ValType(oPnlForm) == "O"
				oPnlForm:Hide()
			endif
			STIClnVar(oPnlAdconal, .T.)
			STIEnblPaymentOptions()
			oListBox:SetFocus()
		EndIf

		//Caso cartão, e desabilitou o parametro MV_LJFCVDA e não tem mais saldo, chama finalizaçao da venda
		If !lFinVendaAut .AND. Alltrim(cForma) $ 'CC/CD/PD/PX' .AND. STBCalcSald("1") == 0
			if Alltrim(cForma) $ 'CC/CD' .OR. (Alltrim(cForma) == 'PX' .AND. !("PX" $ cFPConv)) .OR. (Alltrim(cForma) == 'PD' .AND. !("PD" $ cFPConv))
				LjGrvLog( "L1_NUM: "+STDGPBasket('SL1','L1_NUM'), "Chama Finalização da venda após pagamento total (TPDVE004)" )
				STIConfPay()
			endif
		EndIf
	EndIf

	If lRet
		bCancTela := Nil
	Else
		aRecebtos[nAtaReceb] := aClone(aRecebtosBKP)
		AtuARecebtos() //validacao de campo -> CAMPO "RECEBIDO"
		aRecebtosBKP := {}
	EndIf

	//Restaura areas
	RestArea(aArea)
	FWRestRows(aSaveLines)

	// Limpa os vetores para melhor gerenciamento de memoria (Desaloca Memória)
	aSize( aSaveLines, 0 )
	aSaveLines 	:= Nil

Return lRet

//--------------------------------------------------------------
// Abre tela de detalhamento do desconto
//--------------------------------------------------------------
Static Function STIDetDesc(cForma)

	Local cFPConv := SuperGetMv("TP_FPGCONV",,"")
	Local cCor := SuperGetMv( "MV_LJCOLOR",,"07334C")// Cor da tela
	Local cCorBack := RGB(hextodec(SubStr(cCor,1,2)),hextodec(SubStr(cCor,3,2)),hextodec(SubStr(cCor,5,2)))
	Local oDlgDesc, cCssAux
	Local oBtn1, oBtn2, oBtn3
	Local oGrp1, oSay2, oSay3, oSay4, oSay5, oSay6, oSay7, oSay8, oSay9, oSay10
	Local oSay11, oSay12, oSay13, oSay14, oSay15, oSay16, oSay17, oSay18
	Local lConfirm := .F.
	Local oPnlBack, oTPanel
	Local cUsrDes := ""
	Local nX

	Private oSay1, oGrp2, oProd, oDesc, oQuant, oPrcUni, oPrcNeg, oPrcUsa, oTotDesc, oTotLiqui
	Private oTotGBru, oTotGDesc, oTotGLiqui
	Private oVlrRecD, oPerRecD, oTotDesG, oSldRecD

	Private aEmptyLPr := {}
	Private oNewGDDes
	Private aListGdDes := {}
	Private oListGdDes
	Private nList	 := 0
	Private cNegocia := ""
	Private cSay1 := "Detalhe de Desconto por Produto - " + cNegocia
	Private cGrp2 := " Saldo da Negociação - " + cNegocia + " "
	Private cProduto := Space(TamSx3("L2_PRODUTO")[1])
	Private cDescont := Space(TamSx3("L2_DESCRI")[1])
	Private nQuantid := 0
	Private nPrcUni := 0
	Private nPrcNeg := 0
	Private nPrcUsa := 0
	Private nTotDesc := 0
	Private nTotLiqu := 0
	Private nTotGBrut := 0
	Private nTotGDesc := 0
	Private nTotGLiqu := 0
	Private nVlrRecD := 0
	Private nPerRecD := iif(ValType(nPercent)<>"U",nPercent*100,0)
	Private nTotDesG := 0
	Private nSldRec := 0

	if lAddPromo .AND. STDGPBasket("SL1","L1_XDESPRO") > 0 //se promoflex, não abre a tela
		STFMessage("STIDetDesc","STOP", "Desconto Promoflex ativado. Não permitido aplicar outros descontos." )
		STFShowMessage("STIDetDesc")
		Return .F.
	endif

	//verifica se o usuário tem permissão para acesso a rotina
	U_TRETA37B("DESPDV", "DESCONTO NO PDV")
	cUsrDes := U_VLACESS1("DESPDV", RetCodUsr())
	If cUsrDes == Nil .OR. Empty(cUsrDes)
		STFMessage("STIDetDesc","STOP", "Usuário não tem permissão de acesso a rotina de Detalhamento de Desconto." )
		STFShowMessage("STIDetDesc")
		Return .F.
	EndIf

	//total recebido de outras formas no aRecebtos
	For nX:=1 to Len(aRecebtos)
		nVlrRecD += aRecebtos[nX][9]+aRecebtos[nX][16]
	Next nX

	//limpa as tecla atalho
	U_UKeyCtr() 

	DEFINE MSDIALOG oDlgDesc TITLE " " FROM 000, 000  TO 483, 703 COLORS 0, 16777215 PIXEL //STYLE nOr(WS_VISIBLE, WS_POPUP)

	@ 0,0 MSPANEL oPnlBack SIZE 10, 10 OF oDlgDesc COLORS 0, cCorBack
	oPnlBack:Align := CONTROL_ALIGN_ALLCLIENT

	oTPanel := TPanel():New(004,000,"",oPnlBack,NIL,.T.,.F.,,,350,240,.T.,.F.)
	oTPanel:SetCSS( POSCSS (GetClassName(oTPanel), CSS_PANEL_CONTEXT ))

	@ 008, 010 SAY oSay1 PROMPT cSay1 SIZE 350, 011 OF oTPanel COLORS 0, 16777215 PIXEL
	oSay1:SetCSS( POSCSS (GetClassName(oSay1), CSS_BREADCUMB ))

	@ 020, 010 SAY oSay2 PROMPT "Produtos da venda" SIZE 100, 008 OF oTPanel COLORS 0, 16777215 PIXEL
	oSay2:SetCSS( POSCSS (GetClassName(oSay2), CSS_LABEL_FOCAL ))

	oNewGDDes := DoGdDescon(oTPanel, 030, 005, 347, 080)
	//oNewGDDes:oBrowse:bChange := {|| LoadSelDes() }
	//oNewGDDes:oBrowse:bLDblClick := {|| oPrcUsa:Refresh(), oPrcUsa:SetFocus()}
	oNewGDDes:Hide() //torna o objeto invisível

	/* Cria listbox com os produtos para selecionar */
	aListGdDes := {''}
	oListGdDes := TListBox():New(030, 010, {|u|if(Pcount()>0,nList:=u,nList)},;
						aListGdDes, 332, 054,,oTPanel,,,,.T.)
    oListGdDes:bChange := {|| LoadSelDes() }
    oListGdDes:bLDBLClick := {|| oPrcUsa:Refresh(), oPrcUsa:SetFocus()}
	oListGdDes:SetCSS( POSCSS (GetClassName(oListGdDes), CSS_LISTBOX ))

	@ 085, 010 SAY oSay3 PROMPT "Produto" SIZE 070, 010 OF oTPanel COLORS CLR_GRAY, 16777215 PIXEL
  	//oSay3:SetCSS( POSCSS (GetClassName(oSay3), CSS_LABEL_NORMAL ))
    @ 093, 010 MSGET oProd VAR cProduto SIZE 065, 010 OF oTPanel COLORS 0, 16777215 WHEN .F. PIXEL
    cCssAux := POSCSS (GetClassName(oProd), CSS_GET_NORMAL )
    cCssAux := StrTran(cCssAux,"transparent","#EEEEEE")
	cCssAux := StrTran(cCssAux,"border: none;","") // padding: 0px;
    oProd:SetCSS(cCssAux)

    @ 085, 080 SAY oSay4 PROMPT "Descrição" SIZE 060, 010 OF oTPanel COLORS CLR_GRAY, 16777215 PIXEL
    @ 093, 080 MSGET oDesc VAR cDescont SIZE 190, 010 OF oTPanel COLORS 0, 16777215 WHEN .F. PIXEL
    oDesc:SetCSS(cCssAux)

    @ 085, 275 SAY oSay5 PROMPT "Quantidade" SIZE 060, 010 OF oTPanel COLORS CLR_GRAY, 16777215 PIXEL
    @ 093, 275 MSGET oQuant VAR nQuantid SIZE 070, 010 OF oTPanel COLORS 0, 16777215 PICTURE PesqPict("SL2","L2_QUANT") WHEN .F. PIXEL HASBUTTON
    oQuant:SetCSS(cCssAux)

    @ 108, 010 SAY oSay6 PROMPT "Prç. Unit" SIZE 060, 010 OF oTPanel COLORS CLR_GRAY, 16777215 PIXEL
    @ 116, 010 MSGET oPrcUni VAR nPrcUni SIZE 065, 010 OF oTPanel COLORS 0, 16777215 PICTURE PesqPict("SL2","L2_PRCTAB") WHEN .F. PIXEL HASBUTTON
    oPrcUni:SetCSS(cCssAux)

    @ 108, 080 SAY oSay7 PROMPT "Prç. Negoc." SIZE 060, 010 OF oTPanel COLORS CLR_GRAY, 16777215 PIXEL
    @ 116, 080 MSGET oPrcNeg VAR nPrcNeg SIZE 060, 010 OF oTPanel COLORS 0, 16777215 PICTURE PesqPict("SL2","L2_PRCTAB") WHEN .F. PIXEL HASBUTTON
    oPrcNeg:SetCSS(cCssAux)

    @ 108, 145 SAY oSay8 PROMPT "Prç. Usado" SIZE 060, 010 OF oTPanel COLORS CLR_GRAY, 16777215 PIXEL
    @ 116, 145 MSGET oPrcUsa VAR nPrcUsa SIZE 060, 010 OF oTPanel COLORS 0, 16777215 PICTURE PesqPict("SL2","L2_VRUNIT") WHEN .T. PIXEL HASBUTTON VALID ValidCamDes("L2_VRUNIT")
    oPrcUsa:SetCSS(cCssAux)

    @ 108, 210 SAY oSay9 PROMPT "Tot.Desconto" SIZE 060, 010 OF oTPanel COLORS CLR_GRAY, 16777215 PIXEL
    @ 116, 210 MSGET oTotDesc VAR nTotDesc SIZE 060, 010 OF oTPanel COLORS 0, 16777215 PICTURE PesqPict("SL2","L2_VALDESC") WHEN .T. PIXEL HASBUTTON VALID ValidCamDes("L2_VALDESC")
    oTotDesc:SetCSS(cCssAux)

    @ 108, 275 SAY oSay10 PROMPT "Tot.Liquido" SIZE 060, 010 OF oTPanel COLORS CLR_GRAY, 16777215 PIXEL
    @ 116, 275 MSGET oTotLiqui VAR nTotLiqu SIZE 070, 010 OF oTPanel COLORS 0, 16777215 PICTURE PesqPict("SL1","L1_VLRLIQ") WHEN .T. PIXEL HASBUTTON VALID ValidCamDes("L1_VLRLIQ")
    oTotLiqui:SetCSS(cCssAux)

    @ 127, 005 SAY Replicate("_",345) SIZE 342, 008 OF oTPanel FONT COLORS CLR_HGRAY, 16777215 PIXEL

    @ 137, 010 SAY oSay11 PROMPT "Totais da venda" SIZE 200, 011 OF oTPanel COLORS 0, 16777215 PIXEL
	oSay11:SetCSS( POSCSS (GetClassName(oSay11), CSS_BREADCUMB ))

	@ 155, 010 SAY oSay12 PROMPT "Total Bruto:" SIZE 060, 010 OF oTPanel COLORS CLR_GRAY, 16777215 PIXEL
    oSay12:SetCSS( POSCSS (GetClassName(oSay12), CSS_LABEL_FOCAL ))
    @ 152, 080 MSGET oTotGBru VAR nTotGBrut SIZE 080, 013 OF oTPanel COLORS 0, 16777215 PICTURE PesqPict("SL1","L1_VLRTOT") WHEN .F. PIXEL HASBUTTON
    oTotGBru:SetCSS(cCssAux)

    @ 173, 010 SAY oSay13 PROMPT "Total Desconto:" SIZE 060, 010 OF oTPanel COLORS CLR_GRAY, 16777215 PIXEL
    oSay13:SetCSS( POSCSS (GetClassName(oSay13), CSS_LABEL_FOCAL ))
    @ 170, 080 MSGET oTotGDesc VAR nTotGDesc SIZE 080, 013 OF oTPanel COLORS 0, 16777215 PICTURE PesqPict("SL1","L1_DESCONT") WHEN .T. PIXEL HASBUTTON VALID DoRecalcTotDes("L1_DESCONT")
    oTotGDesc:SetCSS(cCssAux)

    @ 191, 010 SAY oSay14 PROMPT "Total Líquido:" SIZE 060, 010 OF oTPanel COLORS CLR_GRAY, 16777215 PIXEL
    oSay14:SetCSS( POSCSS (GetClassName(oSay14), CSS_LABEL_FOCAL ))
    @ 188, 080 MSGET oTotGLiqui VAR nTotGLiqu SIZE 080, 013 OF oTPanel COLORS 0, 16777215 PICTURE PesqPict("SL1","L1_VLRLIQ") WHEN .T. PIXEL HASBUTTON VALID DoRecalcTotDes("L1_VLRLIQ")
    oTotGLiqui:SetCSS(cCssAux)

    @ 140, 165 GROUP oGrp1 TO 170, 343 PROMPT " Outras Negociações de Pagamento " OF oTPanel COLOR CLR_GRAY, 16777215 PIXEL

    @ 154, 170 SAY oSay15 PROMPT "Valor Pago:" SIZE 50, 010 OF oTPanel COLORS 0, 16777215 PIXEL
	oSay15:SetCSS( POSCSS (GetClassName(oSay15), CSS_LABEL_NORMAL))
	@ 152, 202 SAY oVlrRecD VAR Alltrim(Transform(nVlrRecD,PesqPict("SL1","L1_VLRLIQ"))) SIZE 060, 015 OF oTPanel COLOR 0, 16777215 PIXEL
	oVlrRecD:SetCSS( POSCSS (GetClassName(oVlrRecD), CSS_GET_NORMAL))
	oVlrRecD:lActive := .F.

	@ 154, 271 SAY oSay16 PROMPT "% Pago:" SIZE 50, 010 OF oTPanel COLORS 0, 16777215 PIXEL
	oSay16:SetCSS( POSCSS (GetClassName(oSay16), CSS_LABEL_NORMAL))
	@ 152, 295 SAY oPerRecD VAR Alltrim(Transform(nPerRecD,"@E 999.99 %")) SIZE 060, 015 OF oTPanel COLOR 0, 16777215 PIXEL
	oPerRecD:SetCSS( POSCSS (GetClassName(oPerRecD), CSS_GET_NORMAL))
	oPerRecD:lActive := .F.

    @ 173, 165 GROUP oGrp2 TO 203, 343 PROMPT cGrp2 OF oTPanel COLOR CLR_GRAY, 16777215 PIXEL

    @ 187, 170 SAY oSay17 PROMPT "Total Desc.:" SIZE 50, 010 OF oTPanel COLORS 0, 16777215 PIXEL
	oSay17:SetCSS( POSCSS (GetClassName(oSay17), CSS_LABEL_NORMAL))
	@ 185, 202 SAY oTotDesG VAR Alltrim(Transform(nTotDesG,PesqPict("SL1","L1_VLRLIQ"))) SIZE 060, 015 OF oTPanel COLOR 0, 16777215 PIXEL
	oTotDesG:SetCSS( POSCSS (GetClassName(oTotDesG), CSS_GET_NORMAL))
	oTotDesG:lActive := .F.

	@ 187, 253 SAY oSay18 PROMPT "Saldo a Pagar:" SIZE 50, 010 OF oTPanel COLORS 0, 16777215 PIXEL
	oSay18:SetCSS( POSCSS (GetClassName(oSay18), CSS_LABEL_NORMAL))
	@ 185, 295 SAY oSldRecD VAR Alltrim(Transform(nSldRec,PesqPict("SL1","L1_VLRLIQ"))) SIZE 060, 015 OF oTPanel COLOR 0, 16777215 PIXEL
	oSldRecD:SetCSS( POSCSS (GetClassName(oSldRecD), CSS_GET_NORMAL))
	oSldRecD:lActive := .F.

	// BOTAO CONFIRMAR
	oBtn1 := TButton():New(208,;
							293,;
							"&Confirmar"+CRLF+"(ALT+C)",;
							oTPanel	,;
							{|| iif(ValidaDesc(cForma), (lConfirm:=.T., oDlgDesc:End() ), Nil) },;
							050,;
							021,;
							,,,.T.,;
							,,,{|| .T.})
	oBtn1:SetCSS( POSCSS (GetClassName(oBtn1), CSS_BTN_FOCAL ))

	// BOTAO CANCELAR
	oBtn2 := TButton():New(208,;
							238,;
							"C&ancelar"+CRLF+"(ALT+A)",;
							oTPanel	,;
							{|| oDlgDesc:End() },;
							050,;
							021,;
							,,,.T.,;
							,,,{|| .T.})
	oBtn2:SetCSS( POSCSS (GetClassName(oBtn2), CSS_BTN_ATIVO ))


	oDlgDesc:bInit := {|| LjMsgRun("Aguarde... Carregando os descontos...",,{|| DoBuscarDes(cForma)}) } //faz busca dos dados para tela
	ACTIVATE MSDIALOG oDlgDesc CENTERED

	If lConfirm

		//aplicar descontos
		AtuARecebtos() //Validacao de campo -> CAMPO "RECEBIDO" -> recalcula os valores do aRecebtos
		SetDesconto(cForma)

	EndIf

	if Alltrim(cForma) == "R$"
		If ValType(oDINVlrRec) == "O"
			oDINVlrRec:SetFocus()
		EndIf
	elseif Alltrim(cForma) $ "CC|CD"
		If ValType(oCCVlrRec) == "O"
			oCCVlrRec:SetFocus()
		EndIf
	elseif Alltrim(cForma) == "CF"
		If ValType(oCFVlrRec) == "O"
			oCFVlrRec:SetFocus()
		EndIf
	elseif Alltrim(cForma) $ "NP|CT|"+cFPConv
		If ValType(oNPVlrRec) == "O"
			oNPVlrRec:SetFocus()
		EndIf
	elseif Alltrim(cForma) == "PX|PD"
		If ValType(oPIXVlrRec) == "O"
			oPIXVlrRec:SetFocus()
		EndIf
	elseif Alltrim(cForma) == "CH"
		If ValType(oCHVlrRec) == "O"
			oCHVlrRec:SetFocus()
		EndIf
	elseif Alltrim(cForma) == "NB"
		If ValType(oCRVlrRec) == "O"
			oCRVlrRec:SetFocus()
		EndIf
	endif

	//restaura as teclas atalho
	U_UKeyCtr(.T.) 

Return

//--------------------------------------------------------------
// monta grid de itens, para tela desconto
//--------------------------------------------------------------
Static Function DoGdDescon(oPanel, nTop, nLeft, nWidth, nHeigth)

	Local oNewGD, nX, nPosAux
	Local aHeaderEx 	:= {}
	Local aColsEx 		:= {}
	//Local aFieldFill 	:= {} -> aEmptyLPr
	Local aAlterFields 	:= {}
	Local nLinMax       := 999  //quantidade delinha na getdados
	Local aFields := {"LEG","L2_ITEM","L2_PRODUTO","L2_DESCRI","L2_QUANT","L2_PRCTAB","L2_XPRCNEG","L2_VRUNIT","L2_VLRITEM","L2_VALDESC","L1_VLRLIQ","LF_DESCVAL","LF_DESCPER","U25_FLAGVD"}
	Local aTitles := {"Leg","Item","Produto","Descrição","Quantidade","Prc. Unit.","Prc. Negoc.","Prc. Usado","Tot. Bruto","Tot. Descon.","Tot. Liquido","Vlr.Max.Desc.","% Max. Desc.","Prc.Neg.?"}

	aEmptyLPr := {}
	For nX := 1 to Len(aFields)
		If AllTrim(aFields[nX]) == "LEG"
			Aadd(aHeaderEx,{'','LEG','@BMP',2,0,'','€€€€€€€€€€€€€€','C','','','',''})
			Aadd(aEmptyLPr,'BR_BRANCO') //inicializa linha
		ElseIf AllTrim(aFields[nX]) == "L2_XPRCNEG"
			aadd(aHeaderEx, U_UAHEADER("L2_VRUNIT") )
			nPosAux := len(aHeaderEx)
			aHeaderEx[nPosAux][1] := aTitles[nX]
			aHeaderEx[nPosAux][2] := "L2_XPRCNEG"
			Aadd(aEmptyLPr, 0)
		Else
			aadd(aHeaderEx, U_UAHEADER(aFields[nX]) )
			nPosAux := len(aHeaderEx)
			aHeaderEx[nPosAux][1] := aTitles[nX]

			If aHeaderEx[nPosAux][8] == "N"
				Aadd(aEmptyLPr, 0)
			ElseIf aHeaderEx[nPosAux][8] == "D"
				Aadd(aEmptyLPr, CTOD(""))
			Else
				Aadd(aEmptyLPr, "")
			EndIf
		EndIf
	Next nX

	aadd(aEmptyLPr, .F.) //deleted
	aadd(aColsEx, aEmptyLPr)

	oNewGD := MsNewGetDados():New( nTop, nLeft, nHeigth, nWidth, , "AllwaysTrue", "AllwaysTrue", "AllwaysTrue", aAlterFields, , nLinMax,, "", "AllwaysTrue", oPanel, aHeaderEx, aColsEx)
	//oNewGD:oBrowse:SetCSS( POSCSS("TGRID", CSS_BROWSE) ) //CSS do totvs pdv
	oNewGD:oBrowse:nScrollType := 0 // mudo o tipo do scroll do grid para barra de rolagem

Return oNewGD

//---------------------------------------------------------------
// Função para enviar dados do grid para campos e vice-versa
//---------------------------------------------------------------
Static Function SendDadDes(nTipo,cCampo,xGet)

	Local lTodos  := (cCampo == Nil)

	If nTipo == 1 //se do grid para campos

		cProduto 	:= oNewGDDes:aCols[oNewGDDes:oBrowse:nAt][aScan(oNewGDDes:aHeader,{|x| AllTrim(x[2])=="L2_PRODUTO"})]
		cDescont 	:= oNewGDDes:aCols[oNewGDDes:oBrowse:nAt][aScan(oNewGDDes:aHeader,{|x| AllTrim(x[2])=="L2_DESCRI"}) ]
		nQuantid 	:= oNewGDDes:aCols[oNewGDDes:oBrowse:nAt][aScan(oNewGDDes:aHeader,{|x| AllTrim(x[2])=="L2_QUANT"})  ]
		nPrcUni 	:= oNewGDDes:aCols[oNewGDDes:oBrowse:nAt][aScan(oNewGDDes:aHeader,{|x| AllTrim(x[2])=="L2_PRCTAB"}) ]
		nPrcNeg 	:= oNewGDDes:aCols[oNewGDDes:oBrowse:nAt][aScan(oNewGDDes:aHeader,{|x| AllTrim(x[2])=="L2_XPRCNEG"})]
		nPrcUsa 	:= oNewGDDes:aCols[oNewGDDes:oBrowse:nAt][aScan(oNewGDDes:aHeader,{|x| AllTrim(x[2])=="L2_VRUNIT"}) ]
		nTotDesc 	:= oNewGDDes:aCols[oNewGDDes:oBrowse:nAt][aScan(oNewGDDes:aHeader,{|x| AllTrim(x[2])=="L2_VALDESC"})]
		nTotLiqu 	:= oNewGDDes:aCols[oNewGDDes:oBrowse:nAt][aScan(oNewGDDes:aHeader,{|x| AllTrim(x[2])=="L1_VLRLIQ"}) ]

	ElseIf nTipo == 2 //se do campo para grid

		If lTodos
			oNewGDDes:aCols[oNewGDDes:oBrowse:nAt][aScan(oNewGDDes:aHeader,{|x| AllTrim(x[2])=="L2_PRODUTO"})] := cProduto
			oNewGDDes:aCols[oNewGDDes:oBrowse:nAt][aScan(oNewGDDes:aHeader,{|x| AllTrim(x[2])=="L2_DESCRI"}) ] := cDescont
			oNewGDDes:aCols[oNewGDDes:oBrowse:nAt][aScan(oNewGDDes:aHeader,{|x| AllTrim(x[2])=="L2_QUANT"})  ] := nQuantid
			oNewGDDes:aCols[oNewGDDes:oBrowse:nAt][aScan(oNewGDDes:aHeader,{|x| AllTrim(x[2])=="L2_PRCTAB"}) ] := nPrcUni
			oNewGDDes:aCols[oNewGDDes:oBrowse:nAt][aScan(oNewGDDes:aHeader,{|x| AllTrim(x[2])=="L2_XPRCNEG"})] := nPrcNeg
			oNewGDDes:aCols[oNewGDDes:oBrowse:nAt][aScan(oNewGDDes:aHeader,{|x| AllTrim(x[2])=="L2_VRUNIT"}) ] := nPrcUsa
			oNewGDDes:aCols[oNewGDDes:oBrowse:nAt][aScan(oNewGDDes:aHeader,{|x| AllTrim(x[2])=="L2_VALDESC"})] := nTotDesc
			oNewGDDes:aCols[oNewGDDes:oBrowse:nAt][aScan(oNewGDDes:aHeader,{|x| AllTrim(x[2])=="L1_VLRLIQ"}) ] := nTotLiqu
		Else
			oNewGDDes:aCols[oNewGDDes:oBrowse:nAt][aScan(oNewGDDes:aHeader,{|x| AllTrim(x[2])==cCampo})] := xGet
		EndIf

	EndIf

Return

//--------------------------------------------------------------
// Carrega tela de descontos
//--------------------------------------------------------------
Static Function DoRefreshDes()

	Local nX

	nTotGBrut := 0
	nTotGDesc := 0
	nTotGLiqu := 0

	For nX := 1 to Len(oNewGDDes:aCols)
		nTotGLiqu += Round(oNewGDDes:aCols[nX][aScan(oNewGDDes:aHeader,{|x| AllTrim(x[2])=="L2_VRUNIT"})]*oNewGDDes:aCols[nX][aScan(oNewGDDes:aHeader,{|x| AllTrim(x[2])=="L2_QUANT"})],TamSx3("LR_VLRITEM")[2]) //A410Arred(oNewGDDes:aCols[nX][aScan(oNewGDDes:aHeader,{|x| AllTrim(x[2])=="L2_VRUNIT"})]*oNewGDDes:aCols[nX][aScan(oNewGDDes:aHeader,{|x| AllTrim(x[2])=="L2_QUANT"})],"LR_VLRITEM")
		nTotGBrut += Round(oNewGDDes:aCols[nX][aScan(oNewGDDes:aHeader,{|x| AllTrim(x[2])=="L2_PRCTAB"})]*oNewGDDes:aCols[nX][aScan(oNewGDDes:aHeader,{|x| AllTrim(x[2])=="L2_QUANT"})],TamSx3("LR_VLRITEM")[2]) //A410Arred(oNewGDDes:aCols[nX][aScan(oNewGDDes:aHeader,{|x| AllTrim(x[2])=="L2_PRCTAB"})]*oNewGDDes:aCols[nX][aScan(oNewGDDes:aHeader,{|x| AllTrim(x[2])=="L2_QUANT"})],"LR_VLRITEM")
		nTotGDesc += Round(oNewGDDes:aCols[nX][aScan(oNewGDDes:aHeader,{|x| AllTrim(x[2])=="L2_PRCTAB"})]*oNewGDDes:aCols[nX][aScan(oNewGDDes:aHeader,{|x| AllTrim(x[2])=="L2_QUANT"})],TamSx3("LR_VLRITEM")[2]) - Round(oNewGDDes:aCols[nX][aScan(oNewGDDes:aHeader,{|x| AllTrim(x[2])=="L2_VRUNIT"})]*oNewGDDes:aCols[nX][aScan(oNewGDDes:aHeader,{|x| AllTrim(x[2])=="L2_QUANT"})],TamSx3("LR_VLRITEM")[2]) //A410Arred(oNewGDDes:aCols[nX][aScan(oNewGDDes:aHeader,{|x| AllTrim(x[2])=="L2_PRCTAB"})]*oNewGDDes:aCols[nX][aScan(oNewGDDes:aHeader,{|x| AllTrim(x[2])=="L2_QUANT"})],"LR_VLRITEM") - A410Arred(oNewGDDes:aCols[nX][aScan(oNewGDDes:aHeader,{|x| AllTrim(x[2])=="L2_VRUNIT"})]*oNewGDDes:aCols[nX][aScan(oNewGDDes:aHeader,{|x| AllTrim(x[2])=="L2_QUANT"})],"LR_VLRITEM")
	Next nX

	nTotDesG := Round(nTotGDesc*(1-nPercent),TamSx3("LR_VLRITEM")[2]) //A410Arred(nTotGDesc*(1-nPercent),"LR_VLRITEM") //total de desconto (considerando outras formas)
	nSldRec	 := Round(nTotGLiqu*(1-nPercent),TamSx3("LR_VLRITEM")[2]) //A410Arred(nTotGLiqu*(1-nPercent),"LR_VLRITEM") //saldo a receber (considerando outras formas)

	oProd:Refresh()
	oDesc:Refresh()
	oQuant:Refresh()
	oPrcUni:Refresh()
	oPrcNeg:Refresh()
	oPrcUsa:Refresh()
	oTotDesc:Refresh()
	oTotLiqui:Refresh()
	oTotGBru:Refresh()
	oTotGDesc:Refresh()
	oTotGLiqui:Refresh()
	oVlrRecD:Refresh()
	oPerRecD:Refresh()
	oTotDesG:Refresh()
	oSldRecD:Refresh()

Return

//---------------------------------------------------------------
// Função para busca das informações no aRecebtos
//---------------------------------------------------------------
Static Function DoBuscarDes(cForma)

	Local nX
	Local aArea 	:= GetArea()
	Local aAreaSA1 	:= SA1->(GetArea())
	Local aAreaSB1 	:= SB1->(GetArea())

	Local oModelMaster	:= STDGPBModel()

	GetSelected(cForma)

	oModelMaster 	:= oModelMaster:GetModel("SL1MASTER")
	cGetCodCli 		:= oModelMaster:GetValue("L1_CLIENTE")
	cGetLoja 		:= oModelMaster:GetValue("L1_LOJA")
	cGrpCli 		:= Posicione("SA1",1,xFilial("SA1")+cGetCodCli+cGetLoja, "A1_GRPVEN")
	cGetPlaca 		:= oModelMaster:GetValue("L1_PLACA")

	If nAtaReceb > 0

		lCheque := AllTrim(aRecebtos[nAtaReceb][1])=="CH"
	    If lCheque
		    cNegocia := AllTrim(RetField("U44",1,xFilial("U44")+aRecebtos[nAtaReceb][1]+aRecebtos[nAtaReceb][2],"U44_DESCRI"))+" "+AllTrim(RetField("SA1",1,xFilial("SA1")+aRecebtos[nAtaReceb][3],"A1_NOME"))
	    Else
			cNegocia := AllTrim(RetField("U44",1,xFilial("U44")+aRecebtos[nAtaReceb][1]+aRecebtos[nAtaReceb][2],"U44_DESCRI"))+" "+AllTrim(RetField("SAE",1,xFilial("SAE")+aRecebtos[nAtaReceb][3],"AE_DESC"))
		EndIf
		cSay1 := "Detalhe de Desconto por Produto - " + cNegocia
		oSay1:Refresh()
		cGrp2 := " Saldo da Negociação - " + cNegocia + " "
		oGrp2:cCaption := cGrp2

		oNewGDDes:aCols := {}

		For nX := 1 to Len(aRecebtos[nAtaReceb][5]) //ja desconsidera os produtos com exceção

			Aadd(oNewGDDes:aCols, aClone(aEmptyLPr))

			oNewGDDes:aCols[nX][aScan(oNewGDDes:aHeader,{|x| AllTrim(x[2])=="LEG"})]		:= "BR_VERDE"

			oNewGDDes:aCols[nX][aScan(oNewGDDes:aHeader,{|x| AllTrim(x[2])=="L2_ITEM"})] 	:= aRecebtos[nAtaReceb][5][nX][1] //item
			oNewGDDes:aCols[nX][aScan(oNewGDDes:aHeader,{|x| AllTrim(x[2])=="L2_PRODUTO"})] := aRecebtos[nAtaReceb][5][nX][2] //prod
			oNewGDDes:aCols[nX][aScan(oNewGDDes:aHeader,{|x| AllTrim(x[2])=="L2_DESCRI"})] 	:= POSICIONE("SB1",1,xFilial("SB1")+aRecebtos[nAtaReceb][5][nX][2],"B1_DESC") //despro
			oNewGDDes:aCols[nX][aScan(oNewGDDes:aHeader,{|x| AllTrim(x[2])=="L2_QUANT"})] 	:= aRecebtos[nAtaReceb][5][nX][3] //quantidade
			oNewGDDes:aCols[nX][aScan(oNewGDDes:aHeader,{|x| AllTrim(x[2])=="L2_PRCTAB"})] 	:= aRecebtos[nAtaReceb][5][nX][4] //preco de tabela
			oNewGDDes:aCols[nX][aScan(oNewGDDes:aHeader,{|x| AllTrim(x[2])=="L2_XPRCNEG"})] := aRecebtos[nAtaReceb][5][nX][10] //preco negociado
			oNewGDDes:aCols[nX][aScan(oNewGDDes:aHeader,{|x| AllTrim(x[2])=="L2_VRUNIT"})] 	:= aRecebtos[nAtaReceb][5][nX][5] //preco utilizado
			oNewGDDes:aCols[nX][aScan(oNewGDDes:aHeader,{|x| AllTrim(x[2])=="L2_VLRITEM"})] := Round(aRecebtos[nAtaReceb][5][nX][3]*aRecebtos[nAtaReceb][5][nX][4],TamSx3("L2_VLRITEM")[2]) //A410Arred(aRecebtos[nAtaReceb][5][nX][3]*aRecebtos[nAtaReceb][5][nX][4],"L2_VLRITEM") //total bruto do item
			oNewGDDes:aCols[nX][aScan(oNewGDDes:aHeader,{|x| AllTrim(x[2])=="L1_VLRLIQ"})] 	:= Round(aRecebtos[nAtaReceb][5][nX][3]*aRecebtos[nAtaReceb][5][nX][5],TamSx3("L1_VLRLIQ")[2]) //A410Arred(aRecebtos[nAtaReceb][5][nX][3]*aRecebtos[nAtaReceb][5][nX][5],"L1_VLRLIQ") //total liquido do item
			oNewGDDes:aCols[nX][aScan(oNewGDDes:aHeader,{|x| AllTrim(x[2])=="L2_VALDESC"})] := oNewGDDes:aCols[nX][aScan(oNewGDDes:aHeader,{|x| AllTrim(x[2])=="L2_VLRITEM"})]-oNewGDDes:aCols[nX][aScan(oNewGDDes:aHeader,{|x| AllTrim(x[2])=="L1_VLRLIQ"})] //total de desconto
			oNewGDDes:aCols[nX][aScan(oNewGDDes:aHeader,{|x| AllTrim(x[2])=="LF_DESCVAL"})] := aRecebtos[nAtaReceb][5][nX][11]
			oNewGDDes:aCols[nX][aScan(oNewGDDes:aHeader,{|x| AllTrim(x[2])=="LF_DESCPER"})] := aRecebtos[nAtaReceb][5][nX][12]
			oNewGDDes:aCols[nX][aScan(oNewGDDes:aHeader,{|x| AllTrim(x[2])=="U25_FLAGVD"})]	:= iif(aRecebtos[nAtaReceb][5][nX][9]>0, "S", "N")

			_lCheque	:= alltrim(aRecebtos[nAtaReceb][1])=="CH"
			_cForma 	:= aRecebtos[nAtaReceb][1]
			_cCondicao	:= aRecebtos[nAtaReceb][2]

		    If _lCheque
			    _cAdmFin  := space(TamSX3("AE_COD")[1])
			    _cEmiten  := substr(aRecebtos[nAtaReceb][3],1,TamSX3("A1_COD")[1])
			    _cGetLojaEmi := substr(aRecebtos[nAtaReceb][3],TamSX3("A1_COD")[1]+1,TamSX3("A1_LOJA")[1])
		    Else
				_cAdmFin  := aRecebtos[nAtaReceb][3]
				_cEmiten  := space(TamSX3("A1_COD")[1])
			    _cGetLojaEmi := space(TamSX3("A1_LOJA")[1])
			EndIf

			nLF_DESCPER := RetTotDesP()
			nLF_DESCVAL := RetTotDesV()
			oNewGDDes:aCols[nX][aScan(oNewGDDes:aHeader,{|x| AllTrim(x[2])=="LF_DESCVAL"})] 	:= nLF_DESCVAL //valor desconto maximo
			oNewGDDes:aCols[nX][aScan(oNewGDDes:aHeader,{|x| AllTrim(x[2])=="LF_DESCPER"})] 	:= nLF_DESCPER //percentual desconto maximo

			DoValidNegDes(nX)

		Next nX

		If Empty(oNewGDDes:aCols)
			Aadd(oNewGDDes:aCols, aClone(aEmptyLPr))
		EndIf

		SendDadDes(1)
		DoRefreshDes()
		AtuaListDes()

		oListGdDes:GoTop()
		oListGdDes:SetFocus()

	EndIf

	RestArea(aAreaSB1)
	RestArea(aAreaSA1)
	RestArea(aArea)

Return

//---------------------------------------------------------------
// Função que faz a atualização do listbox dos prod no desconto
//---------------------------------------------------------------
Static Function AtuaListDes(nPos)

	Local nX := 0
	//Local nBkp := oListGdDes:nAt
	Default nPos := Nil
	//{"LEG","L2_ITEM","L2_PRODUTO","L2_DESCRI","L2_QUANT","L2_PRCTAB","L2_XPRCNEG","L2_VRUNIT","L2_VLRITEM","L2_VALDESC","L1_VLRLIQ","LF_DESCVAL","LF_DESCPER"}

	If nPos == Nil //atualiza todos
		aListGdDes := {}
		For nX:=1 to Len(oNewGDDes:aCols)
			//XX - 000001 / BLABLABLA / QTD: 3,00 x R$2,33 = R$6,99 (-R$2,00)
			aadd(aListGdDes,;
							oNewGDDes:aCols[nX][aScan(oNewGDDes:aHeader,{|x| AllTrim(x[2])=="L2_ITEM"})]+' - '+;
							AllTrim(oNewGDDes:aCols[nX][aScan(oNewGDDes:aHeader,{|x| AllTrim(x[2])=="L2_PRODUTO"})])+' / '+;
							AllTrim(oNewGDDes:aCols[nX][aScan(oNewGDDes:aHeader,{|x| AllTrim(x[2])=="L2_DESCRI"})])+' / '+;
							'QTD: '+Alltrim(Transform(oNewGDDes:aCols[nX][aScan(oNewGDDes:aHeader,{|x| AllTrim(x[2])=="L2_QUANT"})],PesqPict("SL2","L2_QUANT")))+' x '+;
							'R$'+Alltrim(Transform(oNewGDDes:aCols[nX][aScan(oNewGDDes:aHeader,{|x| AllTrim(x[2])=="L2_VRUNIT"})],PesqPict("SL2","L2_VRUNIT")))+' = '+;
							'R$'+Alltrim(Transform(oNewGDDes:aCols[nX][aScan(oNewGDDes:aHeader,{|x| AllTrim(x[2])=="L1_VLRLIQ"})],PesqPict("SL1","L1_VLRLIQ")))+' '+;
							iif(oNewGDDes:aCols[nX][aScan(oNewGDDes:aHeader,{|x| AllTrim(x[2])=="L2_VALDESC"})]>0,' (-DESC R$'+Alltrim(Transform(oNewGDDes:aCols[nX][aScan(oNewGDDes:aHeader,{|x| AllTrim(x[2])=="L2_VALDESC"})],PesqPict("SL2","L2_VALDESC")))+')','')+' '+;
							iif(oNewGDDes:aCols[nX][aScan(oNewGDDes:aHeader,{|x| AllTrim(x[2])=="L2_VALDESC"})]<0,' (+ACRE R$'+Alltrim(Transform(-1*oNewGDDes:aCols[nX][aScan(oNewGDDes:aHeader,{|x| AllTrim(x[2])=="L2_VALDESC"})],PesqPict("SL2","L2_VALDESC")))+')','');
							)
		Next nX
		oListGdDes:SetItems(aListGdDes)

	Else

		aListGdDes[nPos] := ""+;
						oNewGDDes:aCols[nPos][aScan(oNewGDDes:aHeader,{|x| AllTrim(x[2])=="L2_ITEM"})]+' - '+;
						AllTrim(oNewGDDes:aCols[nPos][aScan(oNewGDDes:aHeader,{|x| AllTrim(x[2])=="L2_PRODUTO"})])+' / '+;
						AllTrim(oNewGDDes:aCols[nPos][aScan(oNewGDDes:aHeader,{|x| AllTrim(x[2])=="L2_DESCRI"})])+' / '+;
						'QTD: '+Alltrim(Transform(oNewGDDes:aCols[nPos][aScan(oNewGDDes:aHeader,{|x| AllTrim(x[2])=="L2_QUANT"})],PesqPict("SL2","L2_QUANT")))+' x '+;
						'R$'+Alltrim(Transform(oNewGDDes:aCols[nPos][aScan(oNewGDDes:aHeader,{|x| AllTrim(x[2])=="L2_VRUNIT"})],PesqPict("SL2","L2_VRUNIT")))+' = '+;
						'R$'+Alltrim(Transform(oNewGDDes:aCols[nPos][aScan(oNewGDDes:aHeader,{|x| AllTrim(x[2])=="L1_VLRLIQ"})],PesqPict("SL1","L1_VLRLIQ")))+' '+;
						iif(oNewGDDes:aCols[nPos][aScan(oNewGDDes:aHeader,{|x| AllTrim(x[2])=="L2_VALDESC"})]>0,' (-DESC R$'+Alltrim(Transform(oNewGDDes:aCols[nPos][aScan(oNewGDDes:aHeader,{|x| AllTrim(x[2])=="L2_VALDESC"})],PesqPict("SL2","L2_VALDESC")))+')','')+' '+;
						iif(oNewGDDes:aCols[nPos][aScan(oNewGDDes:aHeader,{|x| AllTrim(x[2])=="L2_VALDESC"})]<0,' (+ACRE R$'+Alltrim(Transform(-1*oNewGDDes:aCols[nPos][aScan(oNewGDDes:aHeader,{|x| AllTrim(x[2])=="L2_VALDESC"})],PesqPict("SL2","L2_VALDESC")))+')','')

		oListGdDes:SetItems(aListGdDes)

	EndIf

	oListGdDes:nAt := oNewGDDes:oBrowse:nAt

Return

//---------------------------------------------------------------
// Função que faz a validação dos campos
//---------------------------------------------------------------
Static Function ValidCamDes(cCampo)

	Local lRet := .T.
	Local nBkp := 0

	If (cCampo <> Nil)

		nPosCpo := aScan(oNewGDDes:aHeader,{|x| AllTrim(x[2])==cCampo})
		nBkp := oNewGDDes:aCols[oNewGDDes:oBrowse:nAt][nPosCpo]

		If cCampo == "L2_VRUNIT"
			If nPrcUsa == oNewGDDes:aCols[oNewGDDes:oBrowse:nAt][nPosCpo]
				Return lRet
			EndIf
			SendDadDes(2,cCampo,nPrcUsa)
		ElseIf cCampo == "L2_VALDESC"
			If nTotDesc == oNewGDDes:aCols[oNewGDDes:oBrowse:nAt][nPosCpo]
				Return lRet
			EndIf
			SendDadDes(2,cCampo,nTotDesc)
		ElseIf cCampo == "L1_VLRLIQ"
			If nTotLiqu == oNewGDDes:aCols[oNewGDDes:oBrowse:nAt][nPosCpo]
				Return lRet
			EndIf
			SendDadDes(2,cCampo,nTotLiqu)
		EndIf

		lRet := DoRecalcProDes(cCampo)

		If lRet
			SendDadDes(1)
		Else
			nPosCpo	:= aScan(oNewGDDes:aHeader,{|x| AllTrim(x[2])==cCampo})
			If cCampo == "L2_VRUNIT"
				nPrcUsa := nBkp
			ElseIf cCampo == "L2_VALDESC"
				nTotDesc := nBkp
			ElseIf cCampo == "L1_VLRLIQ"
				nTotLiqu := nBkp
			EndIf
			oNewGDDes:aCols[oNewGDDes:oBrowse:nAt][nPosCpo] := nBkp
		EndIf

		DoRefreshDes()

		AtuaListDes(oListGdDes:nAt)

	EndIf

Return lRet

//----------------------------------------------------------------------
// Função para recalcular os precos dos itens, pelos preco dos totais
//----------------------------------------------------------------------
Static Function DoRecalcTotDes(cCampo)

	Loca nX
	Local lRet := .T.
	Local aBkpAcols := aClone(oNewGDDes:aCols)
	Local nVlrTot := 0, nDesTot := 0, nVllTot := 0

	For nX := 1 to Len(oNewGDDes:aCols)
		nVlrTot += oNewGDDes:aCols[nX][aScan(oNewGDDes:aHeader,{|x| AllTrim(x[2])=="L2_VLRITEM"})]
		nDesTot += oNewGDDes:aCols[nX][aScan(oNewGDDes:aHeader,{|x| AllTrim(x[2])=="L2_VALDESC"})]
		nVllTot += oNewGDDes:aCols[nX][aScan(oNewGDDes:aHeader,{|x| AllTrim(x[2])=="L1_VLRLIQ"})]
	Next nX

	nVlrTot := Round(nVlrTot,TamSx3("LR_VLRITEM")[2]) //A410Arred(nVlrTot,"LR_VLRITEM") //total produtos
	nDesTot := Round(nDesTot,TamSx3("LR_VLRITEM")[2]) //A410Arred(nDesTot,"LR_VLRITEM") //total de desconto
	nVllTot := Round(nVllTot,TamSx3("LR_VLRITEM")[2]) //A410Arred(nVllTot,"LR_VLRITEM") //total liquido

	Do Case

		Case cCampo == "L1_VLRLIQ" .and. nVllTot <> nTotGLiqu
			For nX := 1 to Len(oNewGDDes:aCols)
				oNewGDDes:aCols[nX][aScan(oNewGDDes:aHeader,{|x| AllTrim(x[2])=="L1_VLRLIQ"})] := Round((oNewGDDes:aCols[nX][aScan(oNewGDDes:aHeader,{|x| AllTrim(x[2])=="L2_VLRITEM"})]/nTotGBrut)*nTotGLiqu,TamSx3("LR_VLRITEM")[2]) //A410Arred((oNewGDDes:aCols[nX][aScan(oNewGDDes:aHeader,{|x| AllTrim(x[2])=="L2_VLRITEM"})]/nTotGBrut)*nTotGLiqu,"LR_VLRITEM")
				lRet := DoRecalcProDes("L1_VLRLIQ",nX)
				If !lRet
					Exit
				EndIf
			Next nX
			If lRet
				SendDadDes(1)
			Else
				oNewGDDes:aCols := aClone(aBkpAcols)
			EndIf
			DoRefreshDes()
			AtuaListDes()

		Case cCampo == "L1_DESCONT" .and. nDesTot <> nTotGDesc
			For nX := 1 to Len(oNewGDDes:aCols)
				oNewGDDes:aCols[nX][aScan(oNewGDDes:aHeader,{|x| AllTrim(x[2])=="L2_VALDESC"})] := Round((oNewGDDes:aCols[nX][aScan(oNewGDDes:aHeader,{|x| AllTrim(x[2])=="L2_VLRITEM"})]/nTotGBrut)*nTotGDesc,TamSx3("LR_VLRITEM")[2])//A410Arred((oNewGDDes:aCols[nX][aScan(oNewGDDes:aHeader,{|x| AllTrim(x[2])=="L2_VLRITEM"})]/nTotGBrut)*nTotGDesc,"LR_VLRITEM")
				lRet := DoRecalcProDes("L2_VALDESC",nX)
				If !lRet
					Exit
				EndIf
			Next nX
			If lRet
				SendDadDes(1)
			Else
				oNewGDDes:aCols := aClone(aBkpAcols)
			EndIf
			DoRefreshDes()
			AtuaListDes()

	EndCase

Return lRet

//---------------------------------------------------------------
// Função para recalcular os precos dos itens
//---------------------------------------------------------------
Static Function DoRecalcProDes(cCampo,nPosPro)

	Local lRet 		:= .T.
	Local aBkpAcols := {}
	Default nPosPro := oNewGDDes:oBrowse:nAt

	aBkpAcols := aClone(oNewGDDes:aCols[nPosPro])

	Do Case
		Case cCampo == "L2_VRUNIT" //preço usado
			lRet := DoValidNegDes(nPosPro)
			If lRet
				oNewGDDes:aCols[nPosPro][aScan(oNewGDDes:aHeader,{|x| AllTrim(x[2])=="L1_VLRLIQ"})]	 := Round(oNewGDDes:aCols[nPosPro][aScan(oNewGDDes:aHeader,{|x| AllTrim(x[2])=="L2_QUANT"})]*oNewGDDes:aCols[nPosPro][aScan(oNewGDDes:aHeader,{|x| AllTrim(x[2])=="L2_VRUNIT"})],TamSx3("L1_VLRLIQ")[2]) //A410Arred(oNewGDDes:aCols[nPosPro][aScan(oNewGDDes:aHeader,{|x| AllTrim(x[2])=="L2_QUANT"})]*oNewGDDes:aCols[nPosPro][aScan(oNewGDDes:aHeader,{|x| AllTrim(x[2])=="L2_VRUNIT"})],"L1_VLRLIQ")
				oNewGDDes:aCols[nPosPro][aScan(oNewGDDes:aHeader,{|x| AllTrim(x[2])=="L2_VALDESC"})] := oNewGDDes:aCols[nPosPro][aScan(oNewGDDes:aHeader,{|x| AllTrim(x[2])=="L2_VLRITEM"})] - oNewGDDes:aCols[nPosPro][aScan(oNewGDDes:aHeader,{|x| AllTrim(x[2])=="L1_VLRLIQ"})]
			EndIf
		Case cCampo == "L1_VLRLIQ" //total liquido do item
			oNewGDDes:aCols[nPosPro][aScan(oNewGDDes:aHeader,{|x| AllTrim(x[2])=="L2_VRUNIT"})]	:= Round( oNewGDDes:aCols[nPosPro][aScan(oNewGDDes:aHeader,{|x| AllTrim(x[2])=="L1_VLRLIQ"})]/oNewGDDes:aCols[nPosPro][aScan(oNewGDDes:aHeader,{|x| AllTrim(x[2])=="L2_QUANT"})] ,3) //round(oNewGDDes:aCols[nPosPro][aScan(oNewGDDes:aHeader,{|x| AllTrim(x[2])=="L1_VLRLIQ"})]/oNewGDDes:aCols[nPosPro][aScan(oNewGDDes:aHeader,{|x| AllTrim(x[2])=="L2_QUANT"})],3)
			lRet := DoValidNegDes(nPosPro)
			If lRet
				oNewGDDes:aCols[nPosPro][aScan(oNewGDDes:aHeader,{|x| AllTrim(x[2])=="L1_VLRLIQ"})]	 := Round(oNewGDDes:aCols[nPosPro][aScan(oNewGDDes:aHeader,{|x| AllTrim(x[2])=="L2_QUANT"})]*oNewGDDes:aCols[nPosPro][aScan(oNewGDDes:aHeader,{|x| AllTrim(x[2])=="L2_VRUNIT"})],TamSx3("L1_VLRLIQ")[2]) //A410Arred(oNewGDDes:aCols[nPosPro][aScan(oNewGDDes:aHeader,{|x| AllTrim(x[2])=="L2_QUANT"})]*oNewGDDes:aCols[nPosPro][aScan(oNewGDDes:aHeader,{|x| AllTrim(x[2])=="L2_VRUNIT"})],"L1_VLRLIQ")
				oNewGDDes:aCols[nPosPro][aScan(oNewGDDes:aHeader,{|x| AllTrim(x[2])=="L2_VALDESC"})] := oNewGDDes:aCols[nPosPro][aScan(oNewGDDes:aHeader,{|x| AllTrim(x[2])=="L2_VLRITEM"})] - oNewGDDes:aCols[nPosPro][aScan(oNewGDDes:aHeader,{|x| AllTrim(x[2])=="L1_VLRLIQ"})]
				if oNewGDDes:aCols[nPosPro][aScan(oNewGDDes:aHeader,{|x| AllTrim(x[2])=="L1_VLRLIQ"})] <> aBkpAcols[aScan(oNewGDDes:aHeader,{|x| AllTrim(x[2])=="L1_VLRLIQ"})]
					MsgInfo("Não é possível chegar a um valor unitário exato com o valor digitado! Foi recalculado para o valor mais proximo possível.")
				endif
			EndIf
		Case cCampo == "L2_VALDESC" //total de desconto do item
			oNewGDDes:aCols[nPosPro][aScan(oNewGDDes:aHeader,{|x| AllTrim(x[2])=="L1_VLRLIQ"})]	:= oNewGDDes:aCols[nPosPro][aScan(oNewGDDes:aHeader,{|x| AllTrim(x[2])=="L2_VLRITEM"})] - oNewGDDes:aCols[nPosPro][aScan(oNewGDDes:aHeader,{|x| AllTrim(x[2])=="L2_VALDESC"})]
			oNewGDDes:aCols[nPosPro][aScan(oNewGDDes:aHeader,{|x| AllTrim(x[2])=="L2_VRUNIT"})]	:= Round(oNewGDDes:aCols[nPosPro][aScan(oNewGDDes:aHeader,{|x| AllTrim(x[2])=="L1_VLRLIQ"})]/oNewGDDes:aCols[nPosPro][aScan(oNewGDDes:aHeader,{|x| AllTrim(x[2])=="L2_QUANT"})], 3) //round(oNewGDDes:aCols[nPosPro][aScan(oNewGDDes:aHeader,{|x| AllTrim(x[2])=="L1_VLRLIQ"})]/oNewGDDes:aCols[nPosPro][aScan(oNewGDDes:aHeader,{|x| AllTrim(x[2])=="L2_QUANT"})],3)
			lRet := DoValidNegDes(nPosPro)
			If lRet
				oNewGDDes:aCols[nPosPro][aScan(oNewGDDes:aHeader,{|x| AllTrim(x[2])=="L1_VLRLIQ"})]	 := Round(oNewGDDes:aCols[nPosPro][aScan(oNewGDDes:aHeader,{|x| AllTrim(x[2])=="L2_QUANT"})]*oNewGDDes:aCols[nPosPro][aScan(oNewGDDes:aHeader,{|x| AllTrim(x[2])=="L2_VRUNIT"})],TamSx3("L1_VLRLIQ")[2]) //A410Arred(oNewGDDes:aCols[nPosPro][aScan(oNewGDDes:aHeader,{|x| AllTrim(x[2])=="L2_QUANT"})]*oNewGDDes:aCols[nPosPro][aScan(oNewGDDes:aHeader,{|x| AllTrim(x[2])=="L2_VRUNIT"})],"L1_VLRLIQ")
				oNewGDDes:aCols[nPosPro][aScan(oNewGDDes:aHeader,{|x| AllTrim(x[2])=="L2_VALDESC"})] := oNewGDDes:aCols[nPosPro][aScan(oNewGDDes:aHeader,{|x| AllTrim(x[2])=="L2_VLRITEM"})] - oNewGDDes:aCols[nPosPro][aScan(oNewGDDes:aHeader,{|x| AllTrim(x[2])=="L1_VLRLIQ"})]
				if oNewGDDes:aCols[nPosPro][aScan(oNewGDDes:aHeader,{|x| AllTrim(x[2])=="L1_VLRLIQ"})] <> aBkpAcols[aScan(oNewGDDes:aHeader,{|x| AllTrim(x[2])=="L1_VLRLIQ"})]
					MsgInfo("Não é possível chegar a um valor unitário exato com o valor digitado! Foi recalculado para o valor mais proximo possível.")
				endif
			EndIf
	EndCase

	If !lRet
		oNewGDDes:aCols[nPosPro] := aClone(aBkpAcols)
	EndIf

Return lRet

//----------------------------------------------------------------------
// Função para recalcular os precos dos itens, pelos preco dos totais
//----------------------------------------------------------------------
Static Function DoValidNegDes(nX)

	Local lRet 		:= .T.
	Local lAlcada	:= SuperGetMv("ES_ALCADA",.T.,.F.)
	Local lAlcDes	:= SuperGetMv( "ES_ALCDES",.F.,.F.)
	Local lAlcDPN	:= SuperGetMv( "ES_ALCDPN",.F.,.F.) //desconto sobre preço negociado
	
	Local nVDescMax := oNewGDDes:aCols[nX][aScan(oNewGDDes:aHeader,{|x| AllTrim(x[2])=="LF_DESCVAL"})]
	Local nPDescMax := oNewGDDes:aCols[nX][aScan(oNewGDDes:aHeader,{|x| AllTrim(x[2])=="LF_DESCPER"})]
	Local _nPrcUni  := oNewGDDes:aCols[nX][aScan(oNewGDDes:aHeader,{|x| AllTrim(x[2])=="L2_PRCTAB"})]  //preco unitario de tabela "Prc. Unit."
	Local _nPrcNeg  := oNewGDDes:aCols[nX][aScan(oNewGDDes:aHeader,{|x| AllTrim(x[2])=="L2_XPRCNEG"})] //preco negociado "Prc. Negoc."
	Local _nPrcUsa  := oNewGDDes:aCols[nX][aScan(oNewGDDes:aHeader,{|x| AllTrim(x[2])=="L2_VRUNIT"})]  //preco utilizado (digitado) "Prc. Usado"
	Local lHasU25	:= oNewGDDes:aCols[nX][aScan(oNewGDDes:aHeader,{|x| AllTrim(x[2])=="U25_FLAGVD"})]=="S" //tem preço negociado U25? S/N
	Local cMsgSeq   := "Item: "+AllTrim(oNewGDDes:aCols[nX][aScan(oNewGDDes:aHeader,{|x| AllTrim(x[2])=="L2_ITEM"})])+" - Produto: "+AllTrim(oNewGDDes:aCols[nX][aScan(oNewGDDes:aHeader,{|x| AllTrim(x[2])=="L2_PRODUTO"})])+" - "+AllTrim(oNewGDDes:aCols[nX][aScan(oNewGDDes:aHeader,{|x| AllTrim(x[2])=="L2_DESCRI"})])+CRLF
	Local cBaseDesc := SuperGetMv( "ES_ALCBDES",.F.,"0") //0-Preço Bomba/Tabela; 1=Preço Negociado/Base
	Local nBaseDesc := 0

	//Definição dos bloqueios:
	//1a Posicao: S/N - Bloqueio de Desconto sobre Preço Negociado
	//2a Posicao: S/N - Bloqueio de Desconto em Percentual ou Valor
	Local cStrBlq	:= "NN"

	/*/ MV_XATUPRC - tipo de negociação no Totvs PDV: DESCONTO ou PREÇO UNITÁRIO
		.T. - Trabalha com preço maior que o preço de tabela (não tem desconto, ajuste preço unitário)
		.F. - Trabalha com desconto no preço de tabela (não ajusta preço unitário, trabalha com desconto)
	/*/
	Local lAltVrUnit := SuperGetMv("MV_XATUPRC",.T./*lHelp*/,.T./*uPadrao*/)

	if _nPrcUsa <= 0
		cMsgSeq += "O 'Preço Usado' deve ser maior que zero."+CRLF
		Help('',1,'Prc. Unit.',,cMsgSeq,1,0,,,,,,{"Informe um preço maior que zero!"})
		lRet := .F.
	endif

	If lRet .AND. !lAltVrUnit .AND. _nPrcUsa > _nPrcUni
		cMsgSeq += "O 'Preço Usado' não pode ser maior do que o preço de tabela."+CRLF
		Help('',1,'Prc. Unit.',,cMsgSeq,1,0,,,,,,{"Prc. Tabela: "+Alltrim(Transform(_nPrcUsa,PesqPict("SL2","L2_PRCTAB")))})
		lRet := .F.
	EndIf

	If lRet .AND. _nPrcUsa >= _nPrcNeg //para desconto menor do que o negociado, não existe necessidade de validação
		oNewGDDes:aCols[nX][aScan(oNewGDDes:aHeader,{|x| AllTrim(x[2])=="LEG"})] := cStrBlq
		Return lRet //valor do item ("Prc. Usado") é maior ou igual ao negociado ("Prc. Negoc.")
	EndIf

	//DANILO: alterado para que identifique que tem preço negociado: lHasU25
	//if lRet .AND. lAlcada .AND. lAlcDPN .AND. _nPrcUni <> _nPrcNeg .AND. _nPrcNeg <> _nPrcUsa .AND. _nPrcUsa < _nPrcNeg //somente se tem preço negociado
	if lRet .AND. lAlcada .AND. lAlcDPN .AND. lHasU25 .AND. _nPrcUsa < _nPrcNeg //somente se tem preço negociado
		cMsgSeq += "O 'Preço Usado' está abaixo do preço negociado."+CRLF
		cStrBlq := "S"+SubStr(cStrBlq,2)
	endif

	if cBaseDesc == "1" //se base desconto é preço base
		nBaseDesc := _nPrcNeg
	else
		nBaseDesc := _nPrcUni
	endif

	If lRet .AND. nVDescMax >= 0 .AND. _nPrcUsa > 0 .AND. _nPrcUsa < (nBaseDesc-nVDescMax)
		cMsgSeq += "O 'Preço Usado' está abaixo do valor máximo de desconto."+CRLF
		If lAlcada .AND. lAlcDes
			cStrBlq := SubStr(cStrBlq,1,1)+"S"
		Else
			Help('',1,'Vlr.Max.Desc.',,cMsgSeq,1,0,,,,,,{"Vlr.Max.Desc.: "+Alltrim(Transform(nVDescMax,PesqPict("SLF","LF_DESCVAL")))})
			lRet := .F.
		EndIf
	elseif lRet .AND. nPDescMax >= 0 .AND. _nPrcUsa > 0 .AND. _nPrcUsa < (nBaseDesc*(1-(nPDescMax/100)))
		cMsgSeq += "O 'Preço Usado' está abaixo do percentual máximo de desconto."+CRLF
		If lAlcada .AND. lAlcDes
			cStrBlq := SubStr(cStrBlq,1,1)+"S"
		Else
			Help('',1,'% Max. Desc.',,cMsgSeq,1,0,,,,,,{"% Max. Desc.: "+Alltrim(Transform(nPDescMax,PesqPict("SLF","LF_DESCPER")))})
			lRet := .F.
		EndIf
	EndIf

	if lRet
		oNewGDDes:aCols[nX][aScan(oNewGDDes:aHeader,{|x| AllTrim(x[2])=="LEG"})] := cStrBlq
	endif

Return lRet

//--------------------------------------------------------------
// Carrega campos da tela a partir da linha do grid selecionada
//--------------------------------------------------------------
Static Function LoadSelDes()

	If oListGdDes:nAt > 0 .and. oNewGDDes:nAt <> oListGdDes:nAt
		oNewGDDes:nAt := oListGdDes:nAt //oListGdDes:GetPos()
		oNewGDDes:oBrowse:nAt := oListGdDes:nAt //oListGdDes:GetPos()
	EndIf

	SendDadDes(1)
	DoRefreshDes()

Return

//--------------------------------------------------------------
// Valida confirmar tela de descontos
//--------------------------------------------------------------
Static Function ValidaDesc(cForma)

	Local lRet   := .T.
	Local aProds := {}
	Local nPosPro:=0, nX:=0
	Local cPosLeg := aScan(oNewGDDes:aHeader,{|x| AllTrim(x[2])=="LEG"})
	Local aBkpRecbtos := aClone(aRecebtos)
	Local lAlcada	:= SuperGetMv("ES_ALCADA",,.F.)
	Local lAlcDes	:= SuperGetMv( "ES_ALCDES",.F.,.F.) // desconto por Valor ou Percentual
	Local lAlcDPN	:= SuperGetMv( "ES_ALCDPN",.F.,.F.) // desconto sobre preço negociado
	Local lAlcLid	:= SuperGetMV( "ES_ALCLID",.F.,.F.) // limite de desconto por período
	Local cBaseDesc := SuperGetMv( "ES_ALCBDES",.F.,"0") //0-Preço Bomba/Tabela; 1=Preço Negociado/Base
	Local lBlqDesconto  := .F.
	Local nBkpVlrDescTot := nVlrDescTot

	GetSelected(cForma)

	If nAtaReceb > 0
		//produtos: array -> {{"ITEM","CODIGO","QUANTIDADE","PREÇO PADRAO","PREÇO UTILIZADO","LIMT TROCO","VLR MAX TR","% MAX TR","RECNO U25","PREÇO NEGOCIADO","BLQ ALCADA","USUARIO"}, ...}
		aProds := aClone(aRecebtos[nAtaReceb][5])

		For nX:=1 to Len(oNewGDDes:aCols)
			nPosPro := aScan(aProds,{|x| AllTrim(x[1])==AllTrim(oNewGDDes:aCols[nX][aScan(oNewGDDes:aHeader,{|x| AllTrim(x[2])=="L2_ITEM"})])})
			If nPosPro > 0
				aProds[nPosPro][5]  := oNewGDDes:aCols[nX][aScan(oNewGDDes:aHeader,{|x| AllTrim(x[2])=="L2_VRUNIT"})] //PRECO UTILIZADO
				aProds[nPosPro][15] := oNewGDDes:aCols[nX][cPosLeg] //Iif( oNewGDDes:aCols[nX][cPosLeg]=="BR_VERMELHO", "S", "" )
				If lAlcada .AND. (lAlcDes .or. lAlcDPN .or. lAlcLid) .AND. "S" $ aProds[nPosPro][15]
					lBlqDesconto := .T.
					If cBaseDesc == "1" //se base desconto é preço negociado/preço base
						nVlrDescTot += (aProds[nPosPro][10]-aProds[nPosPro][5])
					Else
						nVlrDescTot += (aProds[nPosPro][4]-aProds[nPosPro][5])
					EndIf
				EndIf
			EndIf
		Next nX

		aRecebtos[nAtaReceb][5] := aClone(aProds)
		aRecebtos[nAtaReceb][6] := nTotGBrut
		aRecebtos[nAtaReceb][7] := nTotGLiqu
		aRecebtos[nAtaReceb][8] := nTotGDesc
		
		If lBlqDesconto
			//libera alçada de desconto
			lRet := LibDescAlcada() //verifico alçada do proprio usuario
			If !lRet
				lRet := TelaLibAlcada() //abre-se a tela de alçada (login)
			EndIf
		EndIf

	EndIf

	//restauro
	if !lRet
		aRecebtos := aClone(aBkpRecbtos)
		nVlrDescTot := nBkpVlrDescTot
	endif

Return lRet

//----------------------------------------------------------------------------------------------
// Caso usuario logado não tenha saldo para liberar a venda, abre-se a tela de alçada (login)
//----------------------------------------------------------------------------------------------
Static Function TelaLibAlcada()
	
	Local lRet := .F.
	Local lEscape := .T.
	Local cMsgErr := "Bloqueio de Descontos!" + CRLF + "Solicite liberação por alçada de um supervisor. " + CRLF
	Local aLogin
	Local cItBlq := ""
	Local nY
	Local lAlcClb := SuperGetMv("MV_XALCCLB",,.F.) //Habilita liberação de alçadas por código de liberação (default .F.)
	Local lAlcDes := SuperGetMv( "ES_ALCDES",.F.,.F.) // desconto por Valor ou Percentual
	Local lAlcDPN := SuperGetMv( "ES_ALCDPN",.F.,.F.) // desconto sobre preço negociado
	Local lAlcLid := SuperGetMV( "ES_ALCLID",.F.,.F.) // limite de desconto por período

	While lEscape
		
		cItBlq := ""
		For nY:=1 to Len(aRecebtos[nAtaReceb][5])
			if aRecebtos[nAtaReceb][5][nY][15] == "SS" .and. lAlcDPN .and. lAlcDes 
				cItBlq += "- Item " + aRecebtos[nAtaReceb][5][nY][1] +": Desconto abaixo do preço negociado e maior que permitido." + CRLF
			elseif aRecebtos[nAtaReceb][5][nY][15] == "SN" .and. lAlcDPN
				cItBlq += "- Item " + aRecebtos[nAtaReceb][5][nY][1] +": Desconto abaixo do preço negociado." + CRLF
			elseif aRecebtos[nAtaReceb][5][nY][15] == "NS" .and. lAlcDes
				cItBlq += "- Item " + aRecebtos[nAtaReceb][5][nY][1] +": Desconto maior que permitido." + CRLF
			endif
		next nY

		if !Empty(cItBlq)
			cItBlq := CRLF + "Itens Bloqueados: " + CRLF + cItBlq
			cMsgErr += cItBlq
		endif

		if lAlcLid .and. nVlrDescTot > 0
			cMsgErr += CRLF
			cMsgErr += "Limite de Desconto a ser liberado por período: "+cValToChar(nVlrDescTot)+"." + CRLF
		endif

		aLogin := U_TelaLogin(cMsgErr,"Bloqueio de Desconto", .T., lAlcClb)
		if empty(aLogin) //cancelou tela
			lEscape := .F.
		else
			if lAlcClb .and. aLogin[1] = 'XXXXXX' .and. !Empty(aLogin[2]) //foi liberado via Código de Liberação
				lRet := LibDescCodLib(aLogin[2])
				lEscape := .F.
			else
				lRet := LibDescAlcada(aLogin[1])
				if !lRet
					cMsgErr := "Usuário "+Alltrim(aLogin[2])+" não possui alçada suficiente para liberar o desconto!" + CRLF
				endif
				lEscape := !lRet
			endif
		endif
	enddo

Return lRet

//--------------------------------------------------------------
// Tenta fazer liberação via código de liberação
//--------------------------------------------------------------
Static Function LibDescCodLib(cCodLib)

	Local nY
	Local cMsgLog := "", cMsgLogAux := ""
	Local oModelMaster	:= STDGPBModel()
	Local cBaseDesc := SuperGetMv( "ES_ALCBDES",.F.,"0") //0-Preço Bomba/Tabela; 1=Preço Negociado/Base

	oModelMaster 	:= oModelMaster:GetModel("SL1MASTER")
	cGetCodCli 		:= oModelMaster:GetValue("L1_CLIENTE")
	cGetLoja 		:= oModelMaster:GetValue("L1_LOJA")

	SA1->(DbSetOrder(1)) //A1_FILIAL+A1_COD+A1_LOJA
	SA1->(DbSeek(xFilial("SA1")+cGetCodCli+cGetLoja))

	For nY:=1 to Len(aRecebtos[nAtaReceb][5])
		If 'S' $ aRecebtos[nAtaReceb][5][nY][15] //Bloq Alcada

			cMsgLog := "Alçada Descontos na Venda" + CRLF
			cMsgLog += "Cliente: " + SA1->A1_COD + "/" + SA1->A1_LOJA + " - " + SA1->A1_NOME + CRLF
			cMsgLog += "Produto: " + aRecebtos[nAtaReceb][5][nY][2] + " - " + Posicione("SB1",1,xfilial("SB1")+aRecebtos[nAtaReceb][5][nY][2],"B1_DESC") + CRLF
			cMsgLog += "Forma+Condição: " + aRecebtos[nAtaReceb][1]+aRecebtos[nAtaReceb][2] + CRLF
			cMsgLog += "Preço Tabela: " + cValToChar(aRecebtos[nAtaReceb][5][nY][4]) + CRLF
			cMsgLog += "Preço Negociado: " + cValToChar(aRecebtos[nAtaReceb][5][nY][10]) + CRLF
			if cBaseDesc == "1"
				cMsgLog += "Base do Desconto: Preço Negociado" + CRLF
			else
				cMsgLog += "Base do Desconto: Preço Tabela" + CRLF
			endif
			cMsgLog += "Preço Usado: " + cValToChar(aRecebtos[nAtaReceb][5][nY][5]) + CRLF
			cMsgLog += CRLF
			if SubStr(aRecebtos[nAtaReceb][5][nY][15], 1, 1) == "S"
				cMsgLogAux := "Desconto sobre preço negociado liberado pelo Código de Liberação " + cCodLib + ". "
				U_AddLogAl("ALCDPN", cCodLib, cMsgLog + cMsgLogAux )
				aRecebtos[nAtaReceb][5][nY][16] := cCodLib
			endif
			if SubStr(aRecebtos[nAtaReceb][5][nY][15], 2, 1) == "S"
				cMsgLogAux := "Desconto da Venda liberado pelo Código de Liberação " + cCodLib + ". "
				U_AddLogAl("ALCDES", cCodLib, cMsgLog + cMsgLogAux, 0)
				aRecebtos[nAtaReceb][5][nY][16] := cCodLib
			endif
			aRecebtos[nAtaReceb][5][nY][15] := 'NN'

		EndIf
	Next nY

Return .T.

//--------------------------------------------------------------
// Tenta fazer liberação via controle de alçadas
//--------------------------------------------------------------
Static Function LibDescAlcada(cCodUsr)
	
	Local nY, nZ
	Local lRet := .F.
	Local aGrupos := {}, nPercDesc := 0, nVlrDesc := 0
	Local lTemU04 := .F.
	Local cGrpProd := ""
	Local oModelMaster	:= STDGPBModel()
	Local cMsgLog := "", cMsgLogAux := ""
	Local cBaseDesc := SuperGetMv( "ES_ALCBDES",.F.,"0") //0-Preço Bomba/Tabela; 1=Preço Negociado/Base
	Local lAlcDes	:= SuperGetMv( "ES_ALCDES",.F.,.F.) // desconto por Valor ou Percentual
	Local lAlcDPN	:= SuperGetMv( "ES_ALCDPN",.F.,.F.) // desconto sobre preço negociado
	Local lAlcLid	:= SuperGetMV( "ES_ALCLID",.F.,.F.) // limite de desconto por período

	Default cCodUsr := RetCodUsr()

	DbSelectArea("U03")
	DbSelectArea("U04")
	DbSelectArea("U0D")

	oModelMaster 	:= oModelMaster:GetModel("SL1MASTER")
	cGetCodCli 		:= oModelMaster:GetValue("L1_CLIENTE")
	cGetLoja 		:= oModelMaster:GetValue("L1_LOJA")
	
	SA1->(DbSetOrder(1)) //A1_FILIAL+A1_COD+A1_LOJA
	SA1->(DbSeek(xFilial("SA1")+cGetCodCli+cGetLoja))
	
	aGrupos := UsrRetGrp(UsrRetName(cCodUsr), cCodUsr)

	For nY:=1 to Len(aRecebtos[nAtaReceb][5])
		If 'S' $ aRecebtos[nAtaReceb][5][nY][15]

			cMsgLog := "Alçada Descontos na Venda" + CRLF
			cMsgLog += "Cliente: " + SA1->A1_COD + "/" + SA1->A1_LOJA + " - " + SA1->A1_NOME + CRLF
			cMsgLog += "Produto: " + aRecebtos[nAtaReceb][5][nY][2] + " - " + Posicione("SB1",1,xfilial("SB1")+aRecebtos[nAtaReceb][5][nY][2],"B1_DESC") + CRLF
			cMsgLog += "Forma+Condição: " + aRecebtos[nAtaReceb][1]+aRecebtos[nAtaReceb][2] + CRLF
			cMsgLog += "Preço Tabela: " + cValToChar(aRecebtos[nAtaReceb][5][nY][4]) + CRLF
			cMsgLog += "Preço Negociado: " + cValToChar(aRecebtos[nAtaReceb][5][nY][10]) + CRLF
			if cBaseDesc == "1"
				cMsgLog += "Base do Desconto: Preço Negociado" + CRLF
			else
				cMsgLog += "Base do Desconto: Preço Tabela" + CRLF
			endif
			cMsgLog += "Preço Usado: " + cValToChar(aRecebtos[nAtaReceb][5][nY][5]) + CRLF

			If cCodUsr == '000000' //usuario administrador, libera tudo
				cMsgLog += CRLF
				if SubStr(aRecebtos[nAtaReceb][5][nY][15], 1, 1) == "S"
					cMsgLogAux := "Desconto sobre preço negociado liberado pelo usuário " + cCodUsr +" - "+ USRRETNAME(cCodUsr) + ". "
					U_AddLogAl("ALCDPN", USRRETNAME(cCodUsr), cMsgLog + cMsgLogAux )
				endif
				if SubStr(aRecebtos[nAtaReceb][5][nY][15], 2, 1) == "S"
					cMsgLogAux := "Desconto da Venda liberado pelo usuário " + cCodUsr +" - "+ USRRETNAME(cCodUsr) + ". "
					U_AddLogAl("ALCDES", USRRETNAME(cCodUsr), cMsgLog + cMsgLogAux, 0)
				endif
				aRecebtos[nAtaReceb][5][nY][15] := 'NN'
			else

				//Bloqueio de desconto sobre preço negociado
				if SubStr(aRecebtos[nAtaReceb][5][nY][15], 1, 1) == "S"
					if !lAlcDPN //quando não esta ativo parametro desconto sobre preço negociado
						aRecebtos[nAtaReceb][5][nY][15] := "N" + SubStr(aRecebtos[nAtaReceb][5][nY][15], 2)

					elseif Posicione("U0D",1,xFilial("U0D")+Space(TamSx3("U04_GRUPO")[1])+PadR(cCodUsr,TamSx3("U04_USER")[1]),"U0D_DESCPN") == "S"
						aRecebtos[nAtaReceb][5][nY][15] := "N" + SubStr(aRecebtos[nAtaReceb][5][nY][15], 2) 
						cMsgLogAux := CRLF
						cMsgLogAux += "Desconto sobre preço negociado liberado por alçada do usuário " + cCodUsr +" - "+ USRRETNAME(cCodUsr) + ". " + CRLF
						cMsgLogAux += "Campo U0D_DESCPN = S"
						U_AddLogAl("ALCDPN", USRRETNAME(cCodUsr), cMsgLog + cMsgLogAux)

					else
						for nZ := 1 to len(aGrupos)
							if Posicione("U0D",1,xFilial("U0D")+PadR(aGrupos[nZ],TamSx3("U04_GRUPO")[1])+Space(TamSx3("U04_USER")[1]),"U0D_DESCPN") == "S"
								aRecebtos[nAtaReceb][5][nY][15] := "N" + SubStr(aRecebtos[nAtaReceb][5][nY][15], 2) 
								cMsgLogAux := CRLF
								cMsgLogAux += "Desconto sobre preço negociado liberado por alçada do grupo "+aGrupos[nZ]+"-"+GrpRetName(aGrupos[nZ])+" do usuário " + cCodUsr +"-"+ USRRETNAME(cCodUsr) + ". " + CRLF
								cMsgLogAux += "Campo U0D_DESCPN = S"
								U_AddLogAl("ALCDPN", USRRETNAME(cCodUsr), cMsgLog + cMsgLogAux)
								EXIT //sai do for nZ

							endif
						next nZ

					endif
				endif
				
				//Bloqueio de desconto por Valor ou Percentual
				if SubStr(aRecebtos[nAtaReceb][5][nY][15], 2, 1) == "S"

					lTemU04 := .F.
					cGrpProd := Posicione("SB1",1,xfilial("SB1")+aRecebtos[nAtaReceb][5][nY][2],"B1_GRUPO")
					U04->(DbSetOrder(1)) //U04_FILIAL+U04_GRUPO+U04_USER+U04_ITEM

					if cBaseDesc == "1" //se base desconto é preço negociado/preço base
						nVlrDesc := (aRecebtos[nAtaReceb][5][nY][10]-aRecebtos[nAtaReceb][5][nY][5])
						nPercDesc := (nVlrDesc/aRecebtos[nAtaReceb][5][nY][10])*100
					else
						nVlrDesc := (aRecebtos[nAtaReceb][5][nY][4]-aRecebtos[nAtaReceb][5][nY][5])
						nPercDesc := (nVlrDesc/aRecebtos[nAtaReceb][5][nY][4])*100
					endif

					if !lAlcDes //quando não esta ativo parametro desconto por Valor ou Percentual
						aRecebtos[nAtaReceb][5][nY][15] := SubStr(aRecebtos[nAtaReceb][5][nY][15],1,1) + "N"

					//procura pelo codigo usuário
					else
					
						if U04->(DbSeek(xFilial("U04")+Space(TamSx3("U04_GRUPO")[1])+PadR(cCodUsr,TamSx3("U04_USER")[1])))
							While U04->(!Eof()) .AND. U04->U04_FILIAL == xFilial("U04") .AND. empty(U04->U04_GRUPO) .AND. cCodUsr = U04->U04_USER

								//COMPARANDO AS REGRAS, A PRIMEIRA QUE ATENDER LIBERA O DESCONTO
								if (empty(U04->U04_FORMPG+U04->U04_CONDPG) .OR. aRecebtos[nAtaReceb][1]+aRecebtos[nAtaReceb][2] == U04->U04_FORMPG+U04->U04_CONDPG); //forma+condicao
									.AND. (empty(U04->U04_CLIENT+U04->U04_LOJCLI) .OR. SA1->A1_COD+SA1->A1_LOJA == U04->U04_CLIENT+U04->U04_LOJCLI); //cliente+loja
									.AND. (empty(U04->U04_GRPCLI) .OR. SA1->A1_GRPVEN == U04->U04_GRPCLI); //cliente+loja
									.AND. (empty(U04->U04_PRODUT) .OR. aRecebtos[nAtaReceb][5][nY][2] == U04->U04_PRODUT); //produto
									.AND. (empty(U04->U04_GRPPRO) .OR. cGrpProd == U04->U04_GRPPRO) //grupo produto

									if nPercDesc <= U04->U04_PORDES .OR. nVlrDesc <= U04->U04_VALDES 
										aRecebtos[nAtaReceb][5][nY][15] := SubStr(aRecebtos[nAtaReceb][5][nY][15],1,1) + "N"
										
										cMsgLogAux := "Valor Desconto Aplicado: " + cValTochar(nVlrDesc) + CRLF	
										cMsgLogAux += "% Desconto Aplicado: " + cValTochar(nPercDesc) + CRLF
										cMsgLogAux += CRLF
										cMsgLogAux += "Desconto por Valor ou Percentual liberado por alçada do usuário " + cCodUsr +" - "+ USRRETNAME(cCodUsr) + ". " + CRLF
										cMsgLogAux += "Detalhes da Regra Desconto: " + CRLF
										cMsgLogAux += "U04_FORMPG+U04_CONDPG = ["+U04->U04_FORMPG+U04->U04_CONDPG+"]" + CRLF
										cMsgLogAux += "U04_CLIENT+U04_LOJCLI = ["+U04->U04_CLIENT+U04->U04_LOJCLI+"]" + CRLF
										cMsgLogAux += "U04_GRPCLI = ["+U04->U04_GRPCLI+"]" + CRLF
										cMsgLogAux += "U04_PRODUT = ["+U04->U04_PRODUT+"]" + CRLF
										cMsgLogAux += "U04_GRPPRO = ["+U04->U04_GRPPRO+"]" + CRLF
										cMsgLogAux += "U04_PORDES = "+ cValtoChar(U04->U04_PORDES) + CRLF
										cMsgLogAux += "U04_VALDES = "+ cValToChar(U04->U04_VALDES) + CRLF
										U_AddLogAl("ALCDES", USRRETNAME(cCodUsr), cMsgLog + cMsgLogAux, nVlrDesc)

										lTemU04 := .T.
										EXIT //sai do EndDo (laço do U04)
									endif

								endif

								U04->(DbSkip())
							enddo
						endif

						//procura pelo grupo do usuário
						if !lTemU04 .AND. Len(aGrupos) > 0
							for nZ := 1 to len(aGrupos)
								if U04->(DbSeek(xFilial("U04")+PadR(aGrupos[nZ],TamSx3("U04_GRUPO")[1])+Space(TamSx3("U04_USER")[1])))
									While U04->(!Eof()) .AND. U04->U04_FILIAL == xFilial("U04") .AND. aGrupos[nZ] = U04->U04_GRUPO .AND. empty(U04->U04_USER)

										//COMPARANDO AS REGRAS, A PRIMEIRA QUE ATENDER LIBERA O DESCONTO
										if (empty(U04->U04_FORMPG+U04->U04_CONDPG) .OR. aRecebtos[nAtaReceb][1]+aRecebtos[nAtaReceb][2] == U04->U04_FORMPG+U04->U04_CONDPG); //forma+condicao
											.AND. (empty(U04->U04_CLIENT+U04->U04_LOJCLI) .OR. SA1->A1_COD+SA1->A1_LOJA == U04->U04_CLIENT+U04->U04_LOJCLI); //cliente+loja
											.AND. (empty(U04->U04_GRPCLI) .OR. SA1->A1_GRPVEN == U04->U04_GRPCLI); //cliente+loja
											.AND. (empty(U04->U04_PRODUT) .OR. aRecebtos[nAtaReceb][5][nY][2] == U04->U04_PRODUT); //produto
											.AND. (empty(U04->U04_GRPPRO) .OR. cGrpProd == U04->U04_GRPPRO) //grupo produto

											if nPercDesc <= U04->U04_PORDES .OR. nVlrDesc <= U04->U04_VALDES 
												aRecebtos[nAtaReceb][5][nY][15] := SubStr(aRecebtos[nAtaReceb][5][nY][15],1,1) + "N"
												
												cMsgLogAux := "Valor Desconto Aplicado: " + cValTochar(nVlrDesc) + CRLF	
												cMsgLogAux += "% Desconto Aplicado: " + cValTochar(nPercDesc) + CRLF
												cMsgLogAux += CRLF
												cMsgLogAux += "Desconto por Valor ou Percentual liberado por alçada do grupo "+aGrupos[nZ]+"-"+GrpRetName(aGrupos[nZ])+" do usuário " + cCodUsr +"-"+ USRRETNAME(cCodUsr) + ". " + CRLF
												cMsgLogAux += "Detalhes da Regra Desconto: " + CRLF
												cMsgLogAux += "U04_FORMPG+U04_CONDPG = ["+U04->U04_FORMPG+U04->U04_CONDPG+"]" + CRLF
												cMsgLogAux += "U04_CLIENT+U04_LOJCLI = ["+U04->U04_CLIENT+U04->U04_LOJCLI+"]" + CRLF
												cMsgLogAux += "U04_GRPCLI = ["+U04->U04_GRPCLI+"]" + CRLF
												cMsgLogAux += "U04_PRODUT = ["+U04->U04_PRODUT+"]" + CRLF
												cMsgLogAux += "U04_GRPPRO = ["+U04->U04_GRPPRO+"]" + CRLF
												cMsgLogAux += "U04_PORDES = "+ cValtoChar(U04->U04_PORDES) + CRLF
												cMsgLogAux += "U04_VALDES = "+ cValToChar(U04->U04_VALDES) + CRLF
												U_AddLogAl("ALCDES", USRRETNAME(cCodUsr), cMsgLog + cMsgLogAux, nVlrDesc)

												lTemU04 := .T.
												EXIT //sai do EndDo (laço do U04)
											endif

										endif

										U04->(DbSkip())
									enddo

									if lTemU04
										EXIT //sai do Next nZ (laço do aGrupos)
									endif
								endif
							next nZ
						endif
					endif
				endif

			endif
		endif
	next nY

	lRet := aScan(aRecebtos[nAtaReceb][5], {|x| "S" $ x[15] }) == 0

	//limite de desconto por período 
	if lAlcLid .and. nVlrDescTot > 0
		lRet := .F.

		cMsgLog := "Alçada Limite de Descontos na Venda" + CRLF
		cMsgLog += "Cliente: " + SA1->A1_COD + "/" + SA1->A1_LOJA + " - " + SA1->A1_NOME + CRLF
		cMsgLog += "Desconto total a ser liberado: " + cValToChar(nVlrDescTot) + CRLF

		if cCodUsr == '000000' //usuario administrador, libera tudo
			cMsgLog += CRLF
			cMsgLogAux := "Limite de desconto por período liberado pelo usuário " + cCodUsr +" - "+ USRRETNAME(cCodUsr) + ". "
			U_AddLogAl("ALCLID", USRRETNAME(cCodUsr), cMsgLog + cMsgLogAux, nVlrDescTot)
			lRet := .T.
		else
			//tenta fazer liberação pelo usuário
			nVlrLid := Posicione("U0D",1,xFilial("U0D")+Space(TamSx3("U04_GRUPO")[1])+PadR(cCodUsr,TamSx3("U04_USER")[1]),"U0D_VLRLID")
			cTipLid := Posicione("U0D",1,xFilial("U0D")+Space(TamSx3("U04_GRUPO")[1])+PadR(cCodUsr,TamSx3("U04_USER")[1]),"U0D_TIPLID")
			nVlrUsd := LimDescPeriod(USRRETNAME(cCodUsr),cTipLid)
			if nVlrDescTot <= (nVlrLid-nVlrUsd)
				cMsgLogAux := CRLF
				cMsgLogAux += "Limite de desconto por período liberado pelo usuário " + cCodUsr +" - "+ USRRETNAME(cCodUsr) + ". " + CRLF
				cMsgLogAux += "Valor Limite Por Período = ["+cValtoChar(nVlrLid)+"]"+ CRLF
				cMsgLogAux += "Tipo Período = ["+cTipLid+"]"+ CRLF
				cMsgLogAux += "Saldo = ["+cValtoChar(nVlrLid-nVlrUsd)+"]"+ CRLF
				cMsgLogAux += "Valor Liberado = ["+cValtoChar(nVlrDescTot)+"]"+ CRLF
				U_AddLogAl("ALCLID", USRRETNAME(cCodUsr), cMsgLog + cMsgLogAux, nVlrDescTot)
				lRet := .T.
			else
				//tenta fazer liberação pelo grupo de usuário
				for nZ := 1 to len(aGrupos)
					nVlrLid := Posicione("U0D",1,xFilial("U0D")+PadR(aGrupos[nZ],TamSx3("U04_GRUPO")[1])+Space(TamSx3("U04_USER")[1]),"U0D_VLRLID")
					cTipLid := Posicione("U0D",1,xFilial("U0D")+PadR(aGrupos[nZ],TamSx3("U04_GRUPO")[1])+Space(TamSx3("U04_USER")[1]),"U0D_TIPLID")
					nVlrUsd := LimDescPeriod(USRRETNAME(cCodUsr),cTipLid)
					if nVlrDescTot <= (nVlrLid-nVlrUsd)
						cMsgLogAux := CRLF
						cMsgLogAux += "Limite de desconto por período liberado pelo grupo "+aGrupos[nZ]+"-"+GrpRetName(aGrupos[nZ])+" do usuário " + cCodUsr +"-"+ USRRETNAME(cCodUsr) + ". " + CRLF
						cMsgLogAux += "Valor Limite Por Período = ["+cValtoChar(nVlrLid)+"]"+ CRLF
						cMsgLogAux += "Tipo Período = ["+cTipLid+"]"+ CRLF
						cMsgLogAux += "Saldo = ["+cValtoChar(nVlrLid-nVlrUsd)+"]"+ CRLF
						cMsgLogAux += "Valor Liberado = ["+cValtoChar(nVlrDescTot)+"]"+ CRLF
						U_AddLogAl("ALCLID", USRRETNAME(cCodUsr), cMsgLog + cMsgLogAux, nVlrDescTot)
						lRet := .T.
						EXIT //sai do for nZ
					endif
				next nZ
			endif
		endif
	endif

Return lRet

//----------------------------------------------------------------
// Busca o valor já liberado pelo usuário em determinado periodo
//----------------------------------------------------------------
Static Function LimDescPeriod(cUserLog,cTpLim) 

Local lRet := .T.
Local nRet := 0
Local nCodRet := 0
Local lHasConnect := .F.
Local lHostError := .F.
Local aParam, nResult

	CursorArrow()
	STFCleanInterfaceMessage()

	STFMessage(ProcName(),"STOP","Realizando consulta de limite de deconto na central PDV. Aguarde...")
	STFShowMessage(ProcName())

	CursorWait()

	//parametros para busca
	aParam := {cUserLog,cTpLim}
	aParam := {"U_TR037SDL",aParam}

	If FWHostPing() .AND. STBRemoteExecute( "_EXEC_CEN", aParam,,,@nResult,/*cType*/,/*cKeyOri*/, @nCodRet )
		// Se retornar esses codigos siginifica que a central esta off
		lHasConnect := !(nCodRet == -105 .OR. nCodRet == -107 .OR. nCodRet == -104)
		// Verifica erro de execucao por parte do host
		//-103 : erro na execução ,-106 : 'erro deserializar os parametros (JSON)
		lHostError := (nCodRet == -103 .OR. nCodRet == -106)
		If lHostError
			STFMessage(ProcName(),"STOP","Erro de conexão central PDV: " + cValtoChar(nCodRet))
			STFShowMessage(ProcName())
			lRet := .F.
		EndIf

	ElseIf nCodRet == -101 .OR. nCodRet == -108
		STFMessage(ProcName(),"STOP","Servidor PDV nao Preparado. Funcionalidade nao existe ou host responsavel não associado. Cadastre a funcionalidade e vincule ao Host da Central PDV: " + cValtoChar(nCodRet))
		STFShowMessage(ProcName())
		lRet := .F.

	Else
		STFMessage(ProcName(),"STOP","Erro de conexão central PDV: " + cValtoChar(nCodRet))
		STFShowMessage(ProcName())
		lRet := .F.

	EndIf

	If lRet .AND. lHasConnect .AND. ValType(nResult)=="N"
		nRet := nResult
		STFCleanInterfaceMessage()
	EndIf

	CursorArrow()

Return nRet

//---------------------------------------------------------------
// Recarregar os valores, pelo desconto dado
//---------------------------------------------------------------
Static Function SetDesconto(cForma)

	Local lRet := .T.
	Local cFPConv := SuperGetMv("TP_FPGCONV",,"")

	if Alltrim(cForma) $ 'R$' .OR. (Alltrim(cForma) == 'PX' .AND. !("PX" $ cFPConv)) .OR. (Alltrim(cForma) == 'PD' .AND. !("PD" $ cFPConv))
		If len(aItensGrid) > 0
			LoadSelNeg(cForma)
	    	DoRefreshNeg(cForma)
	    EndIf
	EndIf

	If Len(aItensGrid) > 0
		RefreshGridPg(cForma) //preenche vetor com dados: aItensGrid

		If AllTrim(cForma) $ 'CC|CD'
			DoFiltrarNeg(aNewGdNeg,.F., oCCListGdNeg, cForma) //atualiza o aCols
			LoadSelNeg(cForma, oCCListGdNeg)
		ElseIf AllTrim(cForma) $ 'CF'
			DoFiltrarNeg(aNewGdNeg,.F., oCFListGdNeg, cForma) //atualiza o aCols
			LoadSelNeg(cForma, oCFListGdNeg)
		ElseIf AllTrim(cForma) $ 'NP|CT|'+cFPConv
			DoFiltrarNeg(aNewGdNeg,.F., oNPListGdNeg,cForma) //atualiza o aCols
			LoadSelNeg(cForma, oNPListGdNeg)
		ElseIf AllTrim(cForma) $ 'CH'
			DoFiltrarNeg(aNewGdNeg,.F., oCHListGdNeg,cForma) //atualiza o aCols
			LoadSelNeg(cForma, oCHListGdNeg)
		ElseIf AllTrim(cForma) $ 'NB'
			LoadSelNeg(cForma, oCRListGdNeg)
		EndIf

		DoRefreshNeg(cForma)
	EndIf

Return lRet


//------------------------------------------------------------------------------
/*{Protheus.doc} STIClnVar
Função para limpar os objetos Static da criação da tela de cartão
@param
@author  	eduardo.sales
@version 	P12
@since   	07/02/2017
@return  	Nil
@obs
@sample
/*/
//------------------------------------------------------------------------------
Static Function STIClnVar(oPnlAdconal, lAll,lClrMsg)
Default lClrMsg := .T.

	if lAll
		nDINVlrRec 	:= 0
		nDINVlrSal	:= 0

		nPIXVlrRec 	:= 0
		nPIXVlrSal	:= 0
		dPIXDataTran := CtoD("")
		nPIXParcelas := 1

		nCCVlrRec	:= 0
		nCCVlrSal	:= 0
		aMyRede		:= {}
		aMyBandei	:= {}
		aMyAdmFin 	:= {}
		cCardForma	:= ""
		cRedeAut  	:= Space(TamSx3("MDE_CODIGO")[1])
		cBandeira 	:= Space(TamSx3("MDE_CODIGO")[1])
		cCCAdmFin   := Space(TamSx3("AE_COD")[1])
		cNsuDoc		:= Space(TAMSx3("L4_NSUTEF")[1])
		cAutoriz	:= Space(TAMSx3("L4_AUTORIZ")[1])
		dCCDataTran := CtoD("")
		nCCParcelas := 1
		lMyContTef	:= .F.

		nCFVlrRec	:= 0
		nCFVlrSal	:= 0
		cCFAdmFin  	:= Space(TamSx3("AE_COD")[1])
		dCFDataTran := CtoD("")
		nCFParcelas := 1
		cCodCF		:= Space(TAMSx3("A1_COD")[1])
		cLojCF		:= Space(TAMSx3("A1_LOJA")[1])
		cCFrete		:= Space(TAMSx3("L4_NUMCART")[1])
		cNomeEmiCF	:= Space(TAMSx3("A1_NOME")[1])
		cObserv		:= Space(TAMSx3("L4_OBS")[1])

		nNPVlrRec	:= 0
		nNPVlrSal	:= 0
		cNPAdmFin  	:= Space(TamSx3("AE_COD")[1])
		dNPDataTran := CtoD("")
		nNPParcelas := 1

		nCHVlrRec	:= 0
		nCHVlrSal	:= 0
		aCheques	:= {}
		nChqAct		:= 0

		cCRBusca	:= Space(40)
		cSayConn    := "Retaguarda OFF-LINE"
	
		STISetContTef(lMyContTef)

		/*/ Se essa funcao nao for chamada por um componente de tela,
		o objeto nao fica instanciado, por isso a protecao /*/
		If ValType(oPnlAdconal) == "O"
			// - 05/03/2020 - Foi comentado a chamada da função FreeChildren pois estava "travando" o Totvs PDV
			//oPnlAdconal:FreeChildren() //-- FreeChildren() -> Elimina/Libera todos os objetos da classe onde este método é chamado.
			FreeObj(oPnlAdconal)
			oPnlAdconal := Nil
		EndIf

		STIBtnActivate()
		U_SetWBtnNF(.T.)

		bCancTela := Nil

	endif

	If lClrMsg
		STFCleanMessage()
		STFCleanInterfaceMessage()
	EndIf

Return .T.

//------------------------------------------------
// carrega as negociações de pagamento do cliente
/*
//ATENCAO -> nao alterar a ordem do array abaixo
Array aRecebtos
{	Forma,            -> [1]
	Condicao,         -> [2]
	Administradora,   -> [3] ou Emit.Cheque
	Padrão?,		  -> [4]
			{[01] - Item,
			 [02] - Produto,
			 [03] - Qtd,
			 [04] - Prc Pad.,
			 [05] - Prc Util,
			 [06] - LimTrocoU25,
			 [07] - VlrMaxU25,
			 [08] - %MaxU25,
			 [09] - RecnoU25,
			 [10] - Prc Neg,
			 [11] - Vlr Max Desc, 	//valor desconto maximo
			 [12] - % Max Desc, 	//percentual desconto maximo
			 [13] - % Marg Min, 	//margem minima (DESCONTINUADO)
			 [14] - Custo Prod, 	//custo do produto (DESCONTINUADO)
			 [15] - Bloq Alcada,
			 [16] - Mensagem Liberaçao Alçada,
			 			} {Item, Produto,...} {?}, -> [5]
	Total Item Cupom, -> [6]
	Total Forma Pgto, -> [7]
	Total Desconto,	  -> [8]
	Recebido,		  -> [9]
	Percentual,		  -> [10]
	Saldo,			  -> [11]
	Original,		  -> [12]
	Desconto,		  -> [13]
	Saldo Outros,	  -> [14]
	{LimTroco, VlrMax, %Max, Perm.Vha}, -> [15] //maximo troco U44
	Troco			  -> [16]
}
*/
//------------------------------------------------
Static Function CarregaRecb(cForma)

	Local aArea	:= GetArea()	//Salva area
	Local aSaveLines  := FWSaveRows()	//Array de linhas salvas
	Local oModelMaster	:= STDGPBModel()
	Local oModelCesta 	:= STDGPBModel()

	Local cGetCodCli := "" //"000001" //M->LQ_CLIENTE // Cliente corrente
	Local cGetLoja   := "" //"01" //M->LQ_LOJA	 // Loja corrente
	Local cGrpCli    := "" //Posicione("SA1",1,xFilial("SA1")+cGetCodCli+cGetLoja, "A1_GRPVEN")
	Local aProdutos  := {}
	Local nPos := 0
	Local nX := 0
	Local nY := 0
	Local cCondicao	:= ""
	Local bCondicao
	Local cCond
	Local lPrcNeg := .F.
	Local nLF_DESCPER := RetTotDesP()
	Local nLF_DESCVAL := RetTotDesV()
	Local nPrcTab := 0

	Local lNgDesc := SuperGetMV("MV_XNGDESC",,.T.) //Ativa negociação pelo valor de desconto: U25_DESPBA

	/*/ MV_XATUPRC - tipo de negociação no Totvs PDV: DESCONTO ou PREÇO UNITÁRIO
		.T. - Trabalha com preço maior que o preço de tabela (não tem desconto, ajuste preço unitário)
		.F. - Trabalha com desconto no preço de tabela (não ajusta preço unitário, trabalha com desconto)
	/*/
	Local lAltVrUnit := SuperGetMv("MV_XATUPRC",.T./*lHelp*/,.T./*uPadrao*/)
	Local lAlcada	:= SuperGetMv("ES_ALCADA",.T.,.F.)
	Local lAlcDes	:= SuperGetMv( "ES_ALCDES",.F.,.F.)
	Local lAlcDPN	:= SuperGetMv( "ES_ALCDPN",.F.,.F.) //desconto sobre preço negociado
	Local lAlcLid	:= SuperGetMV( "ES_ALCLID",.F.,.F.)
	Local nPrcPad := 0, nPrcVen := 0
	Local aTemp := {}

	//Limpo logs da alçada
	If lAlcada .AND. (lAlcDes .OR. lAlcDPN .OR. lAlcLid)
		U_ClLogAlc()
	EndIf

	// Limpa array do bakcup da ultima carta frete
	If FindFunction("U_TPDVA14A")
		U_TPDVA14A()
	EndIf

	oModelMaster 	:= oModelMaster:GetModel("SL1MASTER")
	cGetCodCli 		:= oModelMaster:GetValue("L1_CLIENTE")
	cGetLoja 		:= oModelMaster:GetValue("L1_LOJA")
	cGrpCli 		:= Posicione("SA1",1,xFilial("SA1")+cGetCodCli+cGetLoja, "A1_GRPVEN")
	cGetPlaca 		:= oModelMaster:GetValue("L1_PLACA")

	oModelCesta := oModelCesta:GetModel("SL2DETAIL")

	//****************************************************************
	//----------------------------------------------------------------------------------------------------------
	//produtos: array -> {{"ITEM","CODIGO","QUANTIDADE","PREÇO PADRÃO","PREÇO UTILIZADO","LIMT TROCO","VLR MAX TR","% MAX TR","RECNO U25","PREÇO NEGOCIADO","BLOQ ALCADA","USUARIO"}, ...}
	// -> array com todos os produtos
	//----------------------------------------------------------------------------------------------------------
	aProdutos := {}
	nPos      := 0

	for nX:=1 to oModelCesta:Length() // itens do orçamento
		oModelCesta:GoLine(nX)
		If !oModelCesta:IsDeleted()
			nPos := aScan(aProdutos, {|x| AllTrim(x[1]+x[2])==AllTrim(oModelCesta:GetValue("L2_ITEM")+oModelCesta:GetValue("L2_PRODUTO"))})
			If nPos <= 0
				//L2_VRUNIT -> L2_PRCTAB
				if lAddPromo .AND. STDGPBasket("SL1","L1_XDESPRO") > 0
					nPrcTab := oModelCesta:GetValue("L2_VRUNIT")
				else
					nPrcTab := 0
					If !Empty(oModelCesta:GetValue("L2_MIDCOD"))
						MID->(DbSetOrder(1)) //MID_FILIAL+MID_CODABA
						If MID->(DbSeek(xFilial("MID") + oModelCesta:GetValue("L2_MIDCOD")))
							nPrcTab := MID->MID_PREPLI
						EndIf
					Else// oModelCesta:GetValue("L2_VALDESC")>0
						nPrcTab := U_URetPrec(oModelCesta:GetValue("L2_PRODUTO"),,.F.)
					//Else
					//	nPrcTab := oModelCesta:GetValue("L2_VRUNIT")
					EndIf
					If nPrcTab <= 0
						nPrcTab := U_URetPrec(oModelCesta:GetValue("L2_PRODUTO"),,.F.) //oModelCesta:GetValue("L2_PRCTAB")
					EndIf
				endif
				AAdd(aProdutos,{oModelCesta:GetValue("L2_ITEM"),oModelCesta:GetValue("L2_PRODUTO"),oModelCesta:GetValue("L2_QUANT"),nPrcTab,0,"N",0,0,0,0,0,0,0,0,"",""}) //adiciona produto
			Else
				aProdutos[nPos][3] += oModelCesta:GetValue("L2_QUANT") //soma qtd
			EndIf
		EndIf
	next nX
	//****************************************************************

	//****************************************************************
	//carrego a lista de negociacao (forma+condicao), conforme produto + cliente: "U44"
	aRecebtos := {}
	nTotRecebi := 0
	nVlrDescTot := 0
	//aadd(aRecebtos,{"NB ","   ",space(TamSx3("U25_ADMFIN")[1]),,{},0,0,0,0,0,0,0,0,0,{/*Limit Troco? - U44_PERMTR*/"N", /*U44_VLRMAX*/0, /*U44_PERMAX*/0},0}) //NB - Nota de Crédito Cód. Barras
	for nX:=1 to len(aProdutos)
		aRet := {}
		aRet := RetFormas(aProdutos[nX][2], cGetCodCli, cGetLoja)
		for nY:=1 to len(aRet) //o produto tem que ser adicionado a todas as NEGOCIACOES
			nPosPg := aScan(aRecebtos,{|x| AllTrim(x[1]+x[2])==AllTrim(aRet[nY][1]+aRet[nY][2])})
			If nPosPg <= 0 //negociacao nao adicionada ao array aRecebtos
				aadd(aRecebtos,{aRet[nY][1],aRet[nY][2],iif(alltrim(aRet[nY][1])=="CH",space(tamsx3("U25_EMITEN")[1])+space(tamsx3("U25_LOJEMI")[1]),space(tamsx3("U25_ADMFIN")[1])),,{},0,0,0,0,0,0,0,0,0,aRet[nY][3],0})
				aadd(aRecebtos[len(aRecebtos)][5], aClone(aProdutos[nX]) )
			Else
				nPosPr := aScan(aRecebtos[nPosPg][5],{|x| AllTrim(x[1]+x[2])==AllTrim(aProdutos[nX][1]+aProdutos[nX][2])})
				If nPosPr <= 0
					aadd(aRecebtos[nPosPg][5], aClone(aProdutos[nX]) )
				EndIf
			EndIf
		next nY
	next nX
	//****************************************************************

	if !(lAddPromo .AND. STDGPBasket("SL1","L1_XDESPRO") > 0)
		//****************************************************************
		// FILTRO DA TABELA DE PRECO NEGOCIADO
		cCondicao := " U25_FILIAL == '"+xFilial("U25")+"'"
		cCondicao += " .AND. DTOS(U25_DTINIC) <= '"+DTOS(dDataBase)+"'"
		cCondicao += " .AND. ((DTOS(U25_DTFIM) == '"+DTOS(CTOD(""))+"' .AND. Empty(U25->U25_HRFIM)) .OR. (DTOS(U25_DTFIM)+U25->U25_HRFIM >= '"+DTOS(dDataBase)+SUBSTR(Iif(dDataBase<Date(),"23:59",Time()),1,5)+"'))" //somente com data de fim dentro da vigencia
		cCondicao += " .AND. Empty(U25_NUMORC)" //para trazer somente preços que nao foram utilizdos em venda específica
		cCondicao += " .AND. (Empty(U25_PLACA) .OR. U25_PLACA == '"+ StrTran(StrTran(cGetPlaca,"'"," "),'"'," ") +"')" //placa
		cCondicao += " .AND. U25_BLQL <> 'S' " //nao bloqueado
		
		// limpo os filtros da U25
		U25->(DbClearFilter())

		// executo o filtro na U25
		bCondicao 	:= "{|| " + cCondicao + " }"
		U25->(DbSetFilter(&bCondicao,cCondicao))

		// vou para a primeira linha
		U25->(DbSetOrder(2)) //U25_FILIAL+U25_PRODUT+U25_CLIENT+U25_LOJA+U25_GRPCLI+U25_FORPAG+U25_CONDPG+U25_ADMFIN+U25_EMITEN+U25_LOJEMI+U25_PLACA+DTOS(U25_DTINIC)+U25_HRINIC
		U25->(DbGoTop())
		//****************************************************************

		//****************************************************************
		//adiciono as administradoras financeiras, por produto U25
		aTemp := {}
		If U25->(!EOF())
			for nX:=1 to len(aRecebtos)

				cForma := aRecebtos[nX][1]
				cCond  := aRecebtos[nX][2]

				for nY:=1 to len(aRecebtos[nX][5])
					cProduto := aRecebtos[nX][5][nY][2]

					//vou para a primeira linha
					//U25->(DbGoTop())
					//U25_FILIAL+U25_PRODUT+U25_CLIENT+U25_LOJA+U25_GRPCLI+U25_FORPAG+U25_CONDPG

					//->> [NEGOCIACAO] específica por [PRODUTO] + [CLIENTE] + [FORMA] + [CONDICAO]
					If U25->(DbSeek(xFilial("U25")+cProduto+cGetCodCli+cGetLoja+space(tamsx3("U25_GRPCLI")[1])+cForma+cCond))
						While U25->(!EOF()) .and. U25->U25_FILIAL == xFilial("U25") .and. U25->U25_PRODUT == cProduto .and. U25->U25_CLIENT == cGetCodCli .and. U25->U25_LOJA == cGetLoja .and. U25->U25_GRPCLI == space(tamsx3("U25_GRPCLI")[1]) .and. U25->U25_FORPAG == cForma .and. U25->U25_CONDPG == cCond
							If alltrim(cForma) == "CH"
								If !Empty(U25->U25_EMITEN+U25->U25_LOJEMI)
									nPosTemp := aScan(aTemp,{|x| AllTrim(x[1]+x[2]+x[3])==AllTrim(cForma+cCond+U25->U25_EMITEN+U25->U25_LOJEMI)})
									If nPosTemp <= 0
										aadd(aTemp,aclone(aRecebtos[nX]))
										aTemp[len(aTemp)][3] := U25->U25_EMITEN+U25->U25_LOJEMI
									EndIf
								EndIf
							Else
								If !Empty(U25->U25_ADMFIN)
									nPosTemp := aScan(aTemp,{|x| AllTrim(x[1]+x[2]+x[3])==AllTrim(cForma+cCond+U25->U25_ADMFIN)})
									If nPosTemp <= 0
										aadd(aTemp,aclone(aRecebtos[nX]))
										aTemp[len(aTemp)][3] := U25->U25_ADMFIN
									EndIf
								EndIf
							EndIf
						U25->(dbskip())
						EndDo
					EndIf

					//->> [NEGOCIACAO] específica por [PRODUTO] + [GRUPO DE CLIENTE] + [FORMA] + [CONDICAO]
					If  !Empty(cGrpCli) .and. U25->(DbSeek(xFilial("U25")+cProduto+space(tamsx3("U25_CLIENT")[1])+space(tamsx3("U25_LOJA")[1])+cGrpCli+cForma+cCond))
						While U25->(!EOF()) .and. U25->U25_FILIAL == xFilial("U25") .and. U25->U25_PRODUT == cProduto .and. U25->U25_CLIENT == space(tamsx3("U25_CLIENT")[1]) .and. U25->U25_LOJA == space(tamsx3("U25_LOJA")[1]) .and. U25->U25_GRPCLI == cGrpCli .and. U25->U25_FORPAG == cForma .and. U25->U25_CONDPG == cCond
							If alltrim(cForma) == "CH"
								If !Empty(U25->U25_EMITEN+U25->U25_LOJEMI)
									nPosTemp := aScan(aTemp,{|x| AllTrim(x[1]+x[2]+x[3])==AllTrim(cForma+cCond+U25->U25_EMITEN+U25->U25_LOJEMI)})
									If nPosTemp <= 0
										aadd(aTemp,aclone(aRecebtos[nX]))
										aTemp[len(aTemp)][3] := U25->U25_EMITEN+U25->U25_LOJEMI
									EndIf
								EndIf
							Else
								If !Empty(U25->U25_ADMFIN)
									nPosTemp := aScan(aTemp,{|x| AllTrim(x[1]+x[2]+x[3])==AllTrim(cForma+cCond+U25->U25_ADMFIN)})
									If nPosTemp <= 0
										aadd(aTemp,aclone(aRecebtos[nX]))
										aTemp[len(aTemp)][3] := U25->U25_ADMFIN
									EndIf
								EndIf
							EndIf
						U25->(dbskip())
						EndDo
					EndIf

					//->> [NEGOCIACAO] específica por [PRODUTO] + [FORMA] + [CONDICAO]
					If  U25->(DbSeek(xFilial("U25")+cProduto+space(tamsx3("U25_CLIENT")[1])+space(tamsx3("U25_LOJA")[1])+space(tamsx3("U25_GRPCLI")[1])+cForma+cCond))
						While U25->(!EOF()) .and. U25->U25_FILIAL == xFilial("U25") .and. U25->U25_PRODUT == cProduto .and. Empty(U25->U25_CLIENT) .and. Empty(U25->U25_LOJA) .and. Empty(U25->U25_GRPCLI) .and. U25->U25_FORPAG == cForma .and. U25->U25_CONDPG == cCond
							If alltrim(cForma) == "CH"
								If !Empty(U25->U25_EMITEN+U25->U25_LOJEMI)
									nPosTemp := aScan(aTemp,{|x| AllTrim(x[1]+x[2]+x[3])==AllTrim(cForma+cCond+U25->U25_EMITEN+U25->U25_LOJEMI)})
									If nPosTemp <= 0
										aadd(aTemp,aclone(aRecebtos[nX]))
										aTemp[len(aTemp)][3] := U25->U25_EMITEN+U25->U25_LOJEMI
									EndIf
								EndIf
							Else
								If !Empty(U25->U25_ADMFIN)
									nPosTemp := aScan(aTemp,{|x| AllTrim(x[1]+x[2]+x[3])==AllTrim(cForma+cCond+U25->U25_ADMFIN)})
									If nPosTemp <= 0
										aadd(aTemp,aclone(aRecebtos[nX]))
										aTemp[len(aTemp)][3] := U25->U25_ADMFIN
									EndIf
								EndIf
							EndIf
						U25->(dbskip())
						EndDo
					EndIf

				next nY

			next nX
		EndIf
	endif

	For nX:=1 to len(aTemp)
		nPosTemp := aScan(aRecebtos,{|x| AllTrim(x[1]+x[2]+x[3])==AllTrim(aTemp[nX][1]+aTemp[nX][2]+aTemp[nX][3])})
		if nPosTemp <= 0
			aadd(aRecebtos,aclone(aTemp[nX]))
		endif
	Next nX
	//****************************************************************

	//****************************************************************
	//adiciono as administradoras financeiras, por produto U0C
	// vou para a primeira linha
	if !(lAddPromo .AND. STDGPBasket("SL1","L1_XDESPRO") > 0)
		if lNgDesc .and. U25->(FieldPos("U25_DESPBA"))>0 

			U0C->(DbSetOrder(1)) //U0C_FILIAL+U0C_PRODUT+U0C_FORPAG+U0C_CONDPG+U0C_ADMFIN
			U0C->(DbGoTop())
			U0C->(DbSeek(xFilial("U0C")))
				
			aTemp := {}
			if U0C->(!EOF())
				for nX:=1 to len(aRecebtos)

					cForma   := aRecebtos[nX][1]
					cCond    := aRecebtos[nX][2]

					for nY:=1 to len(aRecebtos[nX][5])
						cProduto := aRecebtos[nX][5][nY][2]

						//U0C_FILIAL+U0C_PRODUT+U0C_FORPAG+U0C_CONDPG+U0C_ADMFIN
						If U0C->(DbSeek(xFilial("U0C")+cProduto+cForma+cCond))
							While U0C->(!EOF()) .and. U0C->U0C_FILIAL == xFilial("U0C") .and. U0C->U0C_PRODUT == cProduto .and. U0C->U0C_FORPAG == cForma .and. U0C->U0C_CONDPG == cCond
								if !empty(U0C->U0C_ADMFIN)
									nPosTemp := aScan(aTemp,{|x| AllTrim(x[1]+x[2]+x[3])==AllTrim(cForma+cCond+U0C->U0C_ADMFIN)})
									if nPosTemp <= 0
										aadd(aTemp,aclone(aRecebtos[nX]))
										aTemp[len(aTemp)][3]  := U0C->U0C_ADMFIN
									endif
								endif
							U0C->(dbskip())
							EndDo
						endif

					next nY

				next nX
			endif

			For nX:=1 to len(aTemp)
				nPosTemp := aScan(aRecebtos,{|x| AllTrim(x[1]+x[2]+x[3])==AllTrim(aTemp[nX][1]+aTemp[nX][2]+aTemp[nX][3])})
				if nPosTemp <= 0
					aadd(aRecebtos,aclone(aTemp[nX]))
				endif
			Next nX

		endif
	endif
	//****************************************************************

	//****************************************************************
	//atualiza o preço negociado da lista de formas no array aRecebtos
	for nX:=1 to len(aRecebtos)

		nTttICup := 0 //total do item pelo preco padrao
		nTttForm := 0 //total pagamento forma pagamento
		nTttDesc := 0 //total de desconto
		cAdmEmit := space(tamsx3("U25_ADMFIN")[1])
		cEmitent := space(tamsx3("U25_EMITEN")[1]) + space(tamsx3("U25_LOJEMI")[1])

		for nY:=1 to len(aRecebtos[nX][5])

			If len(aRecebtos[nX][3]) == tamsx3("U25_ADMFIN")[1]
				cAdmEmit := aRecebtos[nX][3]
	   			cEmitent := space(tamsx3("U25_EMITEN")[1]) + space(tamsx3("U25_LOJEMI")[1])
			ElseIf len(aRecebtos[nX][3]) == tamsx3("U25_EMITEN")[1]+tamsx3("U25_LOJEMI")[1]
				cAdmEmit := space(tamsx3("U25_ADMFIN")[1])
				cEmitent := aRecebtos[nX][3]
			Else
				cAdmEmit := space(tamsx3("U25_ADMFIN")[1])
				cEmitent := space(tamsx3("U25_EMITEN")[1]) + space(tamsx3("U25_LOJEMI")[1])
			EndIf

			nPrcPad := aRecebtos[nX][5][nY][4]
			
			if !(lAddPromo .AND. STDGPBasket("SL1","L1_XDESPRO") > 0)

				nPrcVen := 0 //preco negociado

				//regra mais especifica
				//RetPrcNeg(cProduto,cGetCodCli,cGetLoja,cGrpCli,cForma,cCond,cAdmEmit)
				//regra por: cliente+loja+forma+condicao+administradora
				If U25->(DbSeek(xFilial("U25")+aRecebtos[nX][5][nY][2]+cGetCodCli+cGetLoja+space(tamsx3("U25_GRPCLI")[1])+aRecebtos[nX][1]+aRecebtos[nX][2]+cAdmEmit+cEmitent))
					//DANILO: Verifica se tem outro preço vigente com mesma chave, com data inicio maior
					RetU25DtMaior(xFilial("U25"), aRecebtos[nX][5][nY][2], cGetCodCli, cGetLoja, space(tamsx3("U25_GRPCLI")[1]), aRecebtos[nX][1], aRecebtos[nX][2], cAdmEmit, cEmitent)

					If lNgDesc .and. U25->(FieldPos("U25_DESPBA"))>0 //.and. U25->U25_DESPBA <> 0
						nPrcBase := U_URetPrBa(U25->U25_PRODUT, U25->U25_FORPAG, U25->U25_CONDPG, U25->U25_ADMFIN, 0, U25->U25_DTINIC, U25->U25_HRINIC)
						nPrcVen  := (nPrcBase - U25->U25_DESPBA)
					Else
						nPrcVen := U25->U25_PRCVEN
					EndIf
				//regra por: grupo cliente+forma+condicao+administradora
				ElseIf !Empty(cGrpCli) .and. U25->(DbSeek(xFilial("U25")+aRecebtos[nX][5][nY][2]+space(tamsx3("U25_CLIENT")[1])+space(tamsx3("U25_LOJA")[1])+cGrpCli+aRecebtos[nX][1]+aRecebtos[nX][2]+cAdmEmit+cEmitent))
					//DANILO: Verifica se tem outro preço vigente com mesma chave, com data inicio maior
					RetU25DtMaior(xFilial("U25"),aRecebtos[nX][5][nY][2], space(tamsx3("U25_CLIENT")[1]), space(tamsx3("U25_LOJA")[1]), cGrpCli, aRecebtos[nX][1], aRecebtos[nX][2], cAdmEmit, cEmitent)

					If lNgDesc .and. U25->(FieldPos("U25_DESPBA"))>0 //.and. U25->U25_DESPBA <> 0
						nPrcBase := U_URetPrBa(U25->U25_PRODUT, U25->U25_FORPAG, U25->U25_CONDPG, U25->U25_ADMFIN, 0, U25->U25_DTINIC, U25->U25_HRINIC)
						nPrcVen  := (nPrcBase - U25->U25_DESPBA)
					Else
						nPrcVen := U25->U25_PRCVEN
					EndIf
				//regra por: forma+condicao+admin
				ElseIf U25->(DbSeek(xFilial("U25")+aRecebtos[nX][5][nY][2]+space(tamsx3("U25_CLIENT")[1])+space(tamsx3("U25_LOJA")[1])+space(tamsx3("U25_GRPCLI")[1])+aRecebtos[nX][1]+aRecebtos[nX][2]+cAdmEmit+cEmitent))
					//DANILO: Verifica se tem outro preço vigente com mesma chave, com data inicio maior
					RetU25DtMaior(xFilial("U25"), aRecebtos[nX][5][nY][2], space(tamsx3("U25_CLIENT")[1]), space(tamsx3("U25_LOJA")[1]), space(tamsx3("U25_GRPCLI")[1]), aRecebtos[nX][1], aRecebtos[nX][2], cAdmEmit, cEmitent )

					If lNgDesc .and. U25->(FieldPos("U25_DESPBA"))>0 //.and. U25->U25_DESPBA <> 0
						nPrcBase := U_URetPrBa(U25->U25_PRODUT, U25->U25_FORPAG, U25->U25_CONDPG, U25->U25_ADMFIN, 0, U25->U25_DTINIC, U25->U25_HRINIC)
						nPrcVen  := (nPrcBase - U25->U25_DESPBA)
					Else
						nPrcVen := U25->U25_PRCVEN
					EndIf
				//regra por: cliente+loja
				ElseIf U25->(DbSeek(xFilial("U25")+aRecebtos[nX][5][nY][2]+cGetCodCli+cGetLoja+space(tamsx3("U25_GRPCLI")[1])+space(tamsx3("U25_FORPAG")[1])+space(tamsx3("U25_CONDPG")[1])+space(tamsx3("U25_ADMFIN")[1])+space(tamsx3("U25_EMITEN")[1])+space(tamsx3("U25_LOJEMI")[1])))
					//DANILO: Verifica se tem outro preço vigente com mesma chave, com data inicio maior
					RetU25DtMaior(xFilial("U25"), aRecebtos[nX][5][nY][2], cGetCodCli, cGetLoja, space(tamsx3("U25_GRPCLI")[1]), space(tamsx3("U25_FORPAG")[1]), space(tamsx3("U25_CONDPG")[1]), space(tamsx3("U25_ADMFIN")[1]), space(tamsx3("U25_EMITEN")[1])+space(tamsx3("U25_LOJEMI")[1]) )

					If lNgDesc .and. U25->(FieldPos("U25_DESPBA"))>0 //.and. U25->U25_DESPBA <> 0
						nPrcBase := U_URetPrBa(U25->U25_PRODUT, U25->U25_FORPAG, U25->U25_CONDPG, U25->U25_ADMFIN, 0, U25->U25_DTINIC, U25->U25_HRINIC)
						nPrcVen  := (nPrcBase - U25->U25_DESPBA)
					Else
						nPrcVen := U25->U25_PRCVEN
					EndIf
				//regra por: grupo cliente
				ElseIf !Empty(cGrpCli) .and. U25->(DbSeek(xFilial("U25")+aRecebtos[nX][5][nY][2]+space(tamsx3("U25_CLIENT")[1])+space(tamsx3("U25_LOJA")[1])+cGrpCli+space(tamsx3("U25_FORPAG")[1])+space(tamsx3("U25_CONDPG")[1])+space(tamsx3("U25_ADMFIN")[1])+space(tamsx3("U25_EMITEN")[1])+space(tamsx3("U25_LOJEMI")[1])))
					//DANILO: Verifica se tem outro preço vigente com mesma chave, com data inicio maior
					RetU25DtMaior(xFilial("U25"), aRecebtos[nX][5][nY][2], space(tamsx3("U25_CLIENT")[1]), space(tamsx3("U25_LOJA")[1]), cGrpCli, space(tamsx3("U25_FORPAG")[1]), space(tamsx3("U25_CONDPG")[1]), space(tamsx3("U25_ADMFIN")[1]), space(tamsx3("U25_EMITEN")[1])+space(tamsx3("U25_LOJEMI")[1]) )

					If lNgDesc .and. U25->(FieldPos("U25_DESPBA"))>0 //.and. U25->U25_DESPBA <> 0
						nPrcBase := U_URetPrBa(U25->U25_PRODUT, U25->U25_FORPAG, U25->U25_CONDPG, U25->U25_ADMFIN, 0, U25->U25_DTINIC, U25->U25_HRINIC)
						nPrcVen  := (nPrcBase - U25->U25_DESPBA)
					Else
						nPrcVen := U25->U25_PRCVEN
					EndIf
				EndIf

				lPrcNeg := nPrcVen > 0 //verifica se teve preço negociado

				//prioridade preço negociado: U25 -> U0C -> U51 -> DA1
				//o preco maximo eh o preco de bomba
				If nPrcVen <= 0 .or. (nPrcVen > nPrcPad .and. !lAltVrUnit)
					//-- Caso exista preço base, considera o preço da U0C ao inves do preço padrão da DA1
					nPrcVen := U_URetPrBa(aRecebtos[nX][5][nY][2], aRecebtos[nX][1], aRecebtos[nX][2], cAdmEmit, nPrcPad/*preço de bomba*/)
				EndIf
			
			else
				nPrcVen := nPrcPad
			endif

			aRecebtos[nX][5][nY][5]  := nPrcVen
			aRecebtos[nX][5][nY][10] := nPrcVen

			If lPrcNeg //se teve preço negociado
				aRecebtos[nX][5][nY][6] := U25->U25_PERMTR
				aRecebtos[nX][5][nY][7] := U25->U25_VLRMAX
				aRecebtos[nX][5][nY][8] := U25->U25_PERMAX
				aRecebtos[nX][5][nY][9] := U25->(Recno())
			EndIf

			//*** o arredondamento deve ser por item do cupom, e nao sobre o total ***
			nTttForm += Round(nPrcVen*aRecebtos[nX][5][nY][3],TamSx3("LR_VLRITEM")[2]) //A410Arred(nPrcVen*aRecebtos[nX][5][nY][3],"LR_VLRITEM")
			nTttICup += Round(nPrcPad*aRecebtos[nX][5][nY][3],TamSx3("LR_VLRITEM")[2]) //A410Arred(nPrcPad*aRecebtos[nX][5][nY][3],"LR_VLRITEM")
			nTttDesc += Round(nPrcPad*aRecebtos[nX][5][nY][3],TamSx3("LR_VLRITEM")[2]) - Round(nPrcVen*aRecebtos[nX][5][nY][3],TamSx3("LR_VLRITEM")[2]) //A410Arred(nPrcPad*aRecebtos[nX][5][nY][3],"LR_VLRITEM") - A410Arred(nPrcVen*aRecebtos[nX][5][nY][3],"LR_VLRITEM")

			//
			//	valor maximo de desconto, % maximo de desconto
			//
			_lCheque	:= alltrim(aRecebtos[nX][1])=="CH"
			_cForma 	:= aRecebtos[nX][1]
			_cCondicao	:= aRecebtos[nX][2]

		    If _lCheque
			    _cAdmFin  := space(TamSX3("AE_COD")[1])
			    _cEmiten  := substr(aRecebtos[nX][3],1,TamSX3("A1_COD")[1])
			    _cGetLojaEmi := substr(aRecebtos[nX][3],TamSX3("A1_COD")[1]+1,TamSX3("A1_LOJA")[1])
		    Else
				_cAdmFin  := aRecebtos[nX][3]
				_cEmiten  := space(TamSX3("A1_COD")[1])
			    _cGetLojaEmi := space(TamSX3("A1_LOJA")[1])
			EndIf

			aRecebtos[nX][5][nY][11] := nLF_DESCVAL //valor desconto maximo
			aRecebtos[nX][5][nY][12] := nLF_DESCPER //percentual desconto maximo
			aRecebtos[nX][5][nY][13] := 0 //margem minima (DESCONTINUADO)

			//-----------------------------
			// preço de custo do produto //
			//-----------------------------
			aRecebtos[nX][5][nY][14] := 0 //(DESCONTINUADO) Posicione("SB2",1,xFilial("SB2")+aRecebtos[nAtaReceb][5][nX][2]+"01","B2_CM1")
			
		next nY

		aRecebtos[nX][4] := RetNegPad(aRecebtos[nX][1]+aRecebtos[nX][2])
		aRecebtos[nX][6] := nTttICup
		aRecebtos[nX][7] := nTttForm
		aRecebtos[nX][8] := nTttDesc

		for nY:=1 to len(aProdutos)
			nPosPr := aScan(aRecebtos[nX][5],{|x| AllTrim(x[1]+x[2])==AllTrim(aProdutos[nY][1]+aProdutos[nY][2])})
			If nPosPr == 0
				aRecebtos[nX][14] += Round(aProdutos[nY][3]*aProdutos[nY][4],TamSx3("LR_VLRITEM")[2]) //A410Arred(aProdutos[nY][3]*aProdutos[nY][4],"LR_VLRITEM")
			EndIf
		next nY

		//aRecebtos[nX][6] += aRecebtos[nX][14] -> total do cupom (todos produtos)
	next nX

	//ordeno o aRecebtos pelas colunas de FORMA + CONDICAO + ADMINISTRADORA/EMITENTE
	nCol1 := 1 //FORMA
	nCol2 := 2 //CONDICAO
	nCol3 := 3 //ADMINISTRADORA/EMITENTE
	ASORT(aRecebtos,,,{|x, y| x[nCol1]+x[nCol2]+x[nCol3] < y[nCol1]+y[nCol2]+y[nCol3] }) //ordenação crescente

	// limpo os filtros da U25
	U25->(DbClearFilter())
	
	//Restaura areas
	RestArea(aArea)
	FWRestRows(aSaveLines)

	// Limpa os vetores para melhor gerenciamento de memoria (Desaloca Memória)
	aSize( aSaveLines, 0 )
	aSaveLines 	:= Nil

Return

//função que verifica se tem mesma chave com data inicio maior que o atual registro
//Sempre que usar deve estar no indice 2
Static Function RetU25DtMaior(_cFil,_cProd, _cCli, _cLoj, _cGrp, _cFor, _cCond, _cAdm, _cEmit)

	Local nRecU25 := U25->(Recno())

	While U25->(!Eof()) .AND. ;
		U25->U25_FILIAL == _cFil .AND. ;
		U25->U25_PRODUT == _cProd .AND. ;
		U25->U25_CLIENT == _cCli .AND. ;
		U25->U25_LOJA == _cLoj .AND. ;
		U25->U25_GRPCLI == _cGrp .AND. ;
		U25->U25_FORPAG == _cFor .AND. ;
		U25->U25_CONDPG == _cCond .AND. ;
		U25->U25_ADMFIN == _cAdm .AND. ;
		U25->U25_EMITEN+U25->U25_LOJEMI == _cEmit

		nRecU25 := U25->(Recno())
		U25->(DbSkip())
	Enddo

	U25->(DbGoTo(nRecU25))

Return

//----------------------------------------------------------------------
// retorna se a negociacao e padrao
// (U44_PADRAO == 'S')
//----------------------------------------------------------------------
Static Function RetNegPad(cNeg)

	Local aAreaU44 := U44->(GetArea())
	Local lRet     := .F.

	dbselectarea("U44")
	U44->(dbsetorder(1)) //U44_FILIAL+U44_FORMPG+U44_CONDPG
	If U44->(dbseek(xFilial("U44")+cNeg))
		lRet := (U44->U44_PADRAO == 'S')
	EndIf

	RestArea(aAreaU44)

return lRet

//--------------------------------------------------------------------------------------
// retorna um array com todas as formas de recebimento de um determinado produto
//--------------------------------------------------------------------------------------
Static Function RetFormas(cProduto, _cCodCli, _cLoja, cFilForm)

	Local aArea     := GetArea()
	Local nX        := 0
	Local nPos		:= 0
	Local aRet      := {}
	Local cCliente  := _cCodCli //cGetCodCli
	Local cLoja     := _cLoja   //cGetLoja
	Local cGrpA1    := RetField("SA1",1,xFilial("SA1")+cCliente+cLoja,"A1_GRPVEN")
	Local cClasse   := "" //RetField("SA1",1,xFilial("SA1")+cCliente+cLoja,"A1_XCLASSE")
	Local cAtivid   := RetField("SA1",1,xFilial("SA1")+cCliente+cLoja,"A1_SATIV1")
	Local cGrpB1    := RetField("SB1",1,xFilial("SB1")+cProduto,"B1_GRUPO")
	Local cCondicao	:= ""
	Local bCondicao

	Default cFilForm := ""

	//formas padroes
	cCondicao := "U44->U44_FILIAL = '"+xFilial("U44")+"'"
	cCondicao += " .AND. U44->U44_PADRAO = 'S'" //somente as formas padroes
	If !Empty(cFilForm)
		cCondicao += " .AND. U44->U44_FORMPG $ '"+cFilForm+"'" //somente as formas filtradas
	EndIf

	// limpo os filtros da U44
	//U44->(DbClearFilter())

	// executo o filtro na U44
	//bCondicao 	:= "{|| " + cCondicao + " }"
	//U44->(DbSetFilter(&bCondicao,cCondicao))

	// vou para a primeira linha
	U44->(DbSetOrder(1)) //U44_FILIAL+U44_FORMPG+U44_CONDPG
	U44->(DbGoTop())
	U44->(DbSeek(xFilial("U44")))

	SE4->(DbSetOrder(1)) //E4_FILIAL+E4_CODIGO
	SX5->(DbSetOrder(1)) //X5_FILIAL+X5_TABELA+X5_CHAVE

	While U44->(!EOF())
		If &(AllTrim(cCondicao))
			nPos := aScan( aRet,{|x| AllTrim(x[1]+x[2])==AllTrim(U44->U44_FORMPG+U44->U44_CONDPG)})
			If nPos == 0 ;
				.and. SE4->(DbSeek(xFilial("SE4")+U44->U44_CONDPG)) //verifica se existi condição de pagamento
				
				lExistSX5 := .F.
				If Alltrim(U44->U44_FORMPG) $ 'R$|PX|PD|CC|CD|CH|NB' .and. SX5->(DbSeek(xFilial("SX5")+"24"+"P"+AllTrim(U44->U44_FORMPG)))
					lExistSX5 := .T.
				Else
					lExistSX5 := SX5->(DbSeek(xFilial("SX5")+"24"+U44->U44_FORMPG))
				EndIf

				If lExistSX5
					AAdd(aRet, {U44->U44_FORMPG, U44->U44_CONDPG, {U44->U44_PERMTR, U44->U44_VLRMAX, U44->U44_PERMAX, U44->U44_PERVHA}})
				EndIf

			EndIf
		EndIf
		U44->(DbSkip())
	EndDo

	// limpo os filtros da U44
	//U44->(DbClearFilter())

	//formas negociadas por cliente -> regras por produto/grupo
	DbSelectArea("U53")
	U53->(DbSetOrder(1)) //U53_FILIAL+U53_CODCLI+U53_LOJA+U53_GRPVEN+U53_CLASSE+U53_SATIV1+U53_ITEM

	U44->(DbSetOrder(1)) //U44_FILIAL+U44_FORMPG+U44_CONDPG
	U44->(DbGoTop())

	//PRIMEIRO SERÁ VERIFICADO AS REGRAS

	//regra de segmento
	If !Empty(cAtivid) .and. U53->(dbseek(xFilial("U53")+space(tamsx3("U53_CODCLI")[1])+space(tamsx3("U53_LOJA")[1])+space(tamsx3("U53_GRPVEN")[1])+space(tamsx3("U53_CLASSE")[1])+cAtivid))
		while U53->(!EOF()) .and. U53->U53_SATIV1 == cAtivid
			nPos := aScan( aRet,{|x| AllTrim(x[1]+x[2])==AllTrim(U53->(U53_FORMPG+U53_CONDPG))})
			If U53->U53_TPRGNG == "R"; //regra
				.and. ((!Empty(U53->U53_CODPRO) .and. U53->U53_CODPRO == cProduto) .OR. (!Empty(U53->U53_GRUPO) .and. U53->U53_GRUPO == cGrpB1) .OR. (Empty(U53->U53_CODPRO) .and. Empty(U53->U53_GRUPO)));
				.and. nPos==0 //nao esta adicionado

				If Empty(cFilForm) .OR. U53->U53_FORMPG $ cFilForm
					//posiciono para pegar %/vlr troco
					//Posicione("U44",1,xFilial("U44")+U53->U53_FORMPG+U53->U53_CONDPG,"U44_PADRAO")
					If U44->(DbSeek(xFilial("U44")+U53->U53_FORMPG+U53->U53_CONDPG))

						//adiciona no aRet
						AAdd(aRet, {U53->U53_FORMPG,U53->U53_CONDPG, {U44->U44_PERMTR, U44->U44_VLRMAX, U44->U44_PERMAX, U44->U44_PERVHA} })
					EndIf
				EndIf
			EndIf
			U53->(dbskip())
		enddo
	EndIf

	//regra de classe
	If !Empty(cClasse) .and. U53->(dbseek(xFilial("U53")+space(tamsx3("U53_CODCLI")[1])+space(tamsx3("U53_LOJA")[1])+space(tamsx3("U53_GRPVEN")[1])+cClasse))
		while !U53->(EOF()) .and. U53->U53_CLASSE == cClasse
			nPos := aScan( aRet,{|x| AllTrim(x[1]+x[2])==AllTrim(U53->(U53_FORMPG+U53_CONDPG))})
			If U53->U53_TPRGNG == "R"; //regra
				.and. ((!Empty(U53->U53_CODPRO) .and. U53->U53_CODPRO == cProduto) .OR. (!Empty(U53->U53_GRUPO) .and. U53->U53_GRUPO == cGrpB1) .OR. (Empty(U53->U53_CODPRO) .and. Empty(U53->U53_GRUPO)));
				.and. nPos==0 //nao esta adicionado

				If Empty(cFilForm) .OR. U53->U53_FORMPG $ cFilForm
					//posiciono para pegar %/vlr troco
					//Posicione("U44",1,xFilial("U44")+U53->U53_FORMPG+U53->U53_CONDPG,"U44_PADRAO")
					If U44->(DbSeek(xFilial("U44")+U53->U53_FORMPG+U53->U53_CONDPG))

						//adiciona no aRet
						AAdd(aRet, {U53->U53_FORMPG,U53->U53_CONDPG, {U44->U44_PERMTR, U44->U44_VLRMAX, U44->U44_PERMAX, U44->U44_PERVHA} })
					EndIf
				EndIf
			EndIf
			U53->(dbskip())
		enddo
	EndIf

	//regra de grupo
	If !Empty(cGrpA1) .and. U53->(dbseek(xFilial("U53")+space(tamsx3("U53_CODCLI")[1])+space(tamsx3("U53_LOJA")[1])+cGrpA1))
		while U53->(!EOF()) .and. U53->U53_GRPVEN == cGrpA1
			nPos := aScan( aRet,{|x| AllTrim(x[1]+x[2])==AllTrim(U53->(U53_FORMPG+U53_CONDPG))})
			If U53->U53_TPRGNG == "R"; //regra
				.and. ((!Empty(U53->U53_CODPRO) .and. U53->U53_CODPRO == cProduto) .OR. (!Empty(U53->U53_GRUPO) .and. U53->U53_GRUPO == cGrpB1) .OR. (Empty(U53->U53_CODPRO) .and. Empty(U53->U53_GRUPO)));
				.and. nPos==0 //nao esta adicionado

				If Empty(cFilForm) .OR. U53->U53_FORMPG $ cFilForm
					//posiciono para pegar %/vlr troco
					//Posicione("U44",1,xFilial("U44")+U53->U53_FORMPG+U53->U53_CONDPG,"U44_PADRAO")
					If U44->(DbSeek(xFilial("U44")+U53->U53_FORMPG+U53->U53_CONDPG))

						//adiciona no aRet
						AAdd(aRet, {U53->U53_FORMPG,U53->U53_CONDPG, {U44->U44_PERMTR, U44->U44_VLRMAX, U44->U44_PERMAX, U44->U44_PERVHA} })
					EndIf
				EndIf
			EndIf
			U53->(dbskip())
		enddo
	EndIf

	//regra de cliente
	If !Empty(cCliente) .and. !Empty(cLoja) .and. U53->(dbseek(xFilial("U53")+cCliente+cLoja))
		while U53->(!EOF()) .and. U53->U53_CODCLI == cCliente .and. U53->U53_LOJA == cLoja
			nPos := aScan( aRet,{|x| AllTrim(x[1]+x[2])==AllTrim(U53->(U53_FORMPG+U53_CONDPG))})
			If U53->U53_TPRGNG == "R"; //regra
				.and. ((!Empty(U53->U53_CODPRO) .and. U53->U53_CODPRO == cProduto) .OR. (!Empty(U53->U53_GRUPO) .and. U53->U53_GRUPO == cGrpB1) .OR. (Empty(U53->U53_CODPRO) .and. Empty(U53->U53_GRUPO)));
				.and. nPos==0 //nao esta adicionado

				If Empty(cFilForm) .OR. U53->U53_FORMPG $ cFilForm
					//posiciono para pegar %/vlr troco
					//Posicione("U44",1,xFilial("U44")+U53->U53_FORMPG+U53->U53_CONDPG,"U44_PADRAO")
					If U44->(DbSeek(xFilial("U44")+U53->U53_FORMPG+U53->U53_CONDPG))

						//adiciona no aRet
						AAdd(aRet, {U53->U53_FORMPG,U53->U53_CONDPG, {U44->U44_PERMTR, U44->U44_VLRMAX, U44->U44_PERMAX, U44->U44_PERVHA} })
					EndIf
				EndIf
			EndIf
			U53->(dbskip())
		enddo
	EndIf


	//DEPOIS VERIFICAMOS AS EXCEÇÕES
	//excecao de segmento
	If !Empty(cAtivid) .and. U53->(dbseek(xFilial("U53")+space(tamsx3("U53_CODCLI")[1])+space(tamsx3("U53_LOJA")[1])+space(tamsx3("U53_GRPVEN")[1])+space(tamsx3("U53_CLASSE")[1])+cAtivid))
		while U53->(!EOF()) .and. U53->U53_SATIV1 == cAtivid
			nPos := aScan( aRet,{|x| AllTrim(x[1]+x[2])==AllTrim(U53->(U53_FORMPG+U53_CONDPG))})
			If U53->U53_TPRGNG == "E"; //excecao
				.and. ((!Empty(U53->U53_CODPRO) .and. U53->U53_CODPRO == cProduto) .OR. (!Empty(U53->U53_GRUPO) .and. U53->U53_GRUPO == cGrpB1) .OR. (Empty(U53->U53_CODPRO) .and. Empty(U53->U53_GRUPO)));
				.and. nPos<>0;
				//remove no aRet
				ADel(aRet,nPos)
				ASize(aRet,Len(aRet)-1)
			EndIf
			U53->(dbskip())
		enddo
	EndIf

	//excecao de classe
	If !Empty(cClasse) .and. U53->(dbseek(xFilial("U53")+space(tamsx3("U53_CODCLI")[1])+space(tamsx3("U53_LOJA")[1])+space(tamsx3("U53_GRPVEN")[1])+cClasse))
		while !U53->(EOF()) .and. U53->U53_CLASSE == cClasse
			nPos := aScan( aRet,{|x| AllTrim(x[1]+x[2])==AllTrim(U53->(U53_FORMPG+U53_CONDPG))})
			If U53->U53_TPRGNG == "E"; //excecao
				.and. ((!Empty(U53->U53_CODPRO) .and. U53->U53_CODPRO == cProduto) .OR. (!Empty(U53->U53_GRUPO) .and. U53->U53_GRUPO == cGrpB1) .OR. (Empty(U53->U53_CODPRO) .and. Empty(U53->U53_GRUPO)));
				.and. nPos<>0;
				//remove no aRet
				ADel(aRet,nPos)
				ASize(aRet,Len(aRet)-1)
			EndIf
			U53->(dbskip())
		enddo
	EndIf

	//excecao de grupo
	If !Empty(cGrpA1) .and. U53->(dbseek(xFilial("U53")+space(tamsx3("U53_CODCLI")[1])+space(tamsx3("U53_LOJA")[1])+cGrpA1))
		while U53->(!EOF()) .and. U53->U53_GRPVEN == cGrpA1
			nPos := aScan( aRet,{|x| AllTrim(x[1]+x[2])==AllTrim(U53->(U53_FORMPG+U53_CONDPG))})
			If U53->U53_TPRGNG == "E"; //excecao
				.and. ((!Empty(U53->U53_CODPRO) .and. U53->U53_CODPRO == cProduto) .OR. (!Empty(U53->U53_GRUPO) .and. U53->U53_GRUPO == cGrpB1) .OR. (Empty(U53->U53_CODPRO) .and. Empty(U53->U53_GRUPO)));
				.and. nPos<>0;
				//remove no aRet
				ADel(aRet,nPos)
				ASize(aRet,Len(aRet)-1)
			EndIf
			U53->(dbskip())
		enddo
	EndIf

	//excecao de cliente
	If !Empty(cCliente) .and. !Empty(cLoja) .and. U53->(dbseek(xFilial("U53")+cCliente+cLoja))
		while U53->(!EOF()) .and. U53->U53_CODCLI == cCliente .and. U53->U53_LOJA == cLoja
			nPos := aScan( aRet,{|x| AllTrim(x[1]+x[2])==AllTrim(U53->(U53_FORMPG+U53_CONDPG))})
			If U53->U53_TPRGNG == "E"; //excecao
				.and. ((!Empty(U53->U53_CODPRO) .and. U53->U53_CODPRO == cProduto) .OR. (!Empty(U53->U53_GRUPO) .and. U53->U53_GRUPO == cGrpB1) .OR. (Empty(U53->U53_CODPRO) .and. Empty(U53->U53_GRUPO)));
				.and. nPos<>0;
				//remove no aRet
				ADel(aRet,nPos)
				ASize(aRet,Len(aRet)-1)
			EndIf
			U53->(dbskip())
		enddo
	EndIf

	RestArea(aArea)

Return aRet

//
// Validacao de campo -> CAMPO "RECEBIDO" -> recalcula os valores do aRecebtos
//
Static Function AtuARecebtos(lSoTot, nPosAtu)

	Local nX := 0
	Local nPosGri := 0
	Local nPosFor := aScan(aFieldGrid,{|y| AllTrim(y)=="U44_FORMPG"})
	Local nPosCon := aScan(aFieldGrid,{|y| AllTrim(y)=="U44_CONDPG"})
	Local nPosEmi := aScan(aFieldGrid,{|y| AllTrim(y)=="U25_EMITEN"})
	Local nPosAdm := aScan(aFieldGrid,{|y| AllTrim(y)=="U25_ADMFIN"})
	Local oTotal
	/*/ MV_XATUPRC - tipo de negociação no Totvs PDV: DESCONTO ou PREÇO UNITÁRIO
		.T. - Trabalha com preço maior que o preço de tabela (não tem desconto, ajuste preço unitário)
		.F. - Trabalha com desconto no preço de tabela (não ajusta preço unitário, trabalha com desconto)
	/*/
	Local lAltVrUnit := SuperGetMv("MV_XATUPRC",.T./*lHelp*/,.T./*uPadrao*/)

	Default lSoTot := .F.
	Default nPosAtu := 0

	//----------------------------------------------------------------------
	// atualiza o valor original -> CarrVlrOri(lSoTot)
	//----------------------------------------------------------------------
	for nX:=1 to len(aRecebtos)

		If (aRecebtos[nX][9]+aRecebtos[nX][16]) < aRecebtos[nX][7]
			aRecebtos[nX][12] := (aRecebtos[nX][9]*aRecebtos[nX][6])/aRecebtos[nX][7] //(recebido * total cupom) / total da forma
		Else
			aRecebtos[nX][12] := aRecebtos[nX][6]
		EndIf

		If !lSoTot .and. ValType(aItensGrid)<>"U" //"U" - Não definido
			If AllTrim(aRecebtos[nX][1])=="CH"
				nPosGri := aScan(aItensGrid,{|x| AllTrim(x[nPosFor]+x[nPosCon]+x[nPosEmi])==AllTrim(aRecebtos[nX][1]+aRecebtos[nX][2]+aRecebtos[nX][3])})
			Else
				nPosGri := aScan(aItensGrid,{|x| AllTrim(x[nPosFor]+x[nPosCon]+x[nPosAdm])==AllTrim(aRecebtos[nX][1]+aRecebtos[nX][2]+aRecebtos[nX][3])})
			EndIf
			If nPosGri > 0
				aItensGrid[nPosGri][aScan(aFieldGrid,{|y| AllTrim(y)=="ORIGINAL"})] := Round(aRecebtos[nX][12],2)
			EndIf
		EndIf
	next nX

	//----------------------------------------------------------------------
	// atualiza o status do percentual - carrega percentual -> CarrPerc()
	//----------------------------------------------------------------------
	nPercent := 0

	//atualiza os percentuais dos itens e o percentual total
	for nX:=1 to len(aRecebtos)
		aRecebtos[nX][10] := aRecebtos[nX][12]/(aRecebtos[nX][6]+aRecebtos[nX][14])
		nPercent += aRecebtos[nX][10]
	next nX

	if lAddPromo .AND. STDGPBasket("SL1","L1_XDESPRO") > 0
		oTotal  := STFGetTot() //Recebe o Objeto totalizador
		nPercent += STDGPBasket("SL1","L1_XDESPRO")/oTotal:GetValue("L1_VALMERC")
	endif

	if nPercent > 1
		if nPosAtu > 0
			aRecebtos[nPosAtu][10] := 1 - (nPercent - aRecebtos[nPosAtu][10])
		endif
		nPercent := 1
	else
		//verifico se ja recebi tudo e ainda ficou um percentual estante.. ex 0,99915335
		if nPosAtu > 0 .AND. aRecebtos[nPosAtu][9] >= aRecebtos[nPosAtu][11]
			aRecebtos[nPosAtu][10] += (1 - nPercent)
			nPercent := 1
		endif
	endif

	//----------------------------------------------------------------------
	// atualiza saldo -> CarrSaldo(lSoTot)
	//----------------------------------------------------------------------
	for nX:=1 to len(aRecebtos)
		aRecebtos[nX][11] := ((aRecebtos[nX][6]+aRecebtos[nX][14])*(1-nPercent))*(aRecebtos[nX][7]/aRecebtos[nX][6])

		//ajusto saldo da forma, com novo conceito
		if lAltVrUnit
			aRecebtos[nX][11] := GetNewSld(aRecebtos[nX][11], nX)
		endif
		
		If !lSoTot .and. ValType(aItensGrid)<>"U"
			If AllTrim(aRecebtos[nX][1])=="CH"
				nPosGri := aScan(aItensGrid,{|x| AllTrim(x[nPosFor]+x[nPosCon]+x[nPosEmi])==AllTrim(aRecebtos[nX][1]+aRecebtos[nX][2]+aRecebtos[nX][3])})
			Else
				nPosGri := aScan(aItensGrid,{|x| AllTrim(x[nPosFor]+x[nPosCon]+x[nPosAdm])==AllTrim(aRecebtos[nX][1]+aRecebtos[nX][2]+aRecebtos[nX][3])})
			EndIf
			If nPosGri > 0
				If aRecebtos[nX][11] <= 0
					aItensGrid[nPosGri][aScan(aFieldGrid,{|y| AllTrim(y)=="SALDO"})] := 0
				Else
					If aRecebtos[nX][11] > Round(aRecebtos[nX][11],2)
						aItensGrid[nPosGri][aScan(aFieldGrid,{|y| AllTrim(y)=="SALDO"})] := Round(aRecebtos[nX][11],2) + 0.01
					Else
						aItensGrid[nPosGri][aScan(aFieldGrid,{|y| AllTrim(y)=="SALDO"})] := Round(aRecebtos[nX][11],2)
					EndIf
				EndIf
			EndIf
		EndIf
	next nX

	//----------------------------------------------------------------------
	// atualiza o desconto do item -> CarrDesItm(lSoTot)
	//----------------------------------------------------------------------
	for nX:=1 to len(aRecebtos)
		If (aRecebtos[nX][9]+aRecebtos[nX][16]) > aRecebtos[nX][7]
			aRecebtos[nX][13] := aRecebtos[nX][12] - aRecebtos[nX][7] //valor original - saldo
		Else
			aRecebtos[nX][13] := aRecebtos[nX][12] - (aRecebtos[nX][9]+aRecebtos[nX][16]) //valor original - valor recebido
		EndIf

		If !lSoTot .and. ValType(aItensGrid)<>"U"
			If AllTrim(aRecebtos[nX][1])=="CH"
				nPosGri := aScan(aItensGrid,{|x| AllTrim(x[nPosFor]+x[nPosCon]+x[nPosEmi])==AllTrim(aRecebtos[nX][1]+aRecebtos[nX][2]+aRecebtos[nX][3])})
			Else
				nPosGri := aScan(aItensGrid,{|x| AllTrim(x[nPosFor]+x[nPosCon]+x[nPosAdm])==AllTrim(aRecebtos[nX][1]+aRecebtos[nX][2]+aRecebtos[nX][3])})
			EndIf
			If nPosGri > 0
				aItensGrid[nPosGri][aScan(aFieldGrid,{|y| AllTrim(y)=="DESCONTO"})] := Round(aRecebtos[nX][13], TamSx3("L2_VALDESC")[2]) //A410Arred(aRecebtos[nX][13],"LR_VALDESC")
			EndIf
		EndIf
	next nX

Return .T.

//----------------------------------------------------------------------
// retornar o percentual maximo de desconto do caixa
//----------------------------------------------------------------------
Static Function RetTotDesP(cNumCaixa)

	Local aArea := GetArea()
	Local aAreaSX5 := SX5->(GetArea())
	Local aAreaSLF := SLF->(GetArea())
	Local nRet := 0
	Default cNumCaixa := xNumCaixa()

		DbSelectArea("SLF")
		DbSetOrder(1)
		If DbSeek(xFilial("SLF")+SA6->A6_COD)
			nRet := SLF->LF_DESCPER //percentual maximo de desconto do caixa
		EndIf

	RestArea(aAreaSLF)
	RestArea(aArea)

Return nRet

//----------------------------------------------------------------------
// retornar o valor maximo de desconto do caixa
//----------------------------------------------------------------------
Static Function RetTotDesV(cNumCaixa)

	Local aArea := GetArea()
	Local aAreaSX5 := SX5->(GetArea())
	Local aAreaSLF := SLF->(GetArea())
	Local nRet := 0
	Default cNumCaixa := xNumCaixa()

		DbSelectArea("SLF")
		DbSetOrder(1)
		If DbSeek(xFilial("SLF")+SA6->A6_COD)
			nRet := SLF->LF_DESCVAL //percentual maximo de desconto do caixa
		EndIf

	RestArea(aAreaSLF)
	RestArea(aArea)

Return nRet

//----------------------------------------------------------------------
// Filtra pelos dados informados: aItensGrid
//----------------------------------------------------------------------
Static Function RefreshGridPg(cForma)

	Local lCheque := .F.
	Local nX := 0
	aItensGrid := {}

	For nX:=1 to len(aRecebtos)
		lCheque := AllTrim(aRecebtos[nX][1])=="CH"
	    If lCheque
		    cU44_DESCRI := AllTrim(RetField("U44",1,xFilial("U44")+aRecebtos[nX][1]+aRecebtos[nX][2],"U44_DESCRI"))+" "+AllTrim(RetField("SA1",1,xFilial("SA1")+aRecebtos[nX][3],"A1_NOME"))
	    Else
			cU44_DESCRI := AllTrim(RetField("U44",1,xFilial("U44")+aRecebtos[nX][1]+aRecebtos[nX][2],"U44_DESCRI"))+" "+AllTrim(RetField("SAE",1,xFilial("SAE")+aRecebtos[nX][3],"AE_DESC"))
		EndIf
		If AllTrim(aRecebtos[nX][1]) == AllTrim(cForma)
			//{"SALDO","U44_DESCRI","U44_FORMPG","U44_CONDPG","U25_ADMFIN","U25_EMITEN","EXCECAO","TOTALNEG","ORIGINAL","DESCONTO"}
			AAdd(aItensGrid, {;
				iif(aRecebtos[nX][11]<0,0,aRecebtos[nX][11]), ; //SALDO
				cU44_DESCRI, ; //U44_DESCRI
				aRecebtos[nX][1], ; //U44_FORMPG
				aRecebtos[nX][2], ; //U44_CONDPG
				iif(lCheque,"",aRecebtos[nX][3]), ; //U25_ADMFIN
				iif(lCheque,aRecebtos[nX][3],""),; //EMITEN
				iif(aRecebtos[nX][14] > 0,"LBOK","LBNO"), ; //EXCECAO
				aRecebtos[nX][7], ; //TOTALNEG
				Round(aRecebtos[nX][12],2), ; //ORIGINAL
				Round(aRecebtos[nX][13],2) ; //DESCONTO
				})

		EndIf
	Next nX

Return

//----------------------------------------------------------------------------------
// função que retorna linha do acols selecionada, e ajusta a variável nAtAreceb
//----------------------------------------------------------------------------------
Static Function GetSelected(cForma)

	Local aRet := {}

	Local nPosFor := aScan(aFieldGrid,{|y| AllTrim(y)=="U44_FORMPG"})
	Local nPosCon := aScan(aFieldGrid,{|y| AllTrim(y)=="U44_CONDPG"})
	Local nPosEmi := aScan(aFieldGrid,{|y| AllTrim(y)=="U25_EMITEN"})
	Local nPosAdm := aScan(aFieldGrid,{|y| AllTrim(y)=="U25_ADMFIN"})
	Local cFPConv := SuperGetMv("TP_FPGCONV",,"")

	If Len(aItensGrid)>=1 .and. alltrim(cForma) == alltrim(SuperGetMV("MV_SIMB1")) //dinheiro
		aRet := aClone(aItensGrid[1])
	ElseIf Len(aItensGrid)>=1 .and. (Alltrim(cForma) $ 'NB' .OR. (Alltrim(cForma) == 'PX' .AND. !("PX" $ cFPConv)) .OR. (Alltrim(cForma) == 'PD' .AND. !("PD" $ cFPConv))) //Créditos, PIX e Pag.Digital
		aRet := aClone(aItensGrid[1])
	Else
		If len(aNewGdNeg) >= nNewGdNeg
	   		aRet := aClone(aNewGdNeg[nNewGdNeg]) 
			aSize(aRet, len(aRet)-1) //removo coluna deleted
		EndIf
	EndIf

	If Len(aRet)>0
		nAtaReceb := aScan(aRecebtos,{|x| AllTrim(x[1]+x[2]+x[3])==AllTrim(aRet[nPosFor]+aRet[nPosCon]+iif(Alltrim(aRet[nPosFor])=="CH",aRet[nPosEmi],aRet[nPosAdm]) )})
	EndIf

Return aRet

//--------------------------------------------------------------
// Função para carregar dados complementares na SL4
//--------------------------------------------------------------
Static Function SetL4Custom(cForma, cCondPg, aDados, nVrReceb)

	Local nPosMdl
	Local oMdl, oMdlPaym, oMdlParc, oMldVP
	Local nX, nY, nZ, nParc, aParc, cAutoriz, cNsutef, cFormaid
	Local nLinAtu := 0
	Local cFPConv := SuperGetMv("TP_FPGCONV",,"")
	Local lWhenParc := SuperGetMV("MV_XPARCPG",,.T.) //Define se a quantidade de parcelas será definida pela condição de pagamento ou não

	oMdl := STISetMdlPay() //Get no objeto oMdlPaym: Resumo do Pagamento
	If ValType(oMdl) == "O"
		oMdlPaym := oMdl:GetModel('APAYMENTS') //model pagamentos
		oMdlParc := oMdl:GetModel("PARCELAS")  //model parcelas

		Iif(FindFunction("STBGtMdlVP"),oMldVP:=STBGtMdlVP(),)
		If ValType(oMldVP) != "O" .and. FindFunction("STBStMdlVP")
			STBStMdlVP(oMdlParc)
		EndIf
		
		//carregar o total ja recebido
		If ValType(oMdlPaym) == "O" .AND. len(aDados) > 0

			nPosMdl := oMdlPaym:GetLine() //guardo a linha posicionada

			If Alltrim(cForma) == "R$" //se dinheiro
				//faço verifição se é uma alteração
				For nX := 1 To oMdlPaym:Length()
					oMdlPaym:GoLine(nX) //vou para a ultima linha
					If Alltrim(oMdlPaym:GetValue('L4_FORMA')) == "R$"
						EXIT //sai do For nX
					EndIf
				Next nX
			Else
				oMdlPaym:GoLine(oMdlPaym:Length()) //vou para a ultima linha incluida
			EndIf

			If Alltrim(cForma) == "CH"

				nLinAtu := oMdlPaym:Length()-Len(aCheques) //vou para a primeira linha antes do primeiro cheque
				For nY := 1 to len(aCheques)
					oMdlPaym:GoLine(nLinAtu+nY) //vou para a linha
					If Alltrim(oMdlPaym:GetValue('L4_FORMA')) == Alltrim(cForma) //verifico se realmente é a forma incluida
						For nX := 1 to len(aDados)
							oMdlPaym:LoadValue(aDados[nX][1], aDados[nX][2])
						Next nX
						//aCheques {banco, num cheque, agencia, conta, compensacao, nome emitente, telefone, Rg, lEmitente, data, valor, sequencia, cpf/cnpj emitente, cmc7, codigo, loja}
						oMdlPaym:LoadValue("L4_CGC", aCheques[nY][13])
						oMdlPaym:LoadValue("L4_COMP", aCheques[nY][5])
						oMdlPaym:LoadValue("L4_OBS", aCheques[nY][14])
					EndIf
				Next nY

			ElseIf (AllTrim(cForma) $ 'NP|CF|CT|'+cFPConv) .and. !Empty(cCondPg)
			
				aParc := condicao(nVrReceb,cCondPg,0.00,dDatabase,0.00,{},,0)
				nParc := Len(aParc)
				nLinAtu := oMdlPaym:Length()-nParc //vou para a primeira linha antes da forma: CF ou NP
				
				For nY := 1 to nParc
					oMdlPaym:GoLine(nLinAtu+nY) //vou para a linha
					If Alltrim(oMdlPaym:GetValue('L4_FORMA')) == Alltrim(cForma) //verifico se realmente é a forma incluida
						For nX := 1 to len(aDados)
							oMdlPaym:LoadValue(aDados[nX][1], aDados[nX][2])
						Next nX
						oMdlPaym:LoadValue('L4_DATA', aParc[nY][01], nLinAtu+nY)
					EndIf
				Next nY
				
			ElseIf (Alltrim(cForma) $ "CC/CD") .and. !Empty(cCondPg) //Tratamento para cartão de crédito/débito

				//SOLUCAO DE CONTORNO, ERRO PASSADO PARA ANDERSON
				//Ajuste do L4_FORMID, pois o padrão não está gravando
				If ExistFunc("STBSetIDTF")
					nPosMdl := oMdlPaym:GetLine() //guardo a linha posicionada
					For nX := 1 to oMdlPaym:Length()
						oMdlPaym:GoLine(nX) //vou para a linha do model APAYMENTS

						/* controle sobre o ID do CARTAO */
						If AllTrim(oMdlPaym:GetValue('L4_FORMA')) == "CC" .AND. empty(oMdlPaym:GetValue('L4_FORMAID'))
							//incrementa o ID do cartao de CREDITO
							//STBSetIDTF("CC")
							oMdlPaym:LoadValue( "L4_FORMAID"	, cValToChar(STBGetIDTF("CC")), nX )
						ElseIf AllTrim(oMdlPaym:GetValue('L4_FORMA')) == "CD" .AND. empty(oMdlPaym:GetValue('L4_FORMAID'))
							//incrementa o ID do cartao de DEBITO
							//STBSetIDTF("CD")
							oMdlPaym:LoadValue( "L4_FORMAID"	, cValToChar(STBGetIDTF("CD")), nX )
						EndIf
					next nX
					oMdlPaym:GoLine(nPosMdl)
				EndIf

				//considera que esta posicionado na ultima parcela da forma (ultima linha)
				If AllTrim(oMdlPaym:GetValue('L4_FORMA')) = Alltrim(cForma)
					aParc := condicao(nVrReceb,cCondPg,0.00,dDatabase,0.00,{},,0)
					cAutoriz := oMdlPaym:GetValue('L4_AUTORIZ')
					cNsutef := oMdlPaym:GetValue('L4_NSUTEF')
					cFormaid := oMdlPaym:GetValue('L4_FORMAID')
					nParc := oMdlPaym:GetValue('L4_PARC') //número de parcelas da forma
					If !lWhenParc .OR. nParc = Len(aParc) //compara o número de parcelas da forma no model com o numero de parcelas da condição de pagamento
						nZ := 1
						For nX := 1 to oMdlPaym:Length()
							oMdlPaym:GoLine(nX) //vou para a linha do model APAYMENTS
							If AllTrim(oMdlPaym:GetValue('L4_FORMA')) = Alltrim(cForma) .and. ; //tratamento somente para cartão CC
									oMdlPaym:GetValue('L4_AUTORIZ') == cAutoriz .and. ;
									oMdlPaym:GetValue('L4_NSUTEF') == cNsutef .and. ;
									oMdlPaym:GetValue('L4_FORMAID') == cFormaid .and. ;
									oMdlPaym:GetValue('L4_PARC') == nParc
								For nY := 1 to len(aDados)
									oMdlPaym:LoadValue(aDados[nY][1], aDados[nY][2], nX)
								Next nY
								//ajusta a data de vencimento das parcelas, conforme a condição de pagamento da negociação de pagamento
								if lWhenParc
									oMdlPaym:LoadValue('L4_DATA', aParc[nZ][01], nX) 
								endif
								nZ++
								If (nZ > nParc)
									EXIT //sai do For nX
								EndIf
							EndIf
						Next nX
					EndIf
				EndIf
                    
			Else

				//considera que esta posicionado na ultima parcela da forma (ultima linha) ou na forma R$ (primeira)
				If Alltrim(oMdlPaym:GetValue('L4_FORMA')) == Alltrim(cForma) //verifico se realmente é a forma incluida 
					For nX := 1 to len(aDados)
						oMdlPaym:LoadValue(aDados[nX][1], aDados[nX][2])
					Next nX
				EndIf
				
			EndIf

			oMdlPaym:GoLine(nPosMdl) //restauro a linha posicionada

		EndIf
	EndIf

Return

//-------------------------------------------------------------
// Valdação das telas de cheque, antes de passar a funçao de gravaçao
// Tipo 1 = Primeira tela de valor e negociação
// 		2 = Validação tela da parcela
//-------------------------------------------------------------
Static Function VldCheck(nTipo, nWidth, nHeight, nTamBut, oPnlAdconal)

	Local lRet := .T.
	Local nX := 1
	Local cCondPg
	Local aParc
	Local nSomaChq := 0
	Local bActOk
	Local bActCanc
	Local bActImpr

	If nTipo == 1 //valida tela inicial do cheque

		If nCHVlrRec <= 0 
			STFMessage(ProcName(),"STOP", "Valor informado não pode ser negativo ou zerado: " + cValToChar(nCHVlrRec) )
			STFShowMessage(ProcName())
			Return .F.
		EndIf

		If nAtaReceb > 0
			cCondPg := aRecebtos[nAtaReceb][2]
		Else
			STFMessage(ProcName(),"STOP", "Selecione uma Negociação de pagamento!")
			STFShowMessage(ProcName())
			Return .F.
		EndIf

		If nCHParcelas < 1
			STFMessage(ProcName(),"STOP", "Condição de pagamento da negociação com problemas!")
			STFShowMessage(ProcName())
			Return .F.
		EndIf

		oPnlCH:Hide() //oculto o painel principal
		if oCHBtAOk == NIL
			aObjChq := {}
		endif
		
		//criando array dos dados da tela
		aParc := condicao(nCHVlrRec,cCondPg,0.00,dDatabase,0.00,{},,0)
		for nX := 1 to len(aParc)
			//aCheques {banco, num cheque, agencia, conta, compensacao, nome emitente, telefone, Rg, lEmitente, data, valor, sequencia, cpf/cnpj emitente, cmc7, codigo, loja}
			aadd(aCheques, {Space(TamSx3("EF_BANCO")[1]),; 		//[01] banco
							Space(TamSx3("EF_NUM")[1]),;		//[02] num cheque
							Space(TamSx3("EF_AGENCIA")[1]),;	//[03] agencia
							Space(TamSx3("EF_CONTA")[1]),;		//[04] conta
							Space(TamSx3("EF_COMP")[1]),;		//[05] compensacao
							space(TamSX3("L4_NOMECLI")[1]),; 	//[06] nome emitente
							Space(TamSx3("EF_TEL")[1]),;		//[07] telefone
							Space(TamSx3("EF_RG")[1]),;			//[08] Rg
							.T.,; 								//[09] lEmitente
							aParc[nX][01],; 					//[10] data
							iif(nX==1, aParc[nX][02], 0) ,; 	//[11] valor
							nX,; 								//[12] sequencia
							Space(TamSX3("L4_CGC")[1]),; 		//[13] cpf/cnpj emitente
							Space(34),; 						//[14] cmc7
							Space(TamSX3("A1_COD")[1]),; 		//[15] codigo
							Space(TamSX3("A1_LOJA")[1]); 		//[16] loja
					})
		next nX

		If len(aCheques)>0
			nChqAct := 1
		EndIf

		bActOk := {|| VldCheck(2, nWidth, nHeight, nTamBut, oPnlAdconal)  }
		bActCanc := {|| oPnlCHAux:Hide(), STIPayCancel(), STIClnVar(oPnlAdconal, .T.)}
		bActImpr := {|| BotImpCh(aCheques[nChqAct][1],aCheques[nChqAct][3],aCheques[nChqAct][4],aCheques[nChqAct][2],aCheques[nChqAct][11] ) } //cBanco, cAgencia, cConta, cCheque, nValor

		if empty(aObjChq)
			
			//Criando componentes de tela para dados do cheque
			@ 005, 007 SAY oSay1 PROMPT "Pagamento em Cheque" SIZE 200, 011 OF oPnlCHAux COLORS 0, 16777215 PIXEL
			oSay1:SetCSS( POSCSS (GetClassName(oSay1), CSS_BREADCUMB ))

			@ 020, 007 SAY oSay1 PROMPT "Valor do Cheque" SIZE 70, 008 OF oPnlCHAux COLORS 0, 16777215 PIXEL
			oSay1:SetCSS( POSCSS (GetClassName(oSay1), CSS_LABEL_FOCAL ))
			oGet1 := TGet():New( 30, 007,{|u| iif(nChqAct>0, iif( PCount()==0,aCheques[nChqAct][11],aCheques[nChqAct][11]:=u), )},oPnlCHAux,70, 013,PesqPict("SL4","L4_VALOR"),{|| .T./*bValid*/ },,,,,,.T.,,,{|| .T. },,,,.F.,.F.,,"oGet1",,,,.F.,.T.)
			oGet1:SetCSS( POSCSS (GetClassName(oGet1), CSS_GET_NORMAL ))
			aadd(aObjChq, oGet1)

			@ 020, 090 SAY oSay2 PROMPT "Data Venc." SIZE 070, 007 OF oPnlCHAux COLORS 0, 16777215 PIXEL
			oSay2:SetCSS( POSCSS (GetClassName(oSay2), CSS_LABEL_FOCAL ))
			oGet2 := TGet():New( 30, 090,{|u| iif(nChqAct>0, iif( PCount()==0,aCheques[nChqAct][10],aCheques[nChqAct][10]:=u), )},oPnlCHAux,70, 013,,{|| .T./*bValid*/ },,,,,,.T.,,,{|| .T. },,,,.F.,.F.,,"oGet2",,,,.T.,.F.)
			oGet2:SetCSS( POSCSS (GetClassName(oGet2), CSS_GET_NORMAL ))
			aadd(aObjChq, oGet2)

			If len(aCheques) > 1
				@ 033, nWidth-060 SAY oSay1 PROMPT ("Cheque: " + cValToChar(nChqAct) + " de " + cValToChar(len(aCheques))) SIZE 080, 011 OF oPnlCHAux COLORS 0, 16777215 PIXEL
				oSay1:SetCSS( POSCSS (GetClassName(oSay1), CSS_LABEL_FOCAL ))
				aadd(aObjChq, oSay1)
			Else
				aadd(aObjChq, Nil)
			EndIf

			@ 043, 005 SAY Replicate("_",nWidth) SIZE nWidth-10, 008 OF oPnlCHAux FONT COLORS CLR_HGRAY, 16777215 PIXEL

			//@ 058, 007 SAY oSay3 PROMPT "CPF/CNPJ do Emitente" SIZE 100, 010 OF oPnlCHAux COLORS 0, 16777215 PIXEL
			//oSay3:SetCSS( POSCSS (GetClassName(oSay3), CSS_LABEL_FOCAL ))
			//oGet3 := TGet():New( 68, 007,{|u| iif(nChqAct>0, iif( PCount()==0,aCheques[nChqAct][13],aCheques[nChqAct][13]:=u), )},oPnlCHAux,85, 013,,{|| VldEmitChq() .AND. oPnlCHAux:Refresh() },,,,,,.T.,,,{|| .T. },,,,.F.,.F.,,"oGet3",,,,.T.,.F.)
			//oGet3:SetCSS( POSCSS (GetClassName(oGet3), CSS_GET_NORMAL ))
			//TSearchF3():New(oGet3,400,250,"SA1","A1_CGC",{{"A1_NOME",2},{"A1_CGC",3},{"A1_COD",1}},"SA1->A1_MSBLQL<>'1'"+iif(SA1->(FieldPos("A1_XEMCHQ")) > 0," .AND. SA1->A1_XEMCHQ='S'",""),{{"A1_NOME","A1_EST","A1_MUN"},{"A1_CGC","A1_NOME","A1_EST","A1_MUN"},{"A1_COD","A1_LOJA","A1_NOME","A1_EST","A1_MUN"}},,,0)
			//aadd(aObjChq, oGet3)
			
			@ 053, 007 SAY oSay3 PROMPT "Código" SIZE 100, 010 OF oPnlCHAux COLORS 0, 16777215 PIXEL
			oSay3:SetCSS( POSCSS (GetClassName(oSay3), CSS_LABEL_FOCAL ))
			oGetCod := TGet():New( 063, 007,{|u| iif(nChqAct>0, iif( PCount()==0,aCheques[nChqAct][15],aCheques[nChqAct][15]:=u), )},oPnlCHAux, 055, 013,,{|| VldEmitChq() .AND. oPnlCHAux:Refresh() },,,,,,.T.,,,{|| .T. },,,,.F.,.F.,,"oGetCod",,,,.T.,.F.)
			oGetCod:SetCSS( POSCSS (GetClassName(oGetCod), CSS_GET_NORMAL ))
			aadd(aObjChq, oGetCod)

			@ 053, 062 SAY oSay3 PROMPT "Loja" SIZE 100, 010 OF oPnlCHAux COLORS 0, 16777215 PIXEL
			oSay3:SetCSS( POSCSS (GetClassName(oSay3), CSS_LABEL_FOCAL ))
			oGetLoj := TGet():New( 063, 062,{|u| iif(nChqAct>0, iif( PCount()==0,aCheques[nChqAct][16],aCheques[nChqAct][16]:=u), )},oPnlCHAux, 020, 013,,{|| VldEmitChq() .AND. oPnlCHAux:Refresh() },,,,,,.T.,,,{|| .T. },,,,.F.,.F.,,"oGetLoj",,,,.T.,.F.)
			oGetLoj:SetCSS( POSCSS (GetClassName(oGetLoj), CSS_GET_NORMAL ))
			aadd(aObjChq, oGetLoj)

			@ 053, 97 SAY oSay4 PROMPT "Nome do Emitente" SIZE 070, 010 OF oPnlCHAux COLORS 0, 16777215 PIXEL
			oSay4:SetCSS( POSCSS (GetClassName(oSay4), CSS_LABEL_FOCAL ))
			oGet4 := TGet():New( 63, 97,{|u| iif(nChqAct>0, iif( PCount()==0,aCheques[nChqAct][6],aCheques[nChqAct][6]:=u), )},oPnlCHAux,nWidth-105, 013,,{|| .T./*bValid*/ },,,,,,.T.,,,{|| .T. },,,,.T.,.F.,,"oGet4",,,,.T.,.F.)
			oGet4:SetCSS( POSCSS (GetClassName(oGet4), CSS_GET_NORMAL ))
			oGet4:lCanGotFocus := .F.
			TSearchF3():New(oGetCod,400,250,"SA1","A1_COD",{{"A1_NOME",2},{"A1_CGC",3},{"A1_COD",1}},"SA1->A1_MSBLQL<>'1'"+iif(SA1->(FieldPos("A1_XEMCHQ")) > 0," .AND. SA1->A1_XEMCHQ='S'",""),{{"A1_COD","A1_LOJA","A1_NOME","A1_EST","A1_MUN"},{"A1_COD","A1_LOJA","A1_CGC","A1_NOME","A1_EST","A1_MUN"},{"A1_COD","A1_LOJA","A1_NOME","A1_EST","A1_MUN"}},,,0,,{{oGetLoj,"A1_LOJA"},{oGet4,"A1_NOME"}})
			aadd(aObjChq, oGet4)

			@ 080, 007 SAY oSay5 PROMPT "Codigo de Barras CMC7" SIZE 100, 010 OF oPnlCHAux COLORS 0, 16777215 PIXEL
			oSay5:SetCSS( POSCSS (GetClassName(oSay5), CSS_LABEL_FOCAL ))
			oGet5 := TGet():New( 090, 007,{|u| iif(nChqAct>0, iif( PCount()==0,aCheques[nChqAct][14],aCheques[nChqAct][14]:=u), )},oPnlCHAux,nWidth-015, 013,,{|| VldCMC7Chq() .AND. oPnlCHAux:Refresh() },,,,,,.T.,,,{|| .T. },,,,.F.,.F.,,"oGet4",,,,.T.,.F.)
			oGet5:SetCSS( POSCSS (GetClassName(oGet5), CSS_GET_NORMAL ))
			aadd(aObjChq, oGet5)

			@ 107, 007 SAY oSay6 PROMPT "Banco" SIZE 50, 010 OF oPnlCHAux COLORS 0, 16777215 PIXEL
			oSay6:SetCSS( POSCSS (GetClassName(oSay6), CSS_LABEL_FOCAL ))
			oGet6 := TGet():New( 117, 007,{|u| iif(nChqAct>0, iif( PCount()==0,aCheques[nChqAct][1],aCheques[nChqAct][1]:=u), )},oPnlCHAux,40, 013,,{|| .T./*bValid*/ },,,,,,.T.,,,{|| .T. },,,,.F.,.F.,,"oGet3",,,,.T.,.F.)
			oGet6:SetCSS( POSCSS (GetClassName(oGet6), CSS_GET_NORMAL ))
			aadd(aObjChq, oGet6)

			@ 107, 052 SAY oSay7 PROMPT "Agência" SIZE 50, 010 OF oPnlCHAux COLORS 0, 16777215 PIXEL
			oSay7:SetCSS( POSCSS (GetClassName(oSay7), CSS_LABEL_FOCAL ))
			oGet7 := TGet():New( 117, 052,{|u| iif(nChqAct>0, iif( PCount()==0,aCheques[nChqAct][3],aCheques[nChqAct][3]:=u), )},oPnlCHAux,40, 013,,{|| .T./*bValid*/ },,,,,,.T.,,,{|| .T. },,,,.F.,.F.,,"oGet3",,,,.T.,.F.)
			oGet7:SetCSS( POSCSS (GetClassName(oGet7), CSS_GET_NORMAL ))
			aadd(aObjChq, oGet7)

			@ 107, 097 SAY oSay8 PROMPT "Conta" SIZE 070, 010 OF oPnlCHAux COLORS 0, 16777215 PIXEL
			oSay8:SetCSS( POSCSS (GetClassName(oSay8), CSS_LABEL_FOCAL ))
			oGet8 := TGet():New( 117, 097,{|u| iif(nChqAct>0, iif( PCount()==0,aCheques[nChqAct][4],aCheques[nChqAct][4]:=u), )},oPnlCHAux,070, 013,,{|| .T./*bValid*/ },,,,,,.T.,,,{|| .T. },,,,.F.,.F.,,"oGet4",,,,.T.,.F.)
			oGet8:SetCSS( POSCSS (GetClassName(oGet8), CSS_GET_NORMAL ))
			aadd(aObjChq, oGet8)

			@ 107, 172 SAY oSay9 PROMPT "Num. Cheque" SIZE 070, 010 OF oPnlCHAux COLORS 0, 16777215 PIXEL
			oSay9:SetCSS( POSCSS (GetClassName(oSay9), CSS_LABEL_FOCAL ))
			oGet9 := TGet():New( 117, 172,{|u| iif(nChqAct>0, iif( PCount()==0,aCheques[nChqAct][2],aCheques[nChqAct][2]:=u), )},oPnlCHAux,070, 013,,{|| .T./*bValid*/ },,,,,,.T.,,,{|| .T. },,,,.F.,.F.,,"oGet4",,,,.T.,.F.)
			oGet9:SetCSS( POSCSS (GetClassName(oGet9), CSS_GET_NORMAL ))
			aadd(aObjChq, oGet9)

			@ 134, 007 SAY oSay10 PROMPT "R.G." SIZE 50, 010 OF oPnlCHAux COLORS 0, 16777215 PIXEL
			oSay10:SetCSS( POSCSS (GetClassName(oSay10), CSS_LABEL_FOCAL ))
			oGet10 := TGet():New( 144, 007,{|u| iif(nChqAct>0, iif( PCount()==0,aCheques[nChqAct][8],aCheques[nChqAct][8]:=u), )},oPnlCHAux,85, 013,,{|| .T./*bValid*/ },,,,,,.T.,,,{|| .T. },,,,.F.,.F.,,"oGet3",,,,.T.,.F.)
			oGet10:SetCSS( POSCSS (GetClassName(oGet10), CSS_GET_NORMAL ))
			aadd(aObjChq, oGet10)

			@ 134, 097 SAY oSay11 PROMPT "Telefone" SIZE 50, 010 OF oPnlCHAux COLORS 0, 16777215 PIXEL
			oSay11:SetCSS( POSCSS (GetClassName(oSay11), CSS_LABEL_FOCAL ))
			oGet11 := TGet():New( 144, 097,{|u| iif(nChqAct>0, iif( PCount()==0,aCheques[nChqAct][7],aCheques[nChqAct][7]:=u), )},oPnlCHAux,70, 013,,{|| .T./*bValid*/ },,,,,,.T.,,,{|| .T. },,,,.F.,.F.,,"oGet3",,,,.T.,.F.)
			oGet11:SetCSS( POSCSS (GetClassName(oGet11), CSS_GET_NORMAL ))
			aadd(aObjChq, oGet11)

			@ 134, 172 SAY oSay12 PROMPT "Compensação" SIZE 50, 010 OF oPnlCHAux COLORS 0, 16777215 PIXEL
			oSay12:SetCSS( POSCSS (GetClassName(oSay12), CSS_LABEL_FOCAL ))
			oGet12 := TGet():New( 144, 172,{|u| iif(nChqAct>0, iif( PCount()==0,aCheques[nChqAct][5],aCheques[nChqAct][5]:=u), )},oPnlCHAux,70, 013,,{|| .T./*bValid*/ },,,,,,.T.,,,{|| .T. },,,,.F.,.F.,,"oGet3",,,,.T.,.F.)
			oGet12:SetCSS( POSCSS (GetClassName(oGet12), CSS_GET_NORMAL ))
			aadd(aObjChq, oGet12)

			// BOTAO CONFIRMAR
			oCHBtAOk := TButton():New( nHeight-35,;
									nWidth-nTamBut-5,;
									"&Confirmar Cheque"+CRLF+"(ALT+C)",;
									oPnlCHAux	,;
									bActOk,;
									nTamBut,;
									025,;
									,,,.T.,;
									,,,{|| .T.})
			oCHBtAOk:SetCSS( POSCSS (GetClassName(oCHBtAOk), CSS_BTN_FOCAL ))

			// BOTAO CANCELAR
			oCHBtACan := TButton():New( nHeight-35,;
									nWidth-(2*nTamBut)-10,;
									"C&ancelar Pagamento"+CRLF+"(ALT+A)",;
									oPnlCHAux	,;
									bActCanc,;
									nTamBut,;
									025,;
									,,,.T.,;
									,,,{|| .T.})
			oCHBtACan:SetCSS( POSCSS (GetClassName(oCHBtACan), CSS_BTN_ATIVO ))

			// BOTAO IMPRIMIR
			oCHBtAImp := TButton():New( nHeight-35,;
									007,;
									"&Imprimir Cheque"+CRLF+"(ALT+I)",;
									oPnlCHAux	,;
									bActImpr,; //cBanco, cAgencia, cConta, cCheque, nValor
									nTamBut,;
									025,;
									,,,.T.,;
									,,,{|| .T.})
			oCHBtAImp:SetCSS( POSCSS (GetClassName(oCHBtAImp), CSS_BTN_NORMAL ))
		Else
			oCHBtAOk:bAction := bActOk
			oCHBtACan:bAction := bActCanc
			oCHBtAImp:bAction := bActImpr
		Endif

		oPnlCHAux:Show()
		oPnlCHAux:Refresh()
		aObjChq[1]:SetFocus()

	Else

		//validando valor
		If aCheques[nChqAct][11] <= 0
			STFMessage(ProcName(),"STOP", "Valor do cheque informado não pode ser negativo ou zerado." )
			STFShowMessage(ProcName())
			lRet := .F.
		EndIf
		If lRet
			aEval(aCheques, {|x| nSomaChq += x[11] }) //somando valor dos cheques
			If nSomaChq > nCHVlrRec
				STFMessage(ProcName(),"STOP", "Valor dos cheques não pode ultrapassar o total informado inicialmente." )
				STFShowMessage(ProcName())
				lRet := .F.
			ElseIf len(aCheques) == nChqAct .AND. nSomaChq < nCHVlrRec
				STFMessage(ProcName(),"STOP", "Valor dos cheques não pode ser menor que o total informado inicialmente." )
				STFShowMessage(ProcName())
				lRet := .F.
			EndIf
		EndIf

		//validando data
		If lRet
			aParc := condicao(nCHVlrRec,aRecebtos[nAtaReceb][2],0.00,dDatabase,0.00,{},,0)
			If aCheques[nChqAct][10] > aParc[nChqAct][1]
				STFMessage(ProcName(),"STOP", "Data do cheque deve ser menor ou igual a " + dtoC(aParc[nChqAct][1]) + "." )
				STFShowMessage(ProcName())
				lRet := .F.
			ElseIf aCheques[nChqAct][10] < dDatabase
				STFMessage(ProcName(),"STOP", "Data do cheque deve ser maior ou igual a " + dtoC(dDatabase) + "." )
				STFShowMessage(ProcName())
				lRet := .F.
			EndIf
		EndIf

		//validando obrigatoriedade dos demais campos
		If lRet
			If Empty(aCheques[nChqAct][15]) .or. Empty(aCheques[nChqAct][16])
				STFMessage(ProcName(),"STOP", "Informe o Código/Loja do Emitente!")
				STFShowMessage(ProcName())
				lRet := .F.
			ElseIf Empty(aCheques[nChqAct][6])
				STFMessage(ProcName(),"STOP", "Cadastro do emitente não encontrado!")
				STFShowMessage(ProcName())
				lRet := .F.
			ElseIf Empty(aCheques[nChqAct][1])
				STFMessage(ProcName(),"STOP", "Informe o Banco do cheque!")
				STFShowMessage(ProcName())
				lRet := .F.
			ElseIf Empty(aCheques[nChqAct][3])
				STFMessage(ProcName(),"STOP", "Informe a Agência do cheque!")
				STFShowMessage(ProcName())
				lRet := .F.
			ElseIf Empty(aCheques[nChqAct][4])
				STFMessage(ProcName(),"STOP", "Informe a Conta do cheque!")
				STFShowMessage(ProcName())
				lRet := .F.
			ElseIf Empty(aCheques[nChqAct][2])
				STFMessage(ProcName(),"STOP", "Informe o Numero do cheque!")
				STFShowMessage(ProcName())
				lRet := .F.
			ElseIf Empty(aCheques[nChqAct][7])
				STFMessage(ProcName(),"STOP", "Informe o Telefone do Portador do cheque!")
				STFShowMessage(ProcName())
				lRet := .F.
			EndIf
		EndIf

		//valido repetição de numeração de cheque
		If lRet
			for nX := 1 to len(aCheques)
				If nX != nChqAct
					If aCheques[nChqAct][1]+aCheques[nChqAct][3]+aCheques[nChqAct][4]+aCheques[nChqAct][2] == aCheques[nX][1]+aCheques[nX][3]+aCheques[nX][4]+aCheques[nX][2]
						STFMessage(ProcName(),"STOP", "Cheque já informado na parcela "+cValToChar(nX)+"!")
						STFShowMessage(ProcName())
						lRet := .F.
						EXIT
					EndIf
				EndIf
			next nX
		EndIf

		//finalização
		If lRet
			//ultimo cheque
			If len(aCheques) == nChqAct
				ValidaTela("CH", oPnlAdconal,,oPnlCHAux) //validações gerais e finalização do add forma
			
			//passa para proximo cheque
			Else
				nChqAct++ //incremento proximo cheque
				aCheques[nChqAct][11] := Round( (nCHVlrRec - nSomaChq) / Max(1, (len(aCheques)-nChqAct+1) ) , 2)
				aCheques[nChqAct][10] := aParc[nChqAct][1]
				//pego dados ultimo emitente
				aCheques[nChqAct][13] := aCheques[nChqAct-1][13]
				aCheques[nChqAct][15] := aCheques[nChqAct-1][15]
				aCheques[nChqAct][16] := aCheques[nChqAct-1][16]
				aCheques[nChqAct][6] := aCheques[nChqAct-1][6]
				aCheques[nChqAct][7] := aCheques[nChqAct-1][7]
				aCheques[nChqAct][8] := aCheques[nChqAct-1][8]

				oPnlCHAux:Refresh()
				aObjChq[1]:SetFocus()
			EndIf
		EndIf

	EndIf

Return lRet

//-------------------------------------------------------
// Chama a impressão do cheque.
//-------------------------------------------------------

Static Function BotImpCh(cBanco, cAgencia, cConta, cCheque, nValor)

	Local aArea 		:= GetArea()
	Default cBanco 		:= ""
	Default cAgencia 	:= ""
	Default cConta 		:= ""
	Default cCheque 	:= ""
	Default nValor 		:= 0
	
	U_TPDVE07D(cBanco,cAgencia,cConta,cCheque,nValor,,Left(SM0->M0_CIDCOB,15),dDataBase)

	RestArea(aArea)

Return(Nil)

//-------------------------------------------------------
// Valida e gatilha emitente de cheque
//-------------------------------------------------------
Static Function VldEmitChq()

	Local lRet := .T.

	If Empty(aCheques[nChqAct][15]) 
		aCheques[nChqAct][13] := Space(TamSX3("A1_CGC")[1])
		aCheques[nChqAct][15] := Space(TamSX3("A1_COD")[1])
		aCheques[nChqAct][16] := Space(TamSX3("A1_LOJA")[1])
		aCheques[nChqAct][6] := Space(TamSX3("L4_NOMECLI")[1])
	Else
		if empty(aCheques[nChqAct][16])
			aCheques[nChqAct][16] := Posicione("SA1",1,xFilial("SA1")+aCheques[nChqAct][15],"A1_LOJA")
		endif
		aCheques[nChqAct][6] := SubStr(Posicione("SA1",1,xFilial("SA1")+aCheques[nChqAct][15]+aCheques[nChqAct][16],"A1_NOME"),1,TamSX3("L4_NOMECLI")[1])
		aCheques[nChqAct][13] := Posicione("SA1",1,xFilial("SA1")+aCheques[nChqAct][15]+aCheques[nChqAct][16],"A1_CGC")

		If Empty(aCheques[nChqAct][6])
			STFMessage(ProcName(),"STOP", "Emitente não cadastrado!")
			STFShowMessage(ProcName())
			lRet := .F.
		EndIf

		If SA1->(FieldPos("A1_XEMCHQ")) > 0
			If SA1->A1_XEMCHQ != "S"
				STFMessage(ProcName(),"STOP", "O cliente não está habilitado como Emitente de Cheques!")
				STFShowMessage(ProcName())
				lRet := .F.
			EndIf
		EndIf

		If lRet //gatilha demais campos
			aCheques[nChqAct][7] := PadR(alltrim(SA1->A1_DDD + SA1->A1_TEL),TamSx3("EF_TEL")[1])
			aCheques[nChqAct][8] := iif(SA1->A1_PESSOA=='F',SA1->A1_PFISICA,SA1->A1_INSCR)
		EndIf
	EndIf

Return lRet

//-------------------------------------------------------
// Valida e gatilha emitente de carta frete
//-------------------------------------------------------
Static Function VldEmitCF()

	Local lRet := .T.
	Local lEqCliEmi := SuperGetMV("TP_VLEMTCF",,.F.) //Valida equivalência: cliente vs emitente de carta frete (default .F.)
	Local cGetCodCli := "" // Cliente corrente
	Local cGetLoja   := "" // Loja corrente

	If Empty(cCodCF) 
		cCodCF := Space(TamSX3("A1_COD")[1])
		cLojCF := Space(TamSX3("A1_LOJA")[1])
		cNomeEmiCF := Space(TamSX3("A1_NOME")[1])
	Else
		
		If Empty(cLojCF)
			cLojCF := Posicione("SA1",1,xFilial("SA1")+cCodCF,"A1_LOJA")
		EndIf

		If Empty(Posicione("SA1",1,xFilial("SA1")+cCodCF+cLojCF,"A1_NOME"))
			STFMessage(ProcName(),"STOP", "Emitente não cadastrado!")
			STFShowMessage(ProcName())
			lRet := .F.
		EndIf

		If SA1->(FieldPos("A1_XEMICF")) > 0
			If SA1->A1_XEMICF != "S"
				STFMessage(ProcName(),"STOP", "O cliente não está habilitado como Emitente de Carta Frete!")
				STFShowMessage(ProcName())
				lRet := .F.
			EndIf
		EndIf

		//Valida equivalência entre emitente de carta frete e cliente corrente da venda ([TP_VLEMTCF] -> Ativado!)
		If lRet .and. lEqCliEmi
			oModelMaster := oModelMaster:GetModel("SL1MASTER")
			cGetCodCli 	 := oModelMaster:GetValue("L1_CLIENTE")
			cGetLoja 	 := oModelMaster:GetValue("L1_LOJA")
			If !Empty(cCodCF+cLojCF) .and. (cGetCodCli+cGetLoja) <> (cCodCF+cLojCF)
				STFMessage(ProcName(),"STOP", "O cliente selecionado como emitente não é o mesmo da venda! [TP_VLEMTCF] -> Ativado!")
				STFShowMessage(ProcName())
				lRet := .F.
			EndIf
		EndIf

		If lRet
			cNomeEmiCF := SA1->A1_NOME
		EndIf

	EndIf

Return lRet

//-------------------------------------------------------
// Valida CMC7 e gatilha campos do cheque
//-------------------------------------------------------
Static Function VldCMC7Chq()

	Local lRet := .T.
	Local cCmc7 := ""
    Local c1 := c2 := c3 := ""

	If !Empty(aCheques[nChqAct][14])
		cCmc7 := alltrim(aCheques[nChqAct][14])
		If Len(cCmc7)>=30 .and. Right(cCmc7,1)<>":"
			c1 := SubStr(cCmc7,1,8)
			c2 := SubStr(cCmc7,9,10)
			c3 := SubStr(cCmc7,19,12)
			cCmc7 := "<"+c1+"<"+c2+">"+c3+":"
			aCheques[nChqAct][14] := cCmc7
		EndIf

		If ("?" $ cCmc7) .OR. Len(AllTrim(cCmc7)) <> 34
			STFMessage(ProcName(),"STOP", "Erro na leitura. Passe o cheque novamente no leitor.")
			STFShowMessage(ProcName())
			lRet := .F.
		Else
			If Modulo10(SubStr(cCmc7,2,7)) <> SubStr(cCmc7,22,1)
			     lRet := .F.
			ElseIf Modulo10(SubStr(cCmc7,11,10)) <> SubStr(cCmc7,9,1)
			     lRet := .F.
			ElseIf Modulo10(SubStr(cCmc7,23,10)) <> SubStr(cCmc7,33,1)
			     lRet := .F.
			EndIf
			If !lRet
				STFMessage(ProcName(),"STOP", "O Código CMC7 informado é iválido!")
				STFShowMessage(ProcName())
			EndIf
		EndIf

		//setando campos
		If lRet
			aCheques[nChqAct][1] := PadR(SubStr(cCmc7, 2, 3), TamSx3("EF_BANCO")[1]) //Banco
			aCheques[nChqAct][3] := PadR(SubStr(cCmc7, 5, 4), TamSx3("EF_AGENCIA")[1]) //Agencia
			aCheques[nChqAct][2] := PadR(SubStr(cCmc7, 14, 6),TamSx3("EF_NUM")[1]) //Nro Cheque
			aCheques[nChqAct][5] := PadR(SubStr(cCmc7, 11, 3),TamSx3("L4_COMP")[1]) //Comp.

			//buscando a cona para cada banco
			If aCheques[nChqAct][1]  $  "314/001" //itau, brasil
			 	aCheques[nChqAct][4] := SubStr(cCmc7, 27, 6)  //Conta
			ElseIf aCheques[nChqAct][1] = "756" //sicoob
			 	aCheques[nChqAct][4] := SubStr(cCmc7, 23, 10)  //Conta
			ElseIf aCheques[nChqAct][1] = "237" //bradesco
			 	aCheques[nChqAct][4] := SubStr(cCmc7, 26, 7)  //Conta
			ElseIf aCheques[nChqAct][1] = "104" //caixa
			 	aCheques[nChqAct][4] := SubStr(cCmc7, 24, 9)  //Conta
			ElseIf aCheques[nChqAct][1] = "356" //real
			 	aCheques[nChqAct][4] := SubStr(cCmc7, 26, 7)  //Conta
			ElseIf aCheques[nChqAct][1] = "399" //hsbc
			 	aCheques[nChqAct][4] := SubStr(cCmc7, 23, 9)  //Conta
			ElseIf aCheques[nChqAct][1] = "745" //citibank
				aCheques[nChqAct][4] := SubStr(cCmc7, 25, 8)  //Conta
			Else
				aCheques[nChqAct][4] := SubStr(cCmc7, 25, 8)  //Conta
			EndIf

		EndIf

	EndIf

Return lRet

//-------------------------------------------------------
// Valida código CMC7 informado
//-------------------------------------------------------
Static Function Modulo10(cLinha)

	Local nSoma:= 0
	Local nResto
	Local nCont
	Local cDigRet
	Local nResult
	Local lDobra:= .f.
	Local cValor
	Local nAux

	For nCont:= Len(cLinha) To 1 Step -1
		lDobra:= !lDobra

		If lDobra
			cValor:= AllTrim(Str(Val(Substr(cLinha, nCont, 1)) * 2))
		Else
			cValor:= AllTrim(Str(Val(Substr(cLinha, nCont, 1))))
		EndIf

		For nAux:= 1 To Len(cValor)
			nSoma += Val(Substr(cValor, nAux, 1))
		Next n
	Next nCont

	nResto:= MOD(nSoma, 10)

	nResult:= 10 - nResto

	If nResult == 10
		cDigRet:= "0"
	Else
		cDigRet:= StrZero(10 - nResto, 1)
	EndIf

Return cDigRet

//-------------------------------------------------------
// Busca crédito de cliente na retaguarda
//-------------------------------------------------------
Static Function FindCredCl(cCliente,cLojaCli,cBusca)
Local aParam   := {}  // Array de parametros

	aNCCsCli := Nil // Resultado generico

	CursorArrow()
	STFCleanInterfaceMessage()

	STFMessage(ProcName(),"STOP","Pesquisando crédito do cliente. Aguarde...")
	STFShowMessage(ProcName())

	CursorWait()

	if !Empty(cBusca)
		aParam := {cCliente,cLojaCli,cBusca} //(cCliente, cLojaCli, cBusca, lSaque, cPlaca, cCPFMotor)
		aParam := {"U_TPDVE006",aParam}
		If !STBRemoteExecute("_EXEC_RET", aParam,,, @aNCCsCli)
			// Tratamento do erro de conexao
			STFMessage(ProcName(), "ALERT", "Falha de comunicação com o Back-Office..." )
			STFShowMessage(ProcName())
			STFCleanMessage(ProcName())

		ElseIf aNCCsCli == Nil .OR. Empty(aNCCsCli) .or. valtype(aNCCsCli)<>"A" .or. Len(aNCCsCli) == 0 .OR. valtype(aNCCsCli[1])<>"A" .OR. Len(aNCCsCli[1]) < 15
			// Tratamento para retorno vazio
			STFMessage( ProcName(), "STOP", "Nota de Crédito não encontrada ou já utilizada!" )
			STFShowMessage(ProcName())
			STFCleanMessage(ProcName())

		ElseIf Len(aNCCsCli) > 0
			STFMessage( ProcName(), "STOP", "Foram encontrados"+" "+AllTrim(Str(Len(aNCCsCli)))+" "+"créditos." )
			STFShowMessage(ProcName())
			STFCleanMessage(ProcName())

		EndIf
	else
		STFCleanInterfaceMessage()
	endif

	CursorArrow()

	AtuaListCred()

Return .T.

//---------------------------------------------------------------
// Função que faz a atualização do listbox dos creditos
//---------------------------------------------------------------
Static Function AtuaListCred()

	Local nX := 0
	Local aListGdNeg := {}
	//Local nBkp := oCRListGdNeg:nAt

	/*
			Posicoes de aNCCs

			aNCCs[x,1]  = .F.	// Caso a NCC seja selecionada, este campo recebe TRUE
			aNCCs[x,2]  = SE1->E1_SALDO
			aNCCs[x,3]  = SE1->E1_NUM
			aNCCs[x,4]  = SE1->E1_EMISSAO
			aNCCs[x,5]  = SE1->(Recno())
			aNCCs[x,6]  = SE1->E1_SALDO
			aNCCs[x,7]  = SuperGetMV("MV_MOEDA1")
			aNCCs[x,8]  = SE1->E1_MOEDA
			aNCCs[x,9]  = SE1->E1_PREFIXO
			aNCCs[x,10] = SE1->E1_PARCELA
			aNCCs[x,11] = SE1->E1_TIPO
			aNCCs[x,12] = SE1->E1_XPLACA
			aNCCs[x,13] = SE1->E1_XMOTOR
			aNCCs[x,14] = SE1->E1_FILIAL
			aNCCs[x,15] = SE1->E1_XCODBAR
	*/

	//atualiza todos
	If aNCCsCli <> Nil .AND. ValType(aNCCsCli) == "A"
		For nX:=1 to Len(aNCCsCli)
			//R$ SALDO / TIPO / PREFIXO / NUM / PARCELA / EMISSAO / CODBAR / FILIAL
			aadd(aListGdNeg,;
				'R$ '+Alltrim(Transform(aNCCsCli[nX][2],PesqPict("SL1","L1_VLRLIQ")))+' / '+;
				AllTrim(aNCCsCli[nX][11])+' / '+;
				AllTrim(aNCCsCli[nX][9])+' / '+;
				AllTrim(aNCCsCli[nX][3])+' / '+;
				AllTrim(aNCCsCli[nX][10])+' / '+;
				DtoC(aNCCsCli[nX][4])+' / '+;
				AllTrim(aNCCsCli[nX][15])+' / '+;
				AllTrim(aNCCsCli[nX][14]);
				)
		Next nX
	EndIf
	oCRListGdNeg:SetItems(aListGdNeg)

Return

//-------------------------------------------------------------------------
// Pega o máximo de troco da forma de pagamento de uma linha do aRecebtos
//-------------------------------------------------------------------------
User Function TPDVE04A()

	Local _nPos_ := 0
	Local _nMaxTroco := 0
	Local lLimTrU25 := .T.
	Local nY, _nPerProd, _nValRec
	//Local nTotRPR := 0 //total recebido com requisição pré paga
	//Local _nTttReceb := STIGetTotal() //total recebido

	For _nPos_:=1 to len(aRecebtos)
		If aRecebtos[_nPos_][16] > 0 .and. aRecebtos[_nPos_][9] > 0

			If Len(aRecebtos) < _nPos_ .or. Len(aRecebtos) <= 0 .or. _nPos_ <= 0
				Return _nMaxTroco
			EndIf

			lLimTrU25 := aRecebtos[_nPos_][16] > 0 .and. aRecebtos[_nPos_][9] > 0

			If lLimTrU25
			    For nY := 1 to Len(aRecebtos[_nPos_][5])
			    	If aRecebtos[_nPos_][5][nY][6] <> "S" //se tem um preço de um produto que não tem limite de troco (limite infinito)
			    		lLimTrU25 := .F.
			    	EndIf
			    Next nY
		    EndIf

			If lLimTrU25 //so vai entrar nesse If se todos os produtos tem preços negociados com limite de troco
		    	For nY := 1 to Len(aRecebtos[_nPos_][5])

		    		_nPerProd := (aRecebtos[_nPos_][5][nY][3] * aRecebtos[_nPos_][5][nY][5]) / aRecebtos[_nPos_][7] //% do produto sobre o total da forma
			    	_nValRec  := Round((aRecebtos[_nPos_][9]+aRecebtos[_nPos_][16]) * _nPerProd,2) //valor recebido na forma proporcional ao produto

			    	If _nValRec * (aRecebtos[_nPos_][5][nY][8]/100) > aRecebtos[_nPos_][5][nY][7] //a preferencia é pelo menor valor
						_nMaxTroco += aRecebtos[_nPos_][5][nY][7]
					Else
						_nMaxTroco += _nValRec * (aRecebtos[_nPos_][5][nY][8]/100)
					EndIf

			    Next nY

			Else
				If aRecebtos[_nPos_][15][1] == "S" //possui limite de troco? (S-Sim / N-Nao)
					If (aRecebtos[_nPos_][9]+aRecebtos[_nPos_][16])*(aRecebtos[_nPos_][15][3]/100) > aRecebtos[_nPos_][15][2] //a preferencia é pelo menor valor
						_nMaxTroco := aRecebtos[_nPos_][15][2]
					Else
						_nMaxTroco := (aRecebtos[_nPos_][9]+aRecebtos[_nPos_][16])*(aRecebtos[_nPos_][15][3]/100)
					EndIf
				Else
					_nMaxTroco := aRecebtos[_nPos_][16]
				EndIf

			EndIf

			_nMaxTroco := Round(_nMaxTroco,2)

		EndIf
	Next _nPos_

Return _nMaxTroco

//---------------------------------------------------------------------------
// Verifica se retaguarda está online ou off e atualiza visao
//---------------------------------------------------------------------------
Static Function AtuConnRet()

	If ValType(oSemaforo) == "O"

		lRetOn := IIF(GetPvProfString(CSECAO, CCHAVE, '0', GetAdv97()) == '0', .F., .T.)

		//Carrega imagem
		If lRetOn
		    oSemaforo:SetBMP("FRTONLINE")  //Conectado
		    cSayConn := "Retaguarda ON-LINE"

		Else
		    oSemaforo:SetBMP("FRTOFFLINE") //Sem conexao
		    cSayConn := "Retaguarda OFF-LINE"

		EndIf

		oSemaforo:Refresh()
		oSayConn:Refresh()

	EndIf

Return

//
// Converte em valor da STRING em NUMERICO
// Ex.: 1) RetValr("0230011",3) -> 230.011
//      2) RetValr("565654550",2) -> 5,656,545.50
//
Static Function RetValr(cStr,nDec)
	cStr := SubStr(cStr,1,(Len(cStr)-nDec)) + "." + SubStr(cStr,(Len(cStr)-nDec)+1,Len(cStr)-(Len(cStr)-nDec))
Return Val(cStr)

//--------------------------------------------------------------------
// Função para retornar o conteúdo da variável aRecebtos, utilizado pelo fonte TPDVP017
//--------------------------------------------------------------------
User Function GetReceb()

Return aRecebtos


//ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
/*/{Protheus.doc} STICCConfPay
Confirma o pagamento da transacao: CC/CD

@param   	
@author  	Vendas & CRM
@version 	P12
@since   	29/01/2013
@return  	
@obs     
@sample
/*/
//ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
Static Function USTICCConfPay(	oGetData	, 	oGetValor	, oGetParcels	, oPnlAdconal, ;
						cTypeCard 	,	lPContTef	, cGetNSU 		, cGetAutoriz, ;
						nParcel 	) 

Local oMdl 			:= Nil								//Recupera o model ativo
Local oTEF20		:= Nil								//Obj TEF
Local lRet			:= .T.								//Retorno da Validação
Local nTotPago	 	:= 0								//total Pago
Local nTotVenda 	:= 0								//total da Venda
//Local lRecebTitle 	:= STIGetRecTit()					//Indica se eh recebimento de titulos
Local lValidaNSU	:= SuperGetMv( "MV_LJNSU",,.T. )	//NSU e Autorização obrigatórios para Cartão de Crédito
Local aCallADM		:= {}								//Array com os dados de pagamento do orçamento importado 
Local lConfPay		:= .T.								//Valida se o pagamento com TEF foi efetuado com sucesso

Local lHomolPaf	:= FindFunction("STBHomolPaf") .AND.  STBHomolPaf() //Homologação PAF-ECF
Local nCards	:= 1		//Contador para quando importar um orçamento com pagamento em mais de um cartão
Local oModel 	:= Nil 		//Model de forma de pagamento cartao	

Default lPContTef 	:= .F.
Default cGetNSU 	:= ""
Default cGetAutoriz := ""
Default nParcel 	:= IIF(ValType(oGetParcels) == 'O', Val(oGetParcels:cText) , 1)

//Parcela tem que ser 1 - mesmo se for a vista
If nParcel < 1
	nParcel := 1
EndIf

oModel := ModelCard()
oMdl := oModel:GetModel("CARDMASTER")

oMdl:DeActivate()
oMdl:Activate()

oMdl:LoadValue("L4_FILIAL", xFilial("SL4"))
oMdl:LoadValue("L4_DATA", oGetData:cText)	
oMdl:LoadValue("L4_VALOR", oGetValor:cText)
oMdl:LoadValue("L4_PARC", nParcel)
oMdl:LoadValue("L4_ADMINIS", SubStr(cCCAdmFin,1,TamSx3('L4_ADMINIS')[1]))

If !Empty(cGetNSU)
	oMdl:LoadValue("L4_NSUTEF", cGetNSU)
	oMdl:LoadValue("L4_DOCTEF", cGetNSU)
EndIf
If !Empty(cGetAutoriz)
	oMdl:LoadValue("L4_AUTORIZ", cGetAutoriz)
EndIf

nTotPago  := STIGetTotal() + oGetValor:cText //Retorna o Total Pago
nTotVenda := STDGPBasket( "SL1" , "L1_VLRTOT" )

/* 
	Verificar se o cliente deseja doar para o Instituto Arredondar	
*/
If cTypeCard $ "CC|CD"	//Ideal perguntar antes do TEF
	STBInsArredondar(AllTrim(cTypeCard))
EndIf

//Nao permite troco em cartao, em caso de homologacao de PAF, deverá ser realizado tratamento por meio de lHomolog
//If !lRecebTitle .AND. nTotPago > nTotVenda
//	If ((STWChkTef("CC") .Or. cTypeCard == "CC") .Or. (STWChkTef("CD") .Or. cTypeCard == "CD") .Or. (STWChkTef("PD") .Or. cTypeCard == "PD") .Or. (STWChkTef("PX") .Or. cTypeCard == "PX"))
//		lRet := .F.
//		STFMessage(ProcName(),"STOP","Valor informado superior ao saldo a pagar. Não é permitido troco em cartão." )	// "Valor informado superior ao saldo a pagar. Não é permitido troco em cartão."
//		STFShowMessage(ProcName())	
//		STFCleanMessage(ProcName())
//	EndIf		
//EndIf

If lValidaNSU .AND. (lPContTef .OR. (!STWChkTef("CC") .AND. cTypeCard $ "CC|CD")) .AND. (Empty(cGetNSU) .OR. Empty(cGetAutoriz))
	lRet := .F.
	STFMessage(ProcName(),"STOP","Por favor, preencha o código NSU e o código de autorização!") //"Por favor, preencha o código NSU e o código de autorização!"
	STFShowMessage(ProcName())	
EndIf

If lRet

    STIBtnDeActivate()	

	If lHomolPaf
		STFCleanInterfaceMessage()
	EndIf
	
	oTEF20 := STBGetTEF()
	//Verifica se a transacao foi realizada com sucesso
	lConfPay := STWTypeTran(oMdl, oTEF20, cTypeCard, nParcel, lPContTef)

	//Danilo: estava dando BO no aRecebtos se der erro na transacao TEF e usuário escolher Não Contingencia
	if !lConfPay .AND. !Iif(FindFunction("STIGetContTef"),STIGetContTef(),.F.)
		If !empty(aRecebtosBKP) //restauro o aRecebtos
			aRecebtos[nAtaReceb] := aClone(aRecebtosBKP)
			AtuARecebtos() //validacao de campo -> CAMPO "RECEBIDO"
			aRecebtosBKP := {}
		EndIf
	endif
	
	aCallADM := STIGetaCallADM() 

	If STBIsImpOrc() .And. Len(aCallADM) > 1 .And. (nCards < Len(aCallADM) .Or. !lConfPay) .And. (  aCallADM[nCards + IIF(lConfPay, 1, 0) ,5] $ "CC|CD" )     
        If lConfPay
            nCards += 1
        EndIf
		// Atualiza os valores do Painel para o proximo Cartão
		//STIPayCard(oPnlAdconal, aCallAdm[nCards][5], aCallAdm[nCards][2], aCallAdm[nCards][3])
		MsgAlert("Não homologado importação de forma de pagamento no ambiente posto.", "Atenção")
	Else
		nCards := 1
		if valtype(oPnlAdconal) == "O"
			oPnlAdconal:Hide()
		endif
		STIEnblPaymentOptions()
	EndIf

	STIBtnActivate()

EndIf
		
Return lRet

//Função para ocultar paineis de formas de pagamento. Quando chama outra tela
User Function HidePnlForm()

	if valtype(oPnlDIN) == "O"
		oPnlDIN:Hide()
	endif
	if valtype(oPnlPIX) == "O"
		oPnlPIX:Hide()
	endif
	if valtype(oPnlCC) == "O"
		oPnlCC:Hide()
	endif
	if valtype(oPnlCF) == "O"
		oPnlCF:Hide()
	endif
	if valtype(oPnlNP) == "O"
		oPnlNP:Hide()
	endif
	if valtype(oPnlCH) == "O"
		oPnlCH:Hide()
	endif
	if valtype(oPnlCHAux) == "O"
		oPnlCHAux:Hide()
	endif
	if valtype(oPnlCR) == "O"
		oPnlCR:Hide()
	endif
	STIBtnActivate()
	U_SetWBtnNF(.T.)

Return

//-------------------------------------------------------------------
/*/{Protheus.doc} USTBAjusICMS
Essa função tem o objetivo realizar os ajustes nos itens:
ajuste no ICMS ao aplicar o desconto.

@param
@author  Rene Julian
@version P12117
@since   31/10/2018
@return  
@obs
@sample
/*/
//-------------------------------------------------------------------
Static Function USTBAjusICMS()
Local nI		:= 0
Local lRet		:= .T.

For nI := 1 To STDPBLength("SL2")

	If !STDPBIsDeleted( "SL2", nI )
		
		IIf(lRet , lRet := STDSPBasket( "SL2" , "L2_BASEICM"	, STBTaxRet(nI ,"IT_BASEICM")	, nI	)	,)
		IIf(lRet , lRet := STDSPBasket( "SL2" , "L2_VALICM"		, STBTaxRet(nI ,"IT_VALICM")	, nI	)	,)
		IIf(lRet , lRet := STDSPBasket( "SL2" , "L2_VALFECP"	, STBTaxRet(nI,"IT_VALFECP") 	, nI	)	,) 	    

	EndIf	
			
Next nI

If lRet 
	LjGrvLog(SL1->L1_NUM ,"USTBAjusICMS - Ajustado da base e valor do ICMS")
Else
	LjGrvLog(SL1->L1_NUM ,"USTBAjusICMS - Não foi possivel o Ajustate da base e valor do ICMS")
EndIf

Return 

Static Function GetNewSld(nVlrSal, nLinAtu)

	Local nX := nY := 0
	Local aProdutos := {}
	Local nTotItens := nPosPrd := nTReceb := nDifSaldo := 0

	//## Tratamento para questão de arredondamento, quando há lançamento de mais de 1 forma com preço negociado/desconto
	for nX := 1 to len(aRecebtos[nLinAtu][5]) 
		nPosPrd := aScan(aProdutos, {|x| AllTrim(x[1]+x[2])==AllTrim(aRecebtos[nLinAtu][5][nX][1]+aRecebtos[nLinAtu][5][nX][2])})
		If nPosPrd == 0 //aProdutos - [01] L2_ITEM / [02] L2_PRODUTO / [03] L2_QUANT / [04] PREÇO FUTURO
			AAdd(aProdutos, {aRecebtos[nLinAtu][5][nX][1],aRecebtos[nLinAtu][5][nX][2],aRecebtos[nLinAtu][5][nX][3],0}) //adiciona produto
		Else
			aProdutos[nPosPrd][3] += aRecebtos[nLinAtu][5][nX][1] //soma qtd
		EndIf
	next nX
	//nesse laço monto o preço final de cada produto, como se tivesse pagando tudo com a forma atual
	for nX:=1 to len(aRecebtos)
		nTReceb += aRecebtos[nX][9]
		if aRecebtos[nX][10] > 0 .OR. nX == nLinAtu //se recebeu algo na forma
			for nY:=1 to len(aRecebtos[nX][5])
				nPosPrd  := aScan(aProdutos, {|x| AllTrim(x[1]+x[2])==AllTrim(aRecebtos[nX][5][nY][1]+aRecebtos[nX][5][nY][2])})
				If nPosPrd > 0
					//somo o que ja recebi de cada forma
					if aRecebtos[nX][10] > 0
						aProdutos[nPosPrd][4] += (aRecebtos[nX][10]*aRecebtos[nX][5][nY][5]) //% recebido * preço usado produto
					endif
					//emulo como se tivesse recebendo o restante na forma atual
					if nX == nLinAtu 
						aProdutos[nPosPrd][4] += ((1-nPercent)*aRecebtos[nX][5][nY][5]) //% restante * preço usado produto
					endif
				endif
			next nY
		endif
	next nX
	//Calculo o total da venda somando todos os produtos com o novo preço
	nTotItens := 0
	for nX:=1 to len(aProdutos)
		aProdutos[nX][4] := Round(aProdutos[nX][4], TamSx3("L2_VLRITEM")[2]) //arredondo preço futuro
		nTotItens += STBArred( aProdutos[nX][3] * aProdutos[nX][4] , , "L2_VLRITEM" ) //qtd * novo valor
	next nX
	//Faço a juste com a diferença do total do itens com o saldo calculado
	if nTReceb+nVlrSal <> nTotItens
		nDifSaldo := nTReceb+nVlrSal - nTotItens
		nVlrSal -= nDifSaldo
	endif
	//## FIM Tratamento para questão de arredondamento

Return nVlrSal

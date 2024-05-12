#include 'parmtype.ch'
#include 'poscss.ch'
#include "topconn.ch"
#include "TOTVS.CH"

Static oPnlGeral
Static oPnlAbast
Static oCodBico
Static cCodBico := ""
Static oDescBico
Static cDescBico := ""
Static oBtnTpDiv, oBtnTpAgl
Static lOnlyView := .F.
Static oMsGetAbast
Static oQtdReg
Static nQtdReg := 0

/*/{Protheus.doc} TPDVA003
Realiza Aferição de Abastecimento.

@author pablo
@since 08/11/2018
@version 1.0
@return lRet

@type function
/*/
User Function TPDVA003()

	Local nI
	Local aRes := GetScreenRes()
	Local nWidth, nHeight
	Local lRet := .T.
	Local nPos, nPosAbast, nPosNum, nPosLitro
	Local oGetList
	Local cNrPDV := ""
	Local oTelaPDV, cGetFoco, oTotal, nTotalVend, oModelCesta
	Local cCor := SuperGetMv( "MV_LJCOLOR",,"07334C")// Cor da tela
	Local lHabMult := SuperGetMv("TP_MULTAFE",,.F.) // Habilita aferição selecionando vários itens
	Local cCorBack := RGB(hextodec(SubStr(cCor,1,2)),hextodec(SubStr(cCor,3,2)),hextodec(SubStr(cCor,5,2)))
	Local oPnlPrinc, oPanelMnt, oSay1
	Local cUsrAfc := ""
	Local nTipAfer := SuperGetMv("MV_TIPAFER",,0) //Define tipo de aferição: 0=Sem Nota Fiscal;1=Com Nota Fiscal
    Local cTesAfer := SuperGetMv("MV_TESAFER",,"") //Define tipo de aferição: 0=Sem Nota Fiscal;1=Com Nota Fiscal
	Local nAfMaxLt := SuperGetMv("TP_AFMAXLT",,1000) //Define o maximo de litros de um abastecimento de aferição
	Local cVendAfe 

	Private oDlgMNT

	Private oMsgRod, cMsgRod := ""
	Private oPnlMeio, oPnlRod, oImgTotvs, oPnlRotina
	Private oSayData

	Private oGetVend
	Private cGetVend := Space(TamSX3("A3_COD")[1])
	Private oGetNVen
	Private cGetNVen := Space(TamSX3("A3_NOME")[1])

	//verifica se o usuário tem permissão para acesso a rotina
	U_TRETA37B("AFEPDV", "AFERICAO PDV")
	cUsrAfc := U_VLACESS1("AFEPDV", RetCodUsr())
	If cUsrAfc == Nil .OR. Empty(cUsrAfc)
		STFMessage("AFERICAO","STOP", "Usuário não tem permissão de acesso a rotina de Aferição de Abastecimento." )
		STFShowMessage("AFERICAO")
		Return .F.
	EndIf

	If lHabMult .AND. nTipAfer == 0 //abre tela para multi-seleção (várias aferições)

		//limpa as tecla atalho
		U_UKeyCtr() 

		DEFINE DIALOG oDlgMNT TITLE "" PIXEL STYLE nOr(WS_VISIBLE,WS_POPUP)
		//oDlgMNT:lEscClose := .F.
		oDlgMNT:nWidth := aRes[1]
		oDlgMNT:nHeight := aRes[2]
		nWidth := aRes[1]/2
		nHeight := aRes[2]/2

		//pnl Principal
		@ 0,0 MSPANEL oPnlPrinc SIZE 500, 500 OF oDlgMNT
		oPnlPrinc:Align := CONTROL_ALIGN_ALLCLIENT
		oPnlPrinc:SetCSS( POSCSS (GetClassName(oPnlPrinc), CSS_BG ))

		//pnl Rodape
		@ nHeight-25,0 MSPANEL oPnlRod SIZE nWidth, 25 OF oPnlPrinc
		oPnlRod:SetCSS( POSCSS (GetClassName(oPnlRod), CSS_BAR_BOTTOM ))

		@ 007, 010 SAY oMsgRod PROMPT cMsgRod SIZE nWidth,20 OF oPnlRod PIXEL PICTURE "@!"
		oMsgRod:SetCSS( POSCSS (GetClassName(oMsgRod), CSS_BAR_ALERT ))

		@ 009, nWidth-160 SAY oSayData PROMPT (Alltrim(DiaSemana(dDataBase)) + iif(Dow(dDataBase)==1.OR.Dow(dDataBase)==7,"","-Feira") + ", " + DTOC(dDataBase) + "  |  " + SubStr(Time(),1,5)) SIZE 100,010 OF oPnlRod COLORS 16777215, 16777215 PIXEL RIGHT

		@ 005, nWidth-50 BITMAP oImgTotvs ResName "POS_LOGO_TOTVS_HOR_BRANCO.PNG" SIZE 50, 50 OF oPnlRod PIXEL NOBORDER //só visual

		//Painel do meio
		@ 0,0 MSPANEL oPnlMeio SIZE nWidth, nHeight-55 OF oPnlPrinc
		oPnlMeio:SetCSS( POSCSS (GetClassName(oPnlMeio), CSS_BG ))

		//Painel Rotinas
		@ 003, 004 MSPANEL oPnlRotina SIZE (nWidth-10), (nHeight-65) OF oPnlMeio
		oPnlRotina:SetCSS( "TPanel{ background-color: #F4F4F4; border-radius: 8px; border: 1px solid #F4F4F4;}" )

		U_TPDVA03A(oPnlRotina)

		ACTIVATE MSDIALOG oDlgMNT CENTERED

		//restaura as teclas atalho
		U_UKeyCtr(.T.) 

	else

		STFCleanMessage()
		STFCleanInterfaceMessage()
		cGetFoco := ReadVar()
		oTelaPDV :=STIGetObjTela()

		If oTelaPDV:oOwner:oCtlFocus:cName <> "GRIDABASTECIMENTO" //-- Na Grid de Abastecimento
			If cGetFoco == "CGETSALESMAN"
				STFMessage("AFERICAO","STOP", "Necessário posicionar no abastecimento para realizar a Aferição!" )
			else
				STFMessage("AFERICAO","STOP", "Abra a tela de abastecimentos e posicione no item desejado!" )
			EndIf
			STFShowMessage("AFERICAO")
			Return .F.
		EndIf

		oGetList := STIGGridAbast() //pega o grid de abastecimentos

		If Valtype(oGetList) == "O"
			If len(oGetList:aCols) > 0 //protecao oGetList vazio

				nPos		:= oGetList:nAt
				nPosAbast := aScan(oGetList:aHeader, {|x| Alltrim(x[2])=="MID_CODABA"}) 
				nPosNum := aScan(oGetList:aHeader, {|x| Alltrim(x[2])=="MID_NUMORC"}) 
				nPosLitro := aScan(oGetList:aHeader, {|x| Alltrim(x[2])=="MID_LITABA"}) 

				If nTipAfer == 1 .AND. empty(cTesAfer)
					lRet := .F.
					STFMessage("AFERICAO","STOP", "Configure o parametro MV_TESAFER com a TES de Aferição!" )
					STFShowMessage("AFERICAO")
				EndIf

				//Verifica se informou algum abastecimento para realizar Aferição
				If lRet .AND. empty(oGetList:aCols[nPos][nPosAbast]) //oGetList
					lRet := .F.
					STFMessage("AFERICAO","STOP", "Necessário posicionar no abastecimento para realizar a Aferição!" )
					STFShowMessage("AFERICAO")
				EndIf

				If lRet .AND. oGetList:aCols[nPos][01] == "TICK_VERDE"
					lRet := .F.
					STFMessage("AFERICAO","STOP", "O abatecimento posicionado já está lançado na venda! Desmarque-o!" )
					STFShowMessage("AFERICAO")
				EndIf

				If lRet .AND. oGetList:aCols[nPos][nPosNum] == "O" //O=em uso na venda de algum PDV
					lRet := .F.
					STFMessage("AFERICAO","STOP", "O abatecimento posicionado está em uso!" )
					STFShowMessage("AFERICAO")
				EndIf

				if lRet .AND. oGetList:aCols[nPos][nPosLitro] > nAfMaxLt

					U_TRETA37B("AFEMAX", "AFERICAO ACIMA DO MAXIMO PERMITIDO (TP_AFMAXLT)")
					cUsrAfc := U_VLACESS1("AFEMAX", RetCodUsr())
					If cUsrAfc == Nil .OR. Empty(cUsrAfc)
						lRet := .F.
						STFMessage("AFERICAO","STOP", "O abatecimento posicionado tem litragem superior ao maximo permitido em aferições!" )
						STFShowMessage("AFERICAO")
					EndIf
					
				endif

				If lRet .AND. nTipAfer == 0
					lRet := .F. //mudo flag para usar no confirmar

					//limpa as tecla atalho
					U_UKeyCtr() 

					DEFINE MSDIALOG oDlgMNT TITLE "" FROM 000, 000  TO 350, 410 COLORS 0, 16777215 PIXEL OF GetWndDefault() STYLE DS_MODALFRAME

					@ 0,0 MSPANEL oPnlPrinc SIZE 300, 300 OF oDlgMNT COLORS 0, cCorBack
					oPnlPrinc:Align := CONTROL_ALIGN_ALLCLIENT

					// crio o panel para mudar a cor da tela
					@ 4, 0 MSPANEL oPanelMnt SIZE 203, 175 OF oPnlPrinc //COLORS 0, RGB(40,79,102)
					oPanelMnt:SetCSS( POSCSS (GetClassName(oPanelMnt), CSS_PANEL_CONTEXT ))

					@ 010, 010 SAY oSay1 PROMPT "Aferição de Bico" SIZE 200, 015 OF oPanelMnt COLORS 0, 16777215 PIXEL
					oSay1:SetCSS( POSCSS (GetClassName(oSay1), CSS_BREADCUMB ))

					@ 030, 010 SAY oSay1 PROMPT ("Dados do Abastecimento:" + CRLF + CRLF + ;
						"Nr Abast.: " + Alltrim(oGetList:aCols[nPos][nPosAbast]) + CRLF + ;
						"Produto: " + Alltrim(oGetList:aCols[nPos][aScan(oGetList:aHeader, {|x| Alltrim(x[2])=="MHZ_DESPRO"})]) + CRLF + ;
						"Bico: " + Alltrim(oGetList:aCols[nPos][aScan(oGetList:aHeader, {|x| Alltrim(x[2])=="MID_CODBIC"})]) + CRLF + ;
						"Litros: " + Alltrim(Transform(oGetList:aCols[nPos][nPosLitro],"@E 9,999.999"));
						) SIZE 200, 400 OF oPanelMnt COLORS 0, 16777215 PIXEL
					oSay1:SetCSS( POSCSS (GetClassName(oSay1), CSS_LABEL_FOCAL ))

					@ 110, 010 SAY oSay1 PROMPT "Confirma baixar o abastecimento como Aferição?" SIZE 200, 400 OF oPanelMnt COLORS 0, 16777215 PIXEL
					oSay1:SetCSS( POSCSS (GetClassName(oSay1), CSS_LABEL_FOCAL ))

					// BOTAO CONFIRMAR
					oButton3 := TButton():New(145,;
						150,;
						"&Confirmar",;
						oPanelMnt	,;
						{|| lRet:=.T., oDlgMNT:End() },;
						45,;
						20,;
						,,,.T.,;
						,,,{|| .T.})
					oButton3:SetCSS( POSCSS (GetClassName(oButton3), CSS_BTN_FOCAL ))

					// BOTAO CANCELAR
					oButton4 := TButton():New(145,;
						100,;
						"&Fechar",;
						oPanelMnt	,;
						{|| oDlgMNT:End()},;
						45,;
						20,;
						,,,.T.,;
						,,,{|| .T.})
					oButton4:SetCSS( POSCSS (GetClassName(oButton4), CSS_BTN_ATIVO ))

					ACTIVATE MSDIALOG oDlgMNT CENTERED

					//restaura as teclas atalho
					U_UKeyCtr(.T.) 

					If lRet

						cNrPDV := STFGetStation("PDV")
						cVendAfe := U_TPGetVend() //pego o vendedor logado (vinculado ao usuario ou vendedor logado com controle de senha)
						If FWHostPing() .and. STBRemoteExecute("_EXEC_CEN" ,{"U_TPDVA03C", {oGetList:aCols[nPos][nPosAbast],;
								"0",; //0-Afericao
							cNrPDV, .T., RetCodUsr(), cVendAfe}},; //lIntegra
							NIL, .T.)

							//Ao inves de recarregar, apenas retiro da do grid o item
							aDel(oGetList:aCols, nPos)
							aSize(oGetList:aCols, len(oGetList:aCols)-1)

							oGetList:oBrowse:Refresh()

							STFMessage("AFERICAO","ALERT", "Abastecimento de aferição baixado com sucesso!" ) //POPUP
							STFShowMessage("AFERICAO")

						else
							STFMessage("AFERICAO","STOP", "Não foi possível fazer aferição do abastecimento!" )
							STFShowMessage("AFERICAO")

						EndIf

					EndIf
				
				else

					oTotal := STFGetTot() // Recebe o Objeto totalizador
					nTotalVend := oTotal:GetValue("L1_VLRTOT") // Valor total da venda

					If nTotalVend > 0  //verifico se os itens ja adicionados são também de aferição
						oModelCesta := STDGPBModel()
						oModelCesta := oModelCesta
						For nI := 1 To oModelCesta:Length()
							oModelCesta:GoLine(nI)
							If !oModelCesta:IsDeleted(nI)
								If oModelCesta:GetValue("L2_TES") <> cTesAfer
									STFMessage("AFERICAO","STOP", "Não é permitido realizar aferições com venda em andamento!" )
									STFShowMessage("AFERICAO")
									lRet := .F.
									EXIT
								EndIf
							EndIf
						Next nI
					EndIf

					If lRet

						//TODO: chamar o STIItemregister, passando o TES de aferição
						//STISelAbast(oGetList, oGetList:aHeader, /*oLblList*/, /*oGetPsw*/, /*oGetSearch*/, /*oBtnSel*/, .T./*lAferic*/)
						
						STFMessage("AFERICAO","STOP", "Aferição com nota! Rotina em desenvolvimento!" )
						STFShowMessage("AFERICAO")

					EndIf

				EndIf
			else
				STFMessage("AFERICAO","STOP", "Necessário posicionar no abastecimento para realizar a Aferição!" )
				STFShowMessage("AFERICAO")
			EndIf
		else
			STFMessage("AFERICAO","STOP", "Acione a tela de abastecimentos pendentes!" )
			STFShowMessage("AFERICAO")
		EndIf

	EndIf

Return lRet

//-------------------------------------------------------------------
/*/{Protheus.doc} TPDVA03A
Aferição multiplos abastecimentos.

@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
User Function TPDVA03A(oPnlPrinc)

	Local nWidth, nHeight
	Local oPnlGrid, oPnlAux
	Local cCorBg := SuperGetMv("MV_LJCOLOR",,"07334C")// Cor da tela

	nWidth  := oPnlPrinc:nWidth/2
	nHeight := oPnlPrinc:nHeight/2

	cCodBico  := Space(TamSx3("MID_CODBIC")[1])
	cDescBico := Space(TamSx3("MHZ_DESPRO")[1])

	cAmbiente := GetMV("MV_LJAMBIE")
	If Empty(cAmbiente)
		@ 020, 020 SAY oSay1 PROMPT "<h1>Ops!</h1><br>Configuração do Ambiente (MV_LJAMBIE) no Host Superior não realizada. Entre em contato com o administrador do sistema." SIZE nWidth-40, 100 OF oPnlPrinc COLORS 0, 16777215 PIXEL HTML
		oSay1:SetCSS(POSCSS(GetClassName(oSay1), CSS_LABEL_FOCAL))
		Return ""
	EndIf

	// Painel geral da tela de aferição de bicos (mesmo tamanho da principal)
	oPnlGeral := TPanel():New(000,000,"",oPnlPrinc,NIL,.T.,.F.,,,nWidth,nHeight,.T.,.F.)

	@ 002, 002 SAY oSay1 PROMPT ("AFERIÇÃO DE BICOS") SIZE nWidth-004, 015 OF oPnlGeral COLORS 0, 16777215 PIXEL CENTER
	oSay1:SetCSS(POSCSS(GetClassName(oSay1), CSS_BTN_FOCAL))

	//Painel de aferição de bicos
	oPnlAbast := TPanel():New(020,000,"",oPnlGeral,NIL,.T.,.F.,,,nWidth,nHeight-020,,.T.,.F.)

	@ 005, 005 SAY oSay1 PROMPT "Cód. Bico" SIZE 100, 010 OF oPnlAbast COLORS 0, 16777215 PIXEL
	oSay1:SetCSS(POSCSS (GetClassName(oSay1), CSS_LABEL_FOCAL))
	oCodBico := TGet():New(015, 005,{|u| iif(PCount()==0,cCodBico,cCodBico:=u) },oPnlAbast,050,013,"@!",{|| VldBico() },,,,,,.T.,,,{|| .T. },,,,.F.,.F.,,"oCodBico",,,,.T.,.F.)
	oCodBico:SetCSS(POSCSS(GetClassName(oCodBico), CSS_GET_NORMAL))
	TSearchF3():New(oCodBico,400,250,"MIC","MIC_CODBIC",{{"MIC_CODBIC",1}},"",{{"MIC_CODBIC","MIC_NLOGIC","MIC_LADO"}},,,0,.F.)

	@ 005, 070 SAY oSay2 PROMPT "Descrição" SIZE 100, 010 OF oPnlAbast COLORS 0, 16777215 PIXEL
	oSay2:SetCSS(POSCSS(GetClassName(oSay2), CSS_LABEL_FOCAL))
	oDescBico := TGet():New(015, 070,{|u| iif(PCount()==0,cDescBico,cDescBico:=u)},oPnlAbast,160,013,"@!",{|| .T. },,,,,,.T.,,,{|| .T. },,,,.F.,.F.,,"oDescBico",,,,.T.,.F.)
	oDescBico:SetCSS(POSCSS(GetClassName(oDescBico), CSS_GET_NORMAL))
	oDescBico:lCanGotFocus := .F.

	@ 035, 005 SAY oLblVend PROMPT "Vendedor" SIZE 040, 010 OF oPnlAbast COLOR 0, 16777215 PIXEL
	oLblVend:SetCSS( POSCSS (GetClassName(oLblVend), CSS_LABEL_FOCAL ))
	@ 045, 005 MSGET oGetVend VAR cGetVend SIZE 090, 015 HASBUTTON  OF oPnlAbast VALID (ValidaVend() .and. VldBico()) COLORS 0, 16777215 PIXEL //F3 "SA3"
	oGetVend:SetCSS( POSCSS (GetClassName(oGetVend), CSS_GET_NORMAL ))
	TSearchF3():New(oGetVend,400,180,"SA3","A3_COD",{{"A3_NOME",2},{"A3_RFID",9}},"",{{"A3_COD","A3_NOME","A3_CGC","A3_RFID"},{"A3_COD","A3_NOME","A3_CGC","A3_RFID"}})

	@ 035, 095 SAY oLblNomeV PROMPT "Nome Vendedor" SIZE 080, 010 OF oPnlAbast COLOR 0, 16777215 PIXEL
	oLblNomeV:SetCSS( POSCSS (GetClassName(oLblNomeV), CSS_LABEL_FOCAL ))
	@ 045, 095 MSGET oGetNVen VAR cGetNVen SIZE 200, 015 OF oPnlAbast COLORS 0, 16777215 PIXEL READONLY
	oGetNVen:SetCSS( POSCSS (GetClassName(oGetNVen), CSS_GET_NORMAL ))

	@ 065, 005 SAY oSay4 PROMPT "Abastecimentos do Bico ( para listar TODOS abastecimentos digite asterisco [ * ] no campo 'Cód. Bico' )" SIZE 400, 011 OF oPnlAbast COLORS 0, 16777215 PIXEL
	oSay4:SetCSS( POSCSS (GetClassName(oSay4), CSS_BREADCUMB ))
	@ 069, 005 SAY Replicate("_",nWidth) SIZE nWidth-10, 008 OF oPnlAbast FONT COLORS CLR_HGRAY, 16777215 PIXEL

	//GRID
	@ 080, 003 MSPANEL oPnlGrid SIZE nWidth-4, nHeight-120 OF oPnlAbast

	@ 000,000 BITMAP oTop RESOURCE "x.png" NOBORDER SIZE 000,005 OF oPnlGrid ADJUST PIXEL
	oTop:Align := CONTROL_ALIGN_TOP
	//oTop:SetCSS( POSCSS (GetClassName(oTop), CSS_PANEL_HEADER ))
	oTop:SetCSS("TBitmap{ margin: 0px 9px 0px 5px; border: 1px solid #"+cCorBg+"; background-color: #"+cCorBg+"; border-top-right-radius: 8px; border-top-left-radius: 8px; }")
	oTop:ReadClientCoors(.T.,.T.)

	@ 000,000 BITMAP oBottom RESOURCE "x.png" NOBORDER SIZE 000,025 OF oPnlGrid ADJUST PIXEL
	oBottom:Align := CONTROL_ALIGN_BOTTOM
	oBottom:SetCSS( POSCSS (GetClassName(oBottom), CSS_PANEL_FOOTER ) )
	oBottom:ReadClientCoors(.T.,.T.)

	@ 000,000 BITMAP oContent RESOURCE "x.png" NOBORDER SIZE 000,000 OF oPnlGrid ADJUST PIXEL
	oContent:Align := CONTROL_ALIGN_ALLCLIENT
	oContent:ReadClientCoors(.T.,.T.)
	oPnlAux := POSBrwContainer(oContent)

	oMsGetAbast := MsNewGetAbast(oPnlAux, 001, 005, 150, nWidth-5)
	oMsGetAbast:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT
	oMsGetAbast:oBrowse:SetCSS( StrTran(POSCSS("TGRID", CSS_BROWSE),"gridline-color: white;","") ) //CSS do totvs pdv
	//oMsGetAbast:oBrowse:lCanGotFocus := .F.
	oMsGetAbast:oBrowse:nScrollType := 0
	oMsGetAbast:oBrowse:lHScroll := .F.
	oMsGetAbast:oBrowse:bLDblClick := {|| DbClique(oMsGetAbast)}

	@ (oPnlGrid:nHeight/2)-22, 010 SAY oQtdReg PROMPT (cValToChar(nQtdReg)+" registros encontrados.") SIZE 150, 010 OF oPnlGrid COLORS 0, 16777215 PIXEL
	oQtdReg:SetCSS( POSCSS (GetClassName(oQtdReg), CSS_LABEL_NORMAL))

	oBtn2 := TButton():New( nHeight-45,nWidth-75,"&Confirmar",oPnlAbast,{|| Confirmar() },070,020,,,,.T.,,,,{|| .T.})
	oBtn2:SetCSS(POSCSS(GetClassName(oBtn2), CSS_BTN_FOCAL))

	oBtn3 := TButton():New( nHeight-45,nWidth-150,"&Limpar Tela",oPnlAbast,{|| U_TPDVA03B() },070,020,,,,.T.,,,,{|| .T.})
	oBtn3:SetCSS(POSCSS(GetClassName(oBtn3), CSS_BTN_NORMAL))

	oBtn1 := TButton():New( nHeight-45,nWidth-225,"C&ancelar",oPnlAbast,{|| oDlgMNT:End() },070,020,,,,.T.,,,,{|| .T.})
	oBtn1:SetCSS(POSCSS(GetClassName(oBtn1), CSS_BTN_ATIVO))

	oCodBico:SetFocus()
	cCodBico := PadR(' ',TamSx3("MID_CODBIC")[1]) 
	//PadR('*',TamSx3("MID_CODBIC")[1])
	//VldBico()

Return

/*/{Protheus.doc} ValidaVend
Valida e gatilha vendedor
@author thebr
@since 11/02/2019
@version 1.0
@return nil
@type function
/*/
Static Function ValidaVend()

	Local lRet 			:= .T.
	//Local cMsgErro		:= ""

	If !Empty(cGetVend)

		SA3->(DbSetOrder(1))
		If SA3->(DbSeek(xFilial("SA3") + cGetVend))
			If U_TPDVP23A(cGetVend)
				cGetNVen := SA3->A3_NOME
				oGetNVen:Refresh()
			else
				lRet := .F.
				SetMsgRod("O cargo (A3_CARGO) do vendedor "+SA3->A3_COD+"-"+AllTrim(SA3->A3_NOME)+" não está liberado para ser utilizado no PDV.")
			EndIf
		else
			cGetVend := padl(AllTrim(cGetVend),tamsx3("A3_COD")[1],"0")
			oGetVend:Refresh()
			If SA3->(DbSeek(xFilial("SA3") + cGetVend))
				If U_TPDVP23A(cGetVend)
					cGetNVen := SA3->A3_NOME
					oGetNVen:Refresh()
				else
					lRet := .F.
					SetMsgRod("O cargo (A3_CARGO) do vendedor "+SA3->A3_COD+"-"+AllTrim(SA3->A3_NOME)+" não está liberado para ser utilizado no PDV.")
				EndIf
			else
				lRet 	 := .F.
				cGetNVen := ""
				SetMsgRod("O Vendedor informado é inválido!")
			EndIf
		EndIf

	else
		cGetNVen := ""
		oGetNVen:Refresh()
	EndIf

	If lRet
		SetMsgRod("")
	EndIf

Return(lRet)

/*/{Protheus.doc} TPDVA03B
Função para limpar e resetar tela.

@author Totvs GO
@since 22/07/2019
@version 1.0
@return Nil
@type function
/*/
User Function TPDVA03B()
	Local aFieldFill 	:= {}
	Local nX

	cCodBico  := Space(TamSx3("MID_CODBIC")[1])
	cDescBico := Space(TamSx3("MHZ_DESPRO")[1])
	nQtdReg := 0

	If oMsGetAbast <> Nil

		oMsGetAbast:Acols := {}
		For nX := 1 to Len(oMsGetAbast:aHeader)
			If oMsGetAbast:aHeader[nX,2] == "MARK"
				Aadd(aFieldFill,"LBNO")
			ElseIf oMsGetAbast:aHeader[nX,8] == "N"
				Aadd(aFieldFill,0)
			ElseIf oMsGetAbast:aHeader[nX,8] == "D"
				Aadd(aFieldFill,CTOD(""))
			ElseIf oMsGetAbast:aHeader[nX,8] == "L"
				Aadd(aFieldFill,.F.)
			Else
				Aadd(aFieldFill,"")
			EndIf
		Next nX

		Aadd(aFieldFill, .F.)
		aadd(oMsGetAbast:Acols,aFieldFill)
	EndIf

	SetMsgRod("")

	If oCodBico <> Nil
		oCodBico:SetFocus()
	EndIf

Return


//--------------------------------------------------------
// Validação e gatilho do bico
//--------------------------------------------------------
Static Function VldBico()

	Local cMsgErr := ""
	Local lRet := .T.
	Local cTanque := ""

	If AllTrim(cCodBico) = '*'
		cDescBico := "TODOS ABASTECIMENTOS PENDENTES"
	ElseIf Empty(cCodBico)
		cDescBico := Space(TamSx3("MHZ_DESPRO")[1])
	Else
		cTanque := Posicione("MIC",3,xFilial("MIC")+cCodBico,"MIC_CODTAN") //MIC_FILIAL+MIC_CODBIC+MIC_CODTAN
		cDescBico := Posicione("MHZ",1,xFilial("MHZ")+cTanque,"MHZ_DESPRO") //MHZ_FILIAL+MHZ_CODTAN
		If Empty(cDescBico)
			lRet := .F.
			cMsgErr := "Bico não encontrado!"
		EndIf
	EndIf

	If lRet
		oDescBico:Refresh()
		RefreshAbs() //Consultando abastecimentos pendêntes...
	EndIf

	SetMsgRod(cMsgErr)

Return lRet

//-----------------------------------------------------------------------------------------
// Monta grid NewGetDados de Estorno
//-----------------------------------------------------------------------------------------
Static Function MsNewGetAbast(oPnl, nTop, nLeft, nBottom, nRight)

	Local aHeaderEx 	:= {}
	Local aColsEx 		:= {}
	Local aAlterFields 	:= {}
	Local aFields 		:= { "MID_CODABA", "MID_XCONCE", "MID_LADBOM", "MID_NLOGIC", "MID_CODBIC", "MID_ENCFIN", "MID_LITABA", "MID_PREPLI", "MID_TOTAPA", "MID_DATACO", "MID_HORACO", "MID_RFID", "MID_CODBOM", "MID_XPROD" }
	Local aFieldFill 	:= {}
	Local nX

	// a primeira coluna do grid é MARK
	Aadd(aHeaderEx,{Space(10),'MARK','@BMP',2,0,'','€€€€€€€€€€€€€€','C','','','',''})
	Aadd(aFieldFill,"LBNO")

	For nX:=1 to Len(aFields)
		aadd(aHeaderEx, U_UAHEADER(aFields[nX]) )
	Next nX

	For nX := 2 to Len(aHeaderEx)
		If aHeaderEx[nX][8] == "N"
			Aadd(aFieldFill, 0)
		elseIf aHeaderEx[nX][8] == "D"
			Aadd(aFieldFill, stod(""))
		ElseIf aHeaderEx[nX][8] == "L"
			Aadd(aFieldFill,.F.)
		else
			Aadd(aFieldFill, "")
		EndIf
	Next nX

	Aadd(aFieldFill, .F.)
	Aadd(aColsEx, aFieldFill)

Return MsNewGetDados():New( nTop, nLeft, nBottom, nRight, , "AllwaysTrue", "AllwaysTrue", "+Field1+Field2", aAlterFields,, 999, "AllwaysTrue", "", "AllwaysTrue", oPnl, aHeaderEx, aColsEx)

//-------------------------------------------
// Função chamada pelo duplo clique no grid
//-------------------------------------------
Static Function DbClique(_obj)

	Local nAfMaxLt := SuperGetMv("TP_AFMAXLT",,1000) //Define o maximo de litros de um abastecimento de aferição
	Local nLitros := 0
	Local cUsrAfc
	
	SetMsgRod("")

	If _obj:aCols[_obj:oBrowse:nAt][1] == "LBOK"
		_obj:aCols[_obj:oBrowse:nAt][1] := "LBNO"
	else
		nLitros := _obj:aCols[_obj:oBrowse:nAt][aScan(_obj:aHeader,{|x| AllTrim(x[2])=="MID_LITABA"})]
		if nLitros > nAfMaxLt

			SetMsgRod("O abatecimento tem litragem superior ao maximo permitido em aferições!")

			U_TRETA37B("AFEMAX", "AFERICAO ACIMA DO MAXIMO PERMITIDO (TP_AFMAXLT)")
			cUsrAfc := U_VLACESS1("AFEMAX", RetCodUsr())
			If cUsrAfc == Nil .OR. Empty(cUsrAfc)
			else
				SetMsgRod("")
				_obj:aCols[_obj:oBrowse:nAt][1] := "LBOK"
			EndIf
			
		else
			_obj:aCols[_obj:oBrowse:nAt][1] := "LBOK"
		endif
	EndIf

	_obj:oBrowse:Refresh()

Return()

//------------------------------------------------------
// Função que atualiza o Grid dos abastecimentos
// Consulta abastecimentos pendêntes
//------------------------------------------------------
Static Function RefreshAbs()

	Local aFieldFill 	:= {}
	Local nX := 0, nY := 0
	
	Local cFiltro := "", cRFid := ""

	Local aRet := {}, aCampos := {}, aParam := {}

	If !Empty(cCodBico)

		If !Empty(cGetVend)
			SA3->(DbSetOrder(1))
			If SA3->(DbSeek(xFilial("SA3") + cGetVend))
				cRFid := SA3->A3_RFID
				If !Empty(cRFid)
					cFiltro += "( MID_RFID = '' OR '" + cRFid + "' LIKE '%' || TRIM(MID_RFID) || '%' )"
				EndIf
			EndIf
		EndIf

		SetMsgRod("Consultando abastecimentos pendêntes. Aguarde...")

		CursorArrow()
		CursorWait()

		oMsGetAbast:Acols := {}
		aRet := Nil

		For nX := 1 to Len(oMsGetAbast:aHeader)
			If oMsGetAbast:aHeader[nX,2] <> "MARK"
				Aadd(aCampos,oMsGetAbast:aHeader[nX,2])
			EndIf
		Next nx

		aParam := {iif(AllTrim(cCodBico)='*','',cCodBico),aCampos,cFiltro}
		aParam := {"U_TPDVA09A",aParam}
		If !FWHostPing() .OR. !STBRemoteExecute("_EXEC_CEN",aParam,,,@aRet)
			// Tratamento do erro de conexao
			SetMsgRod("Falha de comunicação com a central...")

		ElseIf aRet = Nil .or. Empty(aRet) .or. Len(aRet) == 0
			// Tratamento para retorno vazio
			SetMsgRod("Ocorreu falha na consulta de abastecimentos ou não existem abastecimentos pendêntes...")

		ElseIf Len(aRet) > 0 //-- consulta realizada com sucesso
			SetMsgRod("Foram encontrados"+" "+AllTrim(Str(Len(aRet)))+" "+"abastecimentos pendêntes...")
			nQtdReg := Len(aRet)
			oQtdReg:Refresh()

			For nX:=1 to Len(aRet)
				aFieldFill := {}

				aadd(aFieldFill, "LBNO")
				For nY:=1 to Len(aRet[nX])
					aadd(aFieldFill, aRet[nX][nY])
				Next nY
				Aadd(aFieldFill, .F.)
				aadd(oMsGetAbast:Acols,aFieldFill)

			Next nX

		EndIf

		CursorArrow()

	Else
		oMsGetAbast:Acols := {}

	EndIf

//-- se array vazio, limpa acols
	If Empty(oMsGetAbast:Acols)

		For nX := 1 to Len(oMsGetAbast:aHeader)
			If oMsGetAbast:aHeader[nX,2] == "MARK"
				Aadd(aFieldFill,"LBNO")
			ElseIf oMsGetAbast:aHeader[nX,8] == "N"
				Aadd(aFieldFill,0)
			ElseIf oMsGetAbast:aHeader[nX,8] == "D"
				Aadd(aFieldFill,CTOD(""))
			ElseIf oMsGetAbast:aHeader[nX,8] == "L"
				Aadd(aFieldFill,.F.)
			Else
				Aadd(aFieldFill,"")
			EndIf
		Next nX

		Aadd(aFieldFill, .F.)
		aadd(oMsGetAbast:Acols,aFieldFill)

	EndIf

	oMsGetAbast:oBrowse:Refresh()

Return()

//---------------------------------------------------------------------
// Função que executa a confirmação da rotina
//---------------------------------------------------------------------
Static Function Confirmar()

	Local nQtdAferido := 0
	Local nX 		:= 1
	Local cCodAbast	:= ""
	Local cVendAfe := U_TPGetVend() //pego o vendedor logado (vinculado ao usuario ou vendedor logado com controle de senha)
	Local cNrPDV := STFGetStation("PDV")
	Local lHabImpAf := SuperGetMv("TP_IMPAFER",,.T.) // Habilita/Desabilita impressão do comprovante de aferição (default .T.) 
	Local nTypeImp := 1
	Local aImpAgrup := {}

	nTypeImp := Aviso("Aferição Multipla", ;
				"Como deseja que seja a impressao do comprovante?" ,;
				{"Individual", "Agrupada"}, 2)

	SetMsgRod("Realizando a gravação da aferição de abastecimento. Aguarde...")

	CursorArrow()
	CursorWait()

	For nX := 1 To Len(oMsGetAbast:aCols)
		If AllTrim(oMsGetAbast:aCols[nX][aScan(oMsGetAbast:aHeader,{|x| AllTrim(x[2])=="MARK"})]) == "LBOK"
			cCodAbast := oMsGetAbast:aCols[nX][aScan(oMsGetAbast:aHeader,{|x| AllTrim(x[2])=="MID_CODABA"})]
			If !empty(cCodAbast) .and. FWHostPing() .and. STBRemoteExecute("_EXEC_CEN" ,{"U_TPDVA03C", {cCodAbast,;
					"0",; //0-Afericao
				cNrPDV, .T. , RetCodUsr(), cVendAfe}},; //lIntegra
				NIL, .T.)
				
				SetMsgRod("Abastecimento N° "+cCodAbast+" aferido com sucesso!")
				nQtdAferido++

				//-------------------------------------------------------------//
				// Faz impressão do comprovante de aferição
				//-------------------------------------------------------------//
				If lHabImpAf
					cOperador := cVendAfe+" - "+AllTrim(Posicione("SA3",1,xFilial("SA3")+cVendAfe,"A3_NOME"))
					cProduto := oMsGetAbast:aCols[nX][aScan(oMsGetAbast:aHeader,{|x| AllTrim(x[2])=="MID_XPROD"})]
					cProduto := AllTrim(cProduto)+" - "+AllTrim(Posicione("SB1",1,xFilial("SB1")+cProduto,"B1_DESC"))
					nLitros := oMsGetAbast:aCols[nX][aScan(oMsGetAbast:aHeader,{|x| AllTrim(x[2])=="MID_LITABA"})]
					cBomba := oMsGetAbast:aCols[nX][aScan(oMsGetAbast:aHeader,{|x| AllTrim(x[2])=="MID_CODBOM"})]
					cBico := oMsGetAbast:aCols[nX][aScan(oMsGetAbast:aHeader,{|x| AllTrim(x[2])=="MID_CODBIC"})]
					nEncIn := oMsGetAbast:aCols[nX][aScan(oMsGetAbast:aHeader,{|x| AllTrim(x[2])=="MID_ENCFIN"})]-nLitros
					nEncFi := oMsGetAbast:aCols[nX][aScan(oMsGetAbast:aHeader,{|x| AllTrim(x[2])=="MID_ENCFIN"})]
					dDtAb := oMsGetAbast:aCols[nX][aScan(oMsGetAbast:aHeader,{|x| AllTrim(x[2])=="MID_DATACO"})]
					cHrAb := oMsGetAbast:aCols[nX][aScan(oMsGetAbast:aHeader,{|x| AllTrim(x[2])=="MID_HORACO"})]
					
					if nTypeImp == 1 //individual
						U_TPDVR007(cOperador,cProduto,nLitros,cBomba,cBico,nEncIn,nEncFi,dDtAb,cHrAb)
					else
						aadd(aImpAgrup, {cOperador,cProduto,nLitros,cBomba,cBico,nEncIn,nEncFi,dDtAb,cHrAb})
					endif
				EndIf

			Else
				SetMsgRod("Não foi possível fazer aferição do abastecimento N° "+cCodAbast+"!")
			EndIf
		EndIf
	Next nX

	If Empty(cCodAbast)
		SetMsgRod("Selecione o(s) abastecimento(s) a serem aferidos!")
	Else
		//imprimindo
		if nTypeImp == 2
			U_TPDVR07A(aImpAgrup)
		endif
		// atualizo a tela com os abastecimentos do bico
		RefreshAbs() //Consultando abastecimentos pendêntes...
		if nQtdAferido > 0
			SetMsgRod("Abastecimento(s) aferido(s) com sucesso!")
		endif
	EndIf

	CursorArrow()

Return

/*/{Protheus.doc} SetMsgRod
Seta mensagem no rodape
@author Totvs GO
@since 02/09/2020
@version 1.0
@return Nil
@param cMensagem, characters, descricao
@type function
/*/
Static Function SetMsgRod(cMensagem)
	cMsgRod := cMensagem
	oMsgRod:Refresh()
Return


//Função que realiza a gravação da afereição no HOST superior
User Function TPDVA03C(cCodigo, cOrcamento, cNrPDV, lIntegra, cUserAfe, cVendAfe)

	Local lRet := .F.

	//faz a gravação do status
	If StwFsChangeStatus(cCodigo, cOrcamento, cNrPDV, lIntegra) .AND. RecLock("MID", .F.)
		If MID->(FieldPos("MID_XUAFER")) > 0
			MID->MID_XUAFER := cUserAfe
		EndIf
		If MID->(FieldPos( "MID_XOPERA" )) > 0
			MID->MID_XOPERA :=  cVendAfe 
		EndIf
		MID->MID_AFERIR :=  "S" 
		MID->( MsUnLock() )
		lRet := .T.
	EndIf

Return lRet

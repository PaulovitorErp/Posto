
#INCLUDE "TOTVS.CH"
#INCLUDE "stpos.ch"
#INCLUDE "poscss.ch"
#INCLUDE "topconn.ch"

#DEFINE NPOSVLR 1
#DEFINE NPOSFPG 3
#DEFINE NPOSDES 4
#DEFINE NPOSDAT 2
#DEFINE NPOSINF 5
#DEFINE NPOSDEL 6

Static cUsrCmp := ""
Static lOnlyView := .F.
Static oPnlGeral
Static oPnlInc
Static oPnlBrow
Static cTitleTela := ""
Static oNumCmp
Static cNumCmp := "INCLUINDO"//Space(TamSX3("UC0_NUM")[1])
Static oVendedor
Static cVendedor := Space(TamSX3("UC0_VEND")[1])
Static oNomVend
Static cNomVend := ""
Static oCodCli
Static cCodCli := Space(TamSX3("A1_COD")[1])
Static oLojCli
Static cLojCli := Space(TamSX3("A1_LOJA")[1])
Static oNomCli
Static cNomCli := ""
Static oPlaca
Static cPlaca := Space(TamSX3("UC0_PLACA")[1])
Static oMsGetEnt
Static oVlrForm
Static nVlrForm := 0
Static oVlrMax
Static nVlrMax := SuperGetMV( "MV_XVOPCMP" , .T., 0 )
Static oJustif
Static cJustif := ""
Static oDocNf
Static cDocNf := Space(TamSX3("L1_DOC")[1])
Static oSerieNf
Static cSerieNf := Space(TamSX3("L1_SERIE")[1])
Static oVlrDin
Static nVlrDin := 0
Static oVlrVale
Static nVlrVale := 0
Static oVlrComp
Static nVlrComp := 0
Static oBuscaCmp
Static cBuscaCmp := Space(TamSX3("UC0_NUM")[1])
Static oBuscaDt
Static dBuscaDt := dDataBase
Static oBuscaCod
Static cBuscaCod := Space(TamSX3("A1_COD")[1])
Static oBuscaLoj
Static cBuscaLoj := Space(TamSX3("A1_LOJA")[1])
Static oBuscaPlaca
Static cBuscaPlaca := Space(TamSX3("UC0_PLACA")[1])
Static oMsGetCmp
Static oQtdReg
Static nQtdReg := 0
Static oCssCombo    := "TComboBox { font: bold; font-size: 13px; text-align: right; color: #656565; background-color: #FFFFFF; border: 1px solid #9C9C9C; border-radius: 4px; padding: 4px; } TComboBox:focus{border: 2px solid #0080FF;} TComboBox:disabled {color:#656565; background-color: #EEEEEE;} TComboBox:drop-down {color:#000000; background-color: #FFFFFF; border-left: 0px; border-radius: 4px; background-image: url(rpo:fwskin_combobox_arrow.png);background-repeat: none;background-position: center;}"
Static lConfCash := .F.
Static lRetOn := .F.
Static aLogAlcada := {}
Static lVincVend := .F.
Static lCMPCPAD := SuperGetMv("TP_CMPCPAD",,.F.) //Habilita compensação para cliente padrão

/*/{Protheus.doc} TPDVA005
Compensação de Valores

@author danilo brito
@since 30/04/2019
@version 1.0
@return Nil
@type function
/*/
User Function TPDVA005(oPnlPrinc, _lConfCash, bConfirm, bCancel, nOpcX, _lVincVend)

	Local nWidth, nHeight
	Local oPnlGrid, oPnlGrid2, oPnlAux, oPnlAux2
	Local cCorBg := SuperGetMv("MV_LJCOLOR",,"07334C")// Cor da tela
	Local lAlcada	:= SuperGetMv("ES_ALCADA",.F.,.F.)
	Local lAlcCmp	:= SuperGetMv( "ES_ALCCMP",.F.,.F.)
	Local lActiveVLH := SuperGetMV("TP_ACTVLH",,.F.)
	Local lMvPswVend := SuperGetMv("TP_PSWVEND",,.F.)
	Local lBlqAI0 	:= SuperGetMv("MV_XBLQAI0",,.F.) .AND. AI0->(FieldPos("AI0_XBLFIL")) > 0 //Habilita bloqueio de venda na filial, olhando para tabela AI0
	Local cFiltro	:= ""
	Default _lConfCash := .F.
	Default _lVincVend := .F.

	DbSelectArea("UC0")
	DbSelectArea("UC1")

	nWidth := oPnlPrinc:nWidth/2
	nHeight := oPnlPrinc:nHeight/2
	lConfCash := _lConfCash
	lVincVend := _lVincVend

	//verifica se o usuário tem permissão para acesso a rotina
	If !lConfCash
		U_TRETA37B("CMPPDV", "COMPENSACAO DE VALORES PDV")
		cUsrCmp := U_VLACESS1("CMPPDV", RetCodUsr())
		If cUsrCmp == Nil .OR. Empty(cUsrCmp)
			@ 020, 020 SAY oSay1 PROMPT "<h1>Ops!</h1><br>Seu usuário não tem permissão de acesso a rotina de Compensação. Entre em contato com o administrador do sistema." SIZE nWidth-40, 100 OF oPnlPrinc COLORS 0, 16777215 PIXEL HTML
			oSay1:SetCSS( POSCSS (GetClassName(oSay1), CSS_LABEL_FOCAL ))
			Return cUsrCmp
		EndIf
	EndIf

	if !lConfCash .AND. lMvPswVend
		cVendedor := U_TPGetVend()
		cNomVend  := U_TPGetVend(2)
	else
		SA3->(DbSetOrder(7)) // A3_FILIAL + A3_CODUSR
		If SA3->(DbSeek(xFilial("SA3") + RETCODUSR()))
			cVendedor := SA3->A3_COD
			cNomVend  := SA3->A3_NOME
		else
			SA3->(DbSetOrder(1))
			If SA3->(DbSeek(xFilial("SA3") + GetMV("MV_VENDPAD") ))
				cVendedor := SA3->A3_COD
				cNomVend  := SA3->A3_NOME
			endif
		EndIf
	endif

	if lVincVend
		cPlaca := SL1->L1_PLACA
		if lCMPCPAD .OR. SL1->L1_CLIENTE+SL1->L1_LOJA != GETMV("MV_CLIPAD")+GETMV("MV_LOJAPAD")
			cCodCli := SL1->L1_CLIENTE
			cLojCli := SL1->L1_LOJA
			cNomCli := Posicione("SA1",1,xFilial("SA1")+cCodCli+cLojCli,"A1_NOME")
		endif
		cDocNf := SL1->L1_DOC
		cSerieNf := SL1->L1_SERIE
	endif

	//painel geral da tela de compensações (mesmo tamanho da principal)
	oPnlGeral := TPanel():New(000,000,"",oPnlPrinc,NIL,.T.,.F.,,,nWidth,nHeight,.T.,.F.)

	cTitleTela := "INCLUSÃO"
	@ 002, 002 SAY oSay1 PROMPT ("COMPENSAÇÃO DE VALORES - "+cTitleTela) SIZE nWidth-004, 015 OF oPnlGeral COLORS 0, 16777215 PIXEL CENTER
	oSay1:SetCSS( POSCSS (GetClassName(oSay1), CSS_BTN_FOCAL ))

	//Painel de Inclusão de compensação
	oPnlInc := TPanel():New(020,000,"",oPnlGeral,NIL,.T.,.F.,,,nWidth,nHeight-020,,.T.,.F.)

	@ 005, 005 SAY oSay2 PROMPT "Compensação" SIZE 100, 010 OF oPnlInc COLORS 0, 16777215 PIXEL
  	oSay2:SetCSS( POSCSS (GetClassName(oSay2), CSS_LABEL_FOCAL ))
  	oNumCmp := TGet():New( 015, 005,{|u| iif( PCount()==0,cNumCmp,cNumCmp:=u) },oPnlInc, 060, 013,,{|| /*bValid*/ },,,,,,.T.,,,{|| .T. },,,,.T.,.F.,,"oNumCmp",,,,.T.,.F.)
  	oNumCmp:SetCSS( POSCSS (GetClassName(oNumCmp), CSS_GET_NORMAL ))
  	oNumCmp:lCanGotFocus := .F.

  	@ 005, 070 SAY oSay5 PROMPT "Placa" SIZE 100, 010 OF oPnlInc COLORS 0, 16777215 PIXEL
  	oSay5:SetCSS( POSCSS (GetClassName(oSay5), CSS_LABEL_FOCAL ))
  	oPlaca := TGet():New( 015, 070,{|u| iif( PCount()==0,cPlaca,cPlaca:=u) },oPnlInc,70, 013,"@!R NNN-9N99",{|| VldPlaca() },,,,,,.T.,,,{|| .T. },,,,.F.,.F.,,"oPlaca",,,,.T.,.F.)
  	oPlaca:SetCSS( POSCSS (GetClassName(oPlaca), CSS_GET_NORMAL ))

	//@ 005, 145 SAY oSay3 PROMPT "CPF/CNPJ do Cliente" SIZE 100, 010 OF oPnlInc COLORS 0, 16777215 PIXEL
  	//oSay3:SetCSS( POSCSS (GetClassName(oSay3), CSS_LABEL_FOCAL ))
  	//oCgcCli := TGet():New( 015, 145,{|u| iif( PCount()==0,cCgcCli,cCgcCli:=u) },oPnlInc,85, 013,,{|| VldCliente() },,,,,,.T.,,,{|| .T. },,,,.F.,.F.,,"oCgcCli",,,,.T.,.F.)
  	//oCgcCli:SetCSS( POSCSS (GetClassName(oCgcCli), CSS_GET_NORMAL ))
	//TSearchF3():New(oCgcCli,400,250,"SA1","A1_CGC",{{"A1_NOME",2},{"A1_CGC",3},{"A1_COD",1}},"SA1->A1_MSBLQL<>'1'",{{"A1_NOME","A1_EST","A1_MUN"},{"A1_CGC","A1_NOME","A1_EST","A1_MUN"},{"A1_COD","A1_LOJA","A1_NOME","A1_EST","A1_MUN"}},,,iif(lConfCash,-40,0))
	
	@ 005, 145 SAY oSay3 PROMPT "Código" SIZE 100, 010 OF oPnlInc COLORS 0, 16777215 PIXEL
	oSay3:SetCSS( POSCSS (GetClassName(oSay3), CSS_LABEL_FOCAL ))
	oCodCli := TGet():New( 015, 145,{|u| iif( PCount()==0,cCodCli,cCodCli:=u) },oPnlInc,55, 013, "@!",{|| VldCliente() },,,,,,.T.,,,{|| .T. },,,,.F.,.F.,,"oCodCli",,,,.T.,.F.)
	oCodCli:SetCSS( POSCSS (GetClassName(oCodCli), CSS_GET_NORMAL ))

	@ 005, 200 SAY oSay3 PROMPT "Loja" SIZE 100, 010 OF oPnlInc COLORS 0, 16777215 PIXEL
	oSay3:SetCSS( POSCSS (GetClassName(oSay3), CSS_LABEL_FOCAL ))
	oLojCli := TGet():New( 015, 200,{|u| iif( PCount()==0,cLojCli,cLojCli:=u) },oPnlInc,20, 013, "@!",{|| VldCliente() },,,,,,.T.,,,{|| .T. },,,,.F.,.F.,,"oLojCli",,,,.T.,.F.)
	oLojCli:SetCSS( POSCSS (GetClassName(oLojCli), CSS_GET_NORMAL ))

  	@ 005, 230 SAY oSay4 PROMPT "Nome Cliente" SIZE 070, 010 OF oPnlInc COLORS 0, 16777215 PIXEL
  	oSay4:SetCSS( POSCSS (GetClassName(oSay4), CSS_LABEL_FOCAL ))
  	oNomCli := TGet():New( 015, 230,{|u| iif( PCount()==0,cNomCli,cNomCli:=u)},oPnlInc,nWidth-235, 013,,{|| .T./*bValid*/ },,,,,,.T.,,,{|| .T. },,,,.T.,.F.,,"oNomCli",,,,.T.,.F.)
  	oNomCli:SetCSS( POSCSS (GetClassName(oNomCli), CSS_GET_NORMAL ))
	oNomCli:lCanGotFocus := .F.

	// bloqueio de filiais
	if lBlqAI0
		cFiltro := " .AND. Posicione('AI0',1,xFilial('AI0')+SA1->A1_COD+SA1->A1_LOJA,'AI0_XBLFIL')!='S'"
	elseIf SA1->(FieldPos("A1_XFILBLQ")) > 0 
		cFiltro := " .AND. (Empty(SA1->A1_XFILBLQ) .OR. !(cFilAnt $ SA1->A1_XFILBLQ))"
	EndIf
	TSearchF3():New(oCodCli,400,250,"SA1","A1_COD",{{"A1_NOME",2},{"A1_CGC",3},{"A1_COD",1}},"SA1->A1_MSBLQL<>'1'"+cFiltro,{{"A1_COD","A1_LOJA","A1_NOME","A1_EST","A1_MUN"},{"A1_COD","A1_LOJA","A1_CGC","A1_NOME","A1_EST","A1_MUN"},{"A1_COD","A1_LOJA","A1_NOME","A1_EST","A1_MUN"}},,,iif(lConfCash,-40,0)/*nAjustPos*/,,{{oLojCli,"A1_LOJA"},{oNomCli,"A1_NOME"}})

	@ 038, 005 SAY oSay6 PROMPT "Formas e Valores de Entrada" SIZE 400, 011 OF oPnlInc COLORS 0, 16777215 PIXEL
	oSay6:SetCSS( POSCSS (GetClassName(oSay6), CSS_BREADCUMB ))
	@ 042, 005 SAY Replicate("_",nWidth) SIZE nWidth-10, 008 OF oPnlInc FONT COLORS CLR_HGRAY, 16777215 PIXEL

	oBtn1 := TButton():New( 053,005,"Incluir Cheque",oPnlInc,{|| ViewCheck() },080,020,,,,.T.,,,,{|| !lOnlyView })
	oBtn1:SetCSS( POSCSS (GetClassName(oBtn1), CSS_BTN_FOCAL ))

	oBtn1 := TButton():New( 078,005,"Incluir Cartão",oPnlInc,{|| ViewCard() },080,020,,,,.T.,,,,{|| !lOnlyView})
	oBtn1:SetCSS( POSCSS (GetClassName(oBtn1), CSS_BTN_FOCAL ))

	oBtn1 := TButton():New( 103,005,"Incluir Carta Frete",oPnlInc,{|| ViewCFrete() },080,020,,,,.T.,,,,{|| !lOnlyView})
	oBtn1:SetCSS( POSCSS (GetClassName(oBtn1), CSS_BTN_FOCAL ))

	//GRID
	@ 053, 090 MSPANEL oPnlGrid SIZE nWidth-90, nHeight-195 OF oPnlInc

	@ 000,000 BITMAP oTop RESOURCE "x.png" NOBORDER SIZE 000,005 OF oPnlGrid ADJUST PIXEL
	oTop:Align := CONTROL_ALIGN_TOP
	//oTop:SetCSS( POSCSS (GetClassName(oTop), CSS_PANEL_HEADER ))
	oTop:SetCSS("TBitmap{ margin: 0px 9px 0px 5px; border: 1px solid #"+cCorBg+"; background-color: #"+cCorBg+"; border-top-right-radius: 8px; border-top-left-radius: 8px; }")
	oTop:ReadClientCoors(.T.,.T.)

	@ 000,000 BITMAP oBottom RESOURCE "x.png" NOBORDER SIZE 000,040 OF oPnlGrid ADJUST PIXEL
	oBottom:Align := CONTROL_ALIGN_BOTTOM
	oBottom:SetCSS( POSCSS (GetClassName(oBottom), CSS_PANEL_FOOTER ) )
	oBottom:ReadClientCoors(.T.,.T.)

	@ 000,000 BITMAP oContent RESOURCE "x.png" NOBORDER SIZE 000,000 OF oPnlGrid ADJUST PIXEL
	oContent:Align := CONTROL_ALIGN_ALLCLIENT
	oContent:ReadClientCoors(.T.,.T.)
	oPnlAux := POSBrwContainer(oContent)

	oMsGetEnt := MsNewGetEnt(oPnlAux, 053, 090, 150, nWidth-5)
	oMsGetEnt:oBrowse:bLDblClick := {|| AltForma() }
	oMsGetEnt:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT
	oMsGetEnt:oBrowse:SetCSS( POSCSS("TGRID", CSS_BROWSE) ) //CSS do totvs pdv
	//oMsGetEnt:oBrowse:lCanGotFocus := .F.
	oMsGetEnt:oBrowse:nScrollType := 0
	oMsGetEnt:oBrowse:lHScroll := .F.

	@ (oPnlGrid:nHeight/2)-33, 010 SAY oSay7 PROMPT "Máximo a Compensar:" SIZE 100, 010 OF oPnlGrid COLORS 0, 16777215 PIXEL
	oSay7:SetCSS( POSCSS (GetClassName(oSay7), CSS_LABEL_NORMAL))
	@ (oPnlGrid:nHeight/2)-25, 007 SAY oVlrMax VAR Alltrim(Transform(nVlrMax,"@E 99,999.99")) SIZE 100, 015 OF oPnlGrid COLOR 0, 16777215 PIXEL
	oVlrMax:SetCSS( POSCSS (GetClassName(oVlrMax), CSS_GET_NORMAL))
	oVlrMax:lActive := .F.
	//Caso alçada desabilittada, oculto valor maximo a compensar
	if !lAlcada .OR. !lAlcCmp
		oVlrMax:Hide()
		oSay7:Hide()
	endif

	@ (oPnlGrid:nHeight/2)-39, (oPnlGrid:nWidth/2)-82 SAY oLblTot PROMPT "Valor Total a Compensar" SIZE 100, 010 OF oPnlGrid COLORS 0, 16777215 PIXEL
	oLblTot:SetCSS( POSCSS (GetClassName(oLblTot), CSS_LABEL_NORMAL))
	@ (oPnlGrid:nHeight/2)-32, (oPnlGrid:nWidth/2)-110 SAY oVlrForm VAR AllTrim(Transform(nVlrForm,"@E 99,999.99")) SIZE 100, 040 OF oPnlGrid RIGHT COLOR 0, 16777215 PIXEL
	oVlrForm:SetCSS( POSCSS (GetClassName(oVlrForm), CSS_LABEL_TOTAL))

	@ nHeight-142, 005 SAY oSay8 PROMPT "Formas de Saída / Informações Complementares" SIZE 400, 013 OF oPnlInc COLORS 0, 16777215 PIXEL
	oSay8:SetCSS( POSCSS (GetClassName(oSay8), CSS_BREADCUMB ))
	@ nHeight-138, 005 SAY Replicate("_",nWidth) SIZE nWidth-10, 008 OF oPnlInc FONT COLORS CLR_HGRAY, 16777215 PIXEL

	@ nHeight-128, 005 SAY oSay3 PROMPT "Vendedor" SIZE 100, 010 OF oPnlInc COLORS 0, 16777215 PIXEL
  	oSay3:SetCSS( POSCSS (GetClassName(oSay3), CSS_LABEL_FOCAL ))
  	oVendedor := TGet():New( nHeight-119, 005,{|u| iif( PCount()==0,cVendedor,cVendedor:=u) },oPnlInc,65, 012,,{|| VldVend() },,,,,,.T.,,,{|| .T. },,,,!lConfCash .AND. lMvPswVend,.F.,,"oVendedor",,,,.T.,.F.)
  	oVendedor:SetCSS( POSCSS (GetClassName(oVendedor), CSS_GET_NORMAL ))
	if !lMvPswVend
  		TSearchF3():New(oVendedor,400,180,"SA3","A3_COD",{{"A3_NOME",2}},"",,,,iif(lConfCash,-40,0))
	endif

  	@ nHeight-128, 070 SAY oSay4 PROMPT "Nome Vendedor" SIZE 100, 010 OF oPnlInc COLORS 0, 16777215 PIXEL
  	oSay4:SetCSS( POSCSS (GetClassName(oSay4), CSS_LABEL_FOCAL ))
  	oNomVend := TGet():New( nHeight-119, 070,{|u| iif( PCount()==0,cNomVend,cNomVend:=u)},oPnlInc,nWidth-265, 012,,{|| .T./*bValid*/ },,,,,,.T.,,,{|| .T. },,,,.T.,.F.,,"oNomVend",,,,.T.,.F.)
  	oNomVend:SetCSS( POSCSS (GetClassName(oNomVend), CSS_GET_NORMAL ))
  	oNomVend:lCanGotFocus := .F.

	@ nHeight-102, 005 SAY oSay5 PROMPT "Nota Fiscal" SIZE 100, 010 OF oPnlInc COLORS 0, 16777215 PIXEL
  	oSay5:SetCSS( POSCSS (GetClassName(oSay4), CSS_LABEL_FOCAL ))
  	oDocNf := TGet():New( nHeight-93, 005,{|u| iif( PCount()==0,cDocNf,cDocNf:=u)},oPnlInc,60, 012,,{|| VldNF() },,,,,,.T.,,,{|| .T. },,,,lVincVend,.F.,,"oDocNf",,,,.T.,.F.)
  	oDocNf:SetCSS( POSCSS (GetClassName(oDocNf), CSS_GET_NORMAL ))

	@ nHeight-077, 005 SAY oSay5 PROMPT "Série NF" SIZE 100, 010 OF oPnlInc COLORS 0, 16777215 PIXEL
  	oSay5:SetCSS( POSCSS (GetClassName(oSay4), CSS_LABEL_FOCAL ))
  	oSerieNf := TGet():New( nHeight-068, 005,{|u| iif( PCount()==0,cSerieNf,cSerieNf:=u)},oPnlInc,60, 012,,{|| VldNF() },,,,,,.T.,,,{|| .T. },,,,lVincVend,.F.,,"oSerieNf",,,,.T.,.F.)
  	oSerieNf:SetCSS( POSCSS (GetClassName(oSerieNf), CSS_GET_NORMAL ))

	@ nHeight-102, 070 SAY oSay8 PROMPT "Justificativa / Observações" SIZE 100, 007 OF oPnlInc COLORS 16777215, 0 PIXEL
	oSay8:SetCSS( POSCSS (GetClassName(oSay8), CSS_LABEL_FOCAL ))
	@ nHeight-093, 070 GET oJustif VAR cJustif OF oPnlInc MULTILINE SIZE nWidth-265, 039 COLORS 0, 16777215 PIXEL
	oJustif:SetCSS( POSCSS (GetClassName(oJustif), CSS_GET_NORMAL))

	@ nHeight-115, nWidth-180 SAY oSay9 PROMPT "Dinheiro / Ch.Troco" SIZE 070, 008 OF oPnlInc COLORS 0, 16777215 PIXEL
	oSay9:SetCSS( POSCSS (GetClassName(oSay9), CSS_LABEL_FOCAL ))
	oVlrDin := TGet():New(nHeight-120, nWidth-105,{|u| iif( PCount()==0,nVlrDin,nVlrDin:= u)},oPnlInc,100, 015,"@E 999,999,999.99",{|| Positivo(nVlrDin) .AND. AtuTotais(.T.) },,,,,,.T.,,,{|| .T.},,,,.F.,.F.,,"oVlrDin",,,,.F.,.T.)
	oVlrDin:SetCSS( POSCSS (GetClassName(oVlrDin), CSS_GET_FOCAL ))
	if !lActiveVLH
		oVlrDin:lReadOnly := .T.
	endif

	@ nHeight-094, nWidth-180 SAY oSay10 PROMPT "Vale Haver" SIZE 070, 008 OF oPnlInc COLORS 0, 16777215 PIXEL
	oSay10:SetCSS( POSCSS (GetClassName(oSay10), CSS_LABEL_FOCAL ))
	oVlrVale := TGet():New(nHeight-099, nWidth-105,{|u| iif( PCount()==0,nVlrVale,nVlrVale:= u)},oPnlInc,100, 015,"@E 999,999,999.99",{|| Positivo(nVlrVale) .AND. AtuTotais() },,,,,,.T.,,,{|| .T.},,,,.F.,.F.,,"oVlrVale",,,,.F.,.T.)
	oVlrVale:SetCSS( POSCSS (GetClassName(oVlrVale), CSS_GET_FOCAL ))
	if !lActiveVLH
		oVlrVale:lReadOnly := .T.
	endif

	@ nHeight-073, nWidth-180 SAY oSay11 PROMPT "Valor Total Saída" SIZE 070, 008 OF oPnlInc COLORS 0, 16777215 PIXEL
	oSay11:SetCSS( POSCSS (GetClassName(oSay11), CSS_LABEL_FOCAL ))
	oVlrComp := TGet():New(nHeight-078, nWidth-105,{|u| iif( PCount()==0,nVlrComp,nVlrComp:= u)},oPnlInc,100, 015,"@E 999,999,999.99",{|| .T. },,,,,,.T.,,,{|| .T.},,,,.T.,.F.,,"oVlrComp",,,,.F.,.T.)
	oVlrComp:SetCSS( POSCSS (GetClassName(oVlrComp), CSS_GET_FOCAL ))
	oVlrComp:lReadOnly := .T.

	oBtn1 := TButton():New( nHeight-45,nWidth-75,"Confirmar",oPnlInc,{|| iif(VldIncComp(),iif(bConfirm<>Nil,Eval(bConfirm),),) },070,020,,,,.T.,,,,{|| .T.})
	oBtn1:SetCSS( POSCSS (GetClassName(oBtn1), CSS_BTN_FOCAL ))

	if lConfCash .OR. lVincVend
		oBtn2 := TButton():New( nHeight-45,nWidth-150,"Cancelar",oPnlInc,bCancel,070,020,,,,.T.,,,,{|| .T.})
		oBtn2:SetCSS( POSCSS (GetClassName(oBtn2), CSS_BTN_NORMAL ))
	else
		oBtn2 := TButton():New( nHeight-45,nWidth-150,"Limpar Tela",oPnlInc,{|| U_TPDVA5CL(.T.) },070,020,,,,.T.,,,,{|| .T.})
		oBtn2:SetCSS( POSCSS (GetClassName(oBtn2), CSS_BTN_NORMAL ))

		oBtn3 := TButton():New( nHeight-45,nWidth-225,"Imp. Termo Resp.",oPnlInc,{|| ImpTermoRes() },070,020,,,,.T.,,,,{|| .T.})
		oBtn3:SetCSS( POSCSS (GetClassName(oBtn3), CSS_BTN_NORMAL ))

		oBtn4 := TButton():New( nHeight-45,005,"Listar Compensações",oPnlInc,{|| cTitleTela := "LISTAGEM", oPnlInc:Hide(), oPnlBrow:Show() },080,020,,,,.T.,,,,{|| .T.})
		oBtn4:SetCSS( POSCSS (GetClassName(oBtn4), CSS_BTN_NORMAL ))

		//////////////////////// BROWSE DAS COMPENSACOES //////////////////////////////////////

		//Painel de Browse das compensações
		oPnlBrow := TPanel():New(020,000,"",oPnlGeral,NIL,.T.,.F.,,,nWidth,nHeight-020,,.T.,.F.)
		oPnlBrow:Hide()

		@ 005, 005 SAY oSay12 PROMPT "Compensação" SIZE 100, 010 OF oPnlBrow COLORS 0, 16777215 PIXEL
	  	oSay12:SetCSS( POSCSS (GetClassName(oSay12), CSS_LABEL_FOCAL ))
	  	oBuscaCmp := TGet():New( 015, 005,{|u| iif( PCount()==0,cBuscaCmp,cBuscaCmp:=u) },oPnlBrow, 070, 013,,{|| /*bValid*/ },,,,,,.T.,,,{|| .T. },,,,.F.,.F.,,"oBuscaCmp",,,,.T.,.F.)
	  	oBuscaCmp:SetCSS( POSCSS (GetClassName(oBuscaCmp), CSS_GET_NORMAL ))

		//@ 005, 080 SAY oSay12 PROMPT "CPF/CNPJ Cliente" SIZE 100, 010 OF oPnlBrow COLORS 0, 16777215 PIXEL
	  	//oSay12:SetCSS( POSCSS (GetClassName(oSay12), CSS_LABEL_FOCAL ))
	  	//oBuscaCpf := TGet():New( 015, 080,{|u| iif( PCount()==0,cBuscaCpf,cBuscaCpf:=u) },oPnlBrow, 080, 013,,{|| /*bValid*/ },,,,,,.T.,,,{|| .T. },,,,.F.,.F.,,"cBuscaCpf",,,,.T.,.F.)
		//oBuscaCpf:SetCSS( POSCSS (GetClassName(oBuscaCpf), CSS_GET_NORMAL ))
		//TSearchF3():New(oBuscaCpf,400,250,"SA1","A1_CGC",{{"A1_NOME",2},{"A1_CGC",3},{"A1_COD",1}},"SA1->A1_MSBLQL<>'1'",{{"A1_NOME","A1_EST","A1_MUN"},{"A1_CGC","A1_NOME","A1_EST","A1_MUN"},{"A1_COD","A1_LOJA","A1_NOME","A1_EST","A1_MUN"}},,,0)

		@ 005, 080 SAY oSay12 PROMPT "Código" SIZE 100, 010 OF oPnlBrow COLORS 0, 16777215 PIXEL
		oSay12:SetCSS( POSCSS (GetClassName(oSay12), CSS_LABEL_FOCAL ))
		oBuscaCli := TGet():New( 015, 080,{|u| iif( PCount()==0,cBuscaCod,cBuscaCod:=u) },oPnlBrow, 055, 013, "@!",{|| /*bValid*/ },,,,,,.T.,,,{|| .T. },,,,.F.,.F.,,"oBuscaCli",,,,.T.,.F.)
		oBuscaCli:SetCSS( POSCSS (GetClassName(oBuscaCli), CSS_GET_NORMAL ))

		@ 005, 135 SAY oSay12 PROMPT "Loja" SIZE 100, 010 OF oPnlBrow COLORS 0, 16777215 PIXEL
		oSay12:SetCSS( POSCSS (GetClassName(oSay12), CSS_LABEL_FOCAL ))
		oBuscaLoj := TGet():New( 015, 135,{|u| iif( PCount()==0,cBuscaLoj,cBuscaLoj:=u) },oPnlBrow, 020, 013, "@!",{|| /*bValid*/ },,,,,,.T.,,,{|| .T. },,,,.F.,.F.,,"oBuscaLoj",,,,.T.,.F.)
		oBuscaLoj:SetCSS( POSCSS (GetClassName(oBuscaLoj), CSS_GET_NORMAL ))
		TSearchF3():New(oBuscaCli,400,250,"SA1","A1_COD",{{"A1_NOME",2},{"A1_CGC",3},{"A1_COD",1}},"SA1->A1_MSBLQL<>'1'",{{"A1_COD","A1_LOJA","A1_NOME","A1_EST","A1_MUN"},{"A1_COD","A1_LOJA","A1_CGC","A1_NOME","A1_EST","A1_MUN"},{"A1_COD","A1_LOJA","A1_NOME","A1_EST","A1_MUN"}},,,iif(lConfCash,-40,0)/*nAjustPos*/,,{{oBuscaLoj,"A1_LOJA"}})

	  	@ 005, 165 SAY oSay5 PROMPT "Placa" SIZE 100, 010 OF oPnlBrow COLORS 0, 16777215 PIXEL
	  	oSay5:SetCSS( POSCSS (GetClassName(oSay5), CSS_LABEL_FOCAL ))
	  	oBuscaPlaca := TGet():New( 015, 165,{|u| iif( PCount()==0,cBuscaPlaca,cBuscaPlaca:=u) },oPnlBrow,50, 013,"@!R NNN-9N99",{|| /*bValid*/ },,,,,,.T.,,,{|| .T. },,,,.F.,.F.,,"cBuscaPlaca",,,,.T.,.F.)
	  	oBuscaPlaca:SetCSS( POSCSS (GetClassName(oBuscaPlaca), CSS_GET_NORMAL ))

	  	@ 005, 220 SAY oSay13 PROMPT "Data" SIZE 035, 008 OF oPnlBrow COLORS 0, 16777215 PIXEL
		oSay13:SetCSS( POSCSS (GetClassName(oSay13), CSS_LABEL_FOCAL ))
		@ 015, 220 MSGET oBuscaDt VAR dBuscaDt SIZE 070, 013 OF oPnlBrow VALID .T. PICTURE "@!" COLORS 0, 16777215 /*FONT oFntGetCab*/ HASBUTTON PIXEL
		oBuscaDt:SetCSS( POSCSS (GetClassName(oBuscaDt), CSS_GET_NORMAL ))

		oBtn5 := TButton():New( 015, 295,"Buscar",oPnlBrow,{|| BuscaCmp() },040,015,,,,.T.,,,,{|| .T.})
		oBtn5:SetCSS( POSCSS (GetClassName(oBtn5), CSS_BTN_FOCAL ))

		//GRID
		@ 035, 003 MSPANEL oPnlGrid2 SIZE nWidth-4, nHeight-80 OF oPnlBrow

		@ 000,000 BITMAP oTop RESOURCE "x.png" NOBORDER SIZE 000,005 OF oPnlGrid2 ADJUST PIXEL
		oTop:Align := CONTROL_ALIGN_TOP
		//oTop:SetCSS( POSCSS (GetClassName(oTop), CSS_PANEL_HEADER ))
		oTop:SetCSS("TBitmap{ margin: 0px 9px 0px 5px; border: 1px solid #"+cCorBg+"; background-color: #"+cCorBg+"; border-top-right-radius: 8px; border-top-left-radius: 8px; }")
		oTop:ReadClientCoors(.T.,.T.)

		@ 000,000 BITMAP oBottom RESOURCE "x.png" NOBORDER SIZE 000,025 OF oPnlGrid2 ADJUST PIXEL
		oBottom:Align := CONTROL_ALIGN_BOTTOM
		oBottom:SetCSS( POSCSS (GetClassName(oBottom), CSS_PANEL_FOOTER ) )
		oBottom:ReadClientCoors(.T.,.T.)

		@ 000,000 BITMAP oContent RESOURCE "x.png" NOBORDER SIZE 000,000 OF oPnlGrid2 ADJUST PIXEL
		oContent:Align := CONTROL_ALIGN_ALLCLIENT
		oContent:ReadClientCoors(.T.,.T.)
		oPnlAux2 := POSBrwContainer(oContent)

		oMsGetCmp := MsNewGetEst(oPnlAux2, 053, 090, 150, nWidth-5)
		oMsGetCmp:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT
		oMsGetCmp:oBrowse:SetCSS( StrTran(POSCSS("TGRID", CSS_BROWSE),"gridline-color: white;","") ) //CSS do totvs pdv
		//oMsGetCmp:oBrowse:lCanGotFocus := .F.
		oMsGetCmp:oBrowse:nScrollType := 0
		//oMsGetCmp:oBrowse:lHScroll := .F.
		oMsGetCmp:oBrowse:bLDblClick := {|| ViewCmp() }

		@ (oPnlGrid2:nHeight/2)-22, 010 SAY oQtdReg PROMPT (cValToChar(nQtdReg)+" registros encontrados.") SIZE 150, 010 OF oPnlGrid2 COLORS 0, 16777215 PIXEL
		oQtdReg:SetCSS( POSCSS (GetClassName(oQtdReg), CSS_LABEL_NORMAL))
		@ (oPnlGrid2:nHeight/2)-21, nWidth-090 BITMAP oLeg ResName "BR_VERDE" OF oPnlGrid2 Size 10, 10 NoBorder When .F. PIXEL
		@ (oPnlGrid2:nHeight/2)-22, nWidth-080 SAY oSay14 PROMPT "Ativo" OF oPnlGrid2 Color CLR_BLACK PIXEL
		oSay14:SetCSS( POSCSS (GetClassName(oSay14), CSS_LABEL_NORMAL))
		@ (oPnlGrid2:nHeight/2)-21, nWidth-055 BITMAP oLeg ResName "BR_PRETO" OF oPnlGrid2 Size 10, 10 NoBorder When .F. PIXEL
		@ (oPnlGrid2:nHeight/2)-22, nWidth-045 SAY oSay14 PROMPT "Estornado" OF oPnlGrid2 Color CLR_BLACK PIXEL
		oSay14:SetCSS( POSCSS (GetClassName(oSay14), CSS_LABEL_NORMAL))

		oBtn6 := TButton():New( nHeight-45,005,"Incluir",oPnlBrow,{|| oPnlInc:Show(), oPlaca:SetFocus(), oPnlBrow:Hide(),U_TPDVA5CL(.T.) },060,020,,,,.T.,,,,{|| .T.})
		oBtn6:SetCSS( POSCSS (GetClassName(oBtn6), CSS_BTN_FOCAL ))

		oBtn7 := TButton():New( nHeight-45,070,"Estornar",oPnlBrow,{|| EstornaCmp() },060,020,,,,.T.,,,,{|| .T.})
		oBtn7:SetCSS( POSCSS (GetClassName(oBtn7), CSS_BTN_NORMAL ))

		oBtn10 := TButton():New( nHeight-45,135,"Visualizar",oPnlBrow,{|| ViewCmp() },060,020,,,,.T.,,,,{|| .T.})
		oBtn10:SetCSS( POSCSS (GetClassName(oBtn10), CSS_BTN_NORMAL ))

		oBtn8 := TButton():New( nHeight-45,200,"Imprimir",oPnlBrow,{|| MsgRun("Aguarde... Imprimindo...","Processando...",{|| ImpCompIF(.T.) }) },060,020,,,,.T.,,,,{|| .T.})
		oBtn8:SetCSS( POSCSS (GetClassName(oBtn8), CSS_BTN_NORMAL ))

		oBtn9 := TButton():New( nHeight-45,265,"Imp. Termo Resp.",oPnlBrow,{|| ImpTermoRes(.T.) },070,020,,,,.T.,,,,{|| .T.})
		oBtn9:SetCSS( POSCSS (GetClassName(oBtn9), CSS_BTN_NORMAL ))

	endif

	oPlaca:SetFocus()

	if lConfCash
		if nOpcX == 2
			ViewCmp()
		else
			U_TPDVA5CL(.T.)
		endif
	endif

Return cUsrCmp

//-----------------------------------------------------------------------------------------
// Monta grid NewGetDados de Entrada
//-----------------------------------------------------------------------------------------
Static Function MsNewGetEnt(oPnl, nTop, nLeft, nBottom, nRight)

	Local aHeaderEx 	:= {}
	Local aColsEx 		:= {}
	Local aFieldFill 	:= {}
	Local aAlterFields 	:= {}

	Aadd(aHeaderEx, {"Valor"	,"VALOR",PesqPict("SL4","L4_VALOR"),TamSX3("L4_VALOR")[1],TamSX3("L4_VALOR")[2],"","€€€€€€€€€€€€€€","N","","","",""})
	Aadd(aFieldFill, 0)

	Aadd(aHeaderEx, {"Data","DATA","",8,0,"","€€€€€€€€€€€€€€","D","","","",""})
	Aadd(aFieldFill, STOD(""))

	Aadd(aHeaderEx, {"Forma Pg.","FORMPG","@!",6,0,"","€€€€€€€€€€€€€€","C","","","",""})
	Aadd(aFieldFill, space(6))

	Aadd(aHeaderEx, {"Descricao","DESCRICAO","@!",20,0,"","€€€€€€€€€€€€€€","C","","","",""})
	Aadd(aFieldFill, space(20))

	Aadd(aFieldFill, Nil)//inf complementares
	Aadd(aFieldFill, .F.)//delete

	Aadd(aColsEx, aFieldFill)

Return MsNewGetDados():New( nTop, nLeft, nBottom, nRight, GD_DELETE , "AllwaysTrue", "AllwaysTrue", "+Field1+Field2", aAlterFields,, 999, "AllwaysTrue", "", "U_TPDVA05D()", oPnl, aHeaderEx, aColsEx)

//-----------------------------------------------------------------------------------------
// Monta grid NewGetDados de Estorno
//-----------------------------------------------------------------------------------------
Static Function MsNewGetEst(oPnl, nTop, nLeft, nBottom, nRight)

	Local aHeaderEx 	:= {}
	Local aColsEx 		:= {}
	Local aAlterFields 	:= {}
	Local aFields 		:= {"UC0_NUM","UC0_DATA","UC0_HORA","A1_CGC","A1_NOME","UC0_PLACA","UC0_PDV","UC0_VLDINH","UC0_VLCHTR","UC0_VLVALE","UC0_VLTOT"}
	Local aFieldFill 	:= {}
	Local nX

	// a primeira coluna do grid é legenda
	Aadd(aHeaderEx,{Space(10),'LEGENDA','@BMP',2,0,'','€€€€€€€€€€€€€€','C','','','',''})
	Aadd(aFieldFill, "BR_BRANCO")

	if UC0->(FieldPos("UC0_DOC")) > 0 .AND. UC0->(FieldPos("UC0_SERIE")) > 0
		aadd(aFields, "UC0_DOC")
		aadd(aFields, "UC0_SERIE")
	endif

	For nX:=1 to Len(aFields)
		aadd(aHeaderEx, U_UAHEADER(aFields[nX]) )
	Next nX

	For nX := 2 to Len(aHeaderEx)
		if aHeaderEx[nX][8] == "N"
			Aadd(aFieldFill, 0)
		elseif aHeaderEx[nX][8] == "D"
			Aadd(aFieldFill, stod(""))
		ElseIf aHeaderEx[nX][8] == "L"
			Aadd(aFieldFill,.F.)
		else
			Aadd(aFieldFill, "")
		endif
	Next nX

	Aadd(aFieldFill, 0) //recno
	Aadd(aFieldFill, .F.)
	Aadd(aColsEx, aFieldFill)

Return MsNewGetDados():New( nTop, nLeft, nBottom, nRight, , "AllwaysTrue", "AllwaysTrue", "+Field1+Field2", aAlterFields,, 999, "AllwaysTrue", "", "AllwaysTrue", oPnl, aHeaderEx, aColsEx)

//--------------------------------------------------------
// Validação e gatilho do cliente
//--------------------------------------------------------
Static Function VldCliente()

	Local cMsgErr := ""
	Local lRet := .T.
	Local lBlqAI0 		:= SuperGetMv("MV_XBLQAI0",,.F.) .AND. AI0->(FieldPos("AI0_XBLFIL")) > 0 //Habilita bloqueio de venda na filial, olhando para tabela AI0
	Local lActiveVLH := SuperGetMV("TP_ACTVLH",,.F.)

	if empty(cCodCli) .or. empty(cLojCli)
		//cNomCli := space(tamsx3("A1_NOME")[1])
		//cCodCli := space(tamsx3("A1_COD")[1])
		//cLojCli := space(tamsx3("A1_LOJA")[1])
		Return lRet
	else
		cNomCli := Posicione("SA1",1,xFilial("SA1")+cCodCli+cLojCli,"A1_NOME")
		if empty(cNomCli)
			lRet := .F.
			cMsgErr := "Cliente não cadastrado!"
		elseif !lCMPCPAD .AND. SA1->A1_COD+SA1->A1_LOJA == GETMV("MV_CLIPAD")+GETMV("MV_LOJAPAD")
			lRet := .F.
			cMsgErr := "Não é permitido fazer compensações para o cliente padrão."
		
		// verifico se o cadastro tem autorização para ser utilizado nesta filial/empresa
		elseif lBlqAI0 .AND. Posicione("AI0",1,xFilial("AI0")+SA1->A1_COD+SA1->A1_LOJA,"AI0_XBLFIL")=="S"
			lRet := .F.
			cMsgErr :=  "O cliente "+SA1->A1_COD+"/"+SA1->A1_LOJA+" não está autorizado nesta filial."
		elseIf !lBlqAI0 .AND. SA1->(FieldPos("A1_XFILBLQ")) > 0 .and. !Empty(SA1->A1_XFILBLQ) .and. (cFilAnt $ SA1->A1_XFILBLQ)
			lRet := .F.
			cMsgErr :=  "O cliente "+SA1->A1_COD+"/"+SA1->A1_LOJA+" não está autorizado nesta filial."
		endif
	endif

	if lRet
		oNomCli:Refresh()

		if lActiveVLH 
			if SA1->A1_COD+SA1->A1_LOJA == GETMV("MV_CLIPAD")+GETMV("MV_LOJAPAD")
				oVlrDin:lReadOnly := .T.
				oVlrVale:lReadOnly := .T.
				nVlrVale := 0
				AtuTotais()
			else
				oVlrDin:lReadOnly := .F.
				oVlrVale:lReadOnly := .F.
			endif
			oVlrDin:Refresh()
			oVlrVale:Refresh()
		endif
	endif

	if lConfCash .OR. lVincVend
		if !empty(cMsgErr)
			MsgInfo(cMsgErr, "Atenção")
		endif
	else
		U_SetMsgRod(cMsgErr)
	endif

Return lRet

//----------------------------------------------------------
// Valida placa e faz gatilho quando ha amarracao com cliente
//----------------------------------------------------------
Static Function VldPlaca()

	Local lRet := .T.
	Local aCliByGrp := {}
	Local nPosCliGrp := 1
	Local lBlqAI0 	:= SuperGetMv("MV_XBLQAI0",,.F.) .AND. AI0->(FieldPos("AI0_XBLFIL")) > 0 //Habilita bloqueio de venda na filial, olhando para tabela AI0

	if !empty(cPlaca)

		DbSelectArea("DA3")
		DA3->(DbSetOrder(3)) //DA3_FILIAL+DA3_PLACA
		if DA3->(DbSeek(xFilial("DA3")+cPlaca ))
			if empty(cCodCli) .OR. (Alltrim(cCodCli) == AllTrim(GetMv("MV_CLIPAD")) .AND. Alltrim(cLojCli) == AllTrim(GetMv("MV_LOJAPAD")))
				if !empty(DA3->DA3_XCODCL) .AND. !empty(Posicione("SA1",1,xFilial("SA1")+DA3->DA3_XCODCL+DA3->DA3_XLOJCL,"A1_COD"))
					
					cCodCli := SA1->A1_COD
					cLojCli := SA1->A1_LOJA
				
				elseif !empty(DA3->DA3_XGRPCL)

					SA1->(DbSetOrder(6)) //A1_FILIAL+A1_GRPVEN
					If SA1->(DbSeek(xFilial("SA1")+DA3->DA3_XGRPCL)) 
						While SA1->(!Eof()) .AND. SA1->A1_FILIAL+SA1->A1_GRPVEN == xFilial("SA1")+DA3->DA3_XGRPCL
							// verifico se o cadastro tem autorização para ser utilizado nesta filial/empresa
							If lBlqAI0 .AND. Posicione("AI0",1,xFilial("AI0")+SA1->A1_COD+SA1->A1_LOJA,"AI0_XBLFIL")=="S"
							ElseIf !lBlqAI0 .AND. SA1->(FieldPos("A1_XFILBLQ")) > 0 .and. !Empty(SA1->A1_XFILBLQ) .and. (cFilAnt $ SA1->A1_XFILBLQ)
							Else
								aadd(aCliByGrp, {SA1->A1_COD, SA1->A1_LOJA, SA1->A1_NOME, SA1->A1_MUN, SA1->A1_EST, SA1->A1_CGC } )
							EndIf
							SA1->(DbSkip())
						EndDo
					EndIf
					If len(aCliByGrp) > 0
						aSort(aCliByGrp,,,{|x,y| x[1]+x[2] < y[1]+y[2]}) //ordem crescente: A1_COD + A1_LOJA
						If len(aCliByGrp) > 1
							//abrir tela para seleçao cliente
							nPosCliGrp := U_TPDVP08B(aCliByGrp, DA3->DA3_XGRPCL, cPlaca)
						EndIf
						cCodCli := aCliByGrp[nPosCliGrp][1]
						cLojCli := aCliByGrp[nPosCliGrp][2]
					EndIf

				endif

				if !empty(cCodCli)
					oCodCli:Refresh()
					oLojCli:Refresh()
					lRet := VldCliente()
				endif
				
			endif
		endif
	endif

Return lRet

//----------------------------------------------------------
// Valida placa e faz gatilho quando ha amarracao com cliente
//----------------------------------------------------------
Static Function VldVend()

	Local cMsgErr := ""
	Local lRet := .T.

	if empty(cVendedor)
		cNomVend := ""
	else
		SA3->(DbSetOrder(1))
		If SA3->(DbSeek(xFilial("SA3") + cVendedor))
			If U_TPDVP23A(cVendedor)
				cNomVend := SA3->A3_NOME
			else
				lRet := .F.
				cMsgErr := "O cargo (A3_CARGO) do vendedor "+SA3->A3_COD+"-"+AllTrim(SA3->A3_NOME)+" não está liberado para ser utilizado no PDV."
			EndIf
		else
			cMsgErr := "Vendedor não cadastrado!"
			lRet := .F.
		EndIf
	endif

	if lRet
		oNomVend:Refresh()
	endif

	if lConfCash .OR. lVincVend
		if !empty(cMsgErr)
			MsgInfo(cMsgErr, "Atenção")
		endif
	else
		U_SetMsgRod(cMsgErr)
	endif

Return lRet

/*/{Protheus.doc} TPDVA5CL
Função para limpar e resetar tela.
@author thebr
@since 30/04/2019
@version 1.0
@return Nil
@type function
/*/
User Function TPDVA5CL(lNoBrowse)

	Local lMvPswVend := SuperGetMv("TP_PSWVEND",,.F.)
	Default lNoBrowse := .F.

	if !lConfCash .AND. empty(cUsrCmp) //se nao tem acesso, nao criou componentes
		Return
	endif

	lOnlyView := .F.
	oVendedor:lReadOnly := .F.
	oCodCli:lReadOnly := .F.
	oLojCli:lReadOnly := .F.
	oPlaca:lReadOnly := .F.
	oJustif:lReadOnly := .F.
	oDocNf:lReadOnly := .F.
	oSerieNf:lReadOnly := .F.
	cTitleTela := "INCLUSÃO"
	cNumCmp := "INCLUINDO"//Space(TamSX3("UC0_NUM")[1])
	cVendedor := Space(TamSX3("UC0_VEND")[1])
	cNomVend := ""
	cCodCli := Space(TamSX3("A1_COD")[1])
	cLojCli := Space(TamSX3("A1_LOJA")[1])
	cNomCli := space(tamsx3("A1_NOME")[1])
	cPlaca := Space(TamSX3("UC0_PLACA")[1])
	nVlrForm := 0
	cJustif := ""
	cDocNf := Space(TamSX3("L1_DOC")[1])
	cSerieNf := Space(TamSX3("L1_SERIE")[1])
	nVlrDin := 0
	nVlrVale := 0
	nVlrComp := 0
	lRetOn := .F.
	aLogAlcada := {}

	ClearGrid(oMsGetEnt)

	If !lNoBrowse //flag para nao limpar browse
		cBuscaCmp := Space(TamSX3("UC0_NUM")[1])
		dBuscaDt  := dDataBase
		cBuscaCod := Space(TamSX3("A1_COD")[1])
		cBuscaLoj := Space(TamSX3("A1_LOJA")[1])
		nQtdReg := 0
		ClearGrid(oMsGetCmp)
	EndIf

	if !lConfCash .AND. lMvPswVend
		cVendedor := U_TPGetVend()
		cNomVend  := U_TPGetVend(2)
	else
		SA3->(DbSetOrder(7)) // A3_FILIAL + A3_CODUSR
		If SA3->(DbSeek(xFilial("SA3") + RETCODUSR()))
			cVendedor := SA3->A3_COD
			cNomVend := SA3->A3_NOME
		else
			SA3->(DbSetOrder(1))
			If SA3->(DbSeek(xFilial("SA3") + GetMV("MV_VENDPAD") ))
				cVendedor := SA3->A3_COD
				cNomVend  := SA3->A3_NOME
			endif
		EndIf
	endif

	if !lConfCash .AND. !lVincVend

		U_SetMsgRod("")

		if oPnlBrow:lVisible
			oBuscaCmp:SetFocus()
		else
			oPlaca:SetFocus()
		endif
	endif

Return

//------------------------------------------------------
// função que faz limpeza do grid.
//------------------------------------------------------
Static Function ClearGrid(oGrid)

	Local nX := 0
	Local aFieldFill := {}

	oGrid:aCols := {}

	For nX := 1 to Len(oGrid:aHeader)
		if oGrid:aHeader[nX][2] == "LEGENDA"
			Aadd(aFieldFill, "BR_BRANCO")
		else
			If oGrid:aHeader[nX][8] == "N"
				Aadd(aFieldFill,0)
			ElseIf oGrid:aHeader[nX][8] == "D"
				Aadd(aFieldFill,CTOD(""))
			ElseIf oGrid:aHeader[nX][8] == "L"
				Aadd(aFieldFill,.F.)
			Else
				Aadd(aFieldFill,"")
			EndIf
		EndIf
	Next nX

	Aadd(aFieldFill, 0) //recno
	Aadd(aFieldFill, .F.)

	aadd(oGrid:aCols, aFieldFill)

	oGrid:oBrowse:Refresh()

Return

//----------------------------------------------------------
// Deletar linha
//----------------------------------------------------------
User Function TPDVA05D()

	oMsGetEnt:aCols[oMsGetEnt:nAt][NPOSDEL] := !oMsGetEnt:aCols[oMsGetEnt:nAt][NPOSDEL]
	AtuTotais()
	oMsGetEnt:aCols[oMsGetEnt:nAt][NPOSDEL] := !oMsGetEnt:aCols[oMsGetEnt:nAt][NPOSDEL]

Return .T.

//----------------------------------------------------------
// Atualização dos totais
//----------------------------------------------------------
Static Function AtuTotais(lCpDin)

	Local lRet := .T.
	Local nX := 0
	Local lActiveVLH := SuperGetMV("TP_ACTVLH",,.F.)
	Default lCpDin := .F.

	nVlrForm := 0

	For nX := 1 to len(oMsGetEnt:aCols)
		if !oMsGetEnt:aCols[nX][NPOSDEL]
			nVlrForm += oMsGetEnt:aCols[nX][NPOSVLR]
		endif
	next nX

	oVlrForm:Refresh()
	if lCpDin
		if lActiveVLH
			nVlrVale := nVlrForm - nVlrDin
			if nVlrVale < 0
				nVlrVale := 0
			endif
		endif
	else
		if lActiveVLH .AND. nVlrVale > 0
			nVlrDin := nVlrForm - nVlrVale
		else
			nVlrDin := nVlrForm
		endif
	endif

	nVlrComp := nVlrDin + nVlrVale
	oVlrComp:Refresh()
	oVlrDin:Refresh()
	oVlrVale:Refresh()

Return lRet

//-----------------------------------------------------------------------
// Chama alteração das formas de pagamento
//-----------------------------------------------------------------------
Static Function AltForma()

	Local cForma := oMsGetEnt:aCols[oMsGetEnt:nAt][NPOSFPG]

	if cForma == "CH"
		ViewCheck(.T.)
	elseif cForma $ "CC,CD"
		ViewCard(.T.)
	elseif cForma == "CF"
		ViewCFrete(.T.)
	endif

Return

//--------------------------------------------------------------------
// Inclusão de uma parcela de Cheque
//--------------------------------------------------------------------
Static Function ViewCheck(lAlt)

	Local aInfComp
	Local nOpcx := 0
	Local nWidth, nHeight
	Local oPnlChk, oPnlTop
	Local bCloseChk := {|| oDlgCH:end() }

	Default lAlt := .F.

	Private nValorCh := 0
	Private dDataCh := stod("")
	Private cCgcEmit := Space(TamSX3("UC1_CGC")[1])
	Private cCodEmit := Space(TamSX3("A1_COD")[1])
	Private cLojEmit := Space(TamSX3("A1_LOJA")[1])
	Private cNomeEmit := ""
	Private cCmc7 := Space(TamSX3("UC1_CMC7")[1])
	Private cBanco := Space(TamSX3("UC1_BANCO")[1])
	Private cAgencia := Space(TamSX3("UC1_AGENCI")[1])
	Private cConta := Space(TamSX3("UC1_CONTA")[1])
	Private cNumCh := Space(TamSX3("UC1_NUMCH")[1])
	Private cRG := Space(TamSX3("UC1_RG")[1])
	Private cTel := Space(TamSX3("UC1_TEL1")[1])
	Private cComp := Space(TamSX3("UC1_COMPEN")[1])
	Private cHelpCh := ""
	Private oHelpCh
	Private oDlgCH

	if lAlt .OR. lOnlyView
		aInfComp := oMsGetEnt:aCols[oMsGetEnt:nAt][NPOSINF]
		nValorCh := aInfComp[1]
		dDataCh := aInfComp[2]
		cCgcEmit := aInfComp[3]
		cCodEmit := aInfComp[13]
		cLojEmit := aInfComp[14]
		cNomeEmit := aInfComp[4]
		cCmc7 := aInfComp[5]
		cBanco := aInfComp[6]
		cAgencia := aInfComp[7]
		cConta := aInfComp[8]
		cNumCh := aInfComp[9]
		cRG := aInfComp[10]
		cTel := aInfComp[11]
		cComp := aInfComp[12]
	endif

	DEFINE MSDIALOG oDlgCH TITLE "" FROM 000,000 TO 400,550 PIXEL STYLE nOr(WS_VISIBLE, WS_POPUP)

	nWidth := (oDlgCH:nWidth/2)
	nHeight := (oDlgCH:nHeight/2)

	@ 000, 000 MSPANEL oPnlChk SIZE nWidth, nHeight OF oDlgCH
	oPnlChk:SetCSS( "TPanel{border: 2px solid #999999; background-color: #f4f4f4;}" )

	@ 000, 000 MSPANEL oPnlTop SIZE nWidth, 017 OF oPnlChk
	oPnlTop:SetCSS( POSCSS (GetClassName(oPnlTop), CSS_BAR_TOP ))
	@ 004, 005 SAY oSay1 PROMPT (iif(lOnlyView,"Visualização",iif(lAlt,"Alteração","Inclusão"))+" de Cheque") SIZE 100, 015 OF oPnlTop COLORS 0, 16777215 PIXEL
	oSay1:SetCSS( POSCSS (GetClassName(oSay1), CSS_BREADCUMB ))
	oClose := TBtnBmp2():New( 002,oDlgCH:nWidth-25,20,30,'FWSKIN_DELETE_ICO',,,,bCloseChk,oPnlTop,,,.T. )
	oClose:SetCss("TBtnBmp2{border: none;background-color: none;}")

	@ 025, 010 SAY oSay1 PROMPT "Valor do Cheque" SIZE 70, 008 OF oPnlChk COLORS 0, 16777215 PIXEL
	oSay1:SetCSS( POSCSS (GetClassName(oSay1), CSS_LABEL_FOCAL ))
	oValorCh := TGet():New( 035, 010,{|u| iif( PCount()==0,nValorCh,nValorCh:=u)},oPnlChk,80, 013,PesqPict("UC1","UC1_VALOR"),{|| .T. },,,,,,.T.,,,{|| .T. },,,,lOnlyView,.F.,,"nValorCh",,,,.F.,.T.)
	oValorCh:SetCSS( POSCSS (GetClassName(oValorCh), CSS_GET_NORMAL ))

	@ 025, 095 SAY oSay2 PROMPT "Data Venc." SIZE 070, 007 OF oPnlChk COLORS 0, 16777215 PIXEL
  	oSay2:SetCSS( POSCSS (GetClassName(oSay2), CSS_LABEL_FOCAL ))
  	oDataCh := TGet():New( 35, 095,{|u| iif( PCount()==0,dDataCh,dDataCh:=u)},oPnlChk,70, 013,,{|| .T./*bValid*/ },,,,,,.T.,,,{|| .T. },,,,lOnlyView,.F.,,"dDataCh",,,,.T.,.F.)
  	oDataCh:SetCSS( POSCSS (GetClassName(oDataCh), CSS_GET_NORMAL ))

  	//@ 055, 010 SAY oSay3 PROMPT "CPF/CNPJ do Emitente" SIZE 100, 010 OF oPnlChk COLORS 0, 16777215 PIXEL
  	//oSay3:SetCSS( POSCSS (GetClassName(oSay3), CSS_LABEL_FOCAL ))
  	//oCgcEmit := TGet():New( 65, 010,{|u| iif( PCount()==0,cCgcEmit,cCgcEmit:=u)},oPnlChk,85, 013,,{|| VldEmitChq() },,,,,,.T.,,,{|| .T. },,,,lOnlyView,.F.,,"cCgcEmit",,,,.T.,.F.)
  	//oCgcEmit:SetCSS( POSCSS (GetClassName(oCgcEmit), CSS_GET_NORMAL ))
	//TSearchF3():New(oCgcEmit,oDlgCH:nWidth-50,210,"SA1","A1_CGC",{{"A1_NOME",2},{"A1_CGC",3},{"A1_COD",1}},"SA1->A1_MSBLQL<>'1'"+iif(SA1->(FieldPos("A1_XEMCHQ"))>0," .AND. SA1->A1_XEMCHQ='S'",""),{{"A1_NOME","A1_EST","A1_MUN"},{"A1_CGC","A1_NOME","A1_EST","A1_MUN"},{"A1_COD","A1_LOJA","A1_NOME","A1_EST","A1_MUN"}},,,iif(lConfCash,-60,0))

	@ 055, 010 SAY oSay3 PROMPT "Código" SIZE 100, 010 OF oPnlChk COLORS 0, 16777215 PIXEL
	oSay3:SetCSS( POSCSS (GetClassName(oSay3), CSS_LABEL_FOCAL ))
	oCodEmit := TGet():New( 065, 010,{|u| iif( PCount()==0,cCodEmit,cCodEmit:=u) },oPnlChk, 055, 013, "@!",{|| VldEmitChq() },,,,,,.T.,,,{|| .T. },,,,.F.,.F.,,"oCodEmit",,,,.T.,.F.)
	oCodEmit:SetCSS( POSCSS (GetClassName(oCodEmit), CSS_GET_NORMAL ))

	@ 055, 065 SAY oSay3 PROMPT "Loja" SIZE 100, 010 OF oPnlChk COLORS 0, 16777215 PIXEL
	oSay3:SetCSS( POSCSS (GetClassName(oSay3), CSS_LABEL_FOCAL ))
	oLojEmit := TGet():New( 065, 065,{|u| iif( PCount()==0,cLojEmit,cLojEmit:=u) },oPnlChk, 020, 013, "@!",{|| VldEmitChq() },,,,,,.T.,,,{|| .T. },,,,.F.,.F.,,"oLojEmit",,,,.T.,.F.)
	oLojEmit:SetCSS( POSCSS (GetClassName(oLojEmit), CSS_GET_NORMAL ))

  	@ 055, 95 SAY oSay4 PROMPT "Nome do Emitente" SIZE 070, 010 OF oPnlChk COLORS 0, 16777215 PIXEL
  	oSay4:SetCSS( POSCSS (GetClassName(oSay4), CSS_LABEL_FOCAL ))
  	oNomeEmit := TGet():New( 65, 95,{|u| iif( PCount()==0,cNomeEmit,cNomeEmit:=u)},oPnlChk,nWidth-105, 013,,{|| .T./*bValid*/ },,,,,,.T.,,,{|| .T. },,,,.T.,.F.,,"cNomeEmit",,,,.T.,.F.)
  	oNomeEmit:SetCSS( POSCSS (GetClassName(oNomeEmit), CSS_GET_NORMAL ))
	oNomeEmit:lCanGotFocus := .F.
	TSearchF3():New(oCodEmit,oDlgCH:nWidth-50,210,"SA1","A1_COD",{{"A1_NOME",2},{"A1_CGC",3},{"A1_COD",1}},"SA1->A1_MSBLQL<>'1'"+iif(SA1->(FieldPos("A1_XEMCHQ"))>0," .AND. SA1->A1_XEMCHQ='S'",""),{{"A1_COD","A1_LOJA","A1_NOME","A1_EST","A1_MUN"},{"A1_COD","A1_LOJA","A1_CGC","A1_NOME","A1_EST","A1_MUN"},{"A1_COD","A1_LOJA","A1_NOME","A1_EST","A1_MUN"}},,,iif(lConfCash,-60,0)/*nAjustPos*/,,{{oLojEmit,"A1_LOJA"},{oNomeEmit,"A1_NOME"}})

  	@ 085, 010 SAY oSay5 PROMPT "Código de Barras CMC7" SIZE 100, 010 OF oPnlChk COLORS 0, 16777215 PIXEL
  	oSay5:SetCSS( POSCSS (GetClassName(oSay5), CSS_LABEL_FOCAL ))
  	oCmc7 := TGet():New( 095, 010,{|u| iif( PCount()==0,cCmc7,cCmc7:=u)},oPnlChk,nWidth-020, 013,,{|| VldCMC7Chq() .AND. oPnlChk:Refresh() },,,,,,.T.,,,{|| .T. },,,,lOnlyView,.F.,,"cCmc7",,,,.T.,.F.)
  	oCmc7:SetCSS( POSCSS (GetClassName(oCmc7), CSS_GET_NORMAL ))

  	@ 115, 010 SAY oSay6 PROMPT "Banco" SIZE 50, 010 OF oPnlChk COLORS 0, 16777215 PIXEL
  	oSay6:SetCSS( POSCSS (GetClassName(oSay6), CSS_LABEL_FOCAL ))
  	oBanco := TGet():New( 125, 010,{|u| iif( PCount()==0,cBanco,cBanco:=u)},oPnlChk,35, 013,,{|| .T./*bValid*/ },,,,,,.T.,,,{|| .T. },,,,lOnlyView,.F.,,"cBanco",,,,.T.,.F.)
  	oBanco:SetCSS( POSCSS (GetClassName(oBanco), CSS_GET_NORMAL ))

  	@ 115, 050 SAY oSay7 PROMPT "Agência" SIZE 50, 010 OF oPnlChk COLORS 0, 16777215 PIXEL
  	oSay7:SetCSS( POSCSS (GetClassName(oSay7), CSS_LABEL_FOCAL ))
  	oAgencia := TGet():New( 125, 050,{|u| iif( PCount()==0,cAgencia,cAgencia:=u)},oPnlChk,40, 013,,{|| .T./*bValid*/ },,,,,,.T.,,,{|| .T. },,,,lOnlyView,.F.,,"cAgencia",,,,.T.,.F.)
  	oAgencia:SetCSS( POSCSS (GetClassName(oAgencia), CSS_GET_NORMAL ))

  	@ 115, 095 SAY oSay8 PROMPT "Conta" SIZE 070, 010 OF oPnlChk COLORS 0, 16777215 PIXEL
  	oSay8:SetCSS( POSCSS (GetClassName(oSay8), CSS_LABEL_FOCAL ))
  	oConta := TGet():New( 125, 095,{|u| iif( PCount()==0,cConta,cConta:=u)},oPnlChk,070, 013,,{|| .T./*bValid*/ },,,,,,.T.,,,{|| .T. },,,,lOnlyView,.F.,,"cConta",,,,.T.,.F.)
  	oConta:SetCSS( POSCSS (GetClassName(oConta), CSS_GET_NORMAL ))

  	@ 115, 170 SAY oSay9 PROMPT "Num. Cheque" SIZE 070, 010 OF oPnlChk COLORS 0, 16777215 PIXEL
  	oSay9:SetCSS( POSCSS (GetClassName(oSay9), CSS_LABEL_FOCAL ))
  	oNumCh := TGet():New( 125, 170,{|u| iif( PCount()==0,cNumCh,cNumCh:=u)},oPnlChk,070, 013,,{|| .T./*bValid*/ },,,,,,.T.,,,{|| .T. },,,,lOnlyView,.F.,,"cNumCh",,,,.T.,.F.)
  	oNumCh:SetCSS( POSCSS (GetClassName(oNumCh), CSS_GET_NORMAL ))

  	@ 145, 010 SAY oSay10 PROMPT "R.G." SIZE 50, 010 OF oPnlChk COLORS 0, 16777215 PIXEL
  	oSay10:SetCSS( POSCSS (GetClassName(oSay10), CSS_LABEL_FOCAL ))
  	oRG := TGet():New( 155, 010,{|u| iif( PCount()==0,cRG,cRG:=u)},oPnlChk,80, 013,,{|| .T. },,,,,,.T.,,,{|| .T. },,,,lOnlyView,.F.,,"cRG",,,,.T.,.F.)
  	oRG:SetCSS( POSCSS (GetClassName(oRG), CSS_GET_NORMAL ))

  	@ 145, 095 SAY oSay11 PROMPT "Telefone" SIZE 50, 010 OF oPnlChk COLORS 0, 16777215 PIXEL
  	oSay11:SetCSS( POSCSS (GetClassName(oSay11), CSS_LABEL_FOCAL ))
  	oTel := TGet():New( 155, 095,{|u| iif( PCount()==0,cTel,cTel:=u)},oPnlChk,70, 013,,{|| .T. },,,,,,.T.,,,{|| .T. },,,,lOnlyView,.F.,,"cTel",,,,.T.,.F.)
  	oTel:SetCSS( POSCSS (GetClassName(oTel), CSS_GET_NORMAL ))

  	@ 145, 170 SAY oSay12 PROMPT "Compensação" SIZE 50, 010 OF oPnlChk COLORS 0, 16777215 PIXEL
  	oSay12:SetCSS( POSCSS (GetClassName(oSay12), CSS_LABEL_FOCAL ))
  	oComp := TGet():New( 155, 170,{|u| iif( PCount()==0,cComp,cComp:=u)},oPnlChk,70, 013,,{|| .T. },,,,,,.T.,,,{|| .T. },,,,lOnlyView,.F.,,"cComp",,,,.T.,.F.)
  	oComp:SetCSS( POSCSS (GetClassName(oComp), CSS_GET_NORMAL ))

  	@ 175, 010 SAY oHelpCh PROMPT cHelpCh PICTURE "@!" SIZE nWidth-15, 020 OF oPnlChk COLORS 0, 16777215 PIXEL
  	oHelpCh:SetCSS( "TSay{ font:bold 13px; color: #AA0000; background-color: transparent; border: none; margin: 0px; }" )

	oBtn6 := TButton():New( nHeight-20,nWidth-60,"Confirmar",oPnlChk,{|| iif(lOnlyView .OR. ValidaCheck(),(nOpcx:=1, oDlgCH:end()),) },050,014,,,,.T.,,,,{|| .T.})
	oBtn6:SetCSS( POSCSS (GetClassName(oBtn6), CSS_BTN_FOCAL ))

	oBtn7 := TButton():New( nHeight-20,nWidth-115,"Cancelar",oPnlChk,bCloseChk,050,014,,,,.T.,,,,{|| .T.})
	oBtn7:SetCSS( POSCSS (GetClassName(oBtn7), CSS_BTN_ATIVO ))

	//TODO desabilitado impresao de cheque até implementar metodo ImpCheck
	if !lConfCash .AND. .F.
		oBtn8 := TButton():New( nHeight-20,010,"Imprimir Cheque",oPnlChk,{|| ImpCheck() },060,014,,,,.T.,,,,{|| .T.})
		oBtn8:SetCSS( POSCSS (GetClassName(oBtn8), CSS_BTN_NORMAL ))
	endif

	oDlgCH:lCentered := .T.
	oDlgCH:Activate()

	if nOpcx == 1 .AND. !lOnlyView

		cCgcEmit := Posicione("SA1",1,xFilial("SA1")+cCodEmit+cLojEmit,"A1_CGC")
		aInfComp := {nValorCh, dDataCh, cCgcEmit, cNomeEmit, cCmc7, cBanco, cAgencia, cConta, cNumCh, cRG, cTel, cComp, cCodEmit, cLojEmit}

		if lAlt
			oMsGetEnt:aCols[oMsGetEnt:nAt][NPOSVLR] := nValorCh
			oMsGetEnt:aCols[oMsGetEnt:nAt][NPOSDAT] := dDataCh
			oMsGetEnt:aCols[oMsGetEnt:nAt][NPOSINF] := aInfComp
		else
			if oMsGetEnt:aCols[1][NPOSVLR] == 0
				oMsGetEnt:aCols := {}
			endif
			aadd(oMsGetEnt:aCols, {nValorCh, dDataCh, "CH", "CHEQUE", aInfComp, .F.} )
		endif

		oMsGetEnt:oBrowse:Refresh()
		AtuTotais()

	endif

Return

//-------------------------------------------------------
// Valida e gatilha emitente de cheque
//-------------------------------------------------------
Static Function VldEmitChq()

	Local lRet := .T.

	if empty(cCodEmit) .or. empty(cLojEmit)
		cCodEmit  := space(tamsx3("A1_COD")[1])
		cLojEmit  := space(tamsx3("A1_LOJA")[1])
		cNomeEmit := space(tamsx3("A1_NOME")[1])
	else
		cNomeEmit := Posicione("SA1",1,xFilial("SA1")+cCodEmit+cLojEmit,"A1_NOME")

		if empty(cNomeEmit)
			cHelpCh := "Emitente não cadastrado!"
			lRet := .F.
		endif

		if SA1->(FieldPos("A1_XEMCHQ")) > 0
			if SA1->A1_XEMCHQ != "S"
				cHelpCh := "O cliente não está habilitado como Emitente de Cheque!"
				lRet := .F.
			endif
		endif

		if lRet //gatilha demais campos
			cTel := PadR(alltrim(SA1->A1_DDD + SA1->A1_TEL),TamSx3("EF_TEL")[1])
			cRG := iif(SA1->A1_PESSOA=='F',SA1->A1_PFISICA,SA1->A1_INSCR)
		endif
	endif

	if lRet
		cHelpCh := ""
	endif
	oHelpCh:Refresh()

Return lRet

//-------------------------------------------------------
// Valida CMC7 e gatilha campos do cheque
//-------------------------------------------------------
Static Function VldCMC7Chq()

	Local lRet := .T.
	Local cMyCmc7 := ""
    Local c1 := c2 := c3 := ""

	if !empty(cCmc7)
		cMyCmc7 := alltrim(cCmc7)
		If Len(cMyCmc7)>=30 .and. Right(cMyCmc7,1)<>":"
			c1 := SubStr(cMyCmc7,1,8)
			c2 := SubStr(cMyCmc7,9,10)
			c3 := SubStr(cMyCmc7,19,12)
			cMyCmc7 := "<"+c1+"<"+c2+">"+c3+":"
			cCmc7 := cMyCmc7
		EndIf

		if ("?" $ cMyCmc7) .OR. Len(AllTrim(cMyCmc7)) <> 34
			cHelpCh := "Erro na leitura. Passe o cheque novamente no leitor."
			lRet := .F.
		else
			if Modulo10(SubStr(cMyCmc7,2,7)) <> SubStr(cMyCmc7,22,1)
			     lRet := .F.
			Elseif Modulo10(SubStr(cMyCmc7,11,10)) <> SubStr(cMyCmc7,9,1)
			     lRet := .F.
			Elseif Modulo10(SubStr(cMyCmc7,23,10)) <> SubStr(cMyCmc7,33,1)
			     lRet := .F.
			endif
			if !lRet
				cHelpCh := "O Código CMC7 informado é iválido!"
			endif
		endif

		//setando campos
		if lRet
			cBanco := PadR(SubStr(cMyCmc7, 2, 3), TamSx3("EF_BANCO")[1]) //Banco
			cAgencia := PadR(SubStr(cMyCmc7, 5, 4), TamSx3("EF_AGENCIA")[1]) //Agencia
			cNumCh := PadR(SubStr(cMyCmc7, 14, 6),TamSx3("EF_NUM")[1]) //Nro Cheque
			cComp := PadR(SubStr(cMyCmc7, 11, 3),TamSx3("L4_COMP")[1]) //Comp.

			//buscando a cona para cada banco
			If cBanco  $  "314/001" //itau, brasil
			 	cConta := SubStr(cMyCmc7, 27, 6)  //Conta
			ElseIf cBanco = "756" //sicoob
			 	cConta := SubStr(cMyCmc7, 23, 10)  //Conta
			ElseIf cBanco = "237" //bradesco
			 	cConta := SubStr(cMyCmc7, 26, 7)  //Conta
			ElseIf cBanco = "104" //caixa
			 	cConta := SubStr(cMyCmc7, 24, 9)  //Conta
			ElseIf cBanco = "356" //real
			 	cConta := SubStr(cMyCmc7, 26, 7)  //Conta
			ElseIf cBanco = "399" //hsbc
			 	cConta := SubStr(cMyCmc7, 23, 9)  //Conta
			ElseIf cBanco = "745" //citibank
				cConta := SubStr(cMyCmc7, 25, 8)  //Conta
			Else
				cConta := SubStr(cMyCmc7, 25, 8)  //Conta
			EndIf

		endif

	endif

	if lRet
		cHelpCh := ""
	endif
	oHelpCh:Refresh()

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

Static Function ImpCheck()

	//TODO implementar metodo

Return

//------------------------------------------------------
// Valida confirmação da tela de cheques
//------------------------------------------------------
Static Function ValidaCheck()

	Local lRet := .T.

	//validando valor
	if nValorCh <= 0
		cHelpCh := "Valor do cheque informado não pode ser negativo ou zerado."
		lRet := .F.
	endif

	if dDataCh < dDataBase
		cHelpCh := "Data do cheque deve ser maior ou igual a data atual."
		lRet := .F.
	endif

	//validando obrigatoriedade dos demais campos
	if lRet
		if empty(cCodEmit) .or. empty(cLojEmit)
			cHelpCh := "Informe o Código/Loja do Emitente!"
			lRet := .F.
		elseif empty(cNomeEmit)
			cHelpCh := "Cadastro do emitente não encontrado!"
			lRet := .F.
		elseif empty(cBanco)
			cHelpCh := "Informe o Banco do cheque!"
			lRet := .F.
		elseif empty(cAgencia)
			cHelpCh := "Informe a Agência do cheque!"
			lRet := .F.
		elseif empty(cConta)
			cHelpCh := "Informe a Conta do cheque!"
			lRet := .F.
		elseif empty(cNumCh)
			cHelpCh := "Informe o Numero do cheque!"
			lRet := .F.
		elseif empty(cTel)
			cHelpCh := "Informe o Telefone do Portador do cheque!"
			lRet := .F.
		endif
	endif

	if lRet
		cHelpCh := ""
	endif
	oHelpCh:Refresh()

Return lRet

//--------------------------------------------------------------------
// Inclusão de um Cartão
//--------------------------------------------------------------------
Static Function ViewCard(lAlt)

	Local aInfComp
	Local nOpcx := 0
	Local nWidth, nHeight, cCssAux
	Local oPnlCard, oPnlTop
	Local bCloseCard := {|| oDlgCard:end() }
	Local lSelAdm := SuperGetMV("MV_XSELADM",,.F.) //Define se ao inves de selecionar OPERADORA + BANDEIRA (.F.), será selecionado ADM. FINANCEIRA (.T.)
	Default lAlt := .F.
	Private nValorC := 0
	Private oBtnCC, oBtnCD
	Private nTipoOper := 0 //0-CRÉDITO;1-DÉBITO"
	Private cRedeAut	:= Space(TamSx3("MDE_CODIGO")[1])
	Private cBandeira	:= Space(TamSx3("MDE_CODIGO")[1])
	Private cAdmFin		:= Space(TamSx3("AE_COD")[1])
	Private cNsuDoc		:= Space(TamSx3("L4_NSUTEF")[1])
	Private cAutoriz	:= Space(TamSx3("L4_AUTORIZ")[1])
	Private dDataTran 	:= dDataBase
	Private nParcelas 	:= 1
	Private cHelpC := ""
	Private oHelpC
	Private oDlgCard
	Private aMyAdmFin := {}
	Private aMyRede := {}
	Private aMyBandei := {}

	if lAlt .OR. lOnlyView
		aInfComp := oMsGetEnt:aCols[oMsGetEnt:nAt][NPOSINF]
		nValorC := aInfComp[1]
		nTipoOper := aInfComp[2]
		cRedeAut := aInfComp[3]
		cBandeira := aInfComp[4]
		cAdmFin := aInfComp[5]
		cNsuDoc := aInfComp[6]
		cAutoriz := aInfComp[7]
		dDataTran := aInfComp[8]
		nParcelas := aInfComp[9]

		//carregar arrays combo
		aMyAdmFin := STDAdmFinan(oMsGetEnt:aCols[oMsGetEnt:nAt][NPOSFPG]) //busco adm fin da forma (funçao padrao)
		aSize(aMyAdmFin, Len(aMyAdmFin)+1)
		aIns(aMyAdmFin,1)
		aMyAdmFin[1] := Space(TamSx3("AE_COD")[1])
		aMyRede := GetMDEAdm(1, aMyAdmFin) //busca redes relacionadas as adm encontradas
		aMyBandei:= GetMDEAdm(2, aMyAdmFin, cRedeAut)
	endif

	DEFINE MSDIALOG oDlgCard TITLE "" FROM 000,000 TO 400,375 PIXEL STYLE nOr(WS_VISIBLE, WS_POPUP)

	nWidth := (oDlgCard:nWidth/2)
	nHeight := (oDlgCard:nHeight/2)

	@ 000, 000 MSPANEL oPnlCard SIZE nWidth, nHeight OF oDlgCard
	oPnlCard:SetCSS( "TPanel{border: 2px solid #999999; background-color: #f4f4f4;}" )

	@ 000, 000 MSPANEL oPnlTop SIZE nWidth, 017 OF oPnlCard
	oPnlTop:SetCSS( POSCSS (GetClassName(oPnlTop), CSS_BAR_TOP ))
	@ 004, 005 SAY oSay1 PROMPT (iif(lOnlyView,"Visualização",iif(lAlt,"Alteração","Inclusão"))+" de Cartão") SIZE 100, 015 OF oPnlTop COLORS 0, 16777215 PIXEL
	oSay1:SetCSS( POSCSS (GetClassName(oSay1), CSS_BREADCUMB ))
	oClose := TBtnBmp2():New( 002,oDlgCard:nWidth-25,20,30,'FWSKIN_DELETE_ICO',,,,bCloseCard,oPnlTop,,,.T. )
	oClose:SetCss("TBtnBmp2{border: none;background-color: none;}")

	@ 025, 010 SAY oSay1 PROMPT "Valor do Cartão" SIZE 70, 008 OF oPnlCard COLORS 0, 16777215 PIXEL
	oSay1:SetCSS( POSCSS (GetClassName(oSay1), CSS_LABEL_FOCAL ))
	oValorCC := TGet():New( 035, 010,{|u| iif( PCount()==0,nValorC,nValorC:=u)},oPnlCard,80, 013,PesqPict("UC1","UC1_VALOR"),{|| .T. },,,,,,.T.,,,{|| .T. },,,,lOnlyView,.F.,,"nValorC",,,,.F.,.T.)
	oValorCC:SetCSS( POSCSS (GetClassName(oValorCC), CSS_GET_NORMAL ))

	@ 025, 100 SAY oSay2 PROMPT "Tipo Operação" SIZE 70, 008 OF oPnlCard COLORS 0, 16777215 PIXEL
	oSay2:SetCSS( POSCSS (GetClassName(oSay2), CSS_LABEL_FOCAL ))

	oBtnCC := TButton():New(035,100,"CRÉDITO", oPnlCard,{|| nTipoOper:=0, SetTipoSel(nTipoOper) },040,015,,,,.T.,,,,{|| !lAlt})
	oBtnCD := TButton():New(035,140,"DÉBITO", oPnlCard,{|| nTipoOper:=1, SetTipoSel(nTipoOper) },040,015,,,,.T.,,,,{|| !lAlt})

	@ 055, 010 SAY oSay3 PROMPT "Operadora" SIZE 106, 010 OF oPnlCard COLORS 0, 16777215 PIXEL
	oSay3:SetCSS( POSCSS (GetClassName(oSay3), CSS_LABEL_FOCAL ))
	oRedeAut := TComboBox():New(065, 010, {|u| If(PCount()>0,cRedeAut:=u,cRedeAut)}, aMyRede , 080, 016, oPnlCard, Nil,{|| aMyBandei:=GetMDEAdm(2, aMyAdmFin, cRedeAut), oBandeira:SetItems(aMyBandei), iif(len(aMyBandei)==2,oBandeira:Select(2),), oBandeira:Refresh() },/*bValid*/,,,.T.,,Nil,Nil,{|| !lOnlyView .AND. !lSelAdm } )
	oRedeAut:SetCSS( oCssCombo)

	@ 055, 100 SAY oSay4 PROMPT "Bandeira" SIZE 106, 010 OF oPnlCard COLORS 0, 16777215 PIXEL
   	oSay4:SetCSS( POSCSS (GetClassName(oSay4), CSS_LABEL_FOCAL ))
  	oBandeira := TComboBox():New(065, 100, {|u| If(PCount()>0,cBandeira:=u,cBandeira)}, aMyBandei , 080, 016, oPnlCard, Nil,{|| nX := GetMDEAdm(3, aMyAdmFin, cRedeAut, cBandeira), oAdmFin:Select(nX) },/*bValid*/,,,.T.,,Nil,Nil,{|| !lOnlyView .AND. !lSelAdm} )
  	oBandeira:SetCSS( oCssCombo )

  	@ 085, 010 SAY oSay5 PROMPT "Adm. Financeira" SIZE 120, 010 OF oPnlCard COLORS 0, 16777215 PIXEL
  	oSay5:SetCSS( POSCSS (GetClassName(oSay5), CSS_LABEL_FOCAL ))
    oAdmFin := TComboBox():New(095, 010, {|u| If(PCount()>0,cAdmFin:=u,cAdmFin)}, aMyAdmFin , 170, 016, oPnlCard, Nil,/*bChange*/,/*bValid*/,,,.T.,,Nil,Nil,{|| lSelAdm } )
	oAdmFin:SetCSS(oCssCombo)

  	@ 115, 010 SAY oSay6 PROMPT "NSU" SIZE 070, 007 OF oPnlCard COLORS 0, 16777215 PIXEL
  	oSay6:SetCSS( POSCSS (GetClassName(oSay6), CSS_LABEL_FOCAL ))
    @ 125, 010 MSGET oNsuDoc VAR cNsuDoc SIZE 080, 013 OF oPnlCard COLORS 0, 16777215 PIXEL PICTURE Replicate("N",len(cNsuDoc))
    cCssAux := POSCSS (GetClassName(oNsuDoc), CSS_GET_NORMAL )
    cCssAux := StrTran(cCssAux,"transparent","#EEEEEE")
	cCssAux := StrTran(cCssAux,"border: none;","") // padding: 0px;
    oNsuDoc:SetCSS(cCssAux)
    oNsuDoc:lReadOnly := lOnlyView

    @ 115, 100 SAY oSay7 PROMPT "Autorização" SIZE 057, 007 OF oPnlCard COLORS 0, 16777215 PIXEL
    oSay7:SetCSS( POSCSS (GetClassName(oSay7), CSS_LABEL_FOCAL ))
    @ 125, 100 MSGET oAutoriz VAR cAutoriz SIZE 080, 013 OF oPnlCard COLORS 0, 16777215 PIXEL PICTURE Replicate("N",len(cAutoriz))
    oAutoriz:SetCSS(cCssAux)
    oAutoriz:lReadOnly := lOnlyView

    @ 145, 010 SAY oSay11 PROMPT "Data" SIZE 070, 007 OF oPnlCard COLORS 0, 16777215 PIXEL
  	oSay11:SetCSS( POSCSS (GetClassName(oSay11), CSS_LABEL_FOCAL ))
    @ 155, 010 MSGET oDataTran VAR DTOC(dDataTran) SIZE 080, 013 OF oPnlCard COLORS 0, 16777215 WHEN .F. PIXEL
    oDataTran:SetCSS(cCssAux)

    @ 145, 100 SAY oSay12 PROMPT "Nº.Parcelas" SIZE 057, 007 OF oPnlCard COLORS 0, 16777215 PIXEL
    oSay12:SetCSS( POSCSS (GetClassName(oSay12), CSS_LABEL_FOCAL ))
    @ 155, 100 MSGET oParcelas VAR nParcelas SIZE 040, 013 OF oPnlCard PICTURE "99" COLORS 0, 16777215 WHEN nTipoOper==0 HASBUTTON PIXEL
    oParcelas:SetCSS(cCssAux)
    oParcelas:lReadOnly := lOnlyView

  	@ 175, 010 SAY oHelpC PROMPT cHelpC PICTURE "@!" SIZE nWidth-15, 020 OF oPnlCard COLORS 0, 16777215 PIXEL
  	oHelpC:SetCSS( "TSay{ font:bold 13px; color: #AA0000; background-color: transparent; border: none; margin: 0px; }" )

	oBtn6 := TButton():New( nHeight-20,nWidth-60,"Confirmar",oPnlCard,{|| iif(lOnlyView .OR. ValidaCard(),(nOpcx:=1, oDlgCard:end()),) },050,014,,,,.T.,,,,{|| .T.})
	oBtn6:SetCSS( POSCSS (GetClassName(oBtn6), CSS_BTN_FOCAL ))

	oBtn7 := TButton():New( nHeight-20,nWidth-115,"Cancelar",oPnlCard,bCloseCard,050,014,,,,.T.,,,,{|| .T.})
	oBtn7:SetCSS( POSCSS (GetClassName(oBtn7), CSS_BTN_ATIVO ))

	SetTipoSel(nTipoOper, lAlt) //carrego combos

	oDlgCard:lCentered := .T.
	oDlgCard:Activate()

	if nOpcx == 1 .AND. !lOnlyView

		aInfComp := {nValorC, nTipoOper, cRedeAut, cBandeira, cAdmFin, cNsuDoc, cAutoriz, dDataTran, nParcelas}

		if lAlt
			oMsGetEnt:aCols[oMsGetEnt:nAt][NPOSVLR] := nValorC
			oMsGetEnt:aCols[oMsGetEnt:nAt][NPOSDAT] := dDataTran
			oMsGetEnt:aCols[oMsGetEnt:nAt][NPOSINF] := aInfComp
		else
			if oMsGetEnt:aCols[1][NPOSVLR] == 0
				oMsGetEnt:aCols := {}
			endif
			if nTipoOper == 0 //CC
				aadd(oMsGetEnt:aCols, {nValorC, dDataTran, "CC", "CARTÃO CRÉDITO", aInfComp, .F.} )
			else //CD
				aadd(oMsGetEnt:aCols, {nValorC, dDataTran, "CD", "CARTÃO DÉBITO", aInfComp, .F.} )
			endif
		endif

		oMsGetEnt:oBrowse:Refresh()
		AtuTotais()

	endif

Return

//----------------------------------------------------------------
// Validacao tela cartao
//----------------------------------------------------------------
Static Function ValidaCard()

	Local lRet := .T.
	Local lSelAdm := SuperGetMV("MV_XSELADM",,.F.) //Define se ao inves de selecionar OPERADORA + BANDEIRA (.F.), será selecionado ADM. FINANCEIRA (.T.)

	//validando valor
	if nValorC <= 0
		cHelpC := "Valor informado não pode ser negativo ou zerado."
		lRet := .F.
	endif

	if lRet
		if !lSelAdm .AND. empty(cRedeAut)
			cHelpC := "Selecione uma Operadora de Cartão!"
			lRet := .F.
		elseif !lSelAdm .AND. empty(cBandeira)
			cHelpC := "Selecione uma Bandeira de Cartão!"
			lRet := .F.
		elseif empty(cAdmFin)
			cHelpC := "Administradora não encontrada!"
			lRet := .F.
		elseif empty(cNsuDoc)
			cHelpC := "Informe o NSU do comprovante!"
			lRet := .F.
		elseif empty(cAutoriz)
			cHelpC := "Informe o Codigo Autorização do Comprovante!"
			lRet := .F.
		endif

		if lRet
			SAE->(DbSetOrder(1))
			SAE->(DbSeek(xFilial("SAE")+cAdmFin))
			If nParcelas <= 0 
				cHelpC := "Numero de parcelas deve ser maior que zero!"
				lRet := .F.
			ElseIf SAE->AE_PARCDE > 0 .AND. nParcelas < SAE->AE_PARCDE
				cHelpC := "Numero mínimo de parcelas é de "+cValToChar(SAE->AE_PARCATE)+"!"
				lRet := .F.
			ElseIf SAE->AE_PARCATE > 0 .AND. nParcelas > SAE->AE_PARCATE
				cHelpC := "Numero máximo de parcelas é de "+cValToChar(SAE->AE_PARCATE)+"!"
				lRet := .F.
			Endif
		endif
	endif

	if lRet
		cHelpC := ""
	endif
	oHelpC:Refresh()

Return lRet

//--------------------------------------------------------------
// Aplica CSS no botão tipo Radio
//--------------------------------------------------------------
Static Function SetTipoSel(nOpcSel, lAlt)

	Local lRet := .T.
	Local cCssBtn
	Local cForma
	Local nX := 0

	if nOpcSel == 0 //Crédito
		//deixo botão CREDITO azul
		cCssBtn := POSCSS(GetClassName(oBtnCC), CSS_BTN_FOCAL )
		cCssBtn:= StrTran(cCssBtn, "border-radius: 6px;", "border-radius: 3px;")
		oBtnCC:SetCss(cCssBtn)

		//deixo botão DEBITO branco
		cCssBtn := POSCSS(GetClassName(oBtnCD), CSS_BTN_NORMAL )
		cCssBtn:= StrTran(cCssBtn, "border-radius: 6px;", "border-radius: 3px;")
		cCssBtn:= StrTran(cCssBtn, "font: bold large;", "")
		oBtnCD:SetCss(cCssBtn)

		cForma := "CC"
	else
		//deixo botão CREDITO branco
		cCssBtn := POSCSS(GetClassName(oBtnCC), CSS_BTN_NORMAL )
		cCssBtn:= StrTran(cCssBtn, "border-radius: 6px;", "border-radius: 3px;")
		cCssBtn:= StrTran(cCssBtn, "font: bold large;", "")
		oBtnCC:SetCss(cCssBtn)

		//deixo botão DEBITO azul
		cCssBtn := POSCSS(GetClassName(oBtnCD), CSS_BTN_FOCAL )
		cCssBtn:= StrTran(cCssBtn, "border-radius: 6px;", "border-radius: 3px;")
		oBtnCD:SetCss(cCssBtn)

		cForma := "CD"
	endif

	oBtnCC:Refresh()
	oBtnCD:Refresh()

	if lAlt
		Return .T.
	endif

	nParcelas 	:= 1 //reseto parcelas
	cRedeAut	:= Space(TamSx3("MDE_CODIGO")[1])
	cBandeira	:= Space(TamSx3("MDE_CODIGO")[1])
	cAdmFin		:= Space(TamSx3("AE_COD")[1])
	aMyAdmFin := {cAdmFin}
	aMyRede := {cRedeAut}
	aMyBandei := {cBandeira}

	aMyAdmFin := STDAdmFinan(Alltrim(cForma)) //busco adm fin da forma (funçao padrao)
	if empty(aMyAdmFin)
		cHelpC := "Não há Adm.Financeira cadastrada para forma " + cForma +"."
		lRet := .F.
	else
		aMyRede := GetMDEAdm(1, aMyAdmFin) //busca redes relacionadas as adm encontradas
		//adicionando opção em branco no combobox adm fin
		aSize(aMyAdmFin, Len(aMyAdmFin)+1)
		aIns(aMyAdmFin,1)
		aMyAdmFin[1] := Space(TamSx3("AE_COD")[1])

		oRedeAut:SetItems(aMyRede)
		oBandeira:SetItems(aMyBandei)
		oAdmFin:SetItems(aMyAdmFin)
	endif

	if lRet
		cHelpC := ""
	endif
	oHelpC:Refresh()

Return

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

	if nTipo <> 3
		aadd(xRet, Space(nTamCdMDE))
	else
		xRet := 1
	endif
	cRede := SubStr(cRede,1,nTamCdMDE)
	cBand := SubStr(cBand,1,nTamCdMDE)

	DbSelectArea("SAE")
	SAE->(DbSetOrder(1))
	For nX := 1 to len(aAdm)
		SAE->(DbSeek(xFilial("SAE")+ SubStr(aAdm[nX],1,nTamCdAE) ))
		if nTipo==1 .AND. !empty(SAE->AE_REDEAUT)
			cCodMDE := Posicione("MDE",1,xFilial("MDE")+SAE->AE_REDEAUT,"MDE_CODIGO")
			if !empty(cCodMDE) .AND. aScan(xRet, {|x| SubStr(x,1,nTamCdMDE)==cCodMDE }) == 0
				aadd(xRet, MDE->MDE_CODIGO + "- " + MDE->MDE_DESC)
			endif
		endif
		if nTipo==2 .AND. !empty(cRede) .AND. SAE->AE_REDEAUT==cRede .AND. !empty(SAE->AE_ADMCART)
			cCodMDE := Posicione("MDE",1,xFilial("MDE")+SAE->AE_ADMCART,"MDE_CODIGO")
			if !empty(cCodMDE) .AND. aScan(xRet, {|x| SubStr(x,1,nTamCdMDE)==cCodMDE }) == 0
				aadd(xRet, MDE->MDE_CODIGO + "- " + MDE->MDE_DESC)
			endif
		endif
		if nTipo==3 .AND. !empty(cRede) .AND. !empty(cBand) .AND. SAE->AE_REDEAUT==cRede .AND. SAE->AE_ADMCART==cBand
			xRet := nX
			EXIT
		endif
	next nX

	//ordenando por codigo
	if nTipo==1 .OR. nTipo==2
		aSort(xRet)
	endif

	RestArea(aArea)

Return xRet

//--------------------------------------------------------------------
// Inclusão de uma carta Frete
//--------------------------------------------------------------------
Static Function ViewCFrete(lAlt)

	Local aInfComp
	Local nOpcx := 0
	Local nWidth, nHeight
	Local oPnlCF, oPnlTop
	Local bCloseCF := {|| oDlgCF:end() }
	Local oCodCF, oLojCF, oNomeEmiCF
	Default lAlt := .F.
	Private nValorCF := 0
	Private cEmitCF := Space(TamSX3("UC1_CGC")[1])
	Private cCodCF := Space(TamSX3("A1_COD")[1])
	Private cLojCF := Space(TamSX3("A1_LOJA")[1])
	Private cNomeEmiCF := ""
	Private cCFrete := Space(TamSX3("UC1_CFRETE")[1])
	Private cObserv := Space(TamSX3("UC1_OBS")[1])
	Private cHelpCF := ""
	Private oHelpCF
	Private oDlgCF
	Private dDataTran := dDataBase

	if lAlt .OR. lOnlyView
		aInfComp := oMsGetEnt:aCols[oMsGetEnt:nAt][NPOSINF]
		nValorCF := aInfComp[1]
		cEmitCF := aInfComp[2]
		cCodCF := aInfComp[6]
		cLojCF := aInfComp[7]
		cNomeEmiCF := aInfComp[3]
		cCFrete := aInfComp[4]
		cObserv := aInfComp[5]
	endif

	// Limpa array do bakcup da ultima carta frete
	If FindFunction("U_TPDVA14A")
		U_TPDVA14A()
	EndIf

	DEFINE MSDIALOG oDlgCF TITLE "" FROM 000,000 TO 375,375 PIXEL STYLE nOr(WS_VISIBLE, WS_POPUP)

	nWidth := (oDlgCF:nWidth/2)
	nHeight := (oDlgCF:nHeight/2)

	@ 000, 000 MSPANEL oPnlCF SIZE nWidth, nHeight OF oDlgCF
	oPnlCF:SetCSS( "TPanel{border: 2px solid #999999; background-color: #f4f4f4;}" )

	@ 000, 000 MSPANEL oPnlTop SIZE nWidth, 017 OF oPnlCF
	oPnlTop:SetCSS( POSCSS (GetClassName(oPnlTop), CSS_BAR_TOP ))
	@ 004, 005 SAY oSay1 PROMPT (iif(lOnlyView,"Visualização",iif(lAlt,"Alteração","Inclusão"))+" de Carta Frete") SIZE 100, 015 OF oPnlTop COLORS 0, 16777215 PIXEL
	oSay1:SetCSS( POSCSS (GetClassName(oSay1), CSS_BREADCUMB ))
	oClose := TBtnBmp2():New( 002,oDlgCF:nWidth-25,20,30,'FWSKIN_DELETE_ICO',,,,bCloseCF,oPnlTop,,,.T. )
	oClose:SetCss("TBtnBmp2{border: none;background-color: none;}")

	//@ 025, 010 SAY oSay2 PROMPT "CNPJ do Emitente" SIZE 100, 008 OF oPnlCF COLORS 0, 16777215 PIXEL
	//oSay2:SetCSS( POSCSS (GetClassName(oSay2), CSS_LABEL_FOCAL ))
	//oEmitCF := TGet():New( 035, 010,{|u| iif(PCount()>0,cEmitCF:=u,cEmitCF)},oPnlCF,85, 013,,{|| VldEmitCF() .AND. oPnlCF:Refresh() },,,,,,.T.,,,{|| .T. },,,,lOnlyView,.F.,,"oEmitCF",,,,.T.,.F.)
	//oEmitCF:SetCSS( POSCSS (GetClassName(oEmitCF), CSS_GET_NORMAL ))
	//TSearchF3():New(oEmitCF,oDlgCF:nWidth-50,210,"SA1","A1_CGC",{{"A1_NOME",2},{"A1_CGC",3},{"A1_COD",1}},"SA1->A1_MSBLQL<>'1'"+iif(SA1->(FieldPos("A1_XEMICF"))>0," .AND. SA1->A1_XEMICF='S'",""),{{"A1_NOME","A1_EST","A1_MUN"},{"A1_CGC","A1_NOME","A1_EST","A1_MUN"},{"A1_COD","A1_LOJA","A1_NOME","A1_EST","A1_MUN"}},,,iif(lConfCash,-60,0))
	
	@ 025, 010 SAY oSay2 PROMPT "Código" SIZE 100, 008 OF oPnlCF COLORS 0, 16777215 PIXEL
	oSay2:SetCSS( POSCSS (GetClassName(oSay2), CSS_LABEL_FOCAL ))
	oCodCF := TGet():New( 035, 010,{|u| iif(PCount()>0,cCodCF:=u,cCodCF)},oPnlCF, 055, 013,,{|| VldEmitCF() .AND. oPnlCF:Refresh() },,,,,,.T.,,,{|| .T. },,,,lOnlyView,.F.,,"oCodCF",,,,.T.,.F.)
	oCodCF:SetCSS( POSCSS (GetClassName(oCodCF), CSS_GET_NORMAL ))

	@ 025, 065 SAY oSay2 PROMPT "Loja" SIZE 100, 008 OF oPnlCF COLORS 0, 16777215 PIXEL
	oSay2:SetCSS( POSCSS (GetClassName(oSay2), CSS_LABEL_FOCAL ))
	oLojCF := TGet():New( 035, 065,{|u| iif(PCount()>0,cLojCF:=u,cLojCF)},oPnlCF, 020, 013,,{|| VldEmitCF() .AND. oPnlCF:Refresh() },,,,,,.T.,,,{|| .T. },,,,lOnlyView,.F.,,"oLojCF",,,,.T.,.F.)
	oLojCF:SetCSS( POSCSS (GetClassName(oLojCF), CSS_GET_NORMAL ))

	@ 055, 010 SAY oSay3 PROMPT "Nome do Emitente" SIZE 080, 010 OF oPnlCF COLORS 0, 16777215 PIXEL
	oSay3:SetCSS( POSCSS (GetClassName(oSay3), CSS_LABEL_FOCAL ))
	oNomeEmiCF := TGet():New( 65, 010,{|u| iif(PCount()>0,cNomeEmiCF:=u,cNomeEmiCF)},oPnlCF,nWidth-20, 013,,{|| .T./*bValid*/ },,,,,,.T.,,,{|| .T. },,,,.T.,.F.,,"oNomeEmiCF",,,,.T.,.F.)
	oNomeEmiCF:SetCSS( POSCSS (GetClassName(oNomeEmiCF), CSS_GET_NORMAL ))
	oNomeEmiCF:lCanGotFocus := .F.
	TSearchF3():New(oCodCF,oDlgCF:nWidth-50,210,"SA1","A1_COD",{{"A1_NOME",2},{"A1_CGC",3},{"A1_COD",1}},"SA1->A1_MSBLQL<>'1'"+iif(SA1->(FieldPos("A1_XEMICF"))>0," .AND. SA1->A1_XEMICF='S'",""),{{"A1_COD","A1_LOJA","A1_NOME","A1_EST","A1_MUN"},{"A1_COD","A1_LOJA","A1_CGC","A1_NOME","A1_EST","A1_MUN"},{"A1_COD","A1_LOJA","A1_NOME","A1_EST","A1_MUN"}},,,iif(lConfCash,-60,0),,{{oLojCF,"A1_LOJA"},{oNomeEmiCF,"A1_NOME"}})

	@ 085, 010 SAY oSay4 PROMPT "Numero Carta Frete" SIZE 100, 008 OF oPnlCF COLORS 0, 16777215 PIXEL
	oSay4:SetCSS( POSCSS (GetClassName(oSay4), CSS_LABEL_FOCAL ))
	oCFrete := TGet():New( 095, 010,{|u| iif(PCount()>0,cCFrete:=u,cCFrete)},oPnlCF,080, 013,,{|| .T./*bValid*/ },,,,,,.T.,,,{|| .T. },,,,lOnlyView,.F.,,"oCFrete",,,,.T.,.F.)
	oCFrete:SetCSS( POSCSS (GetClassName(oCFrete), CSS_GET_NORMAL ))

	@ 085, 095 SAY oSay1 PROMPT "Valor da Carta Frete" SIZE 70, 008 OF oPnlCF COLORS 0, 16777215 PIXEL
	oSay1:SetCSS( POSCSS (GetClassName(oSay1), CSS_LABEL_FOCAL ))
	oCFVlrRec := TGet():New( 095, 095,{|u| iif( PCount()==0,nValorCF,nValorCF:=u)},oPnlCF,78, 013,PesqPict("UC1","UC1_VALOR"),{|| .T. },,,,,,.T.,,,{|| .T. },,,,lOnlyView,.F.,,"nValorCF",,,,.F.,.T.)
	oCFVlrRec:SetCSS( POSCSS (GetClassName(oCFVlrRec), CSS_GET_NORMAL ))

	oCFVlrRec:cF3 := "TPDVA014"
	oCFVlrRec:bF3 := {|| oCFVlrRec:cText:=U_TPDVA014(cCodCF,cLojCF) }
	oCFVlrRec:bGotFocus := {|| bSavKeyF3 := SetKey(VK_F3), SetKey(VK_F3, {|| oCFVlrRec:cText:=U_TPDVA014(cCodCF,cLojCF) }) }
	oCFVlrRec:bLostFocus := {|| iif(Eval(oCFVlrRec:bValid),SetKey(VK_F3, bSavKeyF3),) }

	@ 097, 176 BITMAP oCalCFBMP RESOURCE "CALCULADORA.PNG" NOBORDER SIZE 012, 012 OF oPnlCF ADJUST PIXEL
	oCalCFBMP:ReadClientCoors(.T.,.T.)
	oCalCFBTN := THButton():New(097, 174, "", oPnlCF, {|| oCFVlrRec:cText:=U_TPDVA014(cCodCF,cLojCF) }, 016, 016,,"Cálculo de Saldo Carta Frete (F3)")
	//SetKey(K_ALT_S,{|| oCFVlrRec:cText:=U_TPDVA014(cCodCF,cLojCF)})

	@ 115, 010 SAY oSay5 PROMPT "Observações" SIZE 100, 008 OF oPnlCF COLORS 0, 16777215 PIXEL
	oSay5:SetCSS( POSCSS (GetClassName(oSay5), CSS_LABEL_FOCAL ))
	oObserv := TGet():New( 125, 010,{|u| iif(PCount()>0,cObserv:=u,cObserv)},oPnlCF,nWidth-20, 013,"",{|| .T./*bValid*/ },,,,,,.T.,,,{|| .T. },,,,lOnlyView,.F.,,"oObserv",,,,.T.,.F.)
	oObserv:SetCSS( POSCSS (GetClassName(oObserv), CSS_GET_NORMAL ))

  	@ 145, 010 SAY oHelpCF PROMPT cHelpCF PICTURE "@!" SIZE nWidth-15, 020 OF oPnlCF COLORS 0, 16777215 PIXEL
  	oHelpCF:SetCSS( "TSay{ font:bold 13px; color: #AA0000; background-color: transparent; border: none; margin: 0px; }" )

	oBtn6 := TButton():New( nHeight-20,nWidth-60,"Confirmar",oPnlCF,{|| iif(lOnlyView .OR. ValidaCF(),(nOpcx:=1, oDlgCF:end()),) },050,014,,,,.T.,,,,{|| .T.})
	oBtn6:SetCSS( POSCSS (GetClassName(oBtn6), CSS_BTN_FOCAL ))

	oBtn7 := TButton():New( nHeight-20,nWidth-115,"Cancelar",oPnlCF,bCloseCF,050,014,,,,.T.,,,,{|| .T.})
	oBtn7:SetCSS( POSCSS (GetClassName(oBtn7), CSS_BTN_ATIVO ))

	oDlgCF:lCentered := .T.
	oDlgCF:bInit := {|| oLojCF:SetFocus(), oCodCF:SetFocus() }
	oDlgCF:Activate()

	if nOpcx == 1 .AND. !lOnlyView

		cEmitCF  := Posicione("SA1",1,xFilial("SA1")+cCodCF+cLojCF,"A1_CGC")
		aInfComp := {nValorCF, cEmitCF, cNomeEmiCF, cCFrete, cObserv, cCodCF, cLojCF}

		if lAlt
			oMsGetEnt:aCols[oMsGetEnt:nAt][NPOSDAT] := dDataTran
			oMsGetEnt:aCols[oMsGetEnt:nAt][NPOSVLR] := nValorCF
			oMsGetEnt:aCols[oMsGetEnt:nAt][NPOSINF] := aInfComp
		else
			if oMsGetEnt:aCols[1][NPOSVLR] == 0
				oMsGetEnt:aCols := {}
			endif
			aadd(oMsGetEnt:aCols, {nValorCF, dDataTran, "CF", "CARTA FRETE", aInfComp, .F.} )
		endif

		oMsGetEnt:oBrowse:Refresh()
		AtuTotais()

	endif

Return

//-------------------------------------------------------
// Valida e gatilha emitente de carta frete
//-------------------------------------------------------
Static Function VldEmitCF()

	Local lRet := .T.
	Local aParc

	if empty(cCodCF) .or. empty(cLojCF)
		cCodCF := space(tamsx3("A1_COD")[1])
		cLojCF := space(tamsx3("A1_LOJA")[1])
		cNomeEmiCF := space(tamsx3("A1_NOME")[1])
	else
		if empty(Posicione("SA1",1,xFilial("SA1")+cCodCF+cLojCF,"A1_NOME"))
			cHelpCF := "Emitente não cadastrado!"
			lRet := .F.
		endif

		if SA1->(FieldPos("A1_XEMICF")) > 0
			if SA1->A1_XEMICF != "S"
				cHelpCF := "O cliente não está habilitado como Emitente de Carta Frete!"
				lRet := .F.
			endif
		endif

		if lRet
			cNomeEmiCF := SA1->A1_NOME
		endif
	endif

	if lRet
		cHelpCF := ""
	endif
	oHelpCF:Refresh()

Return lRet

//-------------------------------------------------------
// Validacao da tela de carta frete
//-------------------------------------------------------
Static Function ValidaCF()

	Local lRet := .T.
	Local cCondPg

	//validando valor
	if nValorCF <= 0
		cHelpCF := "Valor informado não pode ser negativo ou zerado."
		lRet := .F.
	endif

	if lRet
		if empty(cCodCF) .or. empty(cLojCF)
			cHelpCF := "Informe um Emitente de Carta Frete!"
			lRet := .F.
		elseif empty(cNomeEmiCF)
			cHelpCF := "Cadastro do Emitente não encontrado!"
			lRet := .F.
		elseif empty(cCFrete)
			cHelpCF := "Informe o Numero da Carta Frete!"
			lRet := .F.
		endif
	endif

	if lRet
		cCondPg := space(tamsx3("E4_CODIGO")[1])
		if SA1->(FieldPos("A1_XCONDCF")) > 0
			cCondPg := Posicione("SA1",1,xFilial("SA1")+cCodCF+cLojCF,"A1_XCONDCF")
		endif
		if empty(cCondPg)
			cCondPg := SuperGetMv("MV_XCONDCF", .F., "")
			if empty(cCondPg)
				cHelpCF := "Condição de Pagamento do emitente carta frete não configurada: campo 'A1_XCONDCF' ou parâmetro 'MV_XCONDCF'"
				lRet := .F.
			endif
		endif
		if lRet
			aParc := condicao(nValorCF,cCondPg,0.00,dDatabase,0.00,{},,0)
			if Len(aParc) > 1
				cHelpCF := "Condição de pagamento do Emitente não pode gerar mais de 1 parcela!"
				lRet := .F.
			elseif !empty(aParc)
				dDataTran := aParc[1][1]
			endif
		endif
	endif

	if lRet
		cHelpCF := ""
	endif
	oHelpCF:Refresh()

Return lRet

//----------------------------------------------------------------------------------
// Validação campos nota fiscal e serie
//----------------------------------------------------------------------------------
Static Function VldNF(nOpc)

	Local cMsgErr := ""
	Local lRet := .T.
	Local aCliSL1 := {} //{L1_CLIENTE, L1_LOJA}
	Local aParam
	Default nOpc := 1 //1-valida campo; 2-validacao final compensacao

	if !empty(cDocNf) .AND. !empty(cSerieNf)

		SL1->(DbSetOrder(2)) //L1_FILIAL + L1_SERIE + L1_DOC + L1_PDV
		if SL1->(DbSeek(xFilial("SL1")+cSerieNf+cDocNf)) //tento encontrar no proprio PDV a venda
			if SL1->L1_SITUA=='07'.or.SL1->L1_STORC=='A'
				lRet := .F.
				cMsgErr := "A NF informada está cancelada. Operação não permitida!"
			else
				aCliSL1 := {SL1->L1_CLIENTE, SL1->L1_LOJA}
			endif
		elseif !lConfCash  //senao tento encontrar na central
			aParam := {cSerieNf, cDocNf}
			aParam := {"U_TPDVA05V",aParam}
			If !STBRemoteExecute("_EXEC_CEN",aParam,,,@aCliSL1)
				// Tratamento do erro de conexao
				lRet := .F.
				cMsgErr := "Falha de comunicação com a retaguarda central! Não foi possível vincular NF."
			ElseIf aCliSL1 = Nil .or. Empty(aCliSL1) .or. Len(aCliSL1) == 0
				aCliSL1 := {} //falhou, garanto que a variavel vai ficar tipo array
			EndIf
		endif

		if lRet .AND. empty(aCliSL1)
			lRet := .F.
			cMsgErr := "A NF informada não foi encontrada na base para vincular compensação!"
		endif

		if lRet .AND. aCliSL1[1]+aCliSL1[2] != GETMV("MV_CLIPAD")+GETMV("MV_LOJAPAD")
			if aCliSL1[1]+aCliSL1[2] <> cCodCli + cLojCli
				lRet := .F.
				cMsgErr := "Não é permitido vincular uma NF com cliente diferente do selecionado na compensação!"
			endif
		endif
	elseif nOpc==2
		if (empty(cDocNf) .AND. !empty(cSerieNf)) .OR. (!empty(cDocNf) .AND. empty(cSerieNf))
			lRet := .F.
			cMsgErr := "Preencha os dois campos [Nota Fiscal e Serie], caso queira vincular uma NF."
		endif
	endif

	if lConfCash .OR. lVincVend
		if !empty(cMsgErr)
			MsgInfo(cMsgErr, "Atenção")
		endif
	else
		U_SetMsgRod(cMsgErr)
	endif

Return lRet

//----------------------------------------------------------------------------------
// Função que busca nota fiscal na base central
//----------------------------------------------------------------------------------
User Function TPDVA05V(cSerieNf, cDocNf)

	Local aCliSL1 := {}

	SL1->(DbSetOrder(2)) //L1_FILIAL + L1_SERIE + L1_DOC + L1_PDV
	if SL1->(DbSeek(xFilial("SL1")+cSerieNf+cDocNf)) //tento encontrar no proprio PDV a venda
		aCliSL1 := {SL1->L1_CLIENTE, SL1->L1_LOJA}
	endif

Return aCliSL1

//----------------------------------------------------------------------------------
// Validação total da tela de inclusão
//----------------------------------------------------------------------------------
Static Function VldIncComp(lVldImpRel)

	Local lRet := .T.
	Local cMsgErr := ""
	Local lAlcada	:= SuperGetMv("ES_ALCADA",.F.,.F.)
	Local lAlcCmp	:= SuperGetMv( "ES_ALCCMP",.F.,.F.)
	Local cUsrLibAlc := ""

	Default lVldImpRel := .F.

	if lOnlyView
		if !lConfCash .AND. !lVincVend
			cTitleTela := "LISTAGEM"
			oPnlInc:Hide()
			oPnlBrow:Show()
		endif
		Return lRet
	endif

	AtuTotais()

	if empty(cPlaca)
		cMsgErr := "Informe a placa do veículo!"
		lRet := .F.
	elseif empty(cCodCli) .or. empty(cLojCli)
		cMsgErr := "Informe o código/loja do cliente!"
		lRet := .F.
	elseif empty(cNomCli)
		cMsgErr := "Cliente não encontrado na base! Verificar cadastro."
		lRet := .F.
	elseif nVlrForm <= 0
		cMsgErr := "Informe pelo menos uma forma/documento de entrada!"
		lRet := .F.
	elseif nVlrComp <= 0 .AND. !lVldImpRel
		cMsgErr := "Informe o valor e a forma de saída!"
		lRet := .F.
	elseif nVlrComp <> nVlrForm .AND. !lVldImpRel
		cMsgErr := "Valor total de saídas nao confere com o valor total de entradas."
		lRet := .F.
	elseif empty(cVendedor) .AND. !lVldImpRel
		cMsgErr := "Informe o vendedor para realizar a operação!"
		lRet := .F.
	elseif empty(cNomVend) .AND. !lVldImpRel
		cMsgErr := "Vendedor informado não encontrado na base! Verificar cadastro."
		lRet := .F.
	elseif empty(cJustif) .AND. !lVldImpRel
		cMsgErr := "Informe uma justificativa para esta compensação."
		lRet := .F.
	else
		lRet := VldNF(2) //valido vinculo com NF
	endif

	//valido database com o date server
	if lRet .AND. !lConfCash .AND. dDataBase <> Date()
		cMsgErr := "A data do sistema esta diferente da data do sistema operacional. Favor efetuar o logoff do sistema."
		lRet := .F.
	endif
	
	if lRet .AND. !lConfCash
		//validaçao maximo a compensar, chama alcada
		if lAlcada .AND. lAlcCmp .AND. !lVldImpRel
			if nVlrComp > nVlrMax
				if !LibAlcadaCMP(,nVlrComp)
					lRet := TelaLibAlcada(0, "Valor a compensar acima do maximo permitido!"+CRLF+"Solicite liberação por alçada de um supervisor.", nVlrComp,,, @cUsrLibAlc)
				endif
			endif
		endif

		//validaçao de credito e limites das formas
		if lRet .AND. !lVldImpRel
			lRet := ValidaCred(@cUsrLibAlc)
		endif
	endif

	if lRet
		if !lVldImpRel
			if !lConfCash .AND. !lVincVend
				U_SetMsgRod("Aguarde, incluindo compensação...")
			endif
			lRet := DoGrava()
		endif
	else
		aLogAlcada := {} //se nao autorizou compensaco limpo log alcada
		if lConfCash .OR. lVincVend
			MsgInfo(cMsgErr, "Atenção")
		else
			U_SetMsgRod(cMsgErr)
		endif
	endif

Return lRet

//----------------------------------------------------------------------------------------
// Faz liberação da compensaçao por alçada
//----------------------------------------------------------------------------------------
Static Function LibAlcadaCMP(cCodUsr, nVlrCmp)

	Local nZ
	Local lRet := .F.
	Local nVlrMaxAlc := 0
	Local cMsgLog 
	Default cCodUsr := RetCodUsr()

	cMsgLog := "Alçada Valor Maximo a Compensar." + CRLF
	cMsgLog += "Cliente: " + cCodCli +"/"+ cLojCli + " - " + cNomCli + CRLF
	cMsgLog += "Valor a Compensar: " + cValToChar(nVlrComp) + CRLF
	cMsgLog += "Valor Maximo sem Alçada: " + cValToChar(nVlrMax) + CRLF

	If cCodUsr == '000000' //usuario administrador, libera tudo
		lRet := .T.
		cMsgLog += "Usuário Liberação: " + cCodUsr + " - " + USRRETNAME(cCodUsr) + CRLF
	else
		aGrupos := UsrRetGrp(UsrRetName(cCodUsr), cCodUsr)

		nVlrMaxAlc := Posicione("U0D",1,xFilial("U0D")+Space(TamSx3("U04_GRUPO")[1])+PadR(cCodUsr,TamSx3("U04_USER")[1]),"U0D_VLRCMP")
		if nVlrMaxAlc > nVlrCmp
			lRet := .T.
			cMsgLog += "Usuário Liberação: " + cCodUsr + " - " + USRRETNAME(cCodUsr) + CRLF
		endif

		if !lRet
			for nZ := 1 to len(aGrupos)
				nVlrMaxAlc := Posicione("U0D",1,xFilial("U0D")+PadR(aGrupos[nZ],TamSx3("U04_GRUPO")[1])+Space(TamSx3("U04_USER")[1]),"U0D_VLRCMP")
				if nVlrMaxAlc > nVlrCmp
					lRet := .T.
					cMsgLog += "Grupo de Usuário Liberação: " + aGrupos[nZ] + " - " + GrpRetName(aGrupos[nZ]) + CRLF
					EXIT
				endif
			next nZ
		endif
	endif

	//para gravaçao do log alçada
	if lRet
		cMsgLog += "Valor Maximo Usuário Alçada: " + cValToChar(nVlrMaxAlc) + CRLF
		aadd(aLogAlcada, {"ALCCMP", USRRETNAME(cCodUsr), cMsgLog})
	endif

Return lRet

//----------------------------------------------------------------------
// chama tela de liberação por alçada
// nTipo: 0=Vlr Max Comp; 1=Bloqueios Limite; 2=Valor Limite
//----------------------------------------------------------------------
Static Function TelaLibAlcada(nTipo, cMsgErr, nVlrVenda, nVlrLim, nSaldoLim, cUsrLibAlc, cMsgLibAlc)
	
Local lRet := .F.
Local lEscape := .T.
Local aLogin
Local nY
Local cMsgUser := ""

While lEscape
	aLogin := U_TelaLogin(cMsgUser+cMsgErr,iif(nTipo==0,"Valor Maximo Comp.","Limite Credito"), .T.)
	if empty(aLogin) //cancelou tela
		lEscape := .F.
	else
		if nTipo == 0
			lRet := LibAlcadaCMP(aLogin[1], nVlrVenda)
			if lRet
				cUsrLibAlc := aLogin[1]
			else
				cMsgUser := "Usuário "+Alltrim(aLogin[2])+" não possui alçada suficiente para Liberar esta Compensação." + CRLF
			endif
		elseif nTipo == 1
			lRet := LibAlcadaBlq(aLogin[1], cMsgLibAlc)
			if lRet
				cUsrLibAlc := aLogin[1]
			else
				cMsgUser := "Usuário "+Alltrim(aLogin[2])+" não possui alçada suficiente para Liberar Compensação de cliente com Bloqueio de Crédito." + CRLF
			endif
		else
			lRet := LibAlcadaLim(aLogin[1], nVlrVenda, nVlrLim, nSaldoLim, cMsgLibAlc)
			if lRet
				cUsrLibAlc := aLogin[1]
			else
				cMsgUser := "Usuário "+Alltrim(aLogin[2])+" não possui alçada suficiente para Liberar Compensação sem Saldo de Limite de Crédito." + CRLF
			endif
		endif
		lEscape := !lRet
	endif
enddo

Return lRet

//--------------------------------------------------------------------
// Validação de limite e bloqueio de crédito
//--------------------------------------------------------------------
Static Function ValidaCred(cUsrLibAlc)

	Local lActiveVCred := SuperGetMV("TP_ACTVCR",,.F.)
	Local lRet := .T.
	Local nX, cMsgErr
	Local aLimites := {}, aParam := {}
	Local lAlcada	:= SuperGetMv("ES_ALCADA",.F.,.F.)
	Local lAlcLimit	:= SuperGetMv( "ES_ALCLIM",.F.,.F.)
	Local lLibLim := .F.
	Local cUsrLibVBL := ""
	Local cUsrLibVSL := ""
	Local cMsgLibAlc := ""
	Local cGetCdUsr	 := RetCodUsr()
	Local lTP_ACTLCS := SuperGetMv("TP_ACTLCS",,.F.) //habilita limite de credito por segmento (filial)
	Local lTP_ACTLGR := SuperGetMv("TP_ACTLGR",,.T.) //habilita limite de credito por grupo de clientes
	Local cSegmento := SuperGetMv("TP_MYSEGLC",," ") //define o segmento da filial do PDV
	Local cLCOffline := SuperGetMV("TP_LCOFFLI",,"0") //define se vai usar limite offline e como vai usar: 0=Somente online; 1=Prioriza Online; 2=Apenas Offline

	/*Parametro Define a prioridade da validação de limite quando há grupo de clientes: 
	0=Limite Ambos: irá fazer a validação tanto do limite do cliente quanto do limite do grupo. Caso um 
		dos dois não tiver saldo para a operação, será barrada a venda (podendo liberar por supervisor). 
	1=Limite Grupo: irá ignorar a validação do limite do cliente, e fazer a validação apenas considerando o 
		limite do grupo*/
	Local cPriGrupo := SuperGetMv("TP_LCPRIOR",,"0") 

	Local aListCli := {} /*/{[01]"CGC",
							 [02]"CLIENTE",
							 [03]"LOJA",
							 [04]"GRUPO",
							 [05]"FORMA",
							 [06]"VALOR",
							 [07]"LIM CRED CLI",
							 [08]"LIM USAD CLI",
							 [09]"SLD LIM CLI",
							 [10]"LIM CRED GRP",
							 [11]"LIM USAD GRP",
							 [12]"SLD LIM GRP",
							 [13]"BLQ CLI",
							 [14]"BLQ GRP"} /*/

	if !lActiveVCred
		if !lVincVend
			U_SetMsgRod("Validação de limite de crédito desativado (TP_ACTVCR).")
		endif
		Return lRet
	endif

	lRetOn := IIF(GetPvProfString(CSECAO, CCHAVE, '0', GetAdv97()) == '0', .F., .T.)

	//Laço parcelas de entrada
	For nX := 1 to len(oMsGetEnt:aCols)
		if !oMsGetEnt:aCols[nX][NPOSDEL]

			cForma := Alltrim(oMsGetEnt:aCols[nX][NPOSFPG])
			If cForma $ "CF/CH" //"Carta Frete" ou "Nota a Prazo" ou "Cheque"
				
				//SA1->(DbSetOrder(1)) //A1_FILIAL+A1_COD+A1_LOJA
				If cForma == "CH"
					cCgc := oMsGetEnt:aCols[nX][NPOSINF][3] //-- CGC do emitente
					//SA1->(DbSeek(xFilial("SA1")+oMsGetEnt:aCols[nX][NPOSINF][13]+oMsGetEnt:aCols[nX][NPOSINF][14]))
				else
					cCgc := oMsGetEnt:aCols[nX][NPOSINF][2] //-- CGC do emitente
					//SA1->(DbSeek(xFilial("SA1")+oMsGetEnt:aCols[nX][NPOSINF][6]+oMsGetEnt:aCols[nX][NPOSINF][7]))
				endif
				SA1->(DbSetOrder(3)) //A1_FILIAL+A1_CGC
				SA1->(DbSeek(xFilial("SA1")+cCgc))

				ACY->(DbSetOrder(1)) // ACY_FILIAL + ACY_GRPVEN
				ACY->(DbSeek(xFilial("ACY")+SA1->A1_GRPVEN))

				nPos := aScan( aListCli, {|x| AllTrim(x[02]+x[03]) == SA1->A1_COD+SA1->A1_LOJA})
				If nPos <= 0
					aadd(aListCli,{ cCgc,;
									SA1->A1_COD,;
									SA1->A1_LOJA,;
									iif(lTP_ACTLGR,SA1->A1_GRPVEN,""),;
									cForma,;
									oMsGetEnt:aCols[nX][NPOSVLR],;
									SA1->A1_XLC,;
									0,;
									0,;
									Iif(ACY->(!Eof()),ACY->ACY_XLC,0),;
									0,;
									0,;
									Iif(!Empty(SA1->A1_XBLQLC),SA1->A1_XBLQLC,'2'),;
									Iif(ACY->(!Eof()),ACY->ACY_XBLPRZ,'2');
									})

				Else
					aListCli[nPos][06] += oMsGetEnt:aCols[nX][NPOSVLR]
					If !(cForma $ aListCli[nPos][05])
						aListCli[nPos][05] += " + "+cForma
					EndIf
				EndIf

			EndIf
		Endif
	Next nX

	If Len(aListCli) > 0

		CursorArrow()
		
		if !lVincVend
			U_SetMsgRod("Pesquisando limite de crédito do cliente"+iif(lRetOn .AND. cLCOffline <> "2"," no Back-Office","")+". Aguarde...")
		endif

		CursorWait()

		aLimites := {}
		aParam := {}
		For nX:=1 to Len(aListCli)
			aadd(aParam,{aListCli[nX][02],aListCli[nX][03],""})
		Next nX
		aParam := {1,aParam}
		if lTP_ACTLCS
			aadd(aParam, cSegmento)
		endif
		if lRetOn .AND. cLCOffline <> "2" //so nao pesquisa online se parametro define apenas offline
			//conout(">> TRETE032 - INICIO - Retorna o limite utilizado de um CLIENTE e GRUPO DE CLIENTE")
			//conout("	Data: "+DTOC(Date())+" / Hora: "+cValToChar(Time())+"")
			aLimites := U_TRETE032(aParam[1],aParam[2],iif(lTP_ACTLCS,aParam[3],))
			If .T. //STBRemoteExecute("_EXEC_RET", {"U_TRETE032",aParam},,, @aLimites)
				If ValType(aLimites) == "A" .AND. Len(aLimites)>0
					For nX:=1 to Len(aLimites)

						//[01] [limite venda] ou [limite saque] UTILIZADO  do [Cliente] / [02] [limite venda] ou [limite saque] UTILIZADO  do [Grupo de Cliente]
						//[03] [limite venda] ou [limite saque] CADASTRADO do [Cliente] / [04] [limite venda] ou [limite saque] CADASTRADO do [Grupo de Cliente]
						//[05] [bloqueio venda] ou [bloqueio saque] do [Cliente]		/ [06] [bloqueio venda] ou [bloqueio saque] do [Grupo de Cliente]

						aListCli[nX][08] := aLimites[nX][01]
						aListCli[nX][07] := aLimites[nX][03]
						aListCli[nX][13] := aLimites[nX][05]
						aListCli[nX][09] := aListCli[nX][07] - aListCli[nX][08] //saldo limite cliente

						aListCli[nX][11] := aLimites[nX][02]
						aListCli[nX][10] := aLimites[nX][04]
						aListCli[nX][14] := aLimites[nX][06]
						aListCli[nX][12] := aListCli[nX][10] - aListCli[nX][11] //saldo limite do grupo de cliente

					Next nX
				Else
					aLimites := {}
				EndIf
			Else
				aLimites := {}
			EndIf

			//conout("")
			//conout("	aLimites: "+U_XtoStrin(aLimites))
			//conout("")
			//conout(">> TRETE032 - FIM - Retorna o limite utilizado de um CLIENTE e GRUPO DE CLIENTE")
			//conout("	Data: "+DTOC(Date())+" / Hora: "+cValToChar(Time())+"")
		endif

		if empty(aLimites) .AND. cLCOffline <> "0" //so nao pesquisa offline se parametro define apenas online
			aLimites := U_TR032OFF(aParam[1],aParam[2],iif(lTP_ACTLCS,aParam[3],))
			For nX:=1 to Len(aLimites)
				//[01] [limite venda] ou [limite saque] UTILIZADO  do [Cliente] / [02] [limite venda] ou [limite saque] UTILIZADO  do [Grupo de Cliente]
				//[03] [limite venda] ou [limite saque] CADASTRADO do [Cliente] / [04] [limite venda] ou [limite saque] CADASTRADO do [Grupo de Cliente]
				//[05] [bloqueio venda] ou [bloqueio saque] do [Cliente]		/ [06] [bloqueio venda] ou [bloqueio saque] do [Grupo de Cliente]

				aListCli[nX][08] := aLimites[nX][01]
				aListCli[nX][07] := aLimites[nX][03]
				aListCli[nX][13] := aLimites[nX][05]
				aListCli[nX][09] := aListCli[nX][07] - aListCli[nX][08] //saldo limite cliente

				aListCli[nX][11] := aLimites[nX][02]
				aListCli[nX][10] := aLimites[nX][04]
				aListCli[nX][14] := aLimites[nX][06]
				aListCli[nX][12] := aListCli[nX][10] - aListCli[nX][11] //saldo limite do grupo de cliente
			Next nX
		endif
		
		if !lVincVend
			U_SetMsgRod("")
		endif

		CursorArrow()

	EndIf

	//valida limite e bloqueio dos clientes/grupo
	For nX:=1 to Len(aListCli)

		//VALIDANDO BLOQUEIOS DE LIMITE PARA COMPENSAÇÃO
		//bloqueio de limite de cliente
		If (empty(aListCli[nX][04]) .OR. cPriGrupo <> "1") .AND. aListCli[nX][13] == '1' 
			cMsgErr := "Cliente "+AllTrim(Posicione("SA1",1,xFilial("SA1")+aListCli[nX][02]+aListCli[nX][03],"A1_NOME"))+" com bloqueio de crédito (PGTO EM "+AllTrim(aListCli[nX][05])+")."
			if lVincVend
				MsgInfo(cMsgErr,"Atenção")
			else
				U_SetMsgRod(cMsgErr)
			endif

			if lAlcada .AND. lAlcLimit
				cMsgLibAlc := "Alçada de Bloqueio de Limite de Credito - Cliente" + CRLF
				cMsgLibAlc += "Cliente/Emitente: " + SA1->A1_COD + "/" + SA1->A1_LOJA + " - " + SA1->A1_NOME + CRLF
				cMsgLibAlc += "Forma Pagamento: " + aListCli[nX][05] + CRLF

				//verifico alçada do prorio usuario
				lLibLim := LibAlcadaBlq(,cMsgLibAlc) 
				//se nao liberou e ja chamou tela açada para alguma forma, tento com ultimo usuário
				if !lLibLim .AND. !empty(cUsrLibAlc)
					lLibLim := LibAlcadaBlq(cUsrLibAlc, cMsgLibAlc) 
				endif
				if !lLibLim 
					//solicita liberaçao de alçada de outro usuario
					lLibLim := TelaLibAlcada(1, cMsgErr+CRLF+"Solicite liberação por alçada de um supervisor.",,,,@cUsrLibAlc, cMsgLibAlc)
					if !lLibLim
						if lVincVend
							MsgInfo("Usuário não tem alçada para Liberar Compensação de Cliente com Bloqueio de Crédito.","Atenção")
						else
							U_SetMsgRod("Usuário não tem alçada para Liberar Compensação de Cliente com Bloqueio de Crédito.")
						endif
						Return .F.
					endif
				endif
			else
				if empty(cUsrLibVBL)
					U_TRETA37B("LIBVBL", "LIBERAR CLIENTE/GRUPO COM BLOQUEIO CREDITO")
					cUsrLibVBL := U_VLACESS1("LIBVBL", cGetCdUsr) 
					If cUsrLibVBL == Nil .OR. Empty(cUsrLibVBL)
						if lVincVend
							MsgInfo("Usuário não tem permissão de acesso para Liberar Compensação de Cliente com Bloqueio de Crédito.","Atenção")
						else
							U_SetMsgRod("Usuário não tem permissão de acesso para Liberar Compensação de Cliente com Bloqueio de Crédito.")
						endif
						Return .F.
					EndIf
				endif
			endif

		//bloqueio de limite de grupo de cliente
		elseif !Empty(aListCli[nX][04]) .and. aListCli[nX][14] == '1' 
			cMsgErr := "Grupo de Cliente "+AllTrim(Posicione("ACY",1,xFilial("ACY")+aListCli[nX][04],"ACY_DESCRI"))+" com bloqueio de crédito (PGTO EM "+AllTrim(aListCli[nX][05])+")."
			if lVincVend
				MsgInfo(cMsgErr,"Atenção")
			else
				U_SetMsgRod(cMsgErr)
			endif

			if lAlcada .AND. lAlcLimit
				cMsgLibAlc := "Alçada de Bloqueio de Limite de Credito - Grupo" + CRLF
				cMsgLibAlc += "Cliente/Emitente: " + aListCli[nX][02] + "/" + aListCli[nX][03] + " - " + Posicione("SA1",1,xFilial("SA1")+aListCli[nX][02]+aListCli[nX][03],"A1_NOME") + CRLF
				cMsgLibAlc += "Grupo do Cliente: " + ACY->ACY_GRPVEN + " - " + ACY->ACY_DESCRI + CRLF
				cMsgLibAlc += "Forma Pagamento: " + aListCli[nX][05] + CRLF

				//verifico alçada do prorio usuario
				lLibLim := LibAlcadaBlq(,cMsgLibAlc) 
				//se nao liberou e ja chamou tela açada para alguma forma, tento com ultimo usuário
				if !lLibLim .AND. !empty(cUsrLibAlc)
					lLibLim := LibAlcadaBlq(cUsrLibAlc,cMsgLibAlc) 
				endif
				if !lLibLim 
					//solicita liberaçao de alçada de outro usuario
					lLibLim := TelaLibAlcada(1, cMsgErr+CRLF+"Solicite liberação por alçada de um supervisor.",,,,@cUsrLibAlc,cMsgLibAlc)
					if !lLibLim
						if lVincVend
							MsgInfo("Usuário não tem alçada para Liberar Compensação de Cliente com Bloqueio de Crédito.","Atenção")
						else
							U_SetMsgRod("Usuário não tem alçada para Liberar Compensação de Cliente com Bloqueio de Crédito.")
						endif
						Return .F.
					endif
				endif
			else
				if empty(cUsrLibVBL)
					U_TRETA37B("LIBVBL", "LIBERAR CLIENTE/GRUPO COM BLOQUEIO CREDITO")
					cUsrLibVBL := U_VLACESS1("LIBVBL", cGetCdUsr)
					If cUsrLibVBL == Nil .OR. Empty(cUsrLibVBL)
						if lVincVend
							MsgInfo("Usuário não tem permissão de acesso para Liberar Compensação de Cliente com Bloqueio de Crédito.","Atenção")
						else
							U_SetMsgRod("Usuário não tem permissão de acesso para Liberar Compensação de Cliente com Bloqueio de Crédito.")	
						endif
						Return .F.
					EndIf
				endif
			endif

		EndIf
		
		//VALIDANOD VALORES DE LIMITE DE CREDITO
		//se valor da venda > saldo limite credito
		If (empty(aListCli[nX][04]) .OR. cPriGrupo <> "1") .AND. aListCli[nX][06] > aListCli[nX][09]
			cMsgErr := "Cliente "+AllTrim(Posicione("SA1",1,xFilial("SA1")+aListCli[nX][02]+aListCli[nX][03],"A1_NOME"))+" não possui limite de crédito (PGTO EM "+AllTrim(aListCli[nX][05])+"). Saldo de Limite: "+Alltrim(Transform(aListCli[nX][09],PesqPict("SL1","L1_VLRLIQ")))
			if lVincVend
				MsgInfo(cMsgErr,"Atenção")
			else
				U_SetMsgRod(cMsgErr)
			endif

			if lAlcada .AND. lAlcLimit
				cMsgLibAlc := "Alçada de Limite de Credito Excedido - Cliente" + CRLF
				cMsgLibAlc += "Cliente/Emitente: " + SA1->A1_COD + "/" + SA1->A1_LOJA + " - " + SA1->A1_NOME + CRLF
				cMsgLibAlc += "Forma Pagamento: " + aListCli[nX][05] + CRLF
				
				//verifico alçada do prorio usuario
				lLibLim := LibAlcadaLim(,aListCli[nX][06], aListCli[nX][07], aListCli[nX][09], cMsgLibAlc) 
				//se nao liberou e ja chamou tela açada para alguma forma, tento com ultimo usuário
				if !lLibLim .AND. !empty(cUsrLibAlc)
					lLibLim := LibAlcadaLim(cUsrLibAlc, aListCli[nX][06], aListCli[nX][07], aListCli[nX][09], cMsgLibAlc)
				endif
				if !lLibLim 
					//solicita liberaçao de alçada de outro usuario
					lLibLim := TelaLibAlcada(2, cMsgErr+CRLF+"Solicite liberação por alçada de um supervisor.",aListCli[nX][06], aListCli[nX][07], aListCli[nX][09], @cUsrLibAlc, cMsgLibAlc)
					if !lLibLim
						if lVincVend
							MsgInfo("Usuário não tem alçada para Liberar Compensação sem Saldo de Limite de Crédito.","Atenção")
						else
							U_SetMsgRod("Usuário não tem alçada para Liberar Compensação sem Saldo de Limite de Crédito.")	
						endif
						Return .F.
					endif
				endif
			else
				if empty(cUsrLibVSL)
					U_TRETA37B("LIBVSL", "LIBERAR CLIENTE/GRUPO SEM SALDO LIMITE DE CREDITO")
					cUsrLibVSL := U_VLACESS1("LIBVSL", cGetCdUsr)
					If cUsrLibVSL == Nil .OR. Empty(cUsrLibVSL)
						if lVincVend
							MsgInfo("Usuário não tem permissão de acesso para Liberar Compensação sem Saldo de Limite de Crédito.","Atenção")
						else
							U_SetMsgRod("Usuário não tem permissão de acesso para Liberar Compensação sem Saldo de Limite de Crédito.")	
						endif
						Return .F.
					EndIf
				endif
			endif
		
		//se tem grupo cliente e valor da venda > saldo limite credito do grupo
		ElseIf !Empty(aListCli[nX][04]) .and. aListCli[nX][06] > aListCli[nX][12]
			cMsgErr := "Grupo de Cliente "+AllTrim(Posicione("ACY",1,xFilial("ACY")+aListCli[nX][04],"ACY_DESCRI"))+" não possui limite de crédito (PGTO EM "+AllTrim(aListCli[nX][05])+"). Saldo de Limite: "+Alltrim(Transform(aListCli[nX][12],PesqPict("SL1","L1_VLRLIQ")))
			if lVincVend
				MsgInfo(cMsgErr,"Atenção")
			else
				U_SetMsgRod(cMsgErr)
			endif

			if lAlcada .AND. lAlcLimit
				cMsgLibAlc := "Alçada de Limite de Credito Excedido - Grupo" + CRLF
				cMsgLibAlc += "Cliente/Emitente: " + aListCli[nX][02] + "/" + aListCli[nX][03] + " - " + Posicione("SA1",1,xFilial("SA1")+aListCli[nX][02]+aListCli[nX][03],"A1_NOME") + CRLF
				cMsgLibAlc += "Grupo do Cliente: " + ACY->ACY_GRPVEN + " - " + ACY->ACY_DESCRI + CRLF
				cMsgLibAlc += "Forma Pagamento: " + aListCli[nX][05] + CRLF

				//verifico alçada do prorio usuario
				lLibLim := LibAlcadaLim(, aListCli[nX][06], aListCli[nX][10], aListCli[nX][12],cMsgLibAlc) 
				if !lLibLim .AND. !empty(cUsrLibAlc)
					lLibLim := LibAlcadaLim(cUsrLibAlc, aListCli[nX][06], aListCli[nX][10], aListCli[nX][12],cMsgLibAlc) 
				endif
				if !lLibLim 
					//solicita liberaçao de alçada de outro usuario
					lLibLim := TelaLibAlcada(2, cMsgErr+CRLF+"Solicite liberação por alçada de um supervisor.",aListCli[nX][06], aListCli[nX][07], aListCli[nX][09],@cUsrLibAlc,cMsgLibAlc)
					if !lLibLim
						if lVincVend
							MsgInfo("Usuário não tem alçada para Liberar Compensação sem Saldo de Limite de Crédito.","Atenção")
						else
							U_SetMsgRod("Usuário não tem alçada para Liberar Compensação sem Saldo de Limite de Crédito.")	
						endif
						Return .F.
					endif
				endif
			else
				if empty(cUsrLibVSL)
					U_TRETA37B("LIBVSL", "LIBERAR VENDA CLIENTE/GRUPO SEM SALDO LIMITE DE CREDITO")
					cUsrLibVSL := U_VLACESS1("LIBVSL", cGetCdUsr)
					If cUsrLibVSL == Nil .OR. Empty(cUsrLibVSL)
						if lVincVend
							MsgInfo("Usuário não tem permissão de acesso para Liberar Compensação sem Saldo de Limite de Crédito.","Atenção")
						else
							U_SetMsgRod("Usuário não tem permissão de acesso para Liberar Compensação sem Saldo de Limite de Crédito.")	
						endif
						Return .F.
					EndIf
				endif
			endif

		EndIf

	Next nX

	If lRet .AND. !lVincVend
		U_SetMsgRod("")	
	EndIf

Return lRet

//----------------------------------------------------------------------
// Verifica alçada de limite de credito
//----------------------------------------------------------------------
Static Function LibAlcadaLim(cCodUsr, nVlrVenda, nVlrLim, nSaldoLim, cMsgLog)

	Local nZ
	Local lRet := .F.
	Local nVlrLimAlc := 0
	Local nPerLimAlc := 0
	Default cCodUsr := RetCodUsr()
	Default cMsgLog := ""

	cMsgLog += "Valor Forma: " + cValToChar(nVlrVenda) + CRLF
	cMsgLog += "Valor Limite Credito: " + cValToChar(nVlrLim) + CRLF
	cMsgLog += "Saldo Limite Credito: " + cValToChar(nSaldoLim) + CRLF

	If cCodUsr == '000000' //usuario administrador, libera tudo
		lRet := .T.
		cMsgLog += "Usuário Liberação: " + cCodUsr + " - " + USRRETNAME(cCodUsr) + CRLF
	else
		//zero o saldo caso ele seja negativo
		if nSaldoLim < 0
			nSaldoLim := 0
		endif
		aGrupos := UsrRetGrp(UsrRetName(cCodUsr), cCodUsr)

		nVlrLimAlc := Posicione("U0D",1,xFilial("U0D")+Space(TamSx3("U04_GRUPO")[1])+PadR(cCodUsr,TamSx3("U04_USER")[1]),"U0D_VNOLIM")
		nPerLimAlc := Posicione("U0D",1,xFilial("U0D")+Space(TamSx3("U04_GRUPO")[1])+PadR(cCodUsr,TamSx3("U04_USER")[1]),"U0D_PNOLIM")

		// limite alçaca >= saldo sem limite				x % do limite >= saldo sem limite
		if (nVlrLimAlc >= (nVlrVenda - nSaldoLim)) .OR. ( (nVlrLim*nPerLimAlc/100) >= (nVlrVenda - nSaldoLim) )
			lRet := .T.
			cMsgLog += "Usuário Liberação: " + cCodUsr + " - " + USRRETNAME(cCodUsr) + CRLF
			cMsgLog += "Vlr Limite Alçada: " + cValToChar(nVlrLimAlc) + CRLF
			cMsgLog += "% Limite Alçada: " + cValToChar(nPerLimAlc) + CRLF
			cMsgLog += "Vlr obtido do % Limite: " + cValToChar((nVlrLim*nPerLimAlc/100)) + CRLF
		endif

		if !lRet
			for nZ := 1 to len(aGrupos)
				nVlrLimAlc := Posicione("U0D",1,xFilial("U0D")+PadR(aGrupos[nZ],TamSx3("U04_GRUPO")[1])+Space(TamSx3("U04_USER")[1]),"U0D_VNOLIM")
				nPerLimAlc := Posicione("U0D",1,xFilial("U0D")+PadR(aGrupos[nZ],TamSx3("U04_GRUPO")[1])+Space(TamSx3("U04_USER")[1]),"U0D_PNOLIM")

				// limite alçaca >= saldo sem limite				% do limite >= saldo sem limite
				if (nVlrLimAlc >= (nVlrVenda - nSaldoLim)) .OR. ( (nVlrLim*nPerLimAlc/100) >= (nVlrVenda - nSaldoLim) )
					lRet := .T.
					cMsgLog += "Grupo de Usuário Liberação: " + aGrupos[nZ] + " - " + GrpRetName(aGrupos[nZ]) + CRLF
					cMsgLog += "Vlr Limite Alçada: " + cValToChar(nVlrLimAlc) + CRLF
					cMsgLog += "% Limite Alçada: " + cValToChar(nPerLimAlc) + CRLF
					cMsgLog += "Vlr obtido do % Limite: " + cValToChar((nVlrLim*nPerLimAlc/100)) + CRLF
					EXIT
				endif
			next nZ
		endif
	endif

	//para gravaçao do log alçada
	if lRet
		aadd(aLogAlcada, {"ALCLIM", USRRETNAME(cCodUsr), cMsgLog})
	endif

Return lRet

//----------------------------------------------------------------------
// Verifica alçada de bloqueio de credito
//----------------------------------------------------------------------
Static Function LibAlcadaBlq(cCodUsr, cMsgLog)

	Local nZ
	Local lRet := .F.
	Default cCodUsr := RetCodUsr()
	Default cMsgLog := ""
	
	If cCodUsr == '000000' //usuario administrador, libera tudo
		cMsgLog += "Usuário Liberação: " + cCodUsr + " - " + USRRETNAME(cCodUsr) + CRLF
		lRet := .T.
	else
		aGrupos := UsrRetGrp(UsrRetName(cCodUsr), cCodUsr)

		cLimBlq := Posicione("U0D",1,xFilial("U0D")+Space(TamSx3("U04_GRUPO")[1])+PadR(cCodUsr,TamSx3("U04_USER")[1]),"U0D_VDCBLQ")
		if cLimBlq == "S"
			cMsgLog += "Usuário Liberação: " + cCodUsr + " - " + USRRETNAME(cCodUsr) + CRLF
			lRet := .T.
		endif

		if !lRet
			for nZ := 1 to len(aGrupos)
				cLimBlq := Posicione("U0D",1,xFilial("U0D")+PadR(aGrupos[nZ],TamSx3("U04_GRUPO")[1])+Space(TamSx3("U04_USER")[1]),"U0D_VDCBLQ")
				if cLimBlq == "S"
					lRet := .T.
					cMsgLog += "Grupo de Usuário Liberação: " + aGrupos[nZ] + " - " + GrpRetName(aGrupos[nZ]) + CRLF
					EXIT
				endif
			next nZ
		endif
	endif

	//para gravaçao do log alçada
	if lRet
		cMsgLog += "Campo U0D_VDCBLQ = S"
		aadd(aLogAlcada, {"ALCLIM", USRRETNAME(cCodUsr), cMsgLog})
	endif

Return lRet

//----------------------------------------------------------------------------------------
// Gravação da inclusão da compensação
//----------------------------------------------------------------------------------------
Static Function DoGrava()

	Local cPrefixComp := SuperGetMv( "MV_XPFXCOM" , .F. , "CMP",)
	Local nIntervalo	:= SuperGetMV("MV_LJINTER") //Intervalo das parcelas
	Local cNatCHT := SuperGetMv( "MV_XCNATCT" , .F. , "CHEQUE",)
	Local aStation
	Local cNumMov := iif(lConfCash,SLW->LW_NUMMOV,STDNumMov())
	Local nDinheiro := 0
	Local nX, nY, nParcGrv, aParcGrv, nDiferenca, dData, nValor
	Local cSeq := StrZero(0,TamSx3("E1_PARCELA")[1])

	//Informacoes da estacao
	if lConfCash
		aStation := {SLW->LW_OPERADO, SLW->LW_ESTACAO, SLW->LW_SERIE, SLW->LW_PDV, SLG->LG_SERNFIS}
	else
		aStation := STBInfoEst( 1, .T. ) // [1]-CAIXA [2]-ESTACAO [3]-SERIE [4]-PDV [5]-LG_SERNFIS
	endif

	SA1->(DbSetOrder(1)) //A1_FILIAL+A1_COD+A1_LOJA
	SA1->(DbSeek(xFilial("SA1")+cCodCli+cLojCli))

	CursorWait()

	cNumCmp := GetUC0Num()

	if empty(cNumCmp)
		cNumCmp := "INCLUINDO"
		CursorArrow()
		Return .F.
	endif

	oNumCmp:Refresh()

	BeginTran()

	//gravo codificação para evitar duplicidade de código.
	Reclock("UC0", .T.) //altera
		UC0->UC0_FILIAL := xFilial("UC0")
		UC0->UC0_NUM 	:= cNumCmp
		UC0->UC0_DATA	:= dDataBase
		if lConfCash
			UC0->UC0_HORA	:= SLW->LW_HRABERT
		else
			UC0->UC0_HORA	:= Time()
		endif
		UC0->UC0_PDV	:= aStation[4]
		UC0->UC0_OPERAD := aStation[1]
		UC0->UC0_NUMMOV := cNumMov
		UC0->UC0_ESTACA := aStation[2]
		UC0->UC0_CLIENT := SA1->A1_COD
		UC0->UC0_LOJA	:= SA1->A1_LOJA
		UC0->UC0_PLACA	:= cPlaca
		UC0->UC0_VEND 	:= cVendedor
		if UC0->(FieldPos("UC0_DOC")) > 0 .AND. UC0->(FieldPos("UC0_SERIE")) > 0
			UC0->UC0_DOC := cDocNf
			UC0->UC0_SERIE := cSerieNf
		endif
	UC0->(MsUnlock())

	//Tratamento para Cheque Troco
	if nVlrDin > 0
		if lConfCash .OR. !SuperGetMV("TP_ACTCHT",,.F.)
			nDinheiro := nVlrDin
		else
			aRetChq	:= U_TPDVE007(nVlrDin,{UC0->UC0_NUM, cPrefixComp, "", UC0->UC0_CLIENT, UC0->UC0_LOJA, cNatCHT, UC0->UC0_PDV}) //rotina de selecao de cheque troco
			CursorWait()
			nDinheiro := aRetChq[1]
		endif
	endif

	Reclock("UC0", .F.) //inclui
		UC0->UC0_VLDINH := nDinheiro
		UC0->UC0_VLVALE := nVlrVale
		UC0->UC0_VLCHTR := nVlrDin - nDinheiro
		UC0->UC0_VLTOT	:= nVlrComp
		UC0->UC0_JUSTIF := cJustif + iif(!empty(cUsrCmp) .AND. cUsrCmp <> RetCodUsr()," Acesso liberado para inclusão por usuário: " + USRRETNAME(cUsrCmp),"")
		UC0->UC0_GERFIN := iif(lConfCash,"R","N")
		UC0->UC0_ESTORN := "N"
	UC0->(MsUnlock())

	//Gravando parcelas de entrada
	For nX := 1 to len(oMsGetEnt:aCols)
		if !oMsGetEnt:aCols[nX][NPOSDEL]

			nParcGrv := 1
			aParcGrv := {}
			if oMsGetEnt:aCols[nX][NPOSFPG] $ "CC/CD"
				nParcGrv := oMsGetEnt:aCols[nX][NPOSINF][9] //parcelas
				if nParcGrv > 1
					//Ajusto valor da parcela
					nDiferenca := Round( oMsGetEnt:aCols[nX][NPOSVLR] - (( Round( oMsGetEnt:aCols[nX][NPOSVLR] / nParcGrv,2) ) * nParcGrv), 2)
					For nY := 1 to nParcGrv
						dData := oMsGetEnt:aCols[nX][NPOSDAT] + IIf(nY = 1, 0, nIntervalo*(nY-1))
						nValor := Round( oMsGetEnt:aCols[nX][NPOSVLR] / nParcGrv, 2 )
						if nY == nParcGrv //ultima parcela soma diferença
							nValor := Round( nValor + nDiferenca, 2 )
						endif
						aadd(aParcGrv, {nValor, dData})
					next nY
				else
					aadd(aParcGrv, {oMsGetEnt:aCols[nX][NPOSVLR], oMsGetEnt:aCols[nX][NPOSDAT]})
				endif
			endif

			for nY := 1 to nParcGrv
				cSeq := Soma1(cSeq)

				Reclock("UC1", .T.) //inclui
				UC1->UC1_FILIAL := xFilial("UC1")
				UC1->UC1_NUM 	:= cNumCmp
		 		UC1->UC1_FORMA	:= oMsGetEnt:aCols[nX][NPOSFPG]
		 		UC1->UC1_SEQ	:= cSeq

		 		if oMsGetEnt:aCols[nX][NPOSFPG] == "CH"
		 			//aInfComp := {nValorCh, dDataCh, cCgcEmit, cNomeEmit, cCmc7, cBanco, cAgencia, cConta, cNumCh, cRG, cTel, cComp, cCodEmit, cLojEmit}
		 			UC1->UC1_VALOR	:= oMsGetEnt:aCols[nX][NPOSINF][1]
		 			UC1->UC1_VENCTO := oMsGetEnt:aCols[nX][NPOSINF][2]
		 			UC1->UC1_BANCO 	:= oMsGetEnt:aCols[nX][NPOSINF][6]
		 			UC1->UC1_AGENCI := oMsGetEnt:aCols[nX][NPOSINF][7]
		 			UC1->UC1_CONTA 	:= oMsGetEnt:aCols[nX][NPOSINF][8]
		 			UC1->UC1_NUMCH 	:= oMsGetEnt:aCols[nX][NPOSINF][9]
		 			UC1->UC1_CGC 	:= oMsGetEnt:aCols[nX][NPOSINF][3]
		 			UC1->UC1_RG 	:= oMsGetEnt:aCols[nX][NPOSINF][10]
		 			UC1->UC1_TEL1 	:= oMsGetEnt:aCols[nX][NPOSINF][11]
		 			UC1->UC1_COMPEN := oMsGetEnt:aCols[nX][NPOSINF][12]
					UC1->UC1_CMC7 	:= oMsGetEnt:aCols[nX][NPOSINF][5]
					if UC1->(FieldPos("UC1_COD"))>0
						UC1->UC1_COD  := oMsGetEnt:aCols[nX][NPOSINF][13]
						UC1->UC1_LOJA := oMsGetEnt:aCols[nX][NPOSINF][14]
					endif
		 		elseif oMsGetEnt:aCols[nX][NPOSFPG] $ "CC/CD"
		 			//aInfComp := {nValorC, nTipoOper, cRedeAut, cBandeira, cAdmFin, cNsuDoc, cAutoriz, dDataTran, nParcelas}
		 			UC1->UC1_VALOR	:= aParcGrv[nY][1]
		 			UC1->UC1_VENCTO := aParcGrv[nY][2]
		 			UC1->UC1_ADMFIN := oMsGetEnt:aCols[nX][NPOSINF][5]
		 			UC1->UC1_NSUDOC := oMsGetEnt:aCols[nX][NPOSINF][6]
		 			UC1->UC1_CODAUT := oMsGetEnt:aCols[nX][NPOSINF][7]
		 			UC1->UC1_OBS 	:= "REDEAUT:"+oMsGetEnt:aCols[nX][NPOSINF][3]+" / BANDEIRA:"+oMsGetEnt:aCols[nX][NPOSINF][4]
		 			UC1->UC1_COMPEN := cValToChar(nParcGrv)
		 		elseif oMsGetEnt:aCols[nX][NPOSFPG] == "CF"
		 			//aInfComp := {nValorCF, cEmitCF, cNomeEmiCF, cCFrete, cObserv, cCodCF, cLojCF}
		 			UC1->UC1_VALOR	:= oMsGetEnt:aCols[nX][NPOSVLR]
		 			UC1->UC1_VENCTO := oMsGetEnt:aCols[nX][NPOSDAT]
					UC1->UC1_CGC 	:= oMsGetEnt:aCols[nX][NPOSINF][2]
					if UC1->(FieldPos("UC1_COD"))>0
						UC1->UC1_COD  := oMsGetEnt:aCols[nX][NPOSINF][6]
						UC1->UC1_LOJA := oMsGetEnt:aCols[nX][NPOSINF][7]
					endif
		 			UC1->UC1_CFRETE := oMsGetEnt:aCols[nX][NPOSINF][4]
		 			UC1->UC1_OBS 	:= oMsGetEnt:aCols[nX][NPOSINF][5]
		 		endif

		 		UC1->(MsUnlock())

		 		if !lConfCash
		 			U_UREPLICA("UC1",1,UC1->UC1_FILIAL + UC1->UC1_NUM + UC1->UC1_FORMA + UC1->UC1_SEQ, "I")
		 		endif

			next nY
		endif
	next nX

	if !lConfCash
		U_UREPLICA("UC0",1,UC0->UC0_FILIAL + UC0->UC0_NUM, "I")
	endif

	if SuperGetMv("ES_ALCADA",.F.,.F.) .AND. !empty(aLogAlcada) 
		for nX := 1 to len(aLogAlcada)
			U_TR037LOG(aLogAlcada[nX][1], aLogAlcada[nX][2], UC0->UC0_FILIAL + UC0->UC0_NUM, aLogAlcada[nX][3])
		next nX
	endif

	EndTran()

	if !lConfCash
		//faz a impressão do cupom nao fiscal
		ImpCompIF()

		if nVlrVale > 0
			//impressao comprovante vale haver
			U_TPDVR006(nVlrVale, .T./*lCmp*/, UC0->UC0_ESTACA )
		endif

		//limpa tela e mostra mensagem de sucesso!
		U_TPDVA5CL(.T.)
		if lVincVend
			MsgInfo("Compensação incluida com sucesso! Codigo: " + UC0->UC0_NUM, "Atenção")
		else
			U_SetMsgRod("Compensação incluida com sucesso! Codigo: " + UC0->UC0_NUM )
		endif
	endif

	CursorArrow()

Return .T.

//---------------------------------------------------------------------------
//Pega proxima numeração de compensação considerando o prefixo
//---------------------------------------------------------------------------
Static Function GetUC0Num()

	Local aAreaUC0 := UC0->(GetArea())
	Local cRet := ""
	Local cCondicao		:= ""
	Local bCondicao
	Local nTamAmb := 3
	Local cAmbiente :=  PadR(GetMV("MV_LJAMBIE"),nTamAmb)
	Local cQry
	Local lFinCompart := len(Alltrim(xFilial("SE1"))) <> len(Alltrim(xFilial("UC0")))

	UC0->(DbSetOrder(1))
	cRet := StrZero(1,TamSx3("UC0_NUM")[1]-nTamAmb,0)

	#IFDEF TOP
		cQry := "SELECT MAX(UC0_NUM) PROX "
		cQry += " FROM " + RetSqlName("UC0")
		if lFinCompart
			cQry += " WHERE 1 = 1 "
		else
			cQry += " WHERE UC0_FILIAL = '"+xFilial("UC0")+"' "
		endif
		cQry += "   AND SUBSTRING(UC0_NUM,1,"+cValToChar(nTamAmb)+") = '"+cAmbiente+"'"
		cQry := ChangeQuery(cQry)
		If Select("QAUX") > 0
			QAUX->(dbCloseArea())
		EndIf
		TcQuery cQry NEW Alias "QAUX"
		If QAUX->(!Eof()) .AND. !Empty(QAUX->PROX)
			cRet := SubStr(QAUX->PROX,nTamAmb+1)
			cRet := SOMA1(cRet)
		EndIf
		QAUX->(dbCloseArea())
	#ELSE
		cCondicao := "	UC0_FILIAL == '"+xFilial("UC0")+"' "
		cCondicao += "	.AND. '"+cAmbiente+"' == SubStr(UC0_NUM,1,"+cValToChar(nTamAmb)+")  "
		// limpo os filtros
		UC0->(DbClearFilter())
		// executo o filtro
		bCondicao 	:= "{|| " + cCondicao + " }"
		UC0->(DbSetFilter(&bCondicao,cCondicao))
		UC0->(DbGoBottom()) //vou para o ultimo
		if UC0->(!Eof())
			cRet := SubStr(UC0->UC0_NUM,nTamAmb+1)
			cRet := SOMA1(cRet)
		endif
		UC0->(DbClearFilter())
	#ENDIF

	//Enquanto encontrar o numero ja utilizado, soma um
	While UC0->(DbSeek(xFilial("UC0")+cAmbiente+cRet))
		cRet := SOMA1(cRet)
	enddo

	RestArea(aAreaUC0)

Return (cAmbiente+cRet)

//-----------------------------------------------------------
/* Imprime comprovante não fiscal da compensacao
  LAYOUT IMPRESSAO CUPOM COMPENSAÇAO
         1         2         3         4
1234567890123456789012345678901234567890

----------------------------------------
       MARAJO APARECIDA DE GOIANIA
----------------------------------------

       *** COMPENSAÇÃO VALORES ***

DATA.....: XX/XX/XXXX  HORA...: HH:MM:SS
NUM COMP.: XXXXXXXXX   PLACA..: AAA-9X99
OPERADOR.: CAIXA X
CLIENTE..: FULANO DE TAL

VALOR TOTAL COMPENSADO: R$ 2000,00
**(DOIS MIL REAIS)**

FORMAS E VALORES ENTRADA:
CHEQUE A VISTA - R$ 2000,00

FORMAS E VALORES SAÍDA:
DINHEIRO: 2000,00

----------------------------------------
APLICATIVO: MICROSIGA PROTHEUS - TOTVS
*/
//-----------------------------------------------------------
Static Function ImpCompIF(lBrowse)

	Local aArea    := GetArea()
	Local aAreaSA1 := SA1->( GetArea() )
	Local aAreaUC1 := UC1->( GetArea() )
	Local aAreaSM0 := SM0->( GetArea() )
	Local aAreaSA6 := SA6->( GetArea() )

	Local nLarg         := 48 //considera o cupom de 40 posições
	Local nPosFor, nX
	Local aMsgImp		:= {} //mensagens do cupom
	Local cMsgImp         := ""
	Local cExtenso		:= ""
	Local cRodape      := ""
	Local nVias         := 2 //numero de vias (2 - uma para o cliente outra para a marajo)
	Local aFormComp 	:= {} //{Forma, Valor}
	Default lBrowse := .F. //define se está chamando do browse ou não

	if lBrowse
		if oMsGetCmp:acols[oMsGetCmp:nAt][Len(oMsGetCmp:aHeader)+1] > 0
			UC0->(DbGoTo(oMsGetCmp:acols[oMsGetCmp:nAt][Len(oMsGetCmp:aHeader)+1]))
		else
			Return
		endif
	endif

	if !IsInCallStack("STIPosMain")
		if lVincVend
			MsgInfo("Falha na comunicação com a impressora!","Atenção")
		else
			U_SetMsgRod("Falha na comunicação com a impressora!" )
		endif
		Return
	endif

	Posicione("SA1",1,xFilial("SA1")+UC0->UC0_CLIENT+UC0->UC0_LOJA,"A1_NOME")
	Posicione("SA6",1,xFilial("SA6")+UC0->UC0_OPERAD,"A6_NOME")

	//forço o posicionamento na SM0
	SM0->(DbGoTop())
	While SM0->(!Eof())
		If (AllTrim(SM0->M0_CODFIL) == AllTrim(cFilAnt)) .and. (AllTrim(SM0->M0_CODIGO) == AllTrim(cEmpAnt))
			Exit
		EndIf
	 	SM0->(DbSkip())
	EndDo

	AAdd( aMsgImp, Space(nLarg) )
	AAdd( aMsgImp, PadR(AllTrim(SM0->M0_NOME) + " ("+AllTrim(SM0->M0_FILIAL)+")",nLarg) ) //SM0->M0_NOMECOM
	AAdd( aMsgImp, PadR("CNPJ: " + Substr(SM0->M0_CGC,1,2)+ "." +Substr(SM0->M0_CGC,3,3)+ "." +Substr(SM0->M0_CGC,6,3)+ "/" +Substr(SM0->M0_CGC,9,4)+ "-" +Substr(SM0->M0_CGC,13,2),nLarg) )
	AAdd( aMsgImp, PadR("EMISSÃO: " + dtoc( date() ) + "   HORA: " + time() ,nLarg) )
	AAdd( aMsgImp, Space(nLarg) )
	AAdd( aMsgImp, Replicate("-",nLarg) )
	AAdd( aMsgImp, Replicate(chr(32),13)+PadR("COMPENSAÇÃO DE VALORES",nLarg-13 ) )
	AAdd( aMsgImp, Replicate("-",nLarg) )
	AAdd( aMsgImp, Space(nLarg) )
	AAdd( aMsgImp, PadR("DATA.....: "+DtoC(UC0->UC0_DATA)+"  HORA...: "+UC0->UC0_HORA, nLarg) )
	AAdd( aMsgImp, PadR("NR. COMP.: "+alltrim(UC0->UC0_NUM)+"      PLACA..: "+Alltrim(Transform(UC0->UC0_PLACA,"@!R NNN-9N99")), nLarg) )
	AAdd( aMsgImp, PadR("OPERADOR.: "+AllTrim(SA6->A6_COD)+" - "+AllTrim(SA6->A6_NOME),nLarg) )
	AAdd( aMsgImp, PadR("CLIENTE..: "+AllTrim(SA1->A1_COD)+"/"+AllTrim(SA1->A1_LOJA)+" - "+AllTrim(SA1->A1_NOME),nLarg) )
	AAdd( aMsgImp, Space(nLarg) )

	AAdd( aMsgImp, PadR("VALOR TOTAL COMPENSADO: R$ "+AllTrim(Transform(UC0->UC0_VLTOT,"@E 999,999,999.99")), nLarg) )
	cExtenso := "**("+AllTrim(Extenso(UC0->UC0_VLTOT))+")**"
	While !empty(cExtenso)
		 AAdd( aMsgImp, substr(cExtenso,1,nLarg) )
		 if len(cExtenso) > nLarg
		 	cExtenso := substr(cExtenso,nLarg+1,len(cExtenso)-(nLarg+1))
		 else
		 	cExtenso := ""
		 endif
	EndDo

	AAdd( aMsgImp, Space(nLarg) )
	AAdd( aMsgImp, PadR("FORMAS E VALORES ENTRADA:", nLarg) )

	UC1->(DbSetOrder(1))
	UC1->(DbSeek(xFilial("UC1")+UC0->UC0_NUM ))
	while UC1->(!EOf()) .AND. UC1->UC1_FILIAL+UC1->UC1_NUM == xFilial("UC1")+UC0->UC0_NUM
		if (nPosFor := aScan(aFormComp, {|x| x[1] == UC1->UC1_FORMA}) ) > 0
			aFormComp[nPosFor][2] += UC1->UC1_VALOR
		else
			aadd(aFormComp, {UC1->UC1_FORMA, UC1->UC1_VALOR})
		endif
		UC1->(DbSkip())
  	enddo

  	For nX := 1 to len(aFormComp)
  		cExtenso := alltrim(Posicione("SX5",1,xFilial("SX5")+"24"+aFormComp[nX][1],"X5_DESCRI"))
		AAdd( aMsgImp, PadR(cExtenso + ": R$ " + AllTrim(Transform(aFormComp[nX][2],"@E 999,999,999.99")) ,nLarg) )
  	Next nX

	AAdd( aMsgImp, Space(nLarg) )
	AAdd( aMsgImp, PadR("FORMAS E VALORES SAÍDA:",nLarg) )

	if !empty(UC0->UC0_VLDINH)
		AAdd( aMsgImp, PadR("DINHEIRO: R$ " + AllTrim(Transform(UC0->UC0_VLDINH,"@E 999,999,999.99")),nLarg) )
	endif

	if !empty(UC0->UC0_VLVALE)
		AAdd( aMsgImp, PadR("VALE HAVER: R$ " + AllTrim(Transform(UC0->UC0_VLVALE,"@E 999,999,999.99")),nLarg) )
	endif

	if !empty(UC0->UC0_VLCHTR)
		AAdd( aMsgImp, PadR("CH. TROCO: R$ " + AllTrim(Transform(UC0->UC0_VLCHTR,"@E 999,999,999.99")),nLarg) )
	endif

	AAdd( aMsgImp, Space(nLarg) )
	AAdd( aMsgImp, Replicate("-",nLarg) )

	For nX:=1 to Len( aMsgImp )
		cMsgImp += aMsgImp[nX] + chr(10)
	Next nX

	cRodape := PadR("APLICATIVO: MICROSIGA PROTHEUS - TOTVS",nLarg) + chr(10)

	cMsgImp := cMsgImp + cRodape

	//Funçao para impressao do comprovante
	For nX:=1 to nVias
		//parametro nVias=1 para fazer o corte
		STWManagReportPrint( cMsgImp , 1/*nVias*/ )
	next nX

	RestArea( aAreaSA6 )
	RestArea( aAreaSM0 )
	RestArea( aAreaUC1 )
	RestArea( aAreaSA1 )
	RestArea( aArea )

Return

//----------------------------------------------------------
// Busca as compensações de acordo com filtros, brwose
//----------------------------------------------------------
Static Function BuscaCmp()

	Local cCondicao		:= ""
	Local bCondicao
	Local nX
	Local aLinTemp 		:= {}

	if empty(dBuscaDt)
		U_SetMsgRod("Informe uma data para a busca!")
		Return
	endif

	U_SetMsgRod("Buscando compensações...")

	cCondicao := " UC0_FILIAL = '" + xFilial("UC0") + "'"
	cCondicao += " .AND. UC0_DATA == STOD('" + DTOS(dBuscaDt) + "')"
	if !empty(cBuscaCmp)
		cCondicao += " .AND. '" + alltrim(cBuscaCmp) + "' $ UC0_NUM "
	endif
	if !empty(cBuscaCod)
		cCondicao += " .AND. UC0_CLIENT = '" + cBuscaCod + "'"
	endif
	if !empty(cBuscaLoj)
		cCondicao += " .AND. UC0_LOJA = '" + cBuscaLoj + "'"
	endif
	if !empty(cBuscaPlaca)
		cCondicao += " .AND. UC0_PLACA = '" + cBuscaPlaca + "'"
	endif

	// limpo os filtros da UC0
	UC0->(DbClearFilter())

	// executo o filtro na UC0
	bCondicao 	:= "{|| " + cCondicao + " }"
	UC0->(DbSetFilter(&bCondicao,cCondicao))

	// vou para a primeira linha
	UC0->(DbGoTop())

	oMsGetCmp:acols := {}

	//{"LEGENDA","UC0_NUM","UC0_DATA","UC0_HORA","A1_CGC","A1_NOME","UC0_PLACA","UC0_PDV","UC0_VLDINH","UC0_VLCHTR","UC0_VLVALE","UC0_VLTOT"}
	While UC0->(!Eof())
		Posicione("SA1",1,xFilial("SA1")+UC0->UC0_CLIENT+UC0->UC0_LOJA,"A1_COD")

		aLinTemp := {}
		For nX := 1 to len(oMsGetCmp:aHeader)
			if oMsGetCmp:aHeader[nX][2] == "LEGENDA"
				Aadd(aLinTemp, iif(UC0->UC0_ESTORN=="X","BR_PRETO","BR_VERDE") )
			elseif Left(oMsGetCmp:aHeader[nX][2],3)=="UC0"
				Aadd(aLinTemp, UC0->&(oMsGetCmp:aHeader[nX][2]) )
			else
				Aadd(aLinTemp, SA1->&(oMsGetCmp:aHeader[nX][2]) )
			endif
		next nX

		Aadd(aLinTemp, UC0->(RecNo())) //recno
	    Aadd(aLinTemp, .F.) //deleted
		aadd(oMsGetCmp:aCols,aClone(aLinTemp))

		UC0->( dbskip() )
	EndDo

	// limpo os filtros da UF2
	UC0->(DbClearFilter())

	nQtdReg := Len(oMsGetCmp:acols)
	if nQtdReg == 0
		ClearGrid(oMsGetCmp)
	endif

	oMsGetCmp:oBrowse:Refresh()
	oQtdReg:Refresh()
	U_SetMsgRod("")
	oMsGetCmp:oBrowse:SetFocus()

Return

//-------------------------------------------------------------------------
// Faz estorno da compensação
//-------------------------------------------------------------------------
Static Function EstornaCmp()

	Local nX
	Local nOpcx := 0
	Local nWidth, nHeight
	Local oPnlEst, oPnlTop
	Local bCloseCF := {|| oDlgEst:end() }
	Local aStation
	Local cNumMov := STDNumMov()
	
	Private oJustEst
	Private cJustEst := ""
	Private cHelpEst := ""
	Private oHelpEst
	Private oDlgEst

	if oMsGetCmp:acols[oMsGetCmp:nAt][Len(oMsGetCmp:aHeader)+1] > 0
		UC0->(DbGoTo(oMsGetCmp:acols[oMsGetCmp:nAt][Len(oMsGetCmp:aHeader)+1]))
	else
		U_SetMsgRod("Busque e selecione a compensação a estornar!")
		Return
	endif

	if UC0->UC0_ESTORN == "X"
		U_SetMsgRod("Compensação já estornada!")
		Return
	endif

	//valido se é do mesmo caixa
	aStation := STBInfoEst( 1, .T. ) // [1]-CAIXA [2]-ESTACAO [3]-SERIE [4]-PDV [5]-LG_SERNFIS
	
	if !(UC0->UC0_DATA == dDataBase .AND. UC0->UC0_PDV == aStation[4] .AND. UC0->UC0_OPERAD == aStation[1] .AND. UC0->UC0_NUMMOV == cNumMov .AND. UC0->UC0_ESTACA == aStation[2])
		U_SetMsgRod("Compensação não pertence a este caixa. Operação não permitida!")
		Return
	endif

	DEFINE MSDIALOG oDlgEst TITLE "" FROM 000,000 TO 275,500 PIXEL STYLE nOr(WS_VISIBLE, WS_POPUP)

	nWidth := (oDlgEst:nWidth/2)
	nHeight := (oDlgEst:nHeight/2)

	@ 000, 000 MSPANEL oPnlEst SIZE nWidth, nHeight OF oDlgEst
	oPnlEst:SetCSS( "TPanel{border: 2px solid #999999; background-color: #f4f4f4;}" )

	@ 000, 000 MSPANEL oPnlTop SIZE nWidth, 017 OF oPnlEst
	oPnlTop:SetCSS( POSCSS (GetClassName(oPnlTop), CSS_BAR_TOP ))
	@ 004, 005 SAY oSay1 PROMPT "Estorno Compensação" SIZE 100, 015 OF oPnlTop COLORS 0, 16777215 PIXEL
	oSay1:SetCSS( POSCSS (GetClassName(oSay1), CSS_BREADCUMB ))
	oClose := TBtnBmp2():New( 002,oDlgEst:nWidth-25,20,30,'FWSKIN_DELETE_ICO',,,,bCloseCF,oPnlTop,,,.T. )
	oClose:SetCss("TBtnBmp2{border: none;background-color: none;}")

	@ 025, 010 SAY oSay5 PROMPT ("Informe a Justificativa do estorno da compensação " +UC0->UC0_NUM)  SIZE nWidth-020, 008 OF oPnlEst COLORS 0, 16777215 PIXEL
	oSay5:SetCSS( POSCSS (GetClassName(oSay5), CSS_LABEL_FOCAL ))

	@ 035, 010 GET oJustEst VAR cJustEst OF oPnlEst MULTILINE SIZE nWidth-020, nHeight-80 COLORS 0, 16777215 PIXEL
	oJustEst:SetCSS( POSCSS (GetClassName(oJustEst), CSS_GET_NORMAL))

  	@ nHeight-40, 010 SAY oHelpEst PROMPT cHelpEst PICTURE "@!" SIZE nWidth-15, 020 OF oPnlEst COLORS 0, 16777215 PIXEL
  	oHelpEst:SetCSS( "TSay{ font:bold 13px; color: #AA0000; background-color: transparent; border: none; margin: 0px; }" )

	oBtn6 := TButton():New( nHeight-20,nWidth-60,"Confirmar",oPnlEst,{|| iif(empty(cJustEst), cHelpEst:="Informe a justificativa!", (nOpcx:=1, oDlgEst:end()) ) },050,014,,,,.T.,,,,{|| .T.})
	oBtn6:SetCSS( POSCSS (GetClassName(oBtn6), CSS_BTN_FOCAL ))

	oBtn7 := TButton():New( nHeight-20,nWidth-115,"Cancelar",oPnlEst,bCloseCF,050,014,,,,.T.,,,,{|| .T.})
	oBtn7:SetCSS( POSCSS (GetClassName(oBtn7), CSS_BTN_ATIVO ))

	oDlgEst:lCentered := .T.
	oDlgEst:Activate()

	if nOpcx == 1

		Reclock("UC0", .F.) //altera

			UC0->UC0_JUSEST := cJustEst
			UC0->UC0_ESTORN := "X"

		UC0->(MsUnlock())

		U_UREPLICA("UC0",1,UC0->UC0_FILIAL + UC0->UC0_NUM, "A")

		oMsGetCmp:aCols[oMsGetCmp:nAt][1] := "BR_PRETO"
		U_SetMsgRod("Compensação "+UC0->UC0_NUM+" estornada com sucesso!")

		//-- busca cheques troco da compensação para liberá-lo no ambiente PDV
		cChave := UC0->UC0_NUM + SuperGetMv("MV_XPFXCOM", .F., "CMP")
		If !Empty(cChave) .AND. SuperGetMV("TP_ACTCHT",,.F.)

			UF2->(DbSetOrder(3)) //UF2_FILIAL+UF2_DOC+UF2_SERIE+UF2_PDV
			UF2->(DbSeek(xFilial("UF2")+cChave))
			aRecUF2 := {}
			While UF2->(!Eof()) .and. UF2->UF2_FILIAL+UF2->UF2_DOC+UF2->UF2_SERIE = (xFilial("UF2")+cChave)
				//--- limpa campos de situa pra nem subir, caso ainda esteja pendente.
				If UF2->UF2_SITUA == '00'
					If RecLock("UF2")
						UF2->UF2_XSITUA := ""
						UF2->UF2_XINDEX := 0
						UF2->UF2_SITUA  := "TX"
					UF2->(MsUnlock())
					EndIf
				EndIf

				aadd(aRecUF2, UF2->(Recno()))

				UF2->(DbSkip())
			EndDo

			For nX:= 1 to Len(aRecUF2)
				nRecUF2	:= aRecUF2[nX]
				U_TRETE29E(nRecUF2) //limpo campos de usado do cheque
			Next nX

		EndIf

	endif

	// Limpa array do bakcup da ultima carta frete
	If FindFunction("U_TPDVA14A")
		U_TPDVA14A()
	EndIf

Return

//-------------------------------------------------------
// Visualização da compensação
//-------------------------------------------------------
Static Function ViewCmp()

	Local aInfComp, cDsForma
	Local nTipoOper := 0 //0-CRÉDITO;1-DÉBITO"

	if !lConfCash
		if oMsGetCmp:acols[oMsGetCmp:nAt][Len(oMsGetCmp:aHeader)+1] > 0
			UC0->(DbGoTo(oMsGetCmp:acols[oMsGetCmp:nAt][Len(oMsGetCmp:aHeader)+1]))
		else
			U_SetMsgRod("Busque e selecione a compensação a visualizar!")
			Return
		endif
	endif

	lOnlyView := .T.
	cTitleTela := "VISUALIZAR"
	cNumCmp := UC0->UC0_NUM
	cVendedor := UC0->UC0_VEND
	cNomVend := Posicione("SA3",1,xFilial("SA3")+cVendedor,"A3_NOME")
	cCodCli := UC0->UC0_CLIENT
	cLojCli := UC0->UC0_LOJA
	cNomCli := Posicione("SA1",1,xFilial("SA1")+UC0->UC0_CLIENT+UC0->UC0_LOJA,"A1_NOME")
	cPlaca := UC0->UC0_PLACA
	nVlrForm := 0
	cJustif := UC0->UC0_JUSTIF
	if UC0->(FieldPos("UC0_DOC")) > 0 .AND. UC0->(FieldPos("UC0_SERIE")) > 0
		cDocNf := UC0->UC0_DOC
		cSerieNf := UC0->UC0_SERIE 
	endif
	nVlrDin := UC0->UC0_VLDINH + UC0->UC0_VLCHTR
	nVlrVale := UC0->UC0_VLVALE
	nVlrComp := nVlrDin + nVlrVale

	oMsGetEnt:aCols := {}
	UC1->(DbSetOrder(1))
	UC1->(DbSeek(UC0->UC0_FILIAL+UC0->UC0_NUM))
	While UC1->(!Eof()) .AND. UC1->UC1_FILIAL + UC1->UC1_NUM == UC0->UC0_FILIAL+UC0->UC0_NUM

		if Alltrim(UC1->UC1_FORMA) == "CH"
			//aInfComp := {nValorCh, dDataCh, cCgcEmit, cNomeEmit, cCmc7, cBanco, cAgencia, cConta, cNumCh, cRG, cTel, cComp, cCodEmit, cLojEmit}
			cDsForma := "CHEQUE"
			aInfComp := {UC1->UC1_VALOR, UC1->UC1_VENCTO,;
			 	UC1->UC1_CGC, Posicione("SA1",3,xFilial("SA1")+UC1->UC1_CGC,"A1_NOME"),;
			 	UC1->UC1_CMC7,;
			 	UC1->UC1_BANCO, UC1->UC1_AGENCI, UC1->UC1_CONTA,UC1->UC1_NUMCH ,;
			 	UC1->UC1_RG, UC1->UC1_TEL1, UC1->UC1_COMPEN, iif(UC1->(FieldPos("UC1_COD"))>0,UC1->UC1_COD,space(TamSx3("A1_COD")[1])), iif(UC1->(FieldPos("UC1_LOJA"))>0,UC1->UC1_LOJA,space(TamSx3("A1_LOJA")[1]))}
		elseif Alltrim(UC1->UC1_FORMA) $ "CC,CD"
			//aInfComp := {nValorC, nTipoOper, cRedeAut, cBandeira, cAdmFin, cNsuDoc, cAutoriz, dDataTran, nParcelas}
			if Alltrim(UC1->UC1_FORMA) == "CC"
				cDsForma := "CARTÃO CRÉDITO"
				nTipoOper := 0
			else
				cDsForma := "CARTÃO DÉBITO"
				nTipoOper := 1
			endif
			Posicione("SAE",1,xFilial("SAE")+UC1->UC1_ADMFIN,"AE_COD")
			aInfComp := {UC1->UC1_VALOR, nTipoOper,;
			 	Posicione("MDE",1,xFilial("MDE")+SAE->AE_REDEAUT,"MDE_CODIGO")+"- "+MDE->MDE_DESC,;
			 	Posicione("MDE",1,xFilial("MDE")+SAE->AE_ADMCART,"MDE_CODIGO")+"- "+MDE->MDE_DESC,;
			 	SAE->AE_COD + "- "+SAE->AE_DESC,;
			 	UC1->UC1_NSUDOC, UC1->UC1_CODAUT, UC1->UC1_VENCTO, 1}
		elseif Alltrim(UC1->UC1_FORMA) == "CF"
			//aInfComp := {nValorCF, cEmitCF, cNomeEmiCF, cCFrete, cObserv, cCodCF, cLojCF}
			cDsForma := "CARTA FRETE"
			aInfComp := {UC1->UC1_VALOR,;
				UC1->UC1_CGC, Posicione("SA1",3,xFilial("SA1")+UC1->UC1_CGC,"A1_NOME"),;
				UC1->UC1_CFRETE, UC1->UC1_OBS, iif(UC1->(FieldPos("UC1_COD"))>0,UC1->UC1_COD,space(TamSx3("A1_COD")[1])), iif(UC1->(FieldPos("UC1_LOJA"))>0,UC1->UC1_LOJA,space(TamSx3("A1_LOJA")[1]))}
		endif

		aadd(oMsGetEnt:aCols, {UC1->UC1_VALOR, UC1->UC1_VENCTO, Alltrim(UC1->UC1_FORMA), cDsForma, aClone(aInfComp), .F.} )

		nVlrForm += UC1->UC1_VALOR

		UC1->(DbSkip())
	enddo

	oVendedor:lReadOnly := .T.
	oCodCli:lReadOnly := .T.
	oLojCli:lReadOnly := .T.
	oPlaca:lReadOnly := .T.
	oJustif:lReadOnly := .T.
	oDocNf:lReadOnly := .T.
	oSerieNf:lReadOnly := .T.
	oNumCmp:Refresh()
	oVendedor:Refresh()
	oNomVend:Refresh()
	oCodCli:Refresh()
	oLojCli:Refresh()
	oNomCli:Refresh()
	oPlaca:Refresh()
	oMsGetEnt:oBrowse:Refresh()
	oVlrForm:Refresh()
	oVlrMax:Refresh()
	oJustif:Refresh()
	oDocNf:Refresh()
	oSerieNf:Refresh()
	oVlrDin:Refresh()
	oVlrVale:Refresh()
	oVlrComp:Refresh()

	if !lConfCash
		oPnlInc:Show()
		oPlaca:SetFocus()
		oPnlBrow:Hide()
	endif

Return

//-----------------------------------------------------------------------------
// Funcao de impressao do relatório termo de responsabilidade
//-----------------------------------------------------------------------------
Static Function ImpTermoRes(lBorwse)

	Local cNmCli := ""
	Local lContinua := .F.
	Local nX :=0
	Local cClausulas
	Default lBorwse := .F.
	Private aTitItens  //	:= {"Forma"	, "Data Venc."	, "Valor"	, "111111"	, "222222"	, "333333"	, "444444"	, "555555"	, "666666"}
	Private aColPos 	//:= {nMargemL, 270			, 650		, 850		, 1050		,	1200	, 1300	  	, 1470		,  nMargemR}
	Private aColAlign
	Private nOpcImp := iif(lBorwse,0,1)

	if nOpcImp == 0 //se pela tabela

		if oMsGetCmp:acols[oMsGetCmp:nAt][Len(oMsGetCmp:aHeader)+1] > 0
			UC0->(DbGoTo(oMsGetCmp:acols[oMsGetCmp:nAt][Len(oMsGetCmp:aHeader)+1]))
		else
			U_SetMsgRod("Busque e selecione a compensação a estornar!")
			Return
		endif

		UC1->(dbsetorder(1))      //ordenando pelo indice 1
		UC1->(dbgotop())
		if UC1->(dbseek(xFilial("UC1")+UC0->UC0_NUM)) //POSICIONA E ACHA, SE ACHAR PELO MENOS 1 RETORNA VERDADEIRO
			while !UC1->(EOF()) .AND. xFilial("UC1")+UC1->UC1_NUM == xFilial("UC0")+UC0->UC0_NUM
				if (AllTrim(UC1->UC1_FORMA) $ "CH,CF") //Se for Cheque ou Carta frete
					lContinua := .T.
					EXIT
			 	Endif
				UC1->(dbskip()) //avança no proximo registro
			 enddo
		endif

	else //senao é pela memoria

		//valido preenchimento da tela
		if !VldIncComp(.T.)
			Return
		endif

		For nX := 1 to len(oMsGetEnt:aCols)
			if !oMsGetEnt:aCols[nX][NPOSDEL]
				if oMsGetEnt:aCols[nX][NPOSFPG] $ "CH,CF"
					lContinua := .T.
					EXIT
				endif
			endif
		next nX

	endif

	if !lContinua
	 	U_SetMsgRod("Compensação não tem parcelas de Cheque ou Carta Frete! Ação não permitida.")
	 	Return
	endif

	//Variaveis de Tipos de fontes que podem ser utilizadas no relatório
	Private oFont8		:= TFONT():New("ARIAL",8 ,8 ,,.F.,,,,,.F.,.F.) ///Fonte 8 Normal
	Private oFont10 	:= TFONT():New("ARIAL",10,10,,.F.,,,,,.F.,.F.) ///Fonte 10 Normal
	Private oFont10N 	:= TFONT():New("ARIAL",10,10,,.T.,,,,,.F.,.F.) ///Fonte 10 Negrito
	Private oFont12N	:= TFONT():New("ARIAL",12,12,,.T.,,,,,.F.,.F.) ///Fonte 12 Negrito
	Private oFont14N	:= TFONT():New("ARIAL",14,14,,.T.,,,,,.F.,.F.) ///Fonte 14 Negrito
	Private oFont16N	:= TFONT():New("ARIAL",16,16,,.T.,,,,,.F.,.F.) ///Fonte 16 Negrito

	Private oFtCNew10 	:= TFONT():New("Courier New",10,10,,.F.,,,,,.F.,.F.) ///Fonte 10 Normal

	//Variveis para impressao
	Private cStartPath
	Private nLin 		:= 0
	Private nMargemL    := 100
	Private nMargemR    := 2350
	Private nMargemT	:= 120
	Private nMargemB	:= 3300
	Private nCenterPg	:= 1200
	Private oPrint		:= TMSPRINTER():New("")

	//Define Tamanho do Papel
	#define DMPAPER_A4 9 //Papel A4
	oPrint:setPaperSize( DMPAPER_A4 )

	//Orientacao do papel (Retrato ou Paisagem)
	oPrint:SetPortrait()///Define a orientacao da impressao como retrato

	if nOpcImp==0
		cNmCli := POSICIONE("SA1",1,xFilial("SA1")+UC0->UC0_CLIENT+UC0->UC0_LOJA,"A1_NOME")
	else
		cNmCli := POSICIONE("SA1",1,xFilial("SA1")+cCodCli+cLojCli,"A1_NOME")
	endif

	Cabecalho()
	ConfSubC()

	cClausulas := "Eu , ______________________________________________________, CPF ___________________________ , em nome próprio e/ou de "
    cClausulas += Alltrim(cNmCli) + ", " + Transform(SA1->A1_CGC,iif(SA1->A1_PESSOA=="J","@R 99.999.999/9999-99","@R 999.999.999-99")) + ", "
	cClausulas += "transmito e transfiro à " + alltrim(SM0->M0_NOMECOM) + " (" + alltrim(SM0->M0_FILIAL) + "), "
	cClausulas += "todos os direitos creditícios inerentes aos títulos de créditos listados neste documento, emitido e comprometido "
	cClausulas += "ao pagamento pelo emitente listado em cada título, "
	cClausulas += "em razão do(s) serviço(s) prestado(s) pelo veículo placa "+Transform(iif(nOpcImp==0,UC0->UC0_PLACA,cPlaca),"@!R NNN-9N99")+", no valor total de "+Alltrim(Transform(iif(nOpcImp==0,UC0->UC0_VLTOT,nVlrComp),"@E 999,999,999.99"))+","
	cClausulas += "conforme detalhado abaixo e descrito no anverso deste documento. Ratifico e declaro, sob as penas da lei, ter conferido "
	cClausulas += "o presente documento e que o mesmo é lídimo e o crédito nele expressado idôneo e válido para recebimento direto pelos emitente referenciados. "
	cClausulas += "Declaro ainda que eventual irregularidade ou divergência de valores "
	cClausulas += "conforme detalhado abaixo e descrito no anverso deste documento. Ratifico e declaro, sob as penas da lei, ter conferido "
	cClausulas += "é de minha inteira responsabilidade e do(a) "+Alltrim(cNmCli)+", "
	cClausulas += "constituindo-se devedores solidários perante a "+alltrim(SM0->M0_NOMECOM)+". Avalizo o presente documento. "

	aObs := QuebraTexto(cClausulas, 103)

	//fazer laço para quebra de linha
	for nX := 1 to len(aObs)
		oPrint:Say( nLin, nMargemL+5, aObs[nX], oFtCNew10)
		nLin += 50
	next nX

	nLin += 100

	ItensPedCH()  //monta e preenche as linhas da grid CH
	ItensPedCF()  //monta e preenche as linhas da grid CF

	nLin += 100
	oPrint:Say( nLin, nMargemL+5, "Por ser expressão da verdade, assino-o.", oFtCNew10)
	nLin += 150
	oPrint:Say( nLin, nMargemL+5, "Ass: ________________________________________________", oFtCNew10)
	nLin += 50

 	Rod()

	oPrint:Preview()

Return

//------------------------------------------------------
//Monta o cabecalho principal
//------------------------------------------------------
Static Function Cabecalho()

	oPrint:StartPage() // Inicia uma nova pagina
	cStartPath := GetPvProfString(GetEnvServer(),"StartPath","ERROR",GetAdv97())
	cStartPath += If(Right(cStartPath, 1) <> "\", "\", "")

	nLin := nMargemT
	oPrint:SayBitmap(nLin+15, nMargemL, cStartPath + iif(FindFunction('U_URETLGRL'),U_URETLGRL(),"lgrl01.bmp"), 400, 128) //Impressao da Logo
	oPrint:Say(nLin + 180, nMargemL, "Filial: " + cFilAnt + " - " + alltrim(SM0->M0_NOMECOM) + " (" + alltrim(SM0->M0_FILIAL) + ")", oFont10)  //Define o titulo do relatorio
	oPrint:Say(nLin + 20, nCenterPg, "COMPENSAÇÃO DE VALOR", oFont16N,,,,2)  //Define o titulo do relatorio
	nLin += 20

    oPrint:Box( nLin, nMargemL+1850, nLin+110 , nMargemR )
    oPrint:Say( nLin+5, nMargemL+1860, "NUM. COMP.", oFont8)
    oPrint:Say( nLin+50, nMargemR-200, iif(nOpcImp==0,UC0->UC0_NUM,cNumCmp), oFont14N,,,,2)
	nLin += 110

	oPrint:Box( nLin, nMargemL+1850, nLin+110 , nMargemR )
    oPrint:Say( nLin+5, nMargemL+1860, "DATA/HORA COMP.", oFont8)
    oPrint:Say( nLin+50, nMargemR-200, iif(nOpcImp==0,DTOC(UC0->UC0_DATA)+" "+UC0->UC0_HORA,DTOC(dDataBase)+" "+SubStr(Time(),1,5)), oFont12N,,,,2)

	nLin += 120
	oPrint:Line(nLin, nMargemL, nLin, nMargemR)
	nLin += 30

Return

//-------------------------------------------------------
// Monta sub cabeçalho
//-------------------------------------------------------
Static Function ConfSubC()

	oPrint:Box( nLin, nMargemL, nLin+110 , nMargemL+350 )
    oPrint:Say( nLin+5, nMargemL + 10, "CPF/CNPJ CLIENTE", oFont8)
    oPrint:Say( nLin+50, nMargemL + 10, SA1->A1_CGC, oFont12N)

    oPrint:Box( nLin, nMargemL+350, nLin+110 , nMargemL+1750 )
    oPrint:Say( nLin+5, nMargemL + 360, "NOME CLIENTE", oFont8)
    oPrint:Say( nLin+50, nMargemL + 360, SA1->A1_NOME, oFont12N)

    oPrint:Box( nLin, nMargemL+1750, nLin+110 , nMargemR )
    oPrint:Say( nLin+5, nMargemL + 1760, "PLACA", oFont8)
    oPrint:Say( nLin+50, nMargemL + 1760, Transform(iif(nOpcImp==0,UC0->UC0_PLACA,cPlaca),"@!R NNN-9N99"), oFont12N)
	nLin += 250

Return

//-----------------------------------------------------------
//Variveis Colunas (DEPENDE DO TIPO DA FORMA (CF/CH)
//-----------------------------------------------------------
Static Function ConfCabCH()
	aTitItens 	:= {"Data Venc."	, "Valor"	, "Banco"	, "Agencia"	, "Conta"	, "NºCheque"	, "CPF / CNPJ"	, "Emitente"}
	aColPos 	:= {nMargemL		, 490		, 520		, 670		, 840		,	1040			, 1260	  		, 1580}
	aColAlign 	:= {0				, 1			, 0			, 0			, 	0		,	0	  		, 0				,	0}
Return

//----------------------------------------------------
//Variveis headers do tipo forma = CARTA FRETE
//----------------------------------------------------
Static Function ConfCabCF()
	aTitItens 	:= {"Data Venc."	, "Valor"	, "Numero Doc."	, "Emitente"}
	aColPos 	:= {nMargemL		, 490		, 700			, 1210		}
	aColAlign 	:= {0				, 1			, 0				, 0	   		}
Return

//---------------------------------------------------
//Monta o cabeçalho dos itens do relatorio
//---------------------------------------------------
Static Function MontItens()
	Local nI

	for nI := 1 to len(aTitItens)
		oPrint:Say(nLin, aColPos[nI], aTitItens[nI], oFont10N,,,,aColAlign[nI])
	next nI

	nLin += 60
	oPrint:Line(nLin, nMargemL, nLin, nMargemR)
	nLin += 10
Return

//--------------------------------------------------------------
// Faz impressão dos itens de Cheque
//--------------------------------------------------------------
Static Function ItensPedCH()

	Local nX
	Local nTotPed := 0
	Local aCheque := {}

	if nOpcImp == 1
		//Gravando parcelas de entrada
		For nX := 1 to len(oMsGetEnt:aCols)
			if !oMsGetEnt:aCols[nX][NPOSDEL] .AND. oMsGetEnt:aCols[nX][NPOSFPG] == "CH"
				aadd( aCheque, { ;
					oMsGetEnt:aCols[nX][NPOSFPG],;
					DTOC(oMsGetEnt:aCols[nX][NPOSINF][2]),;
					Transform(oMsGetEnt:aCols[nX][NPOSINF][1], "@E 99,999,999.99"),;
					oMsGetEnt:aCols[nX][NPOSINF][6],;
					oMsGetEnt:aCols[nX][NPOSINF][7],;
					oMsGetEnt:aCols[nX][NPOSINF][8],;
					oMsGetEnt:aCols[nX][NPOSINF][9],;
					oMsGetEnt:aCols[nX][NPOSINF][3],;
					Posicione("SA1",3,xFilial("SA1")+UC1->UC1_CGC,"A1_NOME");
				})

				nTotPed += oMsGetEnt:aCols[nX][NPOSINF][1]
		 	Endif
		next nX
	else
		UC1->(dbsetorder(1))      //ordenando pelo indice 1
		UC1->(dbgotop())
		if UC1->(dbseek(xFilial("UC1")+UC0->UC0_NUM)) //POSICIONA E ACHA, SE ACHAR PELO MENOS 1 RETORNA VERDADEIRO
			while !UC1->(EOF()) .AND. xFilial("UC1")+UC1->UC1_NUM == xFilial("UC0")+UC0->UC0_NUM
				if (AllTrim(UC1->UC1_FORMA) == "CH") //Se for Cheque
					aadd( aCheque, { ;
						UC1->UC1_FORMA,;
						DTOC(UC1->UC1_VENCTO),;
						Transform(UC1->UC1_VALOR, "@E 99,999,999.99"),;
						UC1->UC1_BANCO,;
						UC1->UC1_AGENCI,;
						UC1->UC1_CONTA,;
						UC1->UC1_NUMCH,;
						UC1->UC1_CGC,;
						Posicione("SA1",3,xFilial("SA1")+UC1->UC1_CGC,"A1_NOME");
					})
					nTotPed += UC1->UC1_VALOR
			 	Endif
				UC1->(dbskip()) //avança no proximo registro
			 enddo
		endif
	endif

	if nTotPed > 0

		oPrint:Box( nLin, nMargemL, nLin+60 , nMargemR )
	    oPrint:Say( nLin+5, nMargemL + 5, " CHEQUES ", oFont12N)
	    nLin += 80

	    ConfCabCH() //Configura os itens do tipo CH do header da grid
		MontItens()  //Monta o cabecalho dos itens da grid

		for nX:=1 to len(aCheque)

			//Mudando de página
			if nLin >= nMargemB
				Rod()
				Cabecalho()
				MontItens()
			Endif

			nCol := 1

			//oPrint:Say(nLin, aColPos[nCol], aCheque[nX][1], oFont10,,,,aColAlign[nCol++])
			oPrint:Say(nLin, aColPos[nCol], aCheque[nX][2], oFont10,,,,aColAlign[nCol++])
			oPrint:Say(nLin, aColPos[nCol], aCheque[nX][3], oFont10,,,,aColAlign[nCol++])
			oPrint:Say(nLin, aColPos[nCol], aCheque[nX][4], oFont10,,,,aColAlign[nCol++])
			oPrint:Say(nLin, aColPos[nCol], aCheque[nX][5], oFont10,,,,aColAlign[nCol++])
			oPrint:Say(nLin, aColPos[nCol], aCheque[nX][6], oFont10,,,,aColAlign[nCol++])
			oPrint:Say(nLin, aColPos[nCol], aCheque[nX][7], oFont10,,,,aColAlign[nCol++])
			oPrint:Say(nLin, aColPos[nCol], aCheque[nX][8], oFont10,,,,aColAlign[nCol++])
			oPrint:Say(nLin, aColPos[nCol], aCheque[nX][9], oFont10,,,,aColAlign[nCol++])

			nLin += 50

		next nX

		//Impressao do totalizador
		nLin += 20
	    oPrint:Line(nLin, nMargemL, nLin, nMargemR)
	    nLin += 20
	    oPrint:Say(nLin, nMargemR, "VALOR TOTAL CHEQUES:   " + Transform(nTotPed, "@E 999,999,999.99"), oFont10N,,,,1)

		nLin += 200

	endif

Return

//------------------------------------------------------------------------------------------
//Funcao que imprime atraves de um laco de repeticao os itens por linhas do relatorio.
//------------------------------------------------------------------------------------------
Static Function ItensPedCF()

	Local nX
	Local nTotPed := 0
	Local aCFretes := {}

	if nOpcImp == 1

		For nX := 1 to len(oMsGetEnt:aCols)
			if !oMsGetEnt:aCols[nX][NPOSDEL] .AND. oMsGetEnt:aCols[nX][NPOSFPG] == "CF"
				aadd( aCFretes, { ;
						oMsGetEnt:aCols[nX][NPOSFPG], ;
						DTOC(oMsGetEnt:aCols[nX][NPOSDAT]), ;
						Transform(oMsGetEnt:aCols[nX][NPOSVLR], "@E 99,999,999.99"), ;
						oMsGetEnt:aCols[nX][NPOSINF][4], ;
						alltrim(oMsGetEnt:aCols[nX][NPOSINF][2])+" - "+Posicione("SA1",3,xFilial("SA1")+oMsGetEnt:aCols[nX][NPOSINF][2],"A1_NOME") ;
					})
				nTotPed += oMsGetEnt:aCols[nX][NPOSVLR]
		 	Endif
		next nX
	else
		UC1->(dbsetorder(1))      //ordenando pelo indice 1
		UC1->(dbgotop())
		if UC1->(dbseek(xFilial("UC1")+UC0->UC0_NUM)) //POSICIONA E ACHA, SE ACHAR PELO MENOS 1 RETORNA VERDADEIRO
			while !UC1->(EOF()) .AND. xFilial("UC1")+UC1->UC1_NUM == xFilial("UC0")+UC0->UC0_NUM
				if (AllTrim(UC1->UC1_FORMA) == "CF") //Se for CARTA FRETE
					aadd( aCFretes, { ;
						UC1->UC1_FORMA, ;
						DTOC(UC1->UC1_VENCTO), ;
						Transform(UC1->UC1_VALOR, "@E 99,999,999.99"), ;
						UC1->UC1_CFRETE, ;
						Alltrim(UC1->UC1_CGC)+" - "+Posicione("SA1",3,xFilial("SA1")+UC1->UC1_CGC,"A1_NOME") ;
					})
					nTotPed += UC1->UC1_VALOR
				Endif
				UC1->(dbskip()) //avanCa no proximo registro
		    enddo
		endif
    endif

	if nTotPed > 0

		oPrint:Box( nLin, nMargemL, nLin+60 , nMargemR )
	    oPrint:Say( nLin+5, nMargemL + 5, " CARTAS FRETE ", oFont12N)
	    nLin += 80

		ConfCabCF() //Configura os itens do tipo CH do header da grid
		MontItens()  //Monta o cabecalho dos itens da grid

		for nX:=1 to len(aCFretes)
			//Mudando de página
			if nLin >= nMargemB
				Rod()
				Cabecalho()
				MontItens()
			Endif

			nCol := 1
			//oPrint:Say(nLin, aColPos[nCol], aCFretes[nX][1], oFont10,,,,aColAlign[nCol++])
			oPrint:Say(nLin, aColPos[nCol], aCFretes[nX][2], oFont10,,,,aColAlign[nCol++])
			oPrint:Say(nLin, aColPos[nCol], aCFretes[nX][3], oFont10,,,,aColAlign[nCol++])
			oPrint:Say(nLin, aColPos[nCol], aCFretes[nX][4], oFont10,,,,aColAlign[nCol++])
			oPrint:Say(nLin, aColPos[nCol], aCFretes[nX][5], oFont10,,,,aColAlign[nCol++])
			nLin += 50
		next nX

		//Impressao do totalizador
	    nLin += 20
	    oPrint:Line(nLin, nMargemL, nLin, nMargemR)
	    nLin += 20
	    oPrint:Say(nLin, nMargemR, "VALOR TOTAL CARTAS FRETE:   " + Transform(nTotPed, "@E 999,999,999.99"), oFont10N,,,,1)

    endif

Return

//--------------------------------------------
//Monta o rodape principal
//--------------------------------------------
Static Function Rod()

	nLin := nMargemB
	oPrint:Line(nLin, nMargemL, nLin, nMargemR)
	nLin += 5
	oPrint:Say(nLin, nMargemL, "Microsiga Protheus", oFont10)
	oPrint:Say(nLin, nMargemR, DTOC(dDatabase) + " " + TIME(), oFont10,,,,1)

	oPrint:EndPage() //finaliza pagina

Return

//--------------------------------------------------------
// Quebra texto paragrafo para relatório
//--------------------------------------------------------
Static Function QuebraTexto(_cString,_nCaracteres)

	Local aTexto      := {}
	Local cAux        := ""
	Local cString     := AllTrim(_cString)
	Local nX          := 1
	Local nY          := 1

	if _nCaracteres > Len(cString)
		aadd(aTexto,cString)
	else

		While nX <= Len(cString)
	        cAux := SubStr(cString,nX,_nCaracteres)
			if Empty(cAux)
				nX += _nCaracteres
			else
				if SubStr(cAux,Len(cAux),1) == " " .OR. nX + _nCaracteres > Len(cString)
					aadd(aTexto,cAux)
					nX += _nCaracteres
				else
					For nY := Len(cAux) To 1 Step -1
						if SubStr(cAux,nY,1) == " "
							aadd(aTexto,SubStr(cAux,1,nY))
	                        nX += nY
	                        Exit
						endif
					Next nY
				endif
			endif
		EndDo
	endif

Return(aTexto)

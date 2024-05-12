#include 'protheus.ch'
#include 'parmtype.ch'
#include 'poscss.ch'
#include "topconn.ch"
#include "TOTVS.CH"


#DEFINE NPOSSRV 1
#DEFINE NPOSDES 2
#DEFINE NPOSPRC 3
#DEFINE NPOSCON 4
#DEFINE NPOSTOT 5
#DEFINE NPOSDEL 6

Static cUsrVls 		:= ""
Static lOnlyView 	:= .F.
Static oPnlGeral
Static oPnlInc
Static oPnlBrow
Static cTitleTela	:= ""
Static oNumVls
Static cNumVls 		:= "INCLUINDO" //Space(TamSX3("UIC_CODIGO")[1])
Static oCodCli
Static cCodCli 		:= Space(TamSX3("A1_COD")[1])
Static oLojCli
Static cLojCli 		:= Space(TamSX3("A1_LOJA")[1])
Static oNomCli
Static cNomCli 		:= Space(TamSX3("A1_NOME")[1])
Static oPlaca
Static cPlaca 		:= Space(TamSX3("UIC_PLACA")[1])
Static oObserv
Static cObserv 		:= Space(200)
Static oPrestador
Static cPrestador	:= Space(TamSX3("A2_COD")[1]) + Space(1) + Space(TamSX3("A2_LOJA")[1]) + Space(3) + Space(TamSX3("A2_NOME")[1])
Static oBtnTpPos, oBtnTpPre
Static cTipoOper 	:= "R" //R-PRÉ-PAGO;O-PÓS-PAGO"
Static lCliHbPos    := .F.
Static oFindServ
Static cFindServ	:= Space(TamSX3("B1_DESC")[1])
Static oListServ	:= Nil
Static cListServ	:= Space(TamSX3("B1_COD")[1]) + " - " + Space(TamSX3("B1_DESC")[1])
Static oMsGetSrv
Static oVlrTot
Static nVlrTot		:= 0
Static oMsGetVls
Static oBuscaVls
Static cBuscaVls	:= Space(TamSX3("UIC_AMB")[1]+TamSX3("UIC_CODIGO")[1])
Static oBuscaCod
Static cBuscaCod 	:= Space(TamSX3("A1_COD")[1])
Static oBuscaLoj
Static cBuscaLoj 	:= Space(TamSX3("A1_LOJA")[1])
Static oBuscaPlaca
Static cBuscaPlaca	:= Space(TamSX3("UIC_PLACA")[1])
Static oBuscaDt
Static dBuscaDt 	:= dDataBase
Static oQtdReg
Static nQtdReg		:= 0
Static oPercDesc
Static nPercDesc	:= 0
Static oVlrDesc
Static nVlrDesc		:= 0
Static oVlrAtu
Static nVlrAtu		:= 0
Static oResDesc
Static nResDesc		:= 0
Static oHelpVls
Static cHelpVls		:= ""
Static cAmbiente 	:= ""
Static lConfCash := .F.
Static oVendedor
Static cVendedor := Space(TamSX3("UIC_VEND")[1])
Static oNomVend
Static cNomVend := ""
Static aRecnoUIC := {}

Static oCssCombo    := "TComboBox { font: bold; font-size: 13px; text-align: right; color: #656565; background-color: #FFFFFF; border: 1px solid #9C9C9C; border-radius: 4px; padding: 4px; } TComboBox:focus{border: 2px solid #0080FF;} TComboBox:disabled {color:#656565; background-color: #EEEEEE;} TComboBox:drop-down {color:#000000; background-color: #FFFFFF; border-left: 0px; border-radius: 4px; background-image: url(rpo:fwskin_combobox_arrow.png);background-repeat: none;background-position: center;}"

/*/{Protheus.doc} TPDVA006
Vale Serviços

@author TOTVS
@since 01/05/2019
@version 1.0
@return Nil
@type function
/*/

User function TPDVA006(oPnlPrinc, _lConfCash, bConfirm, bCancel, nOpcX)

	Local nWidth, nHeight
	Local oPnlGrid, oPnlGrid2, oPnlAux, oPnlAux2
	Local cCorBg 		:= SuperGetMv( "MV_LJCOLOR",,"07334C") // Cor da tela
	Local aLstPre		:= GetPrest() // Carrega os prestadores de serviços
	Local lMvPswVend 	:= SuperGetMv("TP_PSWVEND",,.F.)
	Local lBlqAI0 	:= SuperGetMv("MV_XBLQAI0",,.F.) .AND. AI0->(FieldPos("AI0_XBLFIL")) > 0 //Habilita bloqueio de venda na filial, olhando para tabela AI0
	Local cFiltro	:= ""
	Default _lConfCash := .F.

	Private aListServ	:= {''}

	DbSelectArea("UIC")
	DbSelectArea("UH9")
	DbSelectArea("UIB")

	nWidth := oPnlPrinc:nWidth/2
	nHeight := oPnlPrinc:nHeight/2
	lConfCash := _lConfCash

	// Verifica se o usuário tem permissão para acesso a rotina
	If !lConfCash
		U_TRETA37B("VLSPDV", "VALE SERVICO PDV")
		cUsrVls := U_VLACESS1("VLSPDV", RetCodUsr())
		If cUsrVls == Nil .Or. Empty(cUsrVls)
			@ 020, 020 SAY oSay1 PROMPT "<h1>Ops!</h1><br>Seu usuário não tem permissão de acesso a rotina de Vale Serviço. Entre em contato com o administrador do sistema." SIZE nWidth-40, 100 OF oPnlPrinc COLORS 0, 16777215 PIXEL HTML
			oSay1:SetCSS(POSCSS(GetClassName(oSay1), CSS_LABEL_FOCAL))
			Return cUsrVls
		EndIf
	endif

	cAmbiente := GetMV("MV_LJAMBIE")
	if empty(cAmbiente)
		@ 020, 020 SAY oSay1 PROMPT "<h1>Ops!</h1><br>Configuração do Ambiente (MV_LJAMBIE) no Host Superior não realizada. Entre em contato com o administrador do sistema." SIZE nWidth-40, 100 OF oPnlPrinc COLORS 0, 16777215 PIXEL HTML
		oSay1:SetCSS(POSCSS(GetClassName(oSay1), CSS_LABEL_FOCAL))
		Return ""
	endif

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

	// Painel geral da tela de Vale Serviço (mesmo tamanho da principal)
	oPnlGeral := TPanel():New(000,000,"",oPnlPrinc,NIL,.T.,.F.,,,nWidth,nHeight,.T.,.F.)

	cTitleTela := "INCLUIR"
	@ 002, 002 SAY oSay1 PROMPT ("VALE SERVIÇO - " + cTitleTela) SIZE nWidth-004, 015 OF oPnlGeral COLORS 0, 16777215 PIXEL CENTER
	oSay1:SetCSS(POSCSS(GetClassName(oSay1), CSS_BTN_FOCAL))

	//Painel de Inclusão de Vale Serviço
	oPnlInc := TPanel():New(020,000,"",oPnlGeral,NIL,.T.,.F.,,,nWidth,nHeight-020,,.T.,.F.)

	@ 005, 005 SAY oSay2 PROMPT "Vale Serviço" SIZE 100, 010 OF oPnlInc COLORS 0, 16777215 PIXEL
	oSay2:SetCSS(POSCSS (GetClassName(oSay2), CSS_LABEL_FOCAL))
	oNumVls := TGet():New(015, 005,{|u| iif(PCount()==0,cNumVls,cNumVls:=u) },oPnlInc, 060, 013,,{|| /*bValid*/ },,,,,,.T.,,,{|| .T. },,,,.T.,.F.,,"oNumVls",,,,.T.,.F.)
	oNumVls:SetCSS(POSCSS(GetClassName(oNumVls), CSS_GET_NORMAL))
	oNumVls:lCanGotFocus := .F.

	@ 005, 070 SAY oSay5 PROMPT "Placa" SIZE 100, 010 OF oPnlInc COLORS 0, 16777215 PIXEL
	oSay5:SetCSS(POSCSS(GetClassName(oSay5), CSS_LABEL_FOCAL))
	oPlaca := TGet():New(015, 070,{|u| iif(PCount()==0,cPlaca,cPlaca:=u)},oPnlInc,70, 013,"@!R NNN-9N99",{|| VldPlaca() },,,,,,.T.,,,{|| .T. },,,,.F.,.F.,,"oPlaca",,,,.T.,.F.)
	oPlaca:SetCSS(POSCSS(GetClassName(oPlaca), CSS_GET_NORMAL))

	//@ 005, 145 SAY oSay3 PROMPT "CPF/CNPJ do Cliente" SIZE 100, 010 OF oPnlInc COLORS 0, 16777215 PIXEL
	//oSay3:SetCSS(POSCSS(GetClassName(oSay3), CSS_LABEL_FOCAL))
	//oCgcCli := TGet():New(015, 145,{|u| iif(PCount()==0,cCgcCli,cCgcCli:=u)},oPnlInc,85, 013,,{|| VldCliente() },,,,,,.T.,,,{|| .T. },,,,.F.,.F.,,"oCgcCli",,,,.T.,.F.)
	//oCgcCli:SetCSS(POSCSS(GetClassName(oCgcCli), CSS_GET_NORMAL))
	//TSearchF3():New(oCgcCli,400,250,"SA1","A1_CGC",{{"A1_NOME",2},{"A1_CGC",3},{"A1_COD",1}},"SA1->A1_MSBLQL<>'1'",{{"A1_NOME","A1_EST","A1_MUN"},{"A1_CGC","A1_NOME","A1_EST","A1_MUN"},{"A1_COD","A1_LOJA","A1_NOME","A1_EST","A1_MUN"}},,,iif(lConfCash,-40,0))
	
	@ 005, 145 SAY oSay3 PROMPT "Código" SIZE 100, 010 OF oPnlInc COLORS 0, 16777215 PIXEL
	oSay3:SetCSS(POSCSS(GetClassName(oSay3), CSS_LABEL_FOCAL))
	oCodCli := TGet():New(015, 145,{|u| iif(PCount()==0,cCodCli,cCodCli:=u)},oPnlInc, 055, 013,,{|| VldCliente() },,,,,,.T.,,,{|| .T. },,,,.F.,.F.,,"oCodCli",,,,.T.,.F.)
	oCodCli:SetCSS(POSCSS(GetClassName(oCodCli), CSS_GET_NORMAL))

	@ 005, 200 SAY oSay3 PROMPT "Loja" SIZE 100, 010 OF oPnlInc COLORS 0, 16777215 PIXEL
	oSay3:SetCSS(POSCSS(GetClassName(oSay3), CSS_LABEL_FOCAL))
	oLojCli := TGet():New(015, 200,{|u| iif(PCount()==0,cLojCli,cLojCli:=u)},oPnlInc, 020, 013,,{|| VldCliente() },,,,,,.T.,,,{|| .T. },,,,.F.,.F.,,"oLojCli",,,,.T.,.F.)
	oLojCli:SetCSS(POSCSS(GetClassName(oLojCli), CSS_GET_NORMAL))

	@ 005, 230 SAY oSay4 PROMPT "Nome Cliente" SIZE 070, 010 OF oPnlInc COLORS 0, 16777215 PIXEL
	oSay4:SetCSS(POSCSS(GetClassName(oSay4), CSS_LABEL_FOCAL))
	oNomCli := TGet():New(015, 230,{|u| iif(PCount()==0,cNomCli,cNomCli:=u)},oPnlInc,nWidth-235, 013,,{|| .T./*bValid*/ },,,,,,.T.,,,{|| .T. },,,,.T.,.F.,,"oNomCli",,,,.T.,.F.)
	oNomCli:SetCSS(POSCSS(GetClassName(oNomCli), CSS_GET_NORMAL))
	oNomCli:lCanGotFocus := .F.

	// bloqueio de filiais
	if lBlqAI0
		cFiltro := " .AND. Posicione('AI0',1,xFilial('AI0')+SA1->A1_COD+SA1->A1_LOJA,'AI0_XBLFIL')!='S'"
	elseIf SA1->(FieldPos("A1_XFILBLQ")) > 0 
		cFiltro := " .AND. (Empty(SA1->A1_XFILBLQ) .OR. !(cFilAnt $ SA1->A1_XFILBLQ))"
	EndIf
	TSearchF3():New(oCodCli,400,250,"SA1","A1_COD",{{"A1_NOME",2},{"A1_CGC",3},{"A1_COD",1}},"SA1->A1_MSBLQL<>'1'"+cFiltro,{{"A1_COD","A1_LOJA","A1_NOME","A1_EST","A1_MUN"},{"A1_COD","A1_LOJA","A1_CGC","A1_NOME","A1_EST","A1_MUN"},{"A1_COD","A1_LOJA","A1_NOME","A1_EST","A1_MUN"}},,,iif(lConfCash,-40,0)/*nAjustPos*/,,{{oLojCli,"A1_LOJA"},{oNomCli,"A1_NOME"}})

	@ 035, 005 SAY oSay6 PROMPT "Prestador de Serviço" SIZE 100, 010 OF oPnlInc COLORS 0, 16777215 PIXEL
	oSay6:SetCSS(POSCSS(GetClassName(oSay6), CSS_LABEL_FOCAL))
	oPrestador := TComboBox():New(045, 005,{|u| iif(PCount()>0,cPrestador:=u,cPrestador)}, aLstPre, 220, 016, oPnlInc, Nil, {|| aListServ := SelSrv(cPrestador), oListServ:SetItems(aListServ), oListServ:Refresh()},/*Valid*/,,,.T.,, Nil, Nil, {|| oMsGetSrv<>Nil .AND. Empty(oMsGetSrv:aCols[1][NPOSSRV]) })
	oPrestador:SetCSS(oCssCombo)

	@ 035, 230 SAY oSay7 PROMPT "Tipo" SIZE 100, 010 OF oPnlInc COLORS 0, 16777215 PIXEL
	oSay7:SetCSS(POSCSS(GetClassName(oSay7), CSS_LABEL_FOCAL))
	oBtnTpPre := TButton():New(045,230,"PRÉ-PAGO", oPnlInc,{|| cTipoOper:="R", SetTipoSel(cTipoOper) },050,015,,,,.T.,,,,{|| !lOnlyView })
	oBtnTpPos := TButton():New(045,280,"PÓS-PAGO", oPnlInc,{|| cTipoOper:="O", SetTipoSel(cTipoOper) },050,015,,,,.T.,,,,{|| !lOnlyView .AND. lCliHbPos })
	SetTipoSel(cTipoOper)

	@ 068, 005 SAY oSay8 PROMPT "Serviços a Executar" SIZE 100, 011 OF oPnlInc COLORS 0, 16777215 PIXEL
	oSay8:SetCSS(POSCSS(GetClassName(oSay8), CSS_BREADCUMB))
	@ 072, 005 SAY Replicate("_",nWidth) SIZE nWidth-10, 008 OF oPnlInc FONT COLORS CLR_HGRAY, 16777215 PIXEL

	@ 085, 005 SAY oSay9 PROMPT "Buscar Serviço" SIZE 100, 010 OF oPnlInc COLORS 0, 16777215 PIXEL
	oSay9:SetCSS(POSCSS(GetClassName(oSay9), CSS_LABEL_FOCAL))
	oFindServ := TGet():New(095, 005,{|u| iif(PCount()==0,cFindServ,cFindServ:=u)},oPnlInc,170, 013,,{|| FindServ() },,,,,,.T.,,,{|| .T. },,,,.F.,.F.,,"oFindServ",,,,.T.,.F.)
	oFindServ:SetCSS(POSCSS(GetClassName(oFindServ), CSS_GET_NORMAL))

	oListServ := TListBox():Create(oPnlInc, 115, 005, Nil, aListServ, 170, nHeight-205,,,,,.T.)
	//oListServ:bSetGet := {|u| iif(PCount()>0,cListServ,) }
	oListServ:bLDBLClick := {|| IncCesta(cCodCli,cLojCli,cPrestador,oListServ:GetSelText())}
	oListServ:SetCSS(POSCSS(GetClassName(oListServ), CSS_LISTBOX))

	@ nHeight-80, 005 SAY oSay3 PROMPT "Vendedor" SIZE 100, 010 OF oPnlInc COLORS 0, 16777215 PIXEL
  	oSay3:SetCSS( POSCSS (GetClassName(oSay3), CSS_LABEL_FOCAL ))
  	oVendedor := TGet():New( nHeight-70, 005,{|u| iif( PCount()==0,cVendedor,cVendedor:=u) },oPnlInc,060, 013,,{|| VldVend() },,,,,,.T.,,,{|| .T. },,,,!lConfCash .AND. lMvPswVend,.F.,,"oVendedor",,,,.T.,.F.)
  	oVendedor:SetCSS( POSCSS (GetClassName(oVendedor), CSS_GET_NORMAL ))
	if !lMvPswVend
  		TSearchF3():New(oVendedor,400,180,"SA3","A3_COD",{{"A3_NOME",2}},"",,,2,iif(lConfCash,-40,0))
	endif

  	@ nHeight-80, 065 SAY oSay4 PROMPT "Nome Vendedor" SIZE 100, 010 OF oPnlInc COLORS 0, 16777215 PIXEL
  	oSay4:SetCSS( POSCSS (GetClassName(oSay4), CSS_LABEL_FOCAL ))
  	oNomVend := TGet():New( nHeight-70, 065,{|u| iif( PCount()==0,cNomVend,cNomVend:=u)},oPnlInc,110, 013,,{|| .T./*bValid*/ },,,,,,.T.,,,{|| .T. },,,,.T.,.F.,,"oNomVend",,,,.T.,.F.)
  	oNomVend:SetCSS( POSCSS (GetClassName(oNomVend), CSS_GET_NORMAL ))
  	oNomVend:lCanGotFocus := .F.

	@ nHeight-80, 185 SAY oSay8 PROMPT "Observações" SIZE 060, 007 OF oPnlInc COLORS 16777215, 0 PIXEL
	oSay8:SetCSS( POSCSS (GetClassName(oSay8), CSS_LABEL_FOCAL ))
	oObserv := TGet():New( nHeight-70, 185,{|u| iif( PCount()==0,cObserv,cObserv:=u)},oPnlInc,nWidth-190, 013,,{|| .T./*bValid*/ },,,,,,.T.,,,{|| .T. },,,,.F.,.F.,,"cObserv",,,,.T.,.F.)
  	oObserv:SetCSS( POSCSS (GetClassName(oObserv), CSS_GET_NORMAL ))

	@ 085, 185 SAY oSay10 PROMPT "Cesta de Serviços" SIZE 120, 010 OF oPnlInc COLORS 0, 16777215 PIXEL
	oSay10:SetCSS(POSCSS(GetClassName(oSay10), CSS_LABEL_FOCAL))

	@ 096, 182 MSPANEL oPnlGrid SIZE nWidth-182, nHeight-178 OF oPnlInc

	@ 000,000 BITMAP oTop RESOURCE "x.png" NOBORDER SIZE 000,005 OF oPnlGrid ADJUST PIXEL
	oTop:Align := CONTROL_ALIGN_TOP
	//oTop:SetCSS(POSCSS(GetClassName(oTop), CSS_PANEL_HEADER))
	oTop:SetCSS("TBitmap{ margin: 0px 9px 0px 5px; border: 1px solid #"+cCorBg+"; background-color: #"+cCorBg+"; border-top-right-radius: 8px; border-top-left-radius: 8px; }")
	oTop:ReadClientCoors(.T.,.T.)

	@ 000,000 BITMAP oBottom RESOURCE "x.png" NOBORDER SIZE 000,040 OF oPnlGrid ADJUST PIXEL
	oBottom:Align := CONTROL_ALIGN_BOTTOM
	oBottom:SetCSS(POSCSS(GetClassName(oBottom), CSS_PANEL_FOOTER))
	oBottom:ReadClientCoors(.T.,.T.)

	@ 000,000 BITMAP oContent RESOURCE "x.png" NOBORDER SIZE 000,000 OF oPnlGrid ADJUST PIXEL
	oContent:Align := CONTROL_ALIGN_ALLCLIENT
	oContent:ReadClientCoors(.T.,.T.)
	oPnlAux := POSBrwContainer(oContent)

	// Grid
	oMsGetSrv := MsNewGetSrv(oPnlAux, 053, 060, 150, nWidth-5)
	oMsGetSrv:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT
	oMsGetSrv:oBrowse:SetCSS(POSCSS("TGRID", CSS_BROWSE)) //CSS do totvs pdv
	//oMsGetSrv:oBrowse:lCanGotFocus := .F.
	oMsGetSrv:oBrowse:nScrollType := 0
	oMsGetSrv:oBrowse:lHScroll := .F.

	oBtn1 := TButton():New((oPnlGrid:nHeight/2)-36,005,"Desconto",oPnlGrid,{|| IncDesc()},080,020,,,,.T.,,,,{|| !lOnlyView})
	oBtn1:SetCSS( POSCSS (GetClassName(oBtn1), CSS_BTN_FOCAL ))

	@ (oPnlGrid:nHeight/2)-39, (oPnlGrid:nWidth/2)-62 SAY oLblTot PROMPT "Total dos Serviços" SIZE 100, 010 OF oPnlGrid COLORS 0, 16777215 PIXEL
	oLblTot:SetCSS(POSCSS(GetClassName(oLblTot), CSS_LABEL_NORMAL))
	@ (oPnlGrid:nHeight/2)-32, (oPnlGrid:nWidth/2)-110 SAY oVlrTot VAR AllTrim(Transform(nVlrTot,"@E 99,999.99")) SIZE 100, 040 OF oPnlGrid RIGHT COLOR 0, 16777215 PIXEL
	oVlrTot:SetCSS(POSCSS(GetClassName(oVlrTot), CSS_LABEL_TOTAL))

	oBtn2 := TButton():New( nHeight-45,nWidth-75,"Confirmar",oPnlInc,{|| iif(ConfInc(),iif(bConfirm<>Nil,Eval(bConfirm),),) },070,020,,,,.T.,,,,{|| .T.})
	oBtn2:SetCSS(POSCSS(GetClassName(oBtn2), CSS_BTN_FOCAL))

	If lConfCash
		oBtn3 := TButton():New( nHeight-45,nWidth-150,"Cancelar",oPnlInc,bCancel,070,020,,,,.T.,,,,{|| .T.})
		oBtn3:SetCSS( POSCSS (GetClassName(oBtn3), CSS_BTN_NORMAL ))
	else

		oBtn3 := TButton():New( nHeight-45,nWidth-150,"Limpar Tela",oPnlInc,{|| U_TPDVA6CL(.T.) },070,020,,,,.T.,,,,{|| .T.})
		oBtn3:SetCSS(POSCSS(GetClassName(oBtn3), CSS_BTN_NORMAL))

		oBtn4 := TButton():New( nHeight-45,005,"Listar Vales Serviços",oPnlInc,{|| cTitleTela := "LISTAGEM", oPnlInc:Hide(), oPnlBrow:Show() },080,020,,,,.T.,,,,{|| .T.})
		oBtn4:SetCSS(POSCSS(GetClassName(oBtn4), CSS_BTN_NORMAL))

		//////////////////////// BROWSE DOS VALES SERVIÇOS //////////////////////////////////////

		// Painel de Browse dos Vales Serviços
		oPnlBrow := TPanel():New(020,000,"",oPnlGeral,NIL,.T.,.F.,,,nWidth,nHeight-020,,.T.,.F.)
		oPnlBrow:Hide()

		@ 005, 005 SAY oSay11 PROMPT "Vale Serviço" SIZE 100, 010 OF oPnlBrow COLORS 0, 16777215 PIXEL
		oSay11:SetCSS(POSCSS(GetClassName(oSay11), CSS_LABEL_FOCAL))
		oBuscaVls := TGet():New(015, 005,{|u| iif( PCount()==0,cBuscaVls,cBuscaVls:=u) },oPnlBrow, 070, 013,,{|| /*bValid*/ },,,,,,.T.,,,{|| .T. },,,,.F.,.F.,,"oBuscaVls",,,,.T.,.F.)
		oBuscaVls:SetCSS(POSCSS(GetClassName(oBuscaVls), CSS_GET_NORMAL))

		//@ 005, 080 SAY oSay12 PROMPT "CPF/CNPJ Cliente" SIZE 100, 010 OF oPnlBrow COLORS 0, 16777215 PIXEL
		//oSay12:SetCSS(POSCSS(GetClassName(oSay12), CSS_LABEL_FOCAL))
		//oBuscaCpf := TGet():New(015, 080,{|u| iif( PCount()==0,cBuscaCpf,cBuscaCpf:=u) },oPnlBrow, 080, 013,,{|| /*bValid*/ },,,,,,.T.,,,{|| .T. },,,,.F.,.F.,,"cBuscaCpf",,,,.T.,.F.)
		//oBuscaCpf:SetCSS(POSCSS(GetClassName(oBuscaCpf), CSS_GET_NORMAL))
		//TSearchF3():New(oBuscaCpf,400,250,"SA1","A1_CGC",{{"A1_NOME",2},{"A1_CGC",3},{"A1_COD",1}},"SA1->A1_MSBLQL<>'1'",{{"A1_NOME","A1_EST","A1_MUN"},{"A1_CGC","A1_NOME","A1_EST","A1_MUN"},{"A1_COD","A1_LOJA","A1_NOME","A1_EST","A1_MUN"}},,,0)

		@ 005, 080 SAY oSay12 PROMPT "Código" SIZE 100, 010 OF oPnlBrow COLORS 0, 16777215 PIXEL
		oSay12:SetCSS( POSCSS (GetClassName(oSay12), CSS_LABEL_FOCAL ))
		oBuscaCli := TGet():New( 015, 080,{|u| iif( PCount()==0,cBuscaCod,cBuscaCod:=u) },oPnlBrow, 055, 013, "@!",{|| /*bValid*/ },,,,,,.T.,,,{|| .T. },,,,.F.,.F.,,"oBuscaCli",,,,.T.,.F.)
		oBuscaCli:SetCSS( POSCSS (GetClassName(oBuscaCli), CSS_GET_NORMAL ))

		@ 005, 135 SAY oSay12 PROMPT "Loja" SIZE 100, 010 OF oPnlBrow COLORS 0, 16777215 PIXEL
		oSay12:SetCSS( POSCSS (GetClassName(oSay12), CSS_LABEL_FOCAL ))
		oBuscaLoj := TGet():New( 015, 135,{|u| iif( PCount()==0,cBuscaLoj,cBuscaLoj:=u) },oPnlBrow, 020, 013, "@!",{|| /*bValid*/ },,,,,,.T.,,,{|| .T. },,,,.F.,.F.,,"oBuscaLoj",,,,.T.,.F.)
		oBuscaLoj:SetCSS( POSCSS (GetClassName(oBuscaLoj), CSS_GET_NORMAL ))
		TSearchF3():New(oBuscaCli,400,250,"SA1","A1_COD",{{"A1_NOME",2},{"A1_CGC",3},{"A1_COD",1}},"SA1->A1_MSBLQL<>'1'",{{"A1_COD","A1_LOJA","A1_NOME","A1_EST","A1_MUN"},{"A1_COD","A1_LOJA","A1_CGC","A1_NOME","A1_EST","A1_MUN"},{"A1_COD","A1_LOJA","A1_NOME","A1_EST","A1_MUN"}},,,0/*nAjustPos*/,,{{oBuscaLoj,"A1_LOJA"}})

		@ 005, 165 SAY oSay13 PROMPT "Placa" SIZE 100, 010 OF oPnlBrow COLORS 0, 16777215 PIXEL
		oSay13:SetCSS(POSCSS(GetClassName(oSay13), CSS_LABEL_FOCAL))
		oBuscaPlaca := TGet():New(015, 165,{|u| iif( PCount()==0,cBuscaPlaca,cBuscaPlaca:=u) },oPnlBrow,50, 013,"@!R NNN-9N99",{|| /*bValid*/ },,,,,,.T.,,,{|| .T. },,,,.F.,.F.,,"cBuscaPlaca",,,,.T.,.F.)
		oBuscaPlaca:SetCSS( POSCSS (GetClassName(oBuscaPlaca), CSS_GET_NORMAL))

		@ 005, 220 SAY oSay14 PROMPT "Data" SIZE 035, 008 OF oPnlBrow COLORS 0, 16777215 PIXEL
		oSay14:SetCSS(POSCSS(GetClassName(oSay14), CSS_LABEL_FOCAL ))
		@ 015, 220 MSGET oBuscaDt VAR dBuscaDt SIZE 070, 013 OF oPnlBrow VALID .T. PICTURE "@!" COLORS 0, 16777215 /*FONT oFntGetCab*/ HASBUTTON PIXEL
		oBuscaDt:SetCSS(POSCSS(GetClassName(oBuscaDt), CSS_GET_NORMAL))

		oBtn5 := TButton():New( 015, 295,"Buscar",oPnlBrow,{|| BuscaVls() },040,015,,,,.T.,,,,{|| .T.})
		oBtn5:SetCSS(POSCSS(GetClassName(oBtn5), CSS_BTN_FOCAL))

		// Grid
		@ 035, 003 MSPANEL oPnlGrid2 SIZE nWidth-4, nHeight-80 OF oPnlBrow

		@ 000,000 BITMAP oTop RESOURCE "x.png" NOBORDER SIZE 000,005 OF oPnlGrid2 ADJUST PIXEL
		oTop:Align := CONTROL_ALIGN_TOP
		//oTop:SetCSS(POSCSS(GetClassName(oTop), CSS_PANEL_HEADER))
		oTop:SetCSS("TBitmap{ margin: 0px 9px 0px 5px; border: 1px solid #"+cCorBg+"; background-color: #"+cCorBg+"; border-top-right-radius: 8px; border-top-left-radius: 8px; }")
		oTop:ReadClientCoors(.T.,.T.)

		@ 000,000 BITMAP oBottom RESOURCE "x.png" NOBORDER SIZE 000,025 OF oPnlGrid2 ADJUST PIXEL
		oBottom:Align := CONTROL_ALIGN_BOTTOM
		oBottom:SetCSS(POSCSS(GetClassName(oBottom), CSS_PANEL_FOOTER))
		oBottom:ReadClientCoors(.T.,.T.)

		@ 000,000 BITMAP oContent RESOURCE "x.png" NOBORDER SIZE 000,000 OF oPnlGrid2 ADJUST PIXEL
		oContent:Align := CONTROL_ALIGN_ALLCLIENT
		oContent:ReadClientCoors(.T.,.T.)
		oPnlAux2 := POSBrwContainer(oContent)

		oMsGetVls := MsNewGetVls(oPnlAux2, 053, 090, 150, nWidth-5)
		oMsGetVls:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT
		oMsGetVls:oBrowse:SetCSS(StrTran(POSCSS("TGRID", CSS_BROWSE),"gridline-color: white;","")) //CSS do totvs pdv
		//oMsGetVls:oBrowse:lCanGotFocus := .F.
		oMsGetVls:oBrowse:nScrollType := 0
		oMsGetVls:oBrowse:lHScroll := .F.
		oMsGetVls:oBrowse:bLDblClick := {|| ViewVls() }

		@ (oPnlGrid2:nHeight/2)-22, 010 SAY oQtdReg PROMPT (cValToChar(nQtdReg)+" registros encontrados.") SIZE 150, 010 OF oPnlGrid2 COLORS 0, 16777215 PIXEL
		oQtdReg:SetCSS( POSCSS (GetClassName(oQtdReg), CSS_LABEL_NORMAL))
		@ (oPnlGrid2:nHeight/2)-21, nWidth-090 BITMAP oLeg ResName "BR_VERDE" OF oPnlGrid2 Size 10, 10 NoBorder When .F. PIXEL
		@ (oPnlGrid2:nHeight/2)-22, nWidth-080 SAY oSay14 PROMPT "Ativo" OF oPnlGrid2 Color CLR_BLACK PIXEL
		oSay14:SetCSS( POSCSS (GetClassName(oSay14), CSS_LABEL_NORMAL))
		@ (oPnlGrid2:nHeight/2)-21, nWidth-055 BITMAP oLeg ResName "BR_PRETO" OF oPnlGrid2 Size 10, 10 NoBorder When .F. PIXEL
		@ (oPnlGrid2:nHeight/2)-22, nWidth-045 SAY oSay14 PROMPT "Estornado" OF oPnlGrid2 Color CLR_BLACK PIXEL
		oSay14:SetCSS( POSCSS (GetClassName(oSay14), CSS_LABEL_NORMAL))

		oBtn6 := TButton():New(nHeight-45,005,"Incluir",oPnlBrow,{|| cTitleTela:="INCLUSÃO",oPnlInc:Show(), oCodCli:SetFocus(), oPnlBrow:Hide(),U_TPDVA6CL(.T.) },060,020,,,,.T.,,,,{|| .T.})
		oBtn6:SetCSS(POSCSS(GetClassName(oBtn6), CSS_BTN_FOCAL))

		oBtn7 := TButton():New(nHeight-45,070,"Visualizar",oPnlBrow,{||  ViewVls()},060,020,,,,.T.,,,,{|| .T.})
		oBtn7:SetCSS(POSCSS(GetClassName(oBtn7), CSS_BTN_NORMAL))

		oBtn8 := TButton():New(nHeight-45,135,"Estornar",oPnlBrow,{||  EstornaVls()},060,020,,,,.T.,,,,{|| .T.})
		oBtn8:SetCSS(POSCSS(GetClassName(oBtn8), CSS_BTN_NORMAL))

		oBtn9 := TButton():New(nHeight-45,200,"Imprimir",oPnlBrow,{||  ImpVls(.T.)},060,020,,,,.T.,,,,{|| .T.})
		oBtn9:SetCSS(POSCSS(GetClassName(oBtn8), CSS_BTN_NORMAL))

	endif

	oPlaca:SetFocus()

	if lConfCash
		if nOpcX == 2
			ViewVls()
		else
			U_TPDVA6CL(.T.)
		endif
	endif

Return cUsrVls

//--------------------------------------------------------------
// Aplica CSS no botão tipo Radio
//--------------------------------------------------------------
Static Function SetTipoSel(cOpcSel)

	Local cCssBtn

	if cOpcSel == "O" //Pós

		//deixo botão PÓS azul
		cCssBtn := POSCSS(GetClassName(oBtnTpPos), CSS_BTN_FOCAL )
		cCssBtn:= StrTran(cCssBtn, "border-radius: 6px;", "border-radius: 3px;")
		oBtnTpPos:SetCss(cCssBtn)

		//deixo botão PRÉ branco
		cCssBtn := POSCSS(GetClassName(oBtnTpPre), CSS_BTN_NORMAL )
		cCssBtn:= StrTran(cCssBtn, "border-radius: 6px;", "border-radius: 3px;")
		cCssBtn:= StrTran(cCssBtn, "font: bold large;", "")
		oBtnTpPre:SetCss(cCssBtn)

	else //Pré

		//deixo botão PÓS branco
		cCssBtn := POSCSS(GetClassName(oBtnTpPos), CSS_BTN_NORMAL )
		cCssBtn:= StrTran(cCssBtn, "border-radius: 6px;", "border-radius: 3px;")
		cCssBtn:= StrTran(cCssBtn, "font: bold large;", "")
		oBtnTpPos:SetCss(cCssBtn)

		//deixo botão PRÉ azul
		cCssBtn := POSCSS(GetClassName(oBtnTpPre), CSS_BTN_FOCAL )
		cCssBtn:= StrTran(cCssBtn, "border-radius: 6px;", "border-radius: 3px;")
		oBtnTpPre:SetCss(cCssBtn)

	endif

	oBtnTpPos:Refresh()
	oBtnTpPre:Refresh()

Return

//---------------------------------------------------------------------
// Retorna os prestadores de serviço cadastrados
//---------------------------------------------------------------------
Static Function GetPrest()

	Local aRet 		:= {}
	Local cFornece	:= ""
	Local cLojaFor	:= ""
	Local cNomeFor	:= ""
	Local nPosPre

	DbSelectArea("UH9")
	UH9->(DbSetOrder(1)) //UH9_FILIAL+UH9_FORNEC+UH9_LOJA+UH9_PRODUT
	UH9->(DbGoTop())

	If UH9->(DbSeek(xFilial("UH9")))

		While UH9->(!EOF()) .And. UH9->UH9_FILIAL == xFilial("UH9")

			cFornece := UH9->UH9_FORNEC
			cLojaFor := UH9->UH9_LOJA
			cNomeFor := Posicione("UH8",1,xFilial("UH8")+cFornece+cLojaFor,"UH8_NOME")

			If (nPosPre := aScan(aRet,{|x| SubStr(x,1,TamSX3("A2_COD")[1] + TamSX3("A2_LOJA")[1] + 1) == cFornece + "/" + cLojaFor})) == 0
				AAdd(aRet,cFornece + "/" + cLojaFor + " - " + cNomeFor)
			EndIf

			UH9->(DbSkip())
		EndDo
	Endif

	If Len(aRet) > 0
		aSize(aRet,Len(aRet) + 1)
		aIns(aRet,1)
		aRet[1] := Space(TamSx3("A2_NOME")[1])
	EndIf

Return aRet

//---------------------------------------------------------------------
// Carrega lista de serviços do prestador
//---------------------------------------------------------------------
Static Function SelSrv(cPrestador)

	Local aRet 		:= {}
	Local cCod		:= ""
	Local cDesc		:= ""
	Local aFor		:= StrTokArr(SubStr(cPrestador,1,TamSX3("A2_COD")[1] + TamSX3("A2_LOJA")[1] + 1),"/")
	Local nPosServ

	DbSelectArea("UH9")
	UH9->(DbSetOrder(1)) //UH9_FILIAL+UH9_FORNEC+UH9_LOJA+UH9_PRODUT
	UH9->(DbGoTop())

	If Len(aFor) == 2 .And. UH9->(DbSeek(xFilial("UH9")+aFor[1]+aFor[2]))

		While UH9->(!EOF()) .And. UH9->UH9_FILIAL == xFilial("UH9") .And. UH9->UH9_FORNEC == aFor[1] .And. UH9->UH9_LOJA == aFor[2]

			cCod	:= UH9->UH9_PRODUT
			cDesc 	:= Posicione("SB1",1,xFilial("SB1")+cCod,"B1_DESC")

			If (nPosServ := aScan(aRet,{|x| SubStr(x,1,TamSX3("B1_COD")[1]) == cCod})) == 0
				AAdd(aRet, Alltrim(cDesc) + " | " + cCod)
			EndIf

			// Traz somente os 10 primeiros resultados
			If Len(aRet) == 10
				if !lConfCash
					U_SetMsgRod("O resultado foi limitado a 10 serviços. Refina sua busca se for necessário!")
				endif
				Exit
			EndIf

			UH9->(DbSkip())
		EndDo
	EndIf

	If Len(aRet) == 0
		aRet := {''}
	EndIf

Return aRet

//---------------------------------------------------------------------
// Validacao da placa
//---------------------------------------------------------------------
Static Function VldPlaca()

	Local lRet := .T.
	Local aCliByGrp := {}
	Local nPosCliGrp := 1
	Local lBlqAI0 	:= SuperGetMv("MV_XBLQAI0",,.F.) .AND. AI0->(FieldPos("AI0_XBLFIL")) > 0 //Habilita bloqueio de venda na filial, olhando para tabela AI0

	If !Empty(cPlaca)

		DbSelectArea("DA3")
		DA3->(DbSetOrder(3)) //DA3_FILIAL+DA3_PLACA

		If DA3->(DbSeek(xFilial("DA3")+cPlaca ))
			if empty(cCodCli) .OR. (Alltrim(cCodCli) == AllTrim(GetMv("MV_CLIPAD")) .AND. Alltrim(cLojCli) == AllTrim(GetMv("MV_LOJAPAD")))
				If !Empty(DA3->DA3_XCODCL) .And. !Empty(Posicione("SA1",1,xFilial("SA1")+DA3->DA3_XCODCL+DA3->DA3_XLOJCL,"A1_COD"))

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

				EndIf

				if !empty(cCodCli)
					oCodCli:Refresh()
					oLojCli:Refresh()
					lRet := VldCliente()
				endif
			endif
		EndIf
	EndIf

Return lRet

//---------------------------------------------------------------------
// Validacao do cliente
//---------------------------------------------------------------------
Static Function VldCliente()

	Local cMsgErr := ""
	Local lRet := .T.
	Local lBlqAI0 		:= SuperGetMv("MV_XBLQAI0",,.F.) .AND. AI0->(FieldPos("AI0_XBLFIL")) > 0 //Habilita bloqueio de venda na filial, olhando para tabela AI0

	lCliHbPos    := .F.

	If Empty(cCodCli) .or. Empty(cLojCli)
		cCodCli := space(tamsx3("A1_COD")[1])
		cLojCli := space(tamsx3("A1_LOJA")[1])
		cNomCli := space(tamsx3("A1_NOME")[1])
	Else

		cNomCli := Posicione("SA1",1,xFilial("SA1")+cCodCli+cLojCli,"A1_NOME")

		If Empty(cNomCli)
			lRet := .F.
			cMsgErr := "Cliente não cadastrado!"
			
		// verifico se o cadastro tem autorização para ser utilizado nesta filial/empresa
		elseif lBlqAI0 .AND. Posicione("AI0",1,xFilial("AI0")+SA1->A1_COD+SA1->A1_LOJA,"AI0_XBLFIL")=="S"
			lRet := .F.
			cMsgErr :=  "O cliente "+SA1->A1_COD+"/"+SA1->A1_LOJA+" não está autorizado nesta filial."
		elseIf !lBlqAI0 .AND. SA1->(FieldPos("A1_XFILBLQ")) > 0 .and. !Empty(SA1->A1_XFILBLQ) .and. (cFilAnt $ SA1->A1_XFILBLQ)
			lRet := .F.
			cMsgErr :=  "O cliente "+SA1->A1_COD+"/"+SA1->A1_LOJA+" não está autorizado nesta filial."
		
		Else

			if SA1->(FieldPos("A1_XVLSPOS")) > 0 .AND. SA1->A1_XVLSPOS == "S"
				lCliHbPos    := .T.
			endif

			oBtnTpPre:Click()
		EndIf
	EndIf

	If lRet
		oNomCli:Refresh()
	EndIf

	if lConfCash
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

	if lConfCash
		if !empty(cMsgErr)
			MsgInfo(cMsgErr, "Atenção")
		endif
	else
		U_SetMsgRod(cMsgErr)
	endif

Return lRet

//---------------------------------------------------------------------
// Procura servico pelo campo busca
//---------------------------------------------------------------------
Static Function FindServ()

	Local aFor		:= StrTokArr(SubStr(cPrestador,1,TamSX3("A2_COD")[1] + TamSX3("A2_LOJA")[1] + 1),"/")
	Local cCod		:= ""
	Local cDesc		:= ""
	Local cCondicao	:= ""
	Local bCondicao

	If !Empty(cFindServ) .and. Len(aFor) == 2

		aListServ := {}

		cCondicao := " UH9_FILIAL == '"+xFilial("UH9")+"'"
		cCondicao += " .AND. UH9_FORNEC == '"+aFor[1]+"'"
		cCondicao += " .AND. UH9_LOJA == '"+aFor[2]+"'"
		cCondicao += " .AND. '" + AllTrim(cFindServ) + "' $ UH9_DESCRI"

		// Limpa os filtros da UH9
		UH9->(DbClearFilter())

		// Filtra na UH9
		bCondicao := "{|| " + cCondicao + " }"
		UH9->(DbSetFilter(&bCondicao,cCondicao))

		UH9->(DbGoTop())

		While UH9->(!EOF())

			cCod	:= UH9->UH9_PRODUT
			cDesc 	:= Posicione("SB1",1,xFilial("SB1")+cCod,"B1_DESC")

			AAdd(aListServ, Alltrim(cDesc) + " | " + cCod )

			UH9->(DbSkip())
		EndDo

		// Limpa os filtros da UH9
		UH9->(DbClearFilter())
	Else
		aListServ := SelSrv(cPrestador)
	EndIf

	oListServ:SetItems(aListServ)
	oListServ:Refresh()

Return

//---------------------------------------------------------------------
// Definicao do grid de serviços
//---------------------------------------------------------------------
Static Function MsNewGetSrv(oPnl, nTop, nLeft, nBottom, nRight)

	Local aHeaderEx 	:= {}
	Local aColsEx 		:= {}
	Local aFieldFill 	:= {}
	Local aAlterFields 	:= {}

	AAdd(aHeaderEx, {"Serviço","SERVICO",PesqPict("SB1","B1_COD"),TamSX3("B1_COD")[1],0,"","€€€€€€€€€€€€€€","C","","","",""})
	AAdd(aFieldFill, Space(TamSX3("B1_COD")[1]))

	AAdd(aHeaderEx, {"Descrição","DESCRICAO",PesqPict("SB1","B1_DESC"),TamSX3("B1_DESC")[1],0,"","€€€€€€€€€€€€€€","C","","","",""})
	AAdd(aFieldFill, Space(TamSX3("B1_DESC")[1]))

	AAdd(aHeaderEx, {"Preço","PRECO","@E 999,999,999.99",12,2,"","€€€€€€€€€€€€€€","N","","","",""})
	AAdd(aFieldFill, 0)

	AAdd(aHeaderEx, {"Desconto","DESCONTO","@E 999,999,999.99",12,2,"","€€€€€€€€€€€€€€","N","","","",""})
	AAdd(aFieldFill, 0)

	AAdd(aHeaderEx, {"Total","TOTAL","@E 999,999,999.99",12,2,"","€€€€€€€€€€€€€€","N","","","",""})
	AAdd(aFieldFill, 0)

	AAdd(aFieldFill, .F.) // Delete
	AAdd(aColsEx, aFieldFill)

Return MsNewGetDados():New( nTop, nLeft, nBottom, nRight, GD_DELETE , "AllwaysTrue", "AllwaysTrue", "+Field1+Field2", aAlterFields,, 999, "AllwaysTrue", "", "U_TPDVA06D()", oPnl, aHeaderEx, aColsEx)

//---------------------------------------------------------------------
// Atualiza total
//---------------------------------------------------------------------
User Function TPDVA06D()

	oMsGetSrv:aCols[oMsGetSrv:nAt][NPOSDEL] := !oMsGetSrv:aCols[oMsGetSrv:nAt][NPOSDEL]
	AtuTotal()
	oMsGetSrv:aCols[oMsGetSrv:nAt][NPOSDEL] := !oMsGetSrv:aCols[oMsGetSrv:nAt][NPOSDEL]

Return .T.

//---------------------------------------------------------------------
// Definicao do browse de vale servicos
//---------------------------------------------------------------------
Static Function MsNewGetVls(oPnl, nTop, nLeft, nBottom, nRight)

	Local aHeaderEx 	:= {}
	Local aColsEx 		:= {}
	Local aAlterFields 	:= {}
	Local aFields 		:= {"UIC_AMB","UIC_CODIGO","UIC_TIPO","UIC_FORNEC","UIC_LOJAF","UIC_NOMEF","UIC_CLIENT","UIC_LOJAC","UIC_NOMEC","UIC_PLACA",;
							"UIC_PRODUT","UIC_DESCRI","UIC_PRCPRO","UIC_DATA","UIC_HORA","UIC_OPERAD"}
	Local aFieldFill 	:= {}
	Local nX

	// a primeira coluna do grid é legenda
	Aadd(aHeaderEx,{Space(10),'LEGENDA','@BMP',2,0,'','€€€€€€€€€€€€€€','C','','','',''})
	Aadd(aFieldFill, "BR_BRANCO")

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

	Aadd(aFieldFill, 0) // RECNO
	Aadd(aFieldFill, .F.)
	Aadd(aColsEx, aFieldFill)

Return MsNewGetDados():New( nTop, nLeft, nBottom, nRight, , "AllwaysTrue", "AllwaysTrue", "+Field1+Field2", aAlterFields,, 999, "AllwaysTrue", "", "AllwaysTrue", oPnl, aHeaderEx, aColsEx)

//---------------------------------------------------------------------
// Inclui item na cesta
//---------------------------------------------------------------------
Static Function IncCesta(cCodCli,cLojCli,cPrestador,cItem)

	Local cMsgErr := ""
	Local cGrpCli	:= Posicione("SA1",1,xFilial("SA1")+cCodCli+cLojCli,"A1_GRPVEN")
	Local cCliente	:= cCodCli
	Local cLojaCli	:= cLojCli
	Local aFor		:= IIF(!Empty(cPrestador),StrTokArr(SubStr(cPrestador,1,TamSX3("A2_COD")[1] + TamSX3("A2_LOJA")[1] + 1),"/"),{})
	Local cServ 	:= SubStr(cItem, At('|',cItem)+2, TamSX3("B1_COD")[1])
	Local lAchou	:= .F.
	Local aServ		:= {}

	//If aScan(oMsGetSrv:aCols,{|x| x[1] == cServ }) == 0

		If Len(aFor) > 0 .And. !Empty(cServ)

			DbSelectArea("UIB")
			UIB->(DbSetOrder(1)) // UIB_FILIAL+UIB_GRPCLI+UIB_CLIENT+UIB_LOJA+UIB_FORNEC+UIB_LOJAFO+UIB_PRODUT
			UIB->(DbGoTop())

			DbSelectArea("UH9")
			UH9->(DbSetOrder(1)) // UH9_FILIAL+UH9_FORNEC+UH9_LOJA+UH9_PRODUT
			UH9->(DbGoTop())

			If !Empty(cCliente) .And. !Empty(cLojaCli)

				If UIB->(DbSeek(xFilial("UIB")+Space(TamSX3("A1_GRPVEN")[1])+cCliente+cLojaCli+aFor[1]+aFor[2]+cServ))
					lAchou := .T.
				Endif

			ElseIf !Empty(cGrpCli)

				If UIB->(DbSeek(xFilial("UIB")+cGrpCli+Space(TamSX3("A1_COD")[1])+Space(TamSX3("A1_LOJA")[1])+aFor[1]+aFor[2]+cServ))
					lAchou := .T.
				Endif
			Endif

			If UH9->(DbSeek(xFilial("UH9")+aFor[1]+aFor[2]+cServ))

				If Len(oMsGetSrv:aCols) == 1
					If !Empty(oMsGetSrv:aCols[1][NPOSSRV])

						AAdd(aServ,cServ)
						AAdd(aServ,Posicione("SB1",1,xFilial("SB1")+cServ,"B1_DESC"))
						AAdd(aServ,UH9->UH9_PRCUNI + iif(lAchou,UIB->UIB_DESACR,0))
						AAdd(aServ,0)
						AAdd(aServ,UH9->UH9_PRCUNI + iif(lAchou,UIB->UIB_DESACR,0))
						AAdd(aServ,.F.)
						AAdd(oMsGetSrv:aCols,aServ)
					Else
						oMsGetSrv:aCols[1][NPOSSRV] := cServ
						oMsGetSrv:aCols[1][NPOSDES] := Posicione("SB1",1,xFilial("SB1")+cServ,"B1_DESC")
						oMsGetSrv:aCols[1][NPOSPRC] := UH9->UH9_PRCUNI + iif(lAchou,UIB->UIB_DESACR,0)
						oMsGetSrv:aCols[1][NPOSTOT] := UH9->UH9_PRCUNI + iif(lAchou,UIB->UIB_DESACR,0)
					EndIf
				Else

					AAdd(aServ,cServ)
					AAdd(aServ,Posicione("SB1",1,xFilial("SB1")+cServ,"B1_DESC"))
					AAdd(aServ,UH9->UH9_PRCUNI + iif(lAchou,UIB->UIB_DESACR,0))
					AAdd(aServ,0)
					AAdd(aServ,UH9->UH9_PRCUNI + iif(lAchou,UIB->UIB_DESACR,0))
					AAdd(aServ,.F.)
					AAdd(oMsGetSrv:aCols,aServ)
				EndIf
			Else
				cMsgErr := "Preço base do serviço não localizado!"
			EndIf
		Endif
	//Else
	//	cMsgErr := "Serviço já selecionado!"
	//Endif

	if lConfCash
		if !empty(cMsgErr)
			MsgInfo(cMsgErr, "Atenção")
		endif
	else
		U_SetMsgRod(cMsgErr)
	endif

	oMsGetSrv:Refresh()
	AtuTotal()

Return

//---------------------------------------------------------------------
// Atualiza o total
//---------------------------------------------------------------------
Static Function AtuTotal()

	Local nX

	nVlrTot := 0

	For nX := 1 To Len(oMsGetSrv:aCols)

		If !oMsGetSrv:aCols[nX][NPOSDEL]
			nVlrTot += oMsGetSrv:aCols[nX][NPOSTOT]
		EndIf
	Next nX

	oVlrTot:Refresh()

Return

//---------------------------------------------------------------------
// Controle dos Descontos
//---------------------------------------------------------------------
Static Function IncDesc()

	Local oSay1, oSay2, oSay3
	Local nOpcx 		:= 0
	Local nWidth, nHeight
	Local oPnlDesc, oPnlTop
	Local bCloseDesc 	:= {|| oDlgDesc:End()}

	Private oDlgDesc

	//TODO - criar controle de acesso para desconto no vale serviço
	//If !U_VLACESS2("??????",RetCodUsr(),.T.)
	//	Return
	//EndIf

	If Empty(oMsGetSrv:aCols[oMsGetSrv:nAt][NPOSSRV])
		if lConfCash
			MsgInfo("Nenhum serviço selecionado!", "Atenção")
		else
			U_SetMsgRod("Nenhum serviço selecionado!")
		endif
		Return
	EndIf

	If Empty(oMsGetSrv:aCols[oMsGetSrv:nAt][NPOSCON])

		nPercDesc	:= 0
		nVlrDesc	:= 0
		nVlrAtu		:= 0
		nResDesc	:= 0
		cHelpVls	:= ""
	Else
		nVlrDesc	:= oMsGetSrv:aCols[oMsGetSrv:nAt][NPOSCON]
		nVlrAtu		:= oMsGetSrv:aCols[oMsGetSrv:nAt][NPOSPRC]
		nPercDesc	:= (nVlrDesc / nVlrAtu) * 100
		nResDesc	:= oMsGetSrv:aCols[oMsGetSrv:nAt][NPOSTOT]
		cHelpVls	:= ""
	EndIf

	DEFINE MSDIALOG oDlgDesc TITLE "" FROM 000,000 TO 375,375 PIXEL STYLE nOr(WS_VISIBLE, WS_POPUP)

	nWidth	:= (oDlgDesc:nWidth/2)
	nHeight	:= (oDlgDesc:nHeight/2)

	@ 000, 000 MSPANEL oPnlDesc SIZE nWidth, nHeight OF oDlgDesc
	oPnlDesc:SetCSS("TPanel{border: 2px solid #999999; background-color: #f4f4f4;}")

	@ 000, 000 MSPANEL oPnlTop SIZE nWidth, 017 OF oPnlDesc
	oPnlTop:SetCSS( POSCSS (GetClassName(oPnlTop), CSS_BAR_TOP ))
	@ 004, 005 SAY oSay2 PROMPT "Inclusão de Desconto" SIZE 100, 015 OF oPnlTop COLORS 0, 16777215 PIXEL
	oSay2:SetCSS(POSCSS(GetClassName(oSay2), CSS_BREADCUMB))
	oClose := TBtnBmp2():New( 002,oDlgDesc:nWidth-25,20,30,'FWSKIN_DELETE_ICO',,,,bCloseDesc,oPnlTop,,,.T. )
	oClose:SetCss("TBtnBmp2{border: none;background-color: none;}")

	@ 025, 010 SAY oSay3 PROMPT "% Desconto" SIZE 080, 010 OF oPnlDesc COLORS 0, 16777215 PIXEL
	oSay3:SetCSS(POSCSS(GetClassName(oSay3), CSS_LABEL_FOCAL))
	oPercDesc := TGet():New(035, 010,{|u| IIF(PCount()>0,nPercDesc:=u,nPercDesc)},oPnlDesc,60, 013,"@E 99.99",{|| Positivo(M->nPercDesc) .And. VldDesc("P") .And. oPnlDesc:Refresh()},,,,,,.T.,,,{|| .T. },,,,lOnlyView,.F.,,"nPercDesc",,,,.T.,.F.)
	oPercDesc:SetCSS(POSCSS(GetClassName(oPercDesc), CSS_GET_NORMAL))

	@ 025, 095 SAY oSay4 PROMPT "Valor Desconto" SIZE 080, 010 OF oPnlDesc COLORS 0, 16777215 PIXEL
	oSay4:SetCSS(POSCSS(GetClassName(oSay4), CSS_LABEL_FOCAL))
	oVlrDesc := TGet():New(035, 095,{|u| IIF(PCount()>0,nVlrDesc:=u,nVlrDesc)},oPnlDesc,80, 013,"@E 99,999,999,999.99",{|| Positivo(M->nVlrDesc) .And. VldDesc("V") .And. oPnlDesc:Refresh()},,,,,,.T.,,,{|| .T. },,,,lOnlyView,.F.,,"nVlrDesc",,,,.T.,.F.)
	oVlrDesc:SetCSS(POSCSS(GetClassName(oVlrDesc), CSS_GET_NORMAL))

	nVlrAtu := oMsGetSrv:aCols[oMsGetSrv:nAt][NPOSPRC]
	@ 055, 010 SAY oSay5 PROMPT "Valor atual" SIZE 080, 010 OF oPnlDesc COLORS 0, 16777215 PIXEL
	oSay5:SetCSS(POSCSS(GetClassName(oSay5), CSS_LABEL_FOCAL))
	oVlrAtu := TGet():New(065, 010,{|u| IIF(PCount()>0,nVlrAtu:=u,nVlrAtu)},oPnlDesc,80, 013,PesqPict("UIC","UIC_PRCPRO"),{|| .T.},,,,,,.T.,,,{|| .T. },,,,.T.,.F.,,"nVlrAtu",,,,.T.,.F.)
	oVlrAtu:SetCSS(POSCSS(GetClassName(oVlrAtu), CSS_GET_NORMAL))
	oVlrAtu:lCanGotFocus := .F.

	@ 055, 095 SAY oSay6 PROMPT "Valor c/ Desconto" SIZE 080, 010 OF oPnlDesc COLORS 0, 16777215 PIXEL
	oSay6:SetCSS(POSCSS(GetClassName(oSay6), CSS_LABEL_FOCAL))
	oResDesc := TGet():New(065, 095,{|u| IIF(PCount()>0,nResDesc:=u,nResDesc)},oPnlDesc,80, 013,PesqPict("UIC","UIC_PRCPRO"),{|| Positivo(M->nResDesc) .And. VldDesc("D") .And. oPnlDesc:Refresh()},,,,,,.T.,,,{|| .T. },,,,lOnlyView,.F.,,"nResDesc",,,,.T.,.F.)
	oResDesc:SetCSS(POSCSS(GetClassName(oResDesc), CSS_GET_NORMAL))

	@ 145, 010 SAY oHelpVls PROMPT cHelpVls PICTURE "@!" SIZE nWidth-15, 020 OF oPnlDesc COLORS 0, 16777215 PIXEL
	oHelpVls:SetCSS( "TSay{ font:bold 13px; color: #AA0000; background-color: transparent; border: none; margin: 0px; }" )

	oBtn6 := TButton():New( nHeight-20,nWidth-60,"Confirmar",oPnlDesc,{|| IIF(lOnlyView .Or. VldConfD(),(nOpcx := 1, oDlgDesc:End()),) },050,014,,,,.T.,,,,{|| .T.})
	oBtn6:SetCSS( POSCSS (GetClassName(oBtn6), CSS_BTN_FOCAL ))

	oBtn7 := TButton():New( nHeight-20,nWidth-115,"Cancelar",oPnlDesc,bCloseDesc,050,014,,,,.T.,,,,{|| .T.})
	oBtn7:SetCSS( POSCSS (GetClassName(oBtn7), CSS_BTN_ATIVO ))

	oDlgDesc:lCentered := .T.
	oDlgDesc:Activate()

	If nOpcx == 1 .AND. !lOnlyView

		oMsGetSrv:aCols[oMsGetSrv:nAt][NPOSCON] := nVlrDesc
		oMsGetSrv:aCols[oMsGetSrv:nAt][NPOSTOT] := nResDesc
		oMsGetSrv:oBrowse:Refresh()
		AtuTotal()
	EndIf

Return

//---------------------------------------------------------------------
// Valida Desconto
//---------------------------------------------------------------------
Static Function VldDesc(cOrigem)

	Local lRet := .T.

	If cOrigem == "P" // Campo percentual

		If nPercDesc > 0
			nVlrDesc	:= nVlrAtu * (nPercDesc / 100)
			nResDesc 	:= nVlrAtu - nVlrDesc
		Else
			nVlrDesc 	:= 0
			nResDesc 	:= nVlrAtu
		EndIf

	ElseIf cOrigem == "V" // Campo valor

		If nVlrDesc > 0 .And. nVlrDesc < nVlrAtu
			nPercDesc	:= (nVlrDesc / nVlrAtu) * 100
			nResDesc	:= nVlrAtu - nVlrDesc
		Else
			nPercDesc 	:= 0
			nResDesc 	:= nVlrAtu
		EndIf

	Else
		If nResDesc > 0 .And. nResDesc < nVlrAtu
			nVlrDesc	:= nVlrAtu - nResDesc
			nPercDesc	:= (nVlrDesc / nVlrAtu) * 100
		Else
			nVlrDesc	:= 0
			nPercDesc	:= 0
		EndIf
	EndIf

	If Round(nResDesc,2) > 0 .And. nResDesc < nVlrAtu

		cHelpVls	:= ""

		oPercDesc:Refresh()
		oVlrDesc:Refresh()
		oResDesc:Refresh()
	Else
		If nPercDesc > 0 .Or. nVlrDesc > 0  .Or. (nResDesc > 0 .And. nResDesc >= nVlrAtu)
			cHelpVls := "O valor de desconto de deve ser inferior ao valor do serviço!"
		EndIf
	EndIf

	oHelpVls:Refresh()

Return lRet

//---------------------------------------------------------------------
// Valida Descontos
//---------------------------------------------------------------------
Static Function VldConfD()

	Local lRet := .T.

	If !Empty(cHelpVls)
		lRet := .F.
	EndIf

Return lRet

//---------------------------------------------------------------------
// Função para limpeza da tela
//---------------------------------------------------------------------
User function TPDVA6CL(lNoBrowse)

	Local lMvPswVend := SuperGetMv("TP_PSWVEND",,.F.)
	Default lNoBrowse := .F.

	If !lConfCash .AND. Empty(cUsrVls) // Se não tem acesso, não criou componentes
		Return
	EndIf

	lOnlyView 				:= .F.
	oPlaca:lReadOnly		:= .F.
	oCodCli:lReadOnly		:= .F.
	oLojCli:lReadOnly		:= .F.
	oPrestador:lReadOnly	:= .F.
	oFindServ:lReadOnly		:= .F.
	oListServ:lReadOnly		:= .F.
	cTitleTela 				:= "INCLUIR"
	cNumVls					:= "INCLUINDO"
	cPlaca					:= Space(TamSX3("UIC_PLACA")[1])
	cCodCli					:= Space(TamSX3("A1_COD")[1])
	cLojCli					:= Space(TamSX3("A1_LOJA")[1])
	cNomCli					:= Space(TamSX3("A1_NOME")[1])
	cPrestador				:= Space(TamSX3("A2_COD")[1]) + Space(1) + Space(TamSX3("A2_LOJA")[1]) + Space(3) + Space(TamSX3("A2_NOME")[1])
	cTipoOper 				:= "R" //pre pago
	lCliHbPos    			:= .F.
	cFindServ				:= Space(TamSX3("B1_DESC")[1])
	aListServ				:= {''}
	oListServ:SetItems(aListServ)
	nVlrTot					:= 0
	cVendedor 				:= Space(TamSX3("UIC_VEND")[1])
	cNomVend 				:= ""
	cObserv					:= Space(200)
	aRecnoUIC 				:= {}

	SetTipoSel(cTipoOper)
	ClearGrid(oMsGetSrv)

	If !lNoBrowse // Flag para não limpar browse
		cBuscaVls	:= Space(TamSX3("UIC_AMB")[1]+TamSX3("UIC_CODIGO")[1])
		dBuscaDt	:= dDataBase
		cBuscaCod	:= Space(TamSX3("A1_COD")[1])
		cBuscaLoj	:= Space(TamSX3("A1_LOJA")[1])
		nQtdReg		:= 0
		ClearGrid(oMsGetVls)
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
	Endif

	if !lConfCash
		U_SetMsgRod("")

		If oPnlBrow:lVisible
			oBuscaVls:SetFocus()
		Else
			oPlaca:SetFocus()
		EndIf
	endif

Return

//---------------------------------------------------------------------
// Função para limpesa do grid
//---------------------------------------------------------------------
Static Function ClearGrid(oGrid)

	Local nX 			:= 0
	Local aFieldFill	:= {}

	oGrid:aCols := {}

	For nX := 1 to Len(oGrid:aHeader)

		If oGrid:aHeader[nX][2] == "LEGENDA"
			Aadd(aFieldFill, "BR_BRANCO")
		Else
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

	AAdd(aFieldFill, 0) // RECNO
	AAdd(aFieldFill, .F.)
	AAdd(oGrid:aCols, aFieldFill)

	oGrid:oBrowse:Refresh()

Return

//---------------------------------------------------------------------
// Confirmação da Inclusao
//---------------------------------------------------------------------
Static Function ConfInc()

	Local cMsgErr := ""
	Local lRet := .T.

	if lOnlyView
		if !lConfCash
			cTitleTela := "LISTAGEM"
			oPnlInc:Hide()
			oPnlBrow:Show()
		endif
		Return lRet
	endif

	AtuTotal()

	If Empty(cPlaca)
		cMsgErr := "Informe a placa do veículo!"
		lRet := .F.
	ElseIf Empty(cCodCli) .or. Empty(cLojCli)
		cMsgErr := "Informe o Código/Loja do cliente!"
		lRet := .F.
	ElseIf Empty(cNomCli)
		cMsgErr := "Cliente não encontrado na base! Verificar cadastro."
		lRet := .F.
	ElseIf nVlrTot <= 0
		cMsgErr := "Informe pelo menos um serviço!"
		lRet := .F.
	elseif empty(cVendedor)
		cMsgErr := "Informe o vendedor para realizar a operação!"
		lRet := .F.
	else
		if cTipoOper == "2" //pós pago
			SA1->(DbSetOrder(1)) //A1_FILIAL+A1_COD+A1_LOJA
			SA1->(DbSeek(xFilial("SA1")+cCodCli+cLojCli))
			If SA1->(FieldPos("A1_XCDVLSP")) > 0 .and. Empty(SA1->A1_XCDVLSP)
				cMsgErr := "Cliente não configurado corretamente para Vale Serviço Pós-Pago. Verifique o cadastro 'Cond.Vl.Serv.' (A1_XCDVLSP)."
				lRet := .F.
			ElseIf SA1->(FieldPos("A1_XCDVLSP")) > 0 .and. !SE4->(DbSeek(xFilial("SE4")+SA1->A1_XCDVLSP))
				cMsgErr := "Condição de Pagamento "+SA1->A1_XCDVLSP+" não cadastrada. Verifique o cadastro 'Cond.Vl.Serv.' (A1_XCDVLSP)."
				lRet := .F.
			endif
		endif
	EndIf

	//valido database com o date server
	if lRet .AND. !lConfCash .AND. dDataBase <> Date()
		cMsgErr := "A data do sistema esta diferente da data do sistema operacional. Favor efetuar o logoff do sistema."
		lRet := .F.
	endif

	If lRet
		CursorWait()
		if !lConfCash
			U_SetMsgRod("Aguarde, incluindo vale(s) serviço...")
		endif
		IncUIC()
		CursorArrow()
	else
		if lConfCash
			MsgInfo(cMsgErr, "Atenção")
		else
			U_SetMsgRod(cMsgErr)
		endif
	EndIf

Return lRet

//---------------------------------------------------------------------
// Gravaçao da inclusao da UIC
//---------------------------------------------------------------------
Static Function IncUIC()

	Local aArea := GetArea()
	Local aAreaSA6 := SA6->( GetArea() )
	Local cCodUIC	:= ""
	Local aStation
	Local cNumMov := iif(lConfCash,SLW->LW_NUMMOV,STDNumMov())
	Local aFor		:= IIF(!Empty(cPrestador),StrTokArr(SubStr(cPrestador,1,TamSX3("A2_COD")[1] + TamSX3("A2_LOJA")[1] + 1),"/"),{})
	Local nX
	Local nCont		:= 0

	//Informacoes da estacao
	if lConfCash
		aStation := {SLW->LW_OPERADO, SLW->LW_ESTACAO, SLW->LW_SERIE, SLW->LW_PDV, SLG->LG_SERNFIS}
	else
		aStation := STBInfoEst( 1, .T. ) // [1]-CAIXA [2]-ESTACAO [3]-SERIE [4]-PDV [5]-LG_SERNFIS
	endif

	SA1->(DbSetOrder(1)) // A1_FILIAL+A1_COD+A1_LOJA
	SA1->(DbSeek(xFilial("SA1")+cCodCli+cLojCli))

	For nX := 1 To Len(oMsGetSrv:aCols)

		If !oMsGetSrv:aCols[nX][NPOSDEL]

			cCodUIC := GetUICNum()

			If Empty(cCodUIC)
				Return
			EndIf

			Reclock("UIC",.T.)
			UIC->UIC_FILIAL	:= xFilial("UIC")
			UIC->UIC_AMB	:= cAmbiente
			UIC->UIC_CODIGO	:= cCodUIC
			UIC->UIC_TIPO	:= cTipoOper
			UIC->UIC_FORNEC	:= aFor[1]
			UIC->UIC_LOJAF	:= aFor[2]
			UIC->UIC_NOMEF	:= Posicione("UH8",1,xFilial("UH8")+aFor[1]+aFor[2],"UH8_NOME")
			UIC->UIC_CLIENT	:= SA1->A1_COD
			UIC->UIC_LOJAC	:= SA1->A1_LOJA
			UIC->UIC_NOMEC	:= SA1->A1_NOME
			UIC->UIC_PLACA	:= cPlaca
			UIC->UIC_PRODUT	:= oMsGetSrv:aCols[nX][NPOSSRV]
			UIC->UIC_DESCRI	:= oMsGetSrv:aCols[nX][NPOSDES]
			UIC->UIC_PRCPRO	:= oMsGetSrv:aCols[nX][NPOSTOT]
			UIC->UIC_DATA	:= dDataBase
			if lConfCash
				UIC->UIC_HORA	:= SLW->LW_HRABERT
				UIC->UIC_PROCBX := "C" //conferencia
			else
				UIC->UIC_HORA	:= Time()
			endif
			UIC->UIC_PDV	:= aStation[4]
			UIC->UIC_OPERAD	:= aStation[1]
			UIC->UIC_NUMMOV := cNumMov
			UIC->UIC_ESTACA := aStation[2]
			UIC->UIC_VEND	:= cVendedor
			UIC->UIC_PROCES := '2' //flag de pendente gerar financeiro
			if cTipoOper == "R" //se pre paga
				UIC->UIC_BANCO 	:= aStation[1]
				UIC->UIC_AG 	:= Posicione("SA6",1,xFilial("SA6")+aStation[1],"A6_AGENCIA")
				UIC->UIC_CONTA 	:= Posicione("SA6",1,xFilial("SA6")+aStation[1],"A6_NUMCON")
			endif
			UIC->UIC_STATUS :="A" //Ativo
			if UIC->(FieldPos("UIC_OBS")) > 0
				UIC->UIC_OBS := cObserv
			endif
			UIC->(MsUnlock())

			aadd(aRecnoUIC, UIC->(Recno()) )

			if !lConfCash
				U_UREPLICA("UIC",1,UIC->UIC_FILIAL + UIC->UIC_AMB + UIC->UIC_CODIGO, "I")

				// Faz a impressão do cupom não fiscal
				ImpVls(.F.)
			endif

			nCont++
		EndIf
	Next nX

	if !lConfCash
		If nCont > 0
			// Limpa tela e mostra mensagem de sucesso!
			U_TPDVA6CL(.T.)
			U_SetMsgRod("Vale(s) serviço incluido com sucesso! Codigo: " + UIC->UIC_AMB + UIC->UIC_CODIGO )
		Else
			U_SetMsgRod("Nenhum serviço selecionado!")
		Endif
	endif

	RestArea( aAreaSA6 )
	RestArea( aArea )

Return

//---------------------------------------------------------------------
// Obtem o proximo numero da UIC
//---------------------------------------------------------------------
Static Function GetUICNum()

	Local cRet := ""

	cRet := U_TPGETNUM("UIC","UIC_CODIGO")

	//Enquanto encontrar o numero ja utilizado, soma um
	UIC->(DbSetOrder(1))
	While UIC->(DbSeek(xFilial("UIC")+cAmbiente+cRet))
		cRet := U_TPGETNUM("UIC","UIC_CODIGO")
	enddo

Return cRet

//---------------------------------------------------------------------
// Busca vale servico no brwose
//---------------------------------------------------------------------
Static Function BuscaVls()

	Local cCondicao		:= ""
	Local bCondicao
	Local nX
	Local aLinTemp 		:= {}

	If Empty(dBuscaDt)
		U_SetMsgRod("Informe uma data para a busca!")
		Return
	EndIf

	U_SetMsgRod("Buscando registros...")

	cCondicao := " UIC_FILIAL == '" + xFilial("UIC") + "'"
	cCondicao += " .AND. UIC_DATA == STOD('" + DTOS(dBuscaDt) + "')"
	if !Empty(cBuscaVls)
		cCondicao += " .AND. '" + AllTrim(cBuscaVls) + "' $ (UIC_AMB+UIC_CODIGO) "
	EndIf
	If !Empty(cBuscaCod)
		cCondicao += " .AND. UIC_CLIENT == '" + cBuscaCod + "'"
	EndIf
	If !Empty(cBuscaLoj)
		cCondicao += " .AND. UIC_LOJAC == '" + cBuscaLoj + "'"
	EndIf
	If !Empty(cBuscaPlaca)
		cCondicao += " .AND. UIC_PLACA == '" + cBuscaPlaca + "'"
	EndIf

	// Limpa os filtros da UIC
	UIC->(DbClearFilter())

	// Filtra na UIC
	bCondicao 	:= "{|| " + cCondicao + " }"
	UIC->(DbSetFilter(&bCondicao,cCondicao))

	UIC->(DbGoTop())

	oMsGetVls:aCols := {}

	While UIC->(!EOF())

		Posicione("SA1",1,xFilial("SA1")+UIC->UIC_CLIENT+UIC->UIC_LOJAC,"A1_COD")

		aLinTemp := {}

		For nX := 1 To Len(oMsGetVls:aHeader)
			if oMsGetVls:aHeader[nX][2] == "LEGENDA"
				Aadd(aLinTemp, iif(UIC->UIC_STATUS=="C","BR_PRETO","BR_VERDE") )
			else
				AAdd(aLinTemp,UIC->&(oMsGetVls:aHeader[nX][2]))
			endif
		Next nX

		AAdd(aLinTemp,UIC->(RecNo())) // RECNO
		AAdd(aLinTemp,.F.) // Deleted
		AAdd(oMsGetVls:aCols,aClone(aLinTemp))

		UIC->(DbSkip())
	EndDo

	// Limpa os filtros da UIC
	UIC->(DbClearFilter())

	nQtdReg := Len(oMsGetVls:acols)
	if nQtdReg == 0
		ClearGrid(oMsGetVls)
	endif

	oMsGetVls:oBrowse:Refresh()
	oQtdReg:Refresh()
	U_SetMsgRod("")
	oMsGetVls:oBrowse:SetFocus()

Return

//---------------------------------------------------------------------
// Visualizacao do vale servico
//---------------------------------------------------------------------
Static Function ViewVls()

	if !lConfCash
		If oMsGetVls:aCols[oMsGetVls:nAt][Len(oMsGetVls:aHeader)+1] > 0
			UIC->(DbGoTo(oMsGetVls:aCols[oMsGetVls:nAt][Len(oMsGetVls:aHeader)+1]))
		Else
			U_SetMsgRod("Busque e selecione o vale serviço a visualizar!")
			Return
		EndIf
	endif

	lOnlyView	:= .T.
	cTitleTela	:= "VISUALIZAR"
	cNumVls 	:= UIC->UIC_AMB + UIC->UIC_CODIGO
	cPlaca 		:= UIC->UIC_PLACA
	cCodCli		:= UIC->UIC_CLIENT
	cLojCli		:= UIC->UIC_LOJAC
	cNomCli 	:= SA1->A1_NOME
	cPrestador	:= UIC->UIC_FORNEC + "/" + UIC->UIC_LOJAF + " - " + UIC->UIC_NOMEF
	cTipoOper	:= UIC->UIC_TIPO
	cFindServ	:= Space(TamSX3("B1_DESC")[1])
	aListServ	:= {''}
	oListServ:SetItems(aListServ)
	nVlrTot 	:= 0
	cVendedor 	:= UIC->UIC_VEND
	cNomVend 	:= Posicione("SA3",1,xFilial("SA3")+cVendedor,"A3_NOME")
	if UIC->(FieldPos("UIC_OBS")) > 0
		cObserv		:= UIC->UIC_OBS
	endif

	oMsGetSrv:aCols := {}
	AAdd(oMsGetSrv:aCols,{UIC->UIC_PRODUTO,UIC->UIC_DESCRI,UIC->UIC_PRCPRO,0,UIC->UIC_PRCPRO,.F.})
	nVlrTot := UIC->UIC_PRCPRO

	oPlaca:lReadOnly		:= .T.
	oCodCli:lReadOnly		:= .T.
	oLojCli:lReadOnly		:= .T.
	oPrestador:lReadOnly	:= .T.
	oFindServ:lReadOnly		:= .T.
	oListServ:lReadOnly		:= .T.

	oNumVls:Refresh()
	oPlaca:Refresh()
	oCodCli:Refresh()
	oLojCli:Refresh()
	oNomCli:Refresh()
	oPrestador:Refresh()
	oFindServ:Refresh()
	oListServ:Refresh()
	oMsGetSrv:oBrowse:Refresh()
	oVlrTot:Refresh()
	SetTipoSel(cTipoOper)

	if !lConfCash
		oPnlInc:Show()
		oPlaca:SetFocus()
		oPnlBrow:Hide()
	endif

Return

//---------------------------------------------------------------------
// Estorno do Vale Servico
//---------------------------------------------------------------------
Static Function EstornaVls()

	Local cChvVls := ""
	Local aStation, nX
	Local cNumMov := STDNumMov()

	If oMsGetVls:aCols[oMsGetVls:nAt][Len(oMsGetVls:aHeader)+1] > 0

		UIC->(DbGoTo(oMsGetVls:aCols[oMsGetVls:nAt][Len(oMsGetVls:aHeader)+1]))

		if UIC->UIC_STATUS == "C"
			U_SetMsgRod("Vale Serviço já estornado!")
			Return
		endif

		//valido se é do mesmo caixa
		aStation := STBInfoEst( 1, .T. ) // [1]-CAIXA [2]-ESTACAO [3]-SERIE [4]-PDV [5]-LG_SERNFIS
		
		if !(UIC->UIC_DATA == dDataBase .AND. UIC->UIC_PDV == aStation[4] .AND. UIC->UIC_OPERAD == aStation[1] .AND. UIC->UIC_NUMMOV == cNumMov .AND. UIC->UIC_ESTACA == aStation[2])
			U_SetMsgRod("Vale Serviço não pertence a este caixa. Operação não permitida!")
			Return
		endif

		If MsgYesNo("Confirma estorno do vale servico?","Atencao")
			cChvVls := UIC->UIC_FILIAL + UIC->UIC_AMB + UIC->UIC_CODIGO
			CursorWait()

			For nX := 1 to 2 // duas vias
				If nX == 1
					cVia := "Via estabelecimento"
				ElseIf nX ==2
					cVia := "Via cliente"
				EndIf

				U_SetMsgRod("Aguarde, imprimindo vale serviço - " + cVia)
				_cMsg := ImpCupom(nX,"002",UIC->UIC_AMB+UIC->UIC_CODIGO)
				STWManagReportPrint(_cMsg,1/*nVias*/)
			Next nX

			Reclock("UIC",.F.)
				UIC->UIC_STATUS := "C" //cancelado
			UIC->(MsUnlock())

			CursorArrow()

			BuscaVls()

			U_UREPLICA("UIC",1,cChvVls,"A")

			U_SetMsgRod("Vale Serviço Estornado com sucesso!")
		EndIf
	Else
		U_SetMsgRod("Busque e selecione o vale serviço a excluir!")
	EndIf

Return

//---------------------------------------------------------------------
// Impressao do Vale Servico
//---------------------------------------------------------------------
Static Function ImpVls(lReimp)

	Local aArea    	:= GetArea()
	Local nLarg		:= 48 //considera o cupom de 40 posições
	Local _cMsg		:= ""
	Local nX 		:= 0

	If !IsInCallStack("STIPosMain")
		U_SetMsgRod("Falha na comunicação com a impressora!" )
		Return
	EndIf

	If lReimp
		If oMsGetVls:aCols[oMsGetVls:nAt][Len(oMsGetVls:aHeader)+1] > 0
			UIC->(DbGoTo(oMsGetVls:aCols[oMsGetVls:nAt][Len(oMsGetVls:aHeader)+1]))
		Else
			U_SetMsgRod("Busque e selecione o vale serviço a imprimir!")
			Return
		EndIf
	endif

	For nX := 1 to 3 // Três vias
		If nX == 1
			cVia := "Via estabelecimento"
		ElseIf nX ==2
			cVia := "Via cliente"
		Else
			cVia := "Via prestador serviço"
		EndIf

		CursorWait()
		U_SetMsgRod("Aguarde, imprimindo vale serviço - " + cVia)
		_cMsg := ImpCupom(nX,"001",UIC->UIC_AMB+UIC->UIC_CODIGO,lReimp,nLarg)
		STWManagReportPrint(_cMsg,1/*nVias*/)
		U_SetMsgRod("")
		CursorArrow()
	Next nX

	RestArea(aArea)

Return

//---------------------------------------------------------------------
// Impressao do cupom nao fiscal
//---------------------------------------------------------------------
Static Function ImpCupom(nOpc,cID,cCodVale,lReimp,nLarg)

	Local cRet		:= ""
	Local _aMsg		:= {""} // Mensagens do cupom
	Local cTxtTmp	:= ""
	Local nX

	Default lReimp	:= .F.
	Default nLarg	:= 48 // Largura do texto POS

	DbSelectArea("UIC")
	UIC->(DbSetOrder(1)) //UIC_FILIAL+UIC_AMB+UIC_CODIGO

	If UIC->(DbSeek(xFilial("UIC")+cCodVale))

		If lReimp
			cTxtTmp := "REIMPRESSAO "
			AAdd(_aMsg, Space((nLarg-Len(cTxtTmp))/2) + cTxtTmp)
		EndIf

		cTxtTmp := "***** VALE SERVICO *****"
		AAdd(_aMsg, Space((nLarg-Len(cTxtTmp))/2) + cTxtTmp)

		// Título
		Do Case
			Case cID == "001" //Inclusão de vale Pós-Pago
			cTxtTmp := ""
			Case cID == "002" //Exclusão do vale Pós-Pago
			cTxtTmp := "ESTORNO - "
			Case cID == "003" //Baixa de vale Pós e Pré Pago
			cTxtTmp := "BAIXA - "
			Case cID == "004" //Exclusão da baixa do vale Pós e Pré Pago
			cTxtTmp := "ESTORNO BAIXA - "
		EndCase

		// Tipo vale
		If UIC->UIC_TIPO == "R" // Se pré-pago
			cTxtTmp += "PRE-PAGO"
		Else
			cTxtTmp += "POS-PAGO"
		EndIf

		AAdd(_aMsg, Space((nLarg-Len(cTxtTmp))/2) + cTxtTmp)

		// Tipo da via
		If nOpc == 1
			cTxtTmp := "via  estabelecimento"
		ElseIf nOpc == 2
			cTxtTmp := "via  cliente"
		ElseIf nOpc == 3
			cTxtTmp := "via  prestador servico"
		Else
			cTxtTmp := ""
		EndIf

		If !Empty(cTxtTmp)
			AAdd(_aMsg, Space((nLarg-Len(cTxtTmp))/2) + cTxtTmp)
		EndIf

		AAdd(_aMsg, "") // Espaço

		AAdd(_aMsg, "DATA: " + DTOC(dDataBase) + " " + SubStr(Time(),1,5))
		if UH8->(FieldPos("UH8_CGC")) > 0 
			AAdd(_aMsg, "CNPJ: " + Posicione("UH8",1,xFilial("UH8")+UIC->UIC_FORNEC+UIC->UIC_LOJAF,"UH8_CGC")) // CNPJ
		else
			AAdd(_aMsg, "CNPJ: " + Posicione("SA2",1,xFilial("SA2")+UIC->UIC_FORNEC+UIC->UIC_LOJAF,"A2_CGC")) // CNPJ
		endif
		AAdd(_aMsg, "FORN: " + Alltrim(UIC->UIC_NOMEF)) // Razão

		AAdd(_aMsg, "") // Espaço

		AAdd(_aMsg, "NR VALE: " + UIC->UIC_AMB + UIC->UIC_CODIGO)
		AAdd(_aMsg, "CLIENTE: " + UIC->UIC_CLIENT+"/"+UIC->UIC_LOJAC)
		AAdd(_aMsg, "CPF/CNPJ:" + Posicione("SA1",1,xFilial("SA1")+UIC->UIC_CLIENT+UIC->UIC_LOJAC,"A1_CGC"))
		AAdd(_aMsg, "NOME: " + Alltrim(Posicione("SA1",1,xFilial("SA1")+UIC->UIC_CLIENT+UIC->UIC_LOJAC,"A1_NOME")))

		AAdd(_aMsg, "PLACA: " + Alltrim(Transform(UIC->UIC_PLACA,"@!R NNN-9N99")))
		If !Empty(UIC->UIC_MOTORI)
			AAdd(_aMsg, "MOTORISTA: " + Alltrim(Posicione("DA4",1,xFilial("DA4")+UIC->UIC_MOTORI,"DA4_NOME")))
		EndIf

		AAdd(_aMsg, "") // Espaço

		cTxtTmp := "PRODUTO/SERVICO "
		AAdd(_aMsg, Space((nLarg-Len(cTxtTmp))/2) + cTxtTmp)
		AAdd(_aMsg, Replicate("-",nLarg))
		AAdd(_aMsg, "COD..: " + Alltrim(UIC->UIC_PRODUT))
		AAdd(_aMsg, "DESCR: " + Alltrim(UIC->UIC_DESCRI))
		AAdd(_aMsg, "QUANT: 1,00")
		AAdd(_aMsg, "PRECO: R$" + Alltrim(Transform(UIC->UIC_PRCPRO, "@E 999,999,999.99")))

		If UIC->UIC_TIPO == "O" // Se pós-pago
			AAdd(_aMsg, "") // Espaço
			AAdd(_aMsg, "ASINATURA:")
			AAdd(_aMsg, "") // Espaço
			AAdd(_aMsg, Replicate("_",nLarg) )
		Endif

		if UIC->(FieldPos("UIC_OBS")) > 0 .And. !Empty(UIC->UIC_OBS)
			AAdd(_aMsg, "OBS: " + Alltrim(UIC->UIC_OBS))
		endif

		For nX:=1 to Len(_aMsg)
			cRet += _aMsg[nX] + CRLF
		Next nX
	EndIf

Return cRet

/*/{Protheus.doc} TPDVA6RI
Retorna array de recno dos Vale Serviços incluidos
@author TOTVS
@since 01/05/2019
@version 1.0
@return Nil
@type function
/*/
User Function TPDVA6RI
Return aRecnoUIC

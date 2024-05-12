#INCLUDE "TOTVS.CH"
#INCLUDE "stpos.ch"
#INCLUDE "poscss.ch"
#INCLUDE "FWMVCDEF.CH"

Static cUsrSaq := ""
Static oPnlGeral
Static oPnlInc
Static oPnlSqPre
Static oPnlSqPos
Static oPnlBrow
Static cTitleTela := ""
Static oCssCombo := "TComboBox { font: bold; font-size: 13px; text-align: right; color: #656565; background-color: #FFFFFF; border: 1px solid #9C9C9C; border-radius: 4px; padding: 4px; } TComboBox:focus{border: 2px solid #0080FF;} TComboBox:disabled {color:#656565; background-color: #EEEEEE;} TComboBox:drop-down {color:#000000; background-color: #FFFFFF; border-left: 0px; border-radius: 4px; background-image: url(rpo:fwskin_combobox_arrow.png);background-repeat: none;background-position: center;}"
Static oCodCli
Static cCodCli := Space(TamSX3("A1_COD")[1])
Static oLojCli
Static cLojCli := Space(TamSX3("A1_LOJA")[1])
Static oNomCli
Static cNomCli := Space(TamSX3("A1_NOME")[1])
Static oPlaca
Static cPlaca := Space(TamSX3("U57_PLACA")[1])
Static oVendedor
Static cVendedor := Space(TamSX3("U57_VEND")[1])
Static oNomVend
Static cNomVend := Space(TamSX3("A3_NOME")[1])
Static oBtnTpPos, oBtnTpPre
Static nTipoOper := 2 //2-PÓS-PAGO;1-PRÉ-PAGO"
Static oCgcMot
Static cCgcMot := Space(TamSX3("U57_MOTORI")[1])
Static oNomMot
Static cNomMot := Space(TamSX3("DA4_NOME")[1])
Static oMotivo
Static cMotivo := Space(TamSX3("U57_MOTIVO")[1])
Static aMotivo
Static oGetCod
Static cGetCod := Space(40)
Static lRetOn := .F.
Static oSayConn
Static cSayConn := "Retaguarda OFF-LINE"
Static oSemaforo := Nil 	//Objeto semaforo de conexao com retaguarda
Static oRequisit
Static cRequisit := Space(TamSX3("U56_REQUIS")[1])
Static oCargo
Static cCargo := Space(TamSX3("U56_CARGO")[1])
Static oValorSq
Static nValorSq := 0
Static oBuscaSaq
Static cBuscaSaq := Space(TamSX3("U57_PREFIX")[1]+TamSX3("U57_CODIGO")[1]+TamSX3("U57_PARCEL")[1])
Static oBuscaDt
Static dBuscaDt := dDataBase
Static oBuscaCod
Static cBuscaCod := Space(TamSX3("A1_COD")[1])
Static oBuscaLoj
Static cBuscaLoj := Space(TamSX3("A1_LOJA")[1])
Static oBuscaPlaca
Static cBuscaPlaca := Space(TamSX3("U57_PLACA")[1])
Static oMsGetSaq
Static oQtdReg
Static nQtdReg := 0
Static oVlrSqPre
Static nVlrSqPre := 0
Static aNCCsReq	:= Nil //Array com todas as NCCs do cliente
Static oListGdNcc := Nil //Objeto TListBox dos creditos do cliente
Static lConfCash := .F.
Static oBtn1 := Nil //Botão confirmar
Static aLogAlcada := {}

/*/{Protheus.doc} TPDVA007
Tela para Saque/Vale Motorista no PDV

@author thebr
@since 12/05/2019
@version 1.0
@return Nil
@type function
/*/
user function TPDVA007(oPnlPrinc, _lConfCash, bConfirm, bCancel)

	Local oPnlAlternate
	Local nWidth, nHeight
	Local cCorBg := SuperGetMv( "MV_LJCOLOR",,"07334C")// Cor da tela
	Local lMvPswVend := SuperGetMv("TP_PSWVEND",,.F.)
	Local lBlqAI0 	:= SuperGetMv("MV_XBLQAI0",,.F.) .AND. AI0->(FieldPos("AI0_XBLFIL")) > 0 //Habilita bloqueio de venda na filial, olhando para tabela AI0
	Local cFiltro	:= ""
	Default _lConfCash := .F.

	DbSelectArea("U56")
	DbSelectArea("U57")

	nWidth  := oPnlPrinc:nWidth/2
	nHeight := oPnlPrinc:nHeight/2
	lConfCash := _lConfCash

	//-- controle de acesso SAQUE NO PDV
	If !lConfCash
		U_TRETA37B("SAQPDV", "SAQUE NO PDV")
		cUsrSaq := U_VLACESS1("SAQPDV", RetCodUsr())
		If cUsrSaq == Nil .OR. Empty(cUsrSaq)
			@ 020, 020 SAY oSay1 PROMPT "<h1>Ops!</h1><br>Seu usuário não tem permissão de acesso a rotina de Compensação. Entre em contato com o administrador do sistema." SIZE nWidth-40, 100 OF oPnlPrinc COLORS 0, 16777215 PIXEL HTML
			oSay1:SetCSS( POSCSS (GetClassName(oSay1), CSS_LABEL_FOCAL ))
			Return cUsrSaq
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
		Else
			SA3->(DbSetOrder(1))
			If SA3->(DbSeek(xFilial("SA3") + GetMV("MV_VENDPAD") ))
				cVendedor := SA3->A3_COD
				cNomVend  := SA3->A3_NOME
			EndIf
		EndIf
	Endif

	//painel geral da tela de saque (mesmo tamanho da principal)
	oPnlGeral := TPanel():New(000,000,"",oPnlPrinc,NIL,.T.,.F.,,,nWidth,nHeight,.T.,.F.)

	cTitleTela := "SACAR"
	@ 002, 002 SAY oSay1 PROMPT ("SAQUE / VALE MOTORISTA - " + cTitleTela) SIZE nWidth-004, 015 OF oPnlGeral COLORS 0, 16777215 PIXEL CENTER
	oSay1:SetCSS( POSCSS (GetClassName(oSay1), CSS_BTN_FOCAL ))

	//////////////////////// PAINEL INCLUSÃO DE SAQUE //////////////////////////////////////

	//Painel de Inclusão de Saque
	oPnlInc := TPanel():New(020,000,"",oPnlGeral,NIL,.T.,.F.,,,nWidth,nHeight-020,,.T.,.F.)

	@ 005, 005 SAY oSay5 PROMPT "Placa" SIZE 100, 010 OF oPnlInc COLORS 0, 16777215 PIXEL
	oSay5:SetCSS( POSCSS (GetClassName(oSay5), CSS_LABEL_FOCAL ))
	oPlaca := TGet():New( 015, 005,{|u| iif( PCount()==0,cPlaca,cPlaca:=u) },oPnlInc,70, 013,"@!R NNN-9N99",{|| VldPlaca() },,,,,,.T.,,,{|| .T. },,,,.F.,.F.,,"oPlaca",,,,.T.,.F.)
	oPlaca:SetCSS( POSCSS (GetClassName(oPlaca), CSS_GET_NORMAL ))

	//@ 005, 080 SAY oSay3 PROMPT "CPF/CNPJ do Cliente" SIZE 100, 010 OF oPnlInc COLORS 0, 16777215 PIXEL
	//oSay3:SetCSS( POSCSS (GetClassName(oSay3), CSS_LABEL_FOCAL ))
	//oCgcCli := TGet():New( 015, 080,{|u| iif( PCount()==0,cCgcCli,cCgcCli:=u) },oPnlInc,80, 013, "@!",{|| VldCliente() },,,,,,.T.,,,{|| .T. },,,,.F.,.F.,,"oCgcCli",,,,.T.,.F.)
	//oCgcCli:SetCSS( POSCSS (GetClassName(oCgcCli), CSS_GET_NORMAL ))
	//TSearchF3():New(oCgcCli,400,250,"SA1","A1_CGC",{{"A1_NOME",2},{"A1_CGC",3},{"A1_COD",1}},"SA1->A1_MSBLQL<>'1'",{{"A1_NOME","A1_EST","A1_MUN"},{"A1_CGC","A1_NOME","A1_EST","A1_MUN"},{"A1_COD","A1_LOJA","A1_NOME","A1_EST","A1_MUN"}},,,iif(lConfCash,-40,0))

	@ 005, 080 SAY oSay3 PROMPT "Código" SIZE 100, 010 OF oPnlInc COLORS 0, 16777215 PIXEL
	oSay3:SetCSS( POSCSS (GetClassName(oSay3), CSS_LABEL_FOCAL ))
	oCodCli := TGet():New( 015, 080,{|u| iif( PCount()==0,cCodCli,cCodCli:=u) },oPnlInc, 055, 013, "@!",{|| VldCliente() },,,,,,.T.,,,{|| .T. },,,,.F.,.F.,,"oCodCli",,,,.T.,.F.)
	oCodCli:SetCSS( POSCSS (GetClassName(oCodCli), CSS_GET_NORMAL ))

	@ 005, 135 SAY oSay3 PROMPT "Loja" SIZE 100, 010 OF oPnlInc COLORS 0, 16777215 PIXEL
	oSay3:SetCSS( POSCSS (GetClassName(oSay3), CSS_LABEL_FOCAL ))
	oLojCli := TGet():New( 015, 135,{|u| iif( PCount()==0,cLojCli,cLojCli:=u) },oPnlInc, 020, 013, "@!",{|| VldCliente() },,,,,,.T.,,,{|| .T. },,,,.F.,.F.,,"oLojCli",,,,.T.,.F.)
	oLojCli:SetCSS( POSCSS (GetClassName(oLojCli), CSS_GET_NORMAL ))
	
	@ 005, 165 SAY oSay4 PROMPT "Nome Cliente" SIZE 070, 010 OF oPnlInc COLORS 0, 16777215 PIXEL
	oSay4:SetCSS( POSCSS (GetClassName(oSay4), CSS_LABEL_FOCAL ))
	oNomCli := TGet():New( 015, 165,{|u| iif( PCount()==0,cNomCli,cNomCli:=u)},oPnlInc,nWidth-175, 013, "@!",{|| .T. },,,,,,.T.,,,{|| .T. },,,,.T.,.F.,,"oNomCli",,,,.T.,.F.)
	oNomCli:SetCSS( POSCSS (GetClassName(oNomCli), CSS_GET_NORMAL ))
	oNomCli:lCanGotFocus := .F.

	// bloqueio de filiais
	if lBlqAI0
		cFiltro := " .AND. Posicione('AI0',1,xFilial('AI0')+SA1->A1_COD+SA1->A1_LOJA,'AI0_XBLFIL')!='S'"
	elseIf SA1->(FieldPos("A1_XFILBLQ")) > 0 
		cFiltro := " .AND. (Empty(SA1->A1_XFILBLQ) .OR. !(cFilAnt $ SA1->A1_XFILBLQ))"
	EndIf
	TSearchF3():New(oCodCli,400,250,"SA1","A1_COD",{{"A1_NOME",2},{"A1_CGC",3},{"A1_COD",1}},"SA1->A1_MSBLQL<>'1'"+cFiltro,{{"A1_COD","A1_LOJA","A1_NOME","A1_EST","A1_MUN"},{"A1_COD","A1_LOJA","A1_CGC","A1_NOME","A1_EST","A1_MUN"},{"A1_COD","A1_LOJA","A1_NOME","A1_EST","A1_MUN"}},,,iif(lConfCash,-40,0)/*nAjustPos*/,,{{oLojCli,"A1_LOJA"},{oNomCli,"A1_NOME"}})

	@ 035, 005 SAY oSay3 PROMPT "CPF do Motorista" SIZE 100, 010 OF oPnlInc COLORS 0, 16777215 PIXEL
	oSay3:SetCSS( POSCSS (GetClassName(oSay3), CSS_LABEL_FOCAL ))
	oCgcMot := TGet():New( 045, 005,{|u| iif( PCount()==0,cCgcMot,cCgcMot:=u) },oPnlInc,70, 013,,{|| (Empty(cCgcMot) .OR. CGC(cCgcMot)) .AND. VldMotoris() },,,,,,.T.,,,{|| .T. },,,,.F.,.F.,,"oCgcMot",,,,.T.,.F.)
	oCgcMot:SetCSS( POSCSS (GetClassName(oCgcMot), CSS_GET_NORMAL ))
	TSearchF3():New(oCgcMot,400,250,"DA4","DA4_CGC",{{"DA4_NOME",2}},,{{"DA4_CGC","DA4_NOME"}},,,iif(lConfCash,-40,0))

	@ 035, 080 SAY oSay4 PROMPT "Nome Motorista" SIZE 070, 010 OF oPnlInc COLORS 0, 16777215 PIXEL
	oSay4:SetCSS( POSCSS (GetClassName(oSay4), CSS_LABEL_FOCAL ))
	oNomMot := TGet():New( 045, 080,{|u| iif( PCount()==0,cNomMot,cNomMot:=u)},oPnlInc,nWidth-200, 013, "@!",{|| .T./*bValid*/ },,,,,,.T.,,,{|| .T. },,,,.F.,.F.,,"oNomMot",,,,.T.,.F.)
	oNomMot:SetCSS( POSCSS (GetClassName(oNomMot), CSS_GET_NORMAL ))

	@ 035, nWidth-110 SAY oSay4 PROMPT "Tipo Saque" SIZE 070, 010 OF oPnlInc COLORS 0, 16777215 PIXEL
	oSay4:SetCSS( POSCSS (GetClassName(oSay4), CSS_LABEL_FOCAL ))
	oBtnTpPos := TButton():New(045,nWidth-110,"PÓS-PAGO", oPnlInc,{|| nTipoOper:=2, SetTipoSel(nTipoOper) },050,015,,,,.T.,,,,{|| .T. })
	oBtnTpPre := TButton():New(045,nWidth-060,"PRÉ-PAGO", oPnlInc,{|| nTipoOper:=1, SetTipoSel(nTipoOper) },050,015,,,,.T.,,,,{|| .T. })

	@ 065, 005 SAY oSay3 PROMPT "Vendedor" SIZE 100, 010 OF oPnlInc COLORS 0, 16777215 PIXEL
	oSay3:SetCSS( POSCSS (GetClassName(oSay3), CSS_LABEL_FOCAL ))
	oVendedor := TGet():New( 075, 005,{|u| iif( PCount()==0,cVendedor,cVendedor:=u) },oPnlInc,70, 013,,{|| VldVend() },,,,,,.T.,,,{|| .T. },,,,!lConfCash .AND. lMvPswVend,.F.,,"oVendedor",,,,.T.,.F.)
	oVendedor:SetCSS( POSCSS (GetClassName(oVendedor), CSS_GET_NORMAL ))
	if !lMvPswVend
		TSearchF3():New(oVendedor,400,180,"SA3","A3_COD",{{"A3_NOME",2}},"",,,,iif(lConfCash,-40,0))
	endif

	@ 065, 080 SAY oSay4 PROMPT "Nome Vendedor" SIZE 100, 010 OF oPnlInc COLORS 0, 16777215 PIXEL
	oSay4:SetCSS( POSCSS (GetClassName(oSay4), CSS_LABEL_FOCAL ))
	oNomVend := TGet():New( 075, 080,{|u| iif( PCount()==0,cNomVend,cNomVend:=u)},oPnlInc,nWidth-200, 013, "@!",{|| .T./*bValid*/ },,,,,,.T.,,,{|| .T. },,,,.T.,.F.,,"oNomVend",,,,.T.,.F.)
	oNomVend:SetCSS( POSCSS (GetClassName(oNomVend), CSS_GET_NORMAL ))
	oNomVend:lCanGotFocus := .F.

	@ 095, 005 SAY oSay3 PROMPT "Motivo Saque" SIZE 100, 010 OF oPnlInc COLORS 0, 16777215 PIXEL
	oSay3:SetCSS( POSCSS (GetClassName(oSay3), CSS_LABEL_FOCAL ))
	aMotivo := LoadMotivos()
	oMotivo := TComboBox():New(105, 005, {|u| If(PCount()>0,cMotivo:=u,cMotivo)}, aMotivo , nWidth-125, 016, oPnlInc, Nil,{|| /*bChange*/ },/*bValid*/,,,.T.,,Nil,Nil,{|| .T. } )
	oMotivo:SetCSS( oCssCombo)

	//// PAINEL ALTERNATIVO - PRE OU POS ////
	@ 125, 005 MSPANEL oPnlAlternate SIZE nWidth-016, nHeight-180 OF oPnlInc

	//// PAINEL - PRE PAGO ////
	@ 000, 000 MSPANEL oPnlSqPre SIZE 100, 100 OF oPnlAlternate
	oPnlSqPre:Align := CONTROL_ALIGN_ALLCLIENT
	oPnlSqPre:SetCSS( "TPanel{border: 1px solid #999999;}" )

	@ 005, 005 SAY oSay2 PROMPT "Cód. Barras / Núm. Título" SIZE 300, 010 OF oPnlSqPre COLORS 0, 16777215 PIXEL
	oSay2:SetCSS( POSCSS (GetClassName(oSay2), CSS_LABEL_FOCAL ))
	oGetCod := TGet():New(015, 005, {|u| iif( PCount()==0, cGetCod, cGetCod:=u)}, oPnlSqPre, nWidth-130, 013, "@!",{|| FindCredCl()},,,,,,.T.,,,{|| .T.},,,,.F.,.F.,,"oGetCod",,,,.F.,.T.)
	oGetCod:SetCSS( POSCSS (GetClassName(oGetCod), CSS_GET_NORMAL ))

	@ 007, nWidth-115 BITMAP oSemaforo RESOURCE "FRTOFFLINE" NOBORDER SIZE 016, 016 OF oPnlSqPre ADJUST PIXEL
	oSemaforo:ReadClientCoors(.T.,.T.)
	@ 010, nWidth-092 SAY oSayConn PROMPT cSayConn OF oPnlSqPre Color CLR_BLACK PIXEL
	oSayConn:SetCSS( POSCSS (GetClassName(oSayConn), CSS_LABEL_FOCAL ))
	If lConfCash
		oSemaforo:Hide()
		oSayConn:Hide()
	EndIf

	oListGdNcc := TListBox():Create(oPnlSqPre, 040, 005, Nil, {''}, nWidth-130, nHeight-230,,,,,.T.,,/*{|| LoadSelNeg(cForma) }*/)
	oListGdNcc:bSetGet := {|u| iif(PCount()>0, LoadSelNcc(), ) } //bloco de código que será executado na mudança do item selecionado
	oListGdNcc:bLDBLClick := {|| LoadSelNcc(), oBtn1:SetFocus()} //bloco de código que será executado quando clicar duas vezes, com o botão esquerdo do mouse, sobre o objeto
	oListGdNcc:SetCSS( POSCSS (GetClassName(oListGdNcc), CSS_LISTBOX ))

	@ 035, nWidth-115 SAY oSay4 PROMPT "Valor do Crédito" SIZE 070, 010 OF oPnlSqPre COLORS 0, 16777215 PIXEL
	oSay4:SetCSS( POSCSS (GetClassName(oSay4), CSS_LABEL_FOCAL ))
	oVlrSqPre := TGet():New( 045, nWidth-115,{|u| iif(PCount()>0,nVlrSqPre:=u,nVlrSqPre)}, oPnlSqPre, 085, 013, PesqPict("SL4","L4_VALOR"),{|| .T. },,,,,,.T.,,,{|| .T. },,,,.T.,.F.,,"oVlrSqPre",,,,.F.,.T.)
	oVlrSqPre:SetCSS( POSCSS (GetClassName(oVlrSqPre), CSS_GET_NORMAL ))
	oVlrSqPre:lCanGotFocus := .F.

	//// PAINEL - POS PAGO ////
	@ 000, 000 MSPANEL oPnlSqPos SIZE 100, 100 OF oPnlAlternate
	oPnlSqPos:Align := CONTROL_ALIGN_ALLCLIENT
	oPnlSqPos:SetCSS( "TPanel{border: 1px solid #999999;}" )

	@ 005, 005 SAY oSay4 PROMPT "Requisitante" SIZE 070, 010 OF oPnlSqPos COLORS 0, 16777215 PIXEL
	oSay4:SetCSS( POSCSS (GetClassName(oSay4), CSS_LABEL_FOCAL ))
	oRequisit := TGet():New( 015, 005,{|u| iif( PCount()==0,cRequisit,cRequisit:=u)}, oPnlSqPos, nWidth-130, 013, PesqPict("U56","U56_REQUIS"),{|| .T./*bValid*/ },,,,,,.T.,,,{|| .T. },,,,.F.,.F.,,"oRequisit",,,,.T.,.F.)
	oRequisit:SetCSS( POSCSS (GetClassName(oRequisit), CSS_GET_NORMAL ))

	@ 035, 005 SAY oSay4 PROMPT "Cargo" SIZE 070, 010 OF oPnlSqPos COLORS 0, 16777215 PIXEL
	oSay4:SetCSS( POSCSS (GetClassName(oSay4), CSS_LABEL_FOCAL ))
	oCargo := TGet():New( 045, 005,{|u| iif( PCount()==0,cCargo,cCargo:=u)}, oPnlSqPos, nWidth-130, 013, PesqPict("U56","U56_CARGO"),{|| .T./*bValid*/ },,,,,,.T.,,,{|| .T. },,,,.F.,.F.,,"oCargo",,,,.T.,.F.)
	oCargo:SetCSS( POSCSS (GetClassName(oCargo), CSS_GET_NORMAL ))

	@ 065, 005 SAY oSay4 PROMPT "Valor do Saque" SIZE 070, 010 OF oPnlSqPos COLORS 0, 16777215 PIXEL
	oSay4:SetCSS( POSCSS (GetClassName(oSay4), CSS_LABEL_FOCAL ))
	oValorSq := TGet():New( 075, 005,{|u| iif(PCount()>0,nValorSq:=u,nValorSq)}, oPnlSqPos, 085, 013, PesqPict("SL4","L4_VALOR"),{|| .T. },,,,,,.T.,,,{|| .T. },,,,.F.,.F.,,"oValorSq",,,,.T.,.F.)
	oValorSq:SetCSS( POSCSS (GetClassName(oValorSq), CSS_GET_NORMAL ))

	nTipoOper:=2
	SetTipoSel(nTipoOper) //configuro operacao inicial na tela

	oBtn1 := TButton():New( nHeight-45,nWidth-75,"Confirmar",oPnlInc,{|| iif(VldIncSaq(.T.),iif(bConfirm<>Nil,Eval(bConfirm),),) },070,020,,,,.T.,,,,{|| .T.})
	oBtn1:SetCSS( POSCSS (GetClassName(oBtn1), CSS_BTN_FOCAL ))

	If lConfCash
		oBtn2 := TButton():New( nHeight-45,nWidth-150,"Cancelar",oPnlInc,bCancel,070,020,,,,.T.,,,,{|| .T.})
		oBtn2:SetCSS( POSCSS (GetClassName(oBtn2), CSS_BTN_NORMAL ))
	Else

		oBtn2 := TButton():New( nHeight-45,nWidth-150,"Limpar Tela",oPnlInc,{|| U_TPDVA7CL(.T.) },070,020,,,,.T.,,,,{|| .T.})
		oBtn2:SetCSS( POSCSS (GetClassName(oBtn2), CSS_BTN_NORMAL ))

		oBtn4 := TButton():New( nHeight-45,005,"Listar Saques",oPnlInc,{|| cTitleTela := "LISTAGEM", oPnlInc:Hide(), oPnlBrow:Show() },080,020,,,,.T.,,,,{|| .T.})
		oBtn4:SetCSS( POSCSS (GetClassName(oBtn4), CSS_BTN_NORMAL ))

		//////////////////////// BROWSE DOS SAQUES //////////////////////////////////////

		//Painel de Browse dos Saques
		oPnlBrow := TPanel():New(020,000,"",oPnlGeral,NIL,.T.,.F.,,,nWidth,nHeight-020,,.T.,.F.)
		oPnlBrow:Hide()

		@ 005, 005 SAY oSay12 PROMPT "Saque" SIZE 100, 010 OF oPnlBrow COLORS 0, 16777215 PIXEL
		oSay12:SetCSS( POSCSS (GetClassName(oSay12), CSS_LABEL_FOCAL ))
		oBuscaSaq := TGet():New( 015, 005,{|u| iif( PCount()==0,cBuscaSaq,cBuscaSaq:=u) },oPnlBrow, 070, 013,,{|| /*bValid*/ },,,,,,.T.,,,{|| .T. },,,,.F.,.F.,,"oBuscaSaq",,,,.T.,.F.)
		oBuscaSaq:SetCSS( POSCSS (GetClassName(oBuscaSaq), CSS_GET_NORMAL ))

		//@ 005, 080 SAY oSay12 PROMPT "CPF/CNPJ Cliente" SIZE 100, 010 OF oPnlBrow COLORS 0, 16777215 PIXEL
		//oSay12:SetCSS( POSCSS (GetClassName(oSay12), CSS_LABEL_FOCAL ))
		//oBuscaCpf := TGet():New( 015, 080,{|u| iif( PCount()==0,cBuscaCpf,cBuscaCpf:=u) },oPnlBrow, 080, 013,,{|| /*bValid*/ },,,,,,.T.,,,{|| .T. },,,,.F.,.F.,,"cBuscaCpf",,,,.T.,.F.)
		//oBuscaCpf:SetCSS( POSCSS (GetClassName(oBuscaCpf), CSS_GET_NORMAL ))
		//TSearchF3():New(oBuscaCpf,400,250,"SA1","A1_CGC",{{"A1_NOME",2},{"A1_CGC",3},{"A1_COD",1}},"SA1->A1_MSBLQL<>'1'",{{"A1_NOME","A1_EST","A1_MUN"},{"A1_CGC","A1_NOME","A1_EST","A1_MUN"},{"A1_COD","A1_LOJA","A1_NOME","A1_EST","A1_MUN"}},,,0)

		@ 005, 080 SAY oSay12 PROMPT "Código" SIZE 100, 010 OF oPnlBrow COLORS 0, 16777215 PIXEL
		oSay12:SetCSS( POSCSS (GetClassName(oSay12), CSS_LABEL_FOCAL ))
		oBuscaCod := TGet():New( 015, 080,{|u| iif( PCount()==0,cBuscaCod,cBuscaCod:=u) },oPnlBrow, 055, 013, "@!",{|| /*bValid*/ },,,,,,.T.,,,{|| .T. },,,,.F.,.F.,,"oBuscaCod",,,,.T.,.F.)
		oBuscaCod:SetCSS( POSCSS (GetClassName(oBuscaCod), CSS_GET_NORMAL ))

		@ 005, 135 SAY oSay12 PROMPT "Loja" SIZE 100, 010 OF oPnlBrow COLORS 0, 16777215 PIXEL
		oSay12:SetCSS( POSCSS (GetClassName(oSay12), CSS_LABEL_FOCAL ))
		oBuscaLoj := TGet():New( 015, 135,{|u| iif( PCount()==0,cBuscaLoj,cBuscaLoj:=u) },oPnlBrow, 020, 013, "@!",{|| /*bValid*/ },,,,,,.T.,,,{|| .T. },,,,.F.,.F.,,"oBuscaLoj",,,,.T.,.F.)
		oBuscaLoj:SetCSS( POSCSS (GetClassName(oBuscaLoj), CSS_GET_NORMAL ))
		TSearchF3():New(oBuscaCod,400,250,"SA1","A1_COD",{{"A1_NOME",2},{"A1_CGC",3},{"A1_COD",1}},"SA1->A1_MSBLQL<>'1'",{{"A1_COD","A1_LOJA","A1_NOME","A1_EST","A1_MUN"},{"A1_COD","A1_LOJA","A1_CGC","A1_NOME","A1_EST","A1_MUN"},{"A1_COD","A1_LOJA","A1_NOME","A1_EST","A1_MUN"}},,,iif(lConfCash,-40,0)/*nAjustPos*/,,{{oBuscaLoj,"A1_LOJA"}})

		@ 005, 165 SAY oSay5 PROMPT "Placa" SIZE 100, 010 OF oPnlBrow COLORS 0, 16777215 PIXEL
		oSay5:SetCSS( POSCSS (GetClassName(oSay5), CSS_LABEL_FOCAL ))
		oBuscaPlaca := TGet():New( 015, 165,{|u| iif( PCount()==0,cBuscaPlaca,cBuscaPlaca:=u) },oPnlBrow,50, 013,"@!R NNN-9N99",{|| /*bValid*/ },,,,,,.T.,,,{|| .T. },,,,.F.,.F.,,"cBuscaPlaca",,,,.T.,.F.)
		oBuscaPlaca:SetCSS( POSCSS (GetClassName(oBuscaPlaca), CSS_GET_NORMAL ))

		@ 005, 220 SAY oSay13 PROMPT "Data" SIZE 035, 008 OF oPnlBrow COLORS 0, 16777215 PIXEL
		oSay13:SetCSS( POSCSS (GetClassName(oSay13), CSS_LABEL_FOCAL ))
		@ 015, 220 MSGET oBuscaDt VAR dBuscaDt SIZE 070, 013 OF oPnlBrow VALID .T. PICTURE "@!" COLORS 0, 16777215 /*FONT oFntGetCab*/ HASBUTTON PIXEL
		oBuscaDt:SetCSS( POSCSS (GetClassName(oBuscaDt), CSS_GET_NORMAL ))

		oBtn5 := TButton():New( 015, 295,"Buscar",oPnlBrow,{|| BuscaSaq() },040,015,,,,.T.,,,,{|| .T.})
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

		oMsGetSaq := MsNewGetEst(oPnlAux2, 053, 090, 150, nWidth-5)
		oMsGetSaq:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT
		oMsGetSaq:oBrowse:SetCSS( StrTran(POSCSS("TGRID", CSS_BROWSE),"gridline-color: white;","") ) //CSS do totvs pdv
		//oMsGetSaq:oBrowse:lCanGotFocus := .F.
		oMsGetSaq:oBrowse:nScrollType := 0
		oMsGetSaq:oBrowse:lHScroll := .F.

		@ (oPnlGrid2:nHeight/2)-22, 010 SAY oQtdReg PROMPT (cValToChar(nQtdReg)+" registros encontrados.") SIZE 150, 010 OF oPnlGrid2 COLORS 0, 16777215 PIXEL
		oQtdReg:SetCSS( POSCSS (GetClassName(oQtdReg), CSS_LABEL_NORMAL))
		@ (oPnlGrid2:nHeight/2)-21, nWidth-090 BITMAP oLeg ResName "BR_VERDE" OF oPnlGrid2 Size 10, 10 NoBorder When .F. PIXEL
		@ (oPnlGrid2:nHeight/2)-22, nWidth-080 SAY oSay14 PROMPT "Ativo" OF oPnlGrid2 Color CLR_BLACK PIXEL
		oSay14:SetCSS( POSCSS (GetClassName(oSay14), CSS_LABEL_NORMAL))
		@ (oPnlGrid2:nHeight/2)-21, nWidth-055 BITMAP oLeg ResName "BR_PRETO" OF oPnlGrid2 Size 10, 10 NoBorder When .F. PIXEL
		@ (oPnlGrid2:nHeight/2)-22, nWidth-045 SAY oSay14 PROMPT "Estornado" OF oPnlGrid2 Color CLR_BLACK PIXEL
		oSay14:SetCSS( POSCSS (GetClassName(oSay14), CSS_LABEL_NORMAL))

		oBtn6 := TButton():New( nHeight-45,005,"Novo Saque",oPnlBrow,{|| oPnlInc:Show(), oPlaca:SetFocus(), oPnlBrow:Hide(), U_TPDVA7CL(.T.) },060,020,,,,.T.,,,,{|| .T.})
		oBtn6:SetCSS( POSCSS (GetClassName(oBtn6), CSS_BTN_FOCAL ))

		oBtn7 := TButton():New( nHeight-45,070,"Estornar",oPnlBrow,{|| DoEstorno() },060,020,,,,.T.,,,,{|| .T.})
		oBtn7:SetCSS( POSCSS (GetClassName(oBtn7), CSS_BTN_NORMAL ))

		oBtn8 := TButton():New( nHeight-45,135,"Imprimir",oPnlBrow,{|| ImpSaque() },060,020,,,,.T.,,,,{|| .T.})
		oBtn8:SetCSS( POSCSS (GetClassName(oBtn8), CSS_BTN_NORMAL ))
	EndIf

	oPlaca:SetFocus()

	AtuConnRet()

	If lConfCash
		U_TPDVA7CL(.T.)
	EndIf

return cUsrSaq

//----------------------------------------------------------
// Valida placa e faz gatilho quando ha amarracao com cliente
//----------------------------------------------------------
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

				If !Empty(DA3->DA3_XCODCL) .AND. !Empty(Posicione("SA1",1,xFilial("SA1")+DA3->DA3_XCODCL+DA3->DA3_XLOJCL,"A1_COD"))
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

				If !Empty(DA3->DA3_MOTORI)
					cCgcMot := PadR(Posicione("DA4",1,xFilial("DA4")+DA3->DA3_MOTORI,"DA4_CGC"),TamSx3("U57_MOTORI")[1])
					cNomMot := Posicione("DA4",1,xFilial("DA4")+DA3->DA3_MOTORI,"DA4_NOME")
					If !Empty(cNomMot)
						oNomMot:lReadonly := .T.
					EndIf
					oCgcMot:Refresh()
					oNomMot:Refresh()
				EndIf

			endif
		EndIf

	EndIf

Return lRet

//--------------------------------------------------------
// Validação e gatilho do cliente
//--------------------------------------------------------
Static Function VldCliente()

	Local cMsgErr := ""
	Local lRet := .T.
	Local lReqCliPad := SuperGetMv("MV_XRQCPAD",,.F.) //permite requsição para cliente padrao? 
	Local lBlqAI0 	:= SuperGetMv("MV_XBLQAI0",,.F.) .AND. AI0->(FieldPos("AI0_XBLFIL")) > 0 //Habilita bloqueio de venda na filial, olhando para tabela AI0

	If Empty(cCodCli) .or. Empty(cLojCli)
		cNomCli := Space(TamSX3("A1_NOME")[1])
		cCodCli := Space(TamSX3("A1_COD")[1])
		cLojCli := Space(TamSX3("A1_LOJA")[1])
	Else
		cNomCli := Posicione("SA1",1,xFilial("SA1")+cCodCli+cLojCli,"A1_NOME") //A1_FILIAL+A1_COD+A1_LOJA
		If Empty(cNomCli)
			lRet := .F.
			cMsgErr := "Cliente não cadastrado!"
		ElseIf !lReqCliPad .AND. SA1->A1_COD+SA1->A1_LOJA == GETMV("MV_CLIPAD")+GETMV("MV_LOJAPAD")
			lRet := .F.
			cMsgErr := "Não é permitido fazer saques para o cliente padrão."

		// verifico se o cadastro tem autorização para ser utilizado nesta filial/empresa
		elseif lBlqAI0 .AND. Posicione("AI0",1,xFilial("AI0")+SA1->A1_COD+SA1->A1_LOJA,"AI0_XBLFIL")=="S"
			lRet := .F.
			cMsgErr :=  "O cliente "+SA1->A1_COD+"/"+SA1->A1_LOJA+" não está autorizado nesta filial."
		elseIf !lBlqAI0 .AND. SA1->(FieldPos("A1_XFILBLQ")) > 0 .and. !Empty(SA1->A1_XFILBLQ) .and. (cFilAnt $ SA1->A1_XFILBLQ)
			lRet := .F.
			cMsgErr :=  "O cliente "+SA1->A1_COD+"/"+SA1->A1_LOJA+" não está autorizado nesta filial."
		EndIf
	EndIf

	If lRet
		oNomCli:Refresh()
	EndIf

	If lConfCash
		If !Empty(cMsgErr)
			MsgInfo(cMsgErr, "Atenção")
		EndIf
	Else
		U_SetMsgRod(cMsgErr)
	EndIf

Return lRet

//----------------------------------------------------------
// Valida motorista e gatilha nome
//----------------------------------------------------------
Static Function VldMotoris()

	Local lRet := .T.

	cNomMot := Space(TamSX3("DA4_NOME")[1])
	oNomMot:lReadonly := .F.

	If !Empty(cCgcMot)
		DbSelectArea("DA4")
		DA4->(DbSetOrder(3)) //DA4_FILIAL+DA4_CGC
		If DA4->(DbSeek(xFilial("DA4")+cCgcMot ))
			cNomMot := DA4->DA4_NOME
			oNomMot:lReadonly := .T.
		EndIf
	EndIf

	oNomMot:Refresh()

Return lRet

//----------------------------------------------------------
// Valida placa e faz gatilho quando ha amarracao com cliente
//----------------------------------------------------------
Static Function VldVend()

	Local cMsgErr := ""
	Local lRet := .T.

	If Empty(cVendedor)
		cNomVend := Space(TamSX3("A3_NOME")[1])
	Else
		SA3->(DbSetOrder(1))
		If SA3->(DbSeek(xFilial("SA3") + cVendedor))
			If U_TPDVP23A(cVendedor)
				cNomVend := SA3->A3_NOME
			else
				lRet := .F.
				cMsgErr := "O cargo (A3_CARGO) do vendedor "+SA3->A3_COD+"-"+AllTrim(SA3->A3_NOME)+" não está liberado para ser utilizado no PDV."
			EndIf
		Else
			cMsgErr := "Vendedor não cadastrado!"
			lRet := .F.
		EndIf
	EndIf

	If lRet
		oNomVend:Refresh()
	EndIf

	If lConfCash
		If !Empty(cMsgErr)
			MsgInfo(cMsgErr, "Atenção")
		EndIf
	Else
		U_SetMsgRod(cMsgErr)
	EndIf

Return lRet

//--------------------------------------------------------------
// Aplica CSS no botão tipo Radio
//--------------------------------------------------------------
Static Function SetTipoSel(nOpcSel)

	Local cCssBtn

	If nOpcSel == 2 //Pós

		//deixo botão PÓS azul
		cCssBtn := POSCSS(GetClassName(oBtnTpPos), CSS_BTN_FOCAL )
		cCssBtn:= StrTran(cCssBtn, "border-radius: 6px;", "border-radius: 3px;")
		oBtnTpPos:SetCss(cCssBtn)

		//deixo botão PRÉ branco
		cCssBtn := POSCSS(GetClassName(oBtnTpPre), CSS_BTN_NORMAL )
		cCssBtn:= StrTran(cCssBtn, "border-radius: 6px;", "border-radius: 3px;")
		cCssBtn:= StrTran(cCssBtn, "font: bold large;", "")
		oBtnTpPre:SetCss(cCssBtn)

		oPnlSqPre:Hide()
		oPnlSqPos:Show()

	Else //Pré

		//deixo botão PÓS branco
		cCssBtn := POSCSS(GetClassName(oBtnTpPos), CSS_BTN_NORMAL )
		cCssBtn:= StrTran(cCssBtn, "border-radius: 6px;", "border-radius: 3px;")
		cCssBtn:= StrTran(cCssBtn, "font: bold large;", "")
		oBtnTpPos:SetCss(cCssBtn)

		//deixo botão PRÉ azul
		cCssBtn := POSCSS(GetClassName(oBtnTpPre), CSS_BTN_FOCAL )
		cCssBtn:= StrTran(cCssBtn, "border-radius: 6px;", "border-radius: 3px;")
		oBtnTpPre:SetCss(cCssBtn)

		oPnlSqPre:Show()
		oPnlSqPos:Hide()
	EndIf

	AtuConnRet()

	oBtnTpPos:Refresh()
	oBtnTpPre:Refresh()

Return

//------------------------------------------------------------------------
// Carrega combo dos motivos
//------------------------------------------------------------------------
Static Function LoadMotivos()

	Local aRet := {}
	Local cDescri := "", nX := 0
	Local aContent := {} //campos de uma tabela no SX5 (Vetor com os dados do SX5 - com: [1] FILIAL [2] TABELA [3] CHAVE [4] DESCRICAO)

	aadd(aRet, space(6))

	//primeiro verifico se a tabela UX existe
	//aContent := FWGetSX5( "UX" )
	//If !Len(aContent) > 0 //se nao tem a tabela criada ainda.. cria.
	//	cDescri := PadR("VALE MOTORISTA",TamSx3("X5_DESCRI")[1])
	//	FwPutSX5(/*cFlavour*/, "UX", PadR("01",TamSx3("X5_CHAVE")[1]), cDescri, cDescri, cDescri, /*cTextoAlt*/)
	//EndIf

	//primeiro verifico se a tabela UX existe 
	//TODO: a função 'FwPutSX5' não esta funcionando....
	DbSelectArea("SX5")
	SX5->(DbSetOrder(1)) //X5_FILIAL+X5_TABELA+X5_CHAVE
	If !SX5->(DbSeek(xFilial("SX5")+"UX")) //se nao tem a tabela criada ainda.. cria.
		cDescri := PadR("VALE MOTORISTA",TamSx3("X5_DESCRI")[1])
		RecLock("SX5",.T.) //inclui
			SX5->X5_FILIAL  := xFilial("SX5")
			SX5->X5_TABELA  := "UX"
			SX5->X5_CHAVE   := "01"
			SX5->X5_DESCRI  := cDescri
			SX5->X5_DESCSPA := cDescri
			SX5->X5_DESCENG := cDescri		
		MsUnlock()
	EndIf

	aContent := FWGetSX5( "UX" )
	If Len(aContent) > 0
		For nX := 1 to Len(aContent)
			aadd(aRet, aContent[nX][3] + "- " + aContent[nX][4])
		Next nX
	EndIf
	
Return aRet

/*/{Protheus.doc} TPDVA7CL
Função para limpar e resetar tela.

@author thebr
@since 12/05/2019
@version 1.0
@return Nil
@type function
/*/
User Function TPDVA7CL(lNoBrowse)

	Local lMvPswVend := SuperGetMv("TP_PSWVEND",,.F.)
	Default lNoBrowse := .F.

	If !lConfCash .AND. Empty(cUsrSaq) //se nao tem acesso, nao criou componentes
		Return
	EndIf

	cTitleTela := "SACAR"
	cCodCli := Space(TamSX3("A1_COD")[1])
	cLojCli := Space(TamSX3("A1_LOJA")[1])
	cNomCli := Space(TamSX3("A1_NOME")[1])
	cPlaca := Space(TamSX3("U57_PLACA")[1])
	cVendedor := Space(TamSX3("U57_VEND")[1])
	cNomVend := Space(TamSX3("A3_NOME")[1])
	cCgcMot := Space(TamSX3("U57_MOTORI")[1])
	cNomMot := Space(TamSX3("DA4_NOME")[1])
	cMotivo := Space(TamSX3("U57_MOTIVO")[1])
	cGetCod := Space(40)
	lRetOn := .F.
	cRequisit := Space(TamSX3("U56_REQUIS")[1])
	cCargo := Space(TamSX3("U56_CARGO")[1])
	nValorSq := 0
	cBuscaSaq := Space(TamSX3("U57_PREFIX")[1]+TamSX3("U57_CODIGO")[1]+TamSX3("U57_PARCEL")[1])
	dBuscaDt := dDataBase
	cBuscaCod := Space(TamSX3("A1_COD")[1])
	cBuscaLoj := Space(TamSX3("A1_LOJA")[1])
	cBuscaPlaca := Space(TamSX3("U57_PLACA")[1])
	nQtdReg := 0
	nVlrSqPre := 0
	aNCCsReq := Nil //Array com todas as NCCs do cliente
	oNomMot:lReadonly := .F.
	aLogAlcada := {}

	//nTipoOper := 2 //2-PÓS-PAGO;1-PRÉ-PAGO"
	//SetTipoSel(nTipoOper)

	AtuaListCred()
	
	if !lConfCash .AND. lMvPswVend
		cVendedor := U_TPGetVend()
		cNomVend  := U_TPGetVend(2)
	else
		SA3->(DbSetOrder(7)) // A3_FILIAL + A3_CODUSR
		If SA3->(DbSeek(xFilial("SA3") + RETCODUSR()))
			cVendedor := SA3->A3_COD
			cNomVend  := SA3->A3_NOME
		Else
			SA3->(DbSetOrder(1))
			If SA3->(DbSeek(xFilial("SA3") + GetMV("MV_VENDPAD") ))
				cVendedor := SA3->A3_COD
				cNomVend  := SA3->A3_NOME
			EndIf
		EndIf
	endif

	If !lConfCash
		If lNoBrowse
			U_SetMsgRod("")
		EndIf

		If oPnlBrow:lVisible
			oBuscaSaq:SetFocus()
		Else
			oPlaca:SetFocus()
		EndIf
	EndIf

	If !lNoBrowse //flag para nao limpar browse
		cBuscaSaq := Space(TamSX3("U57_PREFIX")[1]+TamSX3("U57_CODIGO")[1]+TamSX3("U57_PARCEL")[1])
		dBuscaDt  := dDataBase
		cBuscaCod := Space(TamSX3("A1_COD")[1])
		cBuscaLoj := Space(TamSX3("A1_LOJA")[1])
		nQtdReg := 0
		ClearGrid(oMsGetSaq)
	EndIf

Return

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

//----------------------------------------------------------------------------------
// Validação total da tela de inclusão
//----------------------------------------------------------------------------------
Static Function VldIncSaq(lConfGrv)

	Local cMsgErr := ""
	Local lRet := .T.
	Local lMVValCargo	:= SuperGetMV("MV_XVALCAR", .F., .T.)

	Default lConfGrv := .F.

	SE4->(DbSetOrder(1)) //E4_FILIAL+E4_CODIGO

	If Empty(cPlaca)
		cMsgErr := "Informe a placa do veículo!"
		lRet := .F.
	ElseIf Empty(cCodCli) .or. Empty(cLojCli)
		cMsgErr := "Informe o código/loja do cliente!"
		lRet := .F.
	ElseIf Empty(cNomCli)
		cMsgErr := "Cliente não encontrado na base! Verificar cadastro."
		lRet := .F.
	ElseIf Empty(cCgcMot)
		cMsgErr := "Informe o CPF do motorista!"
		lRet := .F.
	ElseIf Empty(cNomMot)
		cMsgErr := "Informe o nome do Motorista!"
		lRet := .F.
	ElseIf Empty(cVendedor)
		cMsgErr := "Informe o vendedor para realizar a operação!"
		lRet := .F.
	ElseIf Empty(cMotivo)
		cMsgErr := "Informe o motivo do Saque para realizar a operação!"
		lRet := .F.
	ElseIf Empty(cNomVend)
		cMsgErr := "Vendedor informado não encontrado na base! Verificar cadastro."
		lRet := .F.
	ElseIf nTipoOper == 2 .and. lConfGrv //Pós-Paga

		SA1->(DbSetOrder(1)) //A1_FILIAL+A1_COD+A1_LOJA
		If !empty(cCodCli) .and. !empty(cLojCli) .and. !SA1->(DbSeek(xFilial("SA1")+cCodCli+cLojCli))
			cMsgErr := "Cliente não cadastrado!"
			lRet := .F.
		ElseIf SA1->(FieldPos("A1_XCONDSA")) > 0 .and. Empty(SA1->A1_XCONDSA)
			cMsgErr := "Cliente não configurado corretamente para Saque Pós-Pago. Verifique o cadastro 'Condição Pg Saq' (A1_XCONDSA)."
			lRet := .F.
		ElseIf SA1->(FieldPos("A1_XCONDSA")) > 0 .and. !SE4->(DbSeek(xFilial("SE4")+SA1->A1_XCONDSA))
			cMsgErr := "Condição de Pagamento "+SA1->A1_XCONDSA+" não cadastrada. Verifique o cadastro 'Condição Pg Saq' (A1_XCONDSA)."
			lRet := .F.
		ElseIf Empty(cRequisit)
			cMsgErr := "Infome o nome do requisitante."
			lRet := .F.
		ElseIf Empty(cCargo) .And. lMVValCargo
			cMsgErr := "Infome o cargo do requisitante."
			lRet := .F.
		ElseIf nValorSq <= 0
			cMsgErr := "Favor informar o Valor do Saque."
			lRet := .F.
		EndIf

		//valida limite de crédito
		If lRet .and. !lConfCash
			lRet := ValidaCred()
		EndIf

	ElseIf nTipoOper==1 .and. lConfGrv //Pré-Paga

		If oListGdNcc:nAt <= 0 .or. aNCCsReq == Nil .or. Len(aNCCsReq) < oListGdNcc:nAt
			cMsgErr := "Nenhum crédito selecionado..."
			lRet := .F.
		EndIf

		If nVlrSqPre <= 0
			cMsgErr := "Favor selecionar um credito com saldo."
			lRet := .F.
		EndIf

	EndIf

	//valido database com o date server
	if lRet .AND. !lConfCash .AND. dDataBase <> Date()
		cMsgErr := "A data do sistema esta diferente da data do sistema operacional. Favor efetuar o logoff do sistema."
		lRet := .F.
	endif

	If lRet
		If !lConfCash
			U_SetMsgRod("")
		EndIf
		If lConfGrv

			CursorArrow()
			CursorWait()
			If !lConfCash
				U_SetMsgRod("Aguarde enquanto o sistema faz as movimentações necessárias...")
			EndIf

			lRet := DoGrava()

			CursorArrow()
		EndIf
	Else
		aLogAlcada := {} //se nao autorizou saque limpo log alcada
		If lConfCash
			MsgInfo(cMsgErr, "Atenção")
		Else
			U_SetMsgRod(cMsgErr)
		EndIf
	EndIf

Return lRet

//--------------------------------------------------------------------
// Validação de limite e bloqueio de crédito
//--------------------------------------------------------------------
Static Function ValidaCred()

	Local lActiveVCred := SuperGetMV("TP_ACTVCR",,.F.) //-- ativa e desativa a validação de limite de crédito
	Local lTP_ACTLCS := SuperGetMv("TP_ACTLCS",,.F.) //habilita limite de credito por segmento (filial)
	Local cSegmento := SuperGetMv("TP_MYSEGLC",," ") //define o segmento da filial do PDV
	Local lTP_ACTLGR := SuperGetMv("TP_ACTLGR",,.T.) //habilita limite de credito por grupo de clientes
	Local lRet := .T.
	Local nX, cMsgErr
	Local aLimites := {}, aParam := {}
	Local lAlcada	:= SuperGetMv("ES_ALCADA",.F.,.F.)
	Local lAlcSaque	:= SuperGetMv( "ES_ALCSAQ",.F.,.F.)
	Local lLibLim := .F.
	Local cUsrLibAlc := ""
	Local cUsrLibSBL := ""
	Local cUsrLibSSL := ""
	Local cMsgLibAlc := ""
	Local cGetCdUsr	 := RetCodUsr()
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

	If !lActiveVCred
		U_SetMsgRod("Validação de limite de crédito desativado (TP_ACTVCR).")
		Return lRet
	EndIf

	

	lRetOn := IIF(GetPvProfString(CSECAO, CCHAVE, '0', GetAdv97()) == '0', .F., .T.)

	SA1->(DbSetOrder(1)) //A1_FILIAL+A1_COD+A1_LOJA
	SA1->(DbSeek(xFilial("SA1")+cCodCli+cLojCli))

	ACY->(DbSetOrder(1)) // ACY_FILIAL + ACY_GRPVEN
	ACY->(DbSeek(xFilial("ACY")+SA1->A1_GRPVEN))

	aadd(aListCli,{ SA1->A1_CGC,;
					SA1->A1_COD,;
					SA1->A1_LOJA,;
					iif(lTP_ACTLGR,SA1->A1_GRPVEN,""),;
					"SAQUE",;
					nValorSq,;
					SA1->A1_XLIMSQ,;
					0,;
					0,;
					Iif(ACY->(!Eof()),ACY->ACY_XLIMSQ,0),;
					0,;
					0,;
					Iif(!Empty(SA1->A1_XBLQSQ),SA1->A1_XBLQSQ,'2'),;
					Iif(ACY->(!Eof()),ACY->ACY_XBLRSA,'2');
				})

	If Len(aListCli) > 0 

		CursorArrow()

		U_SetMsgRod("Pesquisando limite de crédito de saque do cliente"+iif(lRetOn .AND. cLCOffline <> "2"," no Back-Office","")+". Aguarde...")

		CursorWait()

		//conout(">> TRETE032 - INICIO - Retorna o limite utilizado de um CLIENTE e GRUPO DE CLIENTE")
		//conout("	Data: "+DTOC(Date())+" / Hora: "+cValToChar(Time())+"")

		aLimites := {}
		aParam := {}
		For nX:=1 to Len(aListCli)
			aadd(aParam,{aListCli[nX][02],aListCli[nX][03],""})
		Next nX
		aParam := {2,aParam}
		if lTP_ACTLCS
			aadd(aParam, cSegmento)
		endif
		if lRetOn .AND. cLCOffline <> "2" //so nao pesquisa online se parametro define apenas offline
			If STBRemoteExecute("_EXEC_RET", {"U_TRETE032",aParam},,, @aLimites)
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

		CursorArrow()

	EndIf

	For nX:=1 to Len(aListCli)

		//VALIDANDO BLOQUEIOS DE LIMITE PARA SAQUE POS-PAGO
		//bloqueio de limite de cliente
		If (empty(aListCli[nX][04]) .OR. cPriGrupo <> "1") .AND. aListCli[nX][13] == '1' 
			cMsgErr := "Cliente "+AllTrim(Posicione("SA1",1,xFilial("SA1")+aListCli[nX][02]+aListCli[nX][03],"A1_NOME"))+" com bloqueio de crédito ("+AllTrim(aListCli[nX][05])+")."
			U_SetMsgRod(cMsgErr)

			if lAlcada .AND. lAlcSaque
				cMsgLibAlc := "Alçada de Bloqueio de Limite Credito de Saque - Cliente" + CRLF
				cMsgLibAlc += "Cliente: " + SA1->A1_COD + "/" + SA1->A1_LOJA + " - " + SA1->A1_NOME + CRLF

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
						U_SetMsgRod("Usuário não tem alçada para Liberar Saque de Cliente com Bloqueio de Crédito.")
						Return .F.
					endif
				endif
			else
				if empty(cUsrLibSBL)
					U_TRETA37B("LIBSBL", "LIBERAR SAQUE CLIENTE/GRUPO COM BLOQUEIO CREDITO")
					cUsrLibSBL := U_VLACESS1("LIBSBL", cGetCdUsr)
					If cUsrLibSBL == Nil .OR. Empty(cUsrLibSBL)
						U_SetMsgRod("Usuário não tem permissão de acesso para Liberar Saque de Cliente com Bloqueio de Crédito." )
						Return .F.
					EndIf
				endif
			endif

		//bloqueio de limite de grupo de cliente
		ElseIf !Empty(aListCli[nX][04]) .and. aListCli[nX][14] == '1' 
			cMsgErr := "Grupo de Cliente "+AllTrim(Posicione("ACY",1,xFilial("ACY")+aListCli[nX][04],"ACY_DESCRI"))+" com bloqueio de crédito ("+AllTrim(aListCli[nX][05])+")."
			U_SetMsgRod(cMsgErr)

			if lAlcada .AND. lAlcSaque
				cMsgLibAlc := "Alçada de Bloqueio de Limite Credito de Saque - Grupo" + CRLF
				cMsgLibAlc += "Cliente/Emitente: " + aListCli[nX][02] + "/" + aListCli[nX][03] + " - " + Posicione("SA1",1,xFilial("SA1")+aListCli[nX][02]+aListCli[nX][03],"A1_NOME") + CRLF
				cMsgLibAlc += "Grupo do Cliente: " + ACY->ACY_GRPVEN + " - " + ACY->ACY_DESCRI + CRLF

				//verifico alçada do prorio usuario
				lLibLim := LibAlcadaBlq(,cMsgLibAlc) 
				//se nao liberou e ja chamou tela açada para alguma forma, tento com ultimo usuário
				if !lLibLim .AND. !empty(cUsrLibAlc)
					lLibLim := LibAlcadaBlq(cUsrLibAlc, cMsgLibAlc) 
				endif
				if !lLibLim 
					//solicita liberaçao de alçada de outro usuario
					lLibLim := TelaLibAlcada(1, cMsgErr+CRLF+"Solicite liberação por alçada de um supervisor.",,,,@cUsrLibAlc,cMsgLibAlc)
					if !lLibLim
						U_SetMsgRod("Usuário não tem alçada para Liberar Saque de Cliente com Bloqueio de Crédito.")
						Return .F.
					endif
				endif
			else
				if empty(cUsrLibSBL)
					U_TRETA37B("LIBSBL", "LIBERAR SAQUE CLIENTE/GRUPO COM BLOQUEIO CREDITO")
					cUsrLibSBL := U_VLACESS1("LIBSBL", cGetCdUsr)
					If cUsrLibSBL == Nil .OR. Empty(cUsrLibSBL)
						U_SetMsgRod("Usuário não tem permissão de acesso para Liberar Saque de Cliente com Bloqueio de Crédito." )
						Return .F.
					EndIf
				endif
			endif

		endif
		
		//VALIDANOD VALORES DE LIMITE DE CREDITO
		//se valor do saque > saldo limite credito
		If (empty(aListCli[nX][04]) .OR. cPriGrupo <> "1") .AND. aListCli[nX][06] > aListCli[nX][09] 
			cMsgErr := "Cliente "+AllTrim(Posicione("SA1",1,xFilial("SA1")+aListCli[nX][02]+aListCli[nX][03],"A1_NOME"))+" não possui limite de crédito ("+AllTrim(aListCli[nX][05])+"). Saldo de Limite: "+Alltrim(Transform(aListCli[nX][09],PesqPict("SL1","L1_VLRLIQ")))
			U_SetMsgRod(cMsgErr)

			if lAlcada .AND. lAlcSaque
				cMsgLibAlc := "Alçada de Limite Credito de Saque Excedido - Cliente" + CRLF
				cMsgLibAlc += "Cliente: " + SA1->A1_COD + "/" + SA1->A1_LOJA + " - " + SA1->A1_NOME + CRLF

				//verifico alçada do prorio usuario
				lLibLim := LibAlcadaLim(,aListCli[nX][06], aListCli[nX][07], aListCli[nX][09], cMsgLibAlc) 
				//se nao liberou e ja chamou tela açada para alguma forma, tento com ultimo usuário
				if !lLibLim .AND. !empty(cUsrLibAlc)
					lLibLim := LibAlcadaLim(cUsrLibAlc, aListCli[nX][06], aListCli[nX][07], aListCli[nX][09],cMsgLibAlc)
				endif
				if !lLibLim 
					//solicita liberaçao de alçada de outro usuario
					lLibLim := TelaLibAlcada(2, cMsgErr+CRLF+"Solicite liberação por alçada de um supervisor.",aListCli[nX][06], aListCli[nX][07], aListCli[nX][09], @cUsrLibAlc,cMsgLibAlc)
					if !lLibLim
						U_SetMsgRod("Usuário não tem alçada para Liberar Saque sem Saldo de Limite de Crédito.")	
						Return .F.
					endif
				endif
			else
				if empty(cUsrLibSSL)
					U_TRETA37B("LIBSSL", "LIBERAR SAQUE CLIENTE/GRUPO SEM SALDO LIMITE DE CREDITO")
					cUsrLibSSL := U_VLACESS1("LIBSSL", cGetCdUsr)
					If cUsrLibSSL == Nil .OR. Empty(cUsrLibSSL)
						U_SetMsgRod("Usuário não tem permissão de acesso para Liberar Saque sem Saldo de Limite de Crédito." )
						Return .F.
					EndIf
				endif
			endif

		ElseIf !Empty(aListCli[nX][04]) .and. aListCli[nX][06] > aListCli[nX][12] 
			cMsgErr := "Grupo de Cliente "+AllTrim(Posicione("ACY",1,xFilial("ACY")+aListCli[nX][04],"ACY_DESCRI"))+" não possui limite de crédito ("+AllTrim(aListCli[nX][05])+"). Saldo de Limite: "+Alltrim(Transform(aListCli[nX][12],PesqPict("SL1","L1_VLRLIQ")))
			U_SetMsgRod(cMsgErr)

			if lAlcada .AND. lAlcSaque
				cMsgLibAlc := "Alçada de Limite Credito de Saque Excedido - Grupo" + CRLF
				cMsgLibAlc += "Cliente/Emitente: " + aListCli[nX][02] + "/" + aListCli[nX][03] + " - " + Posicione("SA1",1,xFilial("SA1")+aListCli[nX][02]+aListCli[nX][03],"A1_NOME") + CRLF
				cMsgLibAlc += "Grupo do Cliente: " + ACY->ACY_GRPVEN + " - " + ACY->ACY_DESCRI + CRLF

				//verifico alçada do prorio usuario
				lLibLim := LibAlcadaLim(, aListCli[nX][06], aListCli[nX][10], aListCli[nX][12], cMsgLibAlc) 
				if !lLibLim .AND. !empty(cUsrLibAlc)
					lLibLim := LibAlcadaLim(cUsrLibAlc, aListCli[nX][06], aListCli[nX][10], aListCli[nX][12], cMsgLibAlc) 
				endif
				if !lLibLim 
					//solicita liberaçao de alçada de outro usuario
					lLibLim := TelaLibAlcada(2, cMsgErr+CRLF+"Solicite liberação por alçada de um supervisor.",aListCli[nX][06], aListCli[nX][07], aListCli[nX][09],@cUsrLibAlc,cMsgLibAlc)
					if !lLibLim
						U_SetMsgRod("Usuário não tem alçada para Liberar Saque sem Saldo de Limite de Crédito.")	
						Return .F.
					endif
				endif
			else
				if empty(cUsrLibSSL)
					U_TRETA37B("LIBSSL", "LIBERAR SAQUE CLIENTE/GRUPO SEM SALDO LIMITE DE CREDITO")
					cUsrLibSSL := U_VLACESS1("LIBSSL", cGetCdUsr)
					If cUsrLibSSL == Nil .OR. Empty(cUsrLibSSL)
						U_SetMsgRod("Usuário não tem permissão de acesso para Liberar Saque sem Saldo de Limite de Crédito." )
						Return .F.
					EndIf
				endif
			endif

		EndIf

	Next nX

	If lRet
		U_SetMsgRod("")
	EndIf

Return lRet

//----------------------------------------------------------------------
// Verifica alçada de limite de credito
//----------------------------------------------------------------------
Static Function LibAlcadaLim(cCodUsr, nVlrSaque, nVlrLim, nSaldoLim, cMsgLog)

	Local nZ
	Local lRet := .F.
	Local nVlrLimAlc := 0
	Local nPerLimAlc := 0
	Default cCodUsr := RetCodUsr()
	Default cMsgLog := ""

	cMsgLog += "Valor Saque: " + cValToChar(nVlrSaque) + CRLF
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

		nVlrLimAlc := Posicione("U0D",1,xFilial("U0D")+Space(TamSx3("U04_GRUPO")[1])+PadR(cCodUsr,TamSx3("U04_USER")[1]),"U0D_VLMSQ")
		nPerLimAlc := Posicione("U0D",1,xFilial("U0D")+Space(TamSx3("U04_GRUPO")[1])+PadR(cCodUsr,TamSx3("U04_USER")[1]),"U0D_PLMSQ")

		// limite alçaca >= saldo sem limite				x % do limite >= saldo sem limite
		if (nVlrLimAlc >= (nVlrSaque - nSaldoLim)) .OR. ( (nVlrLim*nPerLimAlc/100) >= (nVlrSaque - nSaldoLim) )
			lRet := .T.
			cMsgLog += "Usuário Liberação: " + cCodUsr + " - " + USRRETNAME(cCodUsr) + CRLF
			cMsgLog += "Vlr Limite Alçada: " + cValToChar(nVlrLimAlc) + CRLF
			cMsgLog += "% Limite Alçada: " + cValToChar(nPerLimAlc) + CRLF
			cMsgLog += "Vlr obtido do % Limite: " + cValToChar((nVlrLim*nPerLimAlc/100)) + CRLF
		endif

		if !lRet
			for nZ := 1 to len(aGrupos)
				nVlrLimAlc := Posicione("U0D",1,xFilial("U0D")+PadR(aGrupos[nZ],TamSx3("U04_GRUPO")[1])+Space(TamSx3("U04_USER")[1]),"U0D_VLMSQ")
				nPerLimAlc := Posicione("U0D",1,xFilial("U0D")+PadR(aGrupos[nZ],TamSx3("U04_GRUPO")[1])+Space(TamSx3("U04_USER")[1]),"U0D_PLMSQ")

				// limite alçaca >= saldo sem limite				% do limite >= saldo sem limite
				if (nVlrLimAlc >= (nVlrSaque - nSaldoLim)) .OR. ( (nVlrLim*nPerLimAlc/100) >= (nVlrSaque - nSaldoLim) )
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
		aadd(aLogAlcada, {"ALCSAQ", USRRETNAME(cCodUsr), cMsgLog})
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
		lRet := .T.
		cMsgLog += "Usuário Liberação: " + cCodUsr + " - " + USRRETNAME(cCodUsr) + CRLF
	else
		aGrupos := UsrRetGrp(UsrRetName(cCodUsr), cCodUsr)

		cLimBlq := Posicione("U0D",1,xFilial("U0D")+Space(TamSx3("U04_GRUPO")[1])+PadR(cCodUsr,TamSx3("U04_USER")[1]),"U0D_SQCBLQ")
		if cLimBlq == "S"
			lRet := .T.
			cMsgLog += "Usuário Liberação: " + cCodUsr + " - " + USRRETNAME(cCodUsr) + CRLF
		endif

		if !lRet
			for nZ := 1 to len(aGrupos)
				cLimBlq := Posicione("U0D",1,xFilial("U0D")+PadR(aGrupos[nZ],TamSx3("U04_GRUPO")[1])+Space(TamSx3("U04_USER")[1]),"U0D_SQCBLQ")
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
		cMsgLog += "Campo U0D_SQCBLQ = S"
		aadd(aLogAlcada, {"ALCSAQ", USRRETNAME(cCodUsr), cMsgLog})
	endif

Return lRet

//----------------------------------------------------------------------
// chama tela de liberação por alçada
// nTipo: 1=Bloqueios Limite; 2=Valor Limite
//----------------------------------------------------------------------
Static Function TelaLibAlcada(nTipo, cMsgErr, nVlrSaque, nVlrLim, nSaldoLim, cUsrLibAlc, cMsgLibAlc)
	
	Local lRet := .F.
	Local lEscape := .T.
	Local aLogin
	Local nY
	Local cMsgUser := ""

	While lEscape
		aLogin := U_TelaLogin(cMsgUser+cMsgErr,"Limite Credito", .T.)
		if empty(aLogin) //cancelou tela
			lEscape := .F.
		else
			if nTipo == 1
				lRet := LibAlcadaBlq(aLogin[1],cMsgLibAlc)
				if lRet
					cUsrLibAlc := aLogin[1]
				else
					cMsgUser := "Usuário "+Alltrim(aLogin[2])+" não possui alçada suficiente para Liberar Saque de cliente com Bloqueio de Crédito." + CRLF
				endif
			else
				lRet := LibAlcadaLim(aLogin[1], nVlrSaque, nVlrLim, nSaldoLim, cMsgLibAlc)
				if lRet
					cUsrLibAlc := aLogin[1]
				else
					cMsgUser := "Usuário "+Alltrim(aLogin[2])+" não possui alçada suficiente para Liberar Saque sem Saldo de Limite de Crédito." + CRLF
				endif
			endif
			lEscape := !lRet
		endif
	enddo

Return lRet

//-------------------------------------------------------------------
// Processa a confirmação...
//-------------------------------------------------------------------
Static Function DoGrava()

	Local aArea := GetArea()
	Local aAreaSA6 := SA6->( GetArea() )
	Local nX
	Local lRet := .T.
	Local aParam    := {}  // Array de parametros
	Local aCposCab  := {}
	Local aCposDet  := {}
	Local aAux      := {}
	Local cFilAut   := cFilAnt + Space(TamSx3("U56_FILAUT")[1]-LEN(cFilAnt))
	Local cCliente  := cCodCli
	Local cLojaCli  := cLojCli
	Local cBanco,cAgencia,cNumCon,aStation
	Local cNumMov := iif(lConfCash,SLW->LW_NUMMOV,STDNumMov())
	Local cCondSaq  := space(TamSx3("U56_CONDSA")[1])
	Local cDoc 		:= ""
	Local cSerie	:= AllTrim(SuperGetMV("MV_XPRFXRS", .T., "RPS")) // Prefixo de Titulo de Requisicoes de Saque
	Local dDatMov   := ddatabase
	Local cHoraMov  := Time()
	Local nDinheiro := 0
	Local nChTroco	:= 0
	Local aRet		:= {-1,"","","","",""} //{"E1_SALDO","U56_REQUIS","U56_CARGO","E1_XCODBAR","E1_CLIENTE","E1_LOJA"}
	Local cNumReq   := ""
	Local cPrfU56	:= ""
	Local lHabTra	:= SuperGetMV("TP_HCTRASQ", .F., .T.) //Habilita controle de transação na rotina de saque/vale ? (default .T.)

	//Informacoes da estacao
	If lConfCash
		aStation := {SLW->LW_OPERADO, SLW->LW_ESTACAO, SLW->LW_SERIE, SLW->LW_PDV, SLG->LG_SERNFIS}
		cHoraMov := SLW->LW_HRABERT
	Else
		aStation := STBInfoEst( 1, .T. ) // [1]-CAIXA [2]-ESTACAO [3]-SERIE [4]-PDV [5]-LG_SERNFIS
	EndIf

	cBanco := aStation[1]
	SA6->(DbSetOrder(1))
	SA6->(DbSeek(xFilial("SA6")+cBanco))
	cAgencia  := SA6->A6_AGENCIA
	cNumCon   := SA6->A6_NUMCON

	If nTipoOper==1 //Pré-Paga
		//nVlrSqPre - aNCCsReq[oListGdNcc:nAt][2]
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

		If lHabTra
			BeginTran() //controle de transação
		EndIf

		CursorArrow() //como a tela do cheque troco desabilita o cursorwait, ativo novamente, pqe ainda tem coisas processando...

		If !lConfCash .AND. SuperGetMV("TP_ACTCHT",,.F.)
			//seleção de cheque troco
			cCodBar 	:= aNCCsReq[oListGdNcc:nAt][15]
			cDoc		:= aNCCsReq[oListGdNcc:nAt][3]
			cSerie		:= aNCCsReq[oListGdNcc:nAt][9]
			aRetChq 	:= {}
			aRetChq 	:= U_TPDVE007(nVlrSqPre,{cDoc, cSerie, cCodBar, cCliente, cLojaCli, /*cNaturez*/, aStation[4]/*cPDV*/},.F./*lImpChq*/) //rotina de selecao de cheque troco
			nDinheiro 	:= aRetChq[01]
		Else
			nDinheiro := nVlrSqPre //quando conferencia nao inclui o cheque troco agora
		EndIf

		CursorWait()

		nChTroco := nVlrSqPre - nDinheiro

		If lConfCash
			nRecNo := aNCCsReq[oListGdNcc:nAt][5]

			SE1->(DbGoTo(nRecNo))
			if SE1->(!Eof()) .AND. SE1->E1_EMISSAO > SLW->LW_DTFECHA
				MsgAlert("Data de emissão da requisição é maior que data do caixa. Não será permitido utilizar esta requisição!","Atenção")
				U57->(DbGoTo(0)) //vou para final de arquivo
				lRet := .F.
			else
				aRet := U_TRETE23D(nRecNo, cBanco, cAgencia, cNumCon, cCgcMot, cPlaca, PadR(cMotivo,TamSx3("U57_MOTIVO")[1]), aStation[4], aStation[2], PadR(cNumMov,TamSx3("U57_XNUMMO")[1]), nVlrSqPre, nChTroco, dDatMov, cHoraMov, cVendedor, cNomMot)
				If aRet[1] <> 0
					MsgInfo("Ocorreu falha na baixa da requisição de saque...","Atenção")
					U57->(DbGoTo(0)) //vou para final de arquivo
					lRet := .F.
				EndIf
			endif
		Else
			//U_TRETE23D(nRecNo,cBanco,cAgencia,cNumCon,cCPF,cPlaca,cMotivo,cPdv,cEstacao,cNumMov,nValSaq,nChTroco,dDatMov,cHoraMov,cVendedor, cNomMot)
			nRecNo := aNCCsReq[oListGdNcc:nAt][5]
			aParam := {nRecNo, cBanco, cAgencia, cNumCon, cCgcMot, cPlaca, PadR(cMotivo,TamSx3("U57_MOTIVO")[1]), aStation[4], aStation[2], PadR(cNumMov,TamSx3("U57_XNUMMO")[1]), nVlrSqPre, nChTroco, dDatMov, cHoraMov, cVendedor, cNomMot}
			aParam := {"U_TRETE23D",aParam}
			If !STBRemoteExecute("_EXEC_RET",aParam,,,@aRet)
				// Tratamento do erro de conexao
				U_SetMsgRod("Falha de comunicação com o Back-Office...")
				lRet := .F.
			ElseIf aRet = Nil .or. aRet[1] <> 0
				// O saldo apos a baixa deve ser zerado
				U_SetMsgRod("Ocorreu falha na baixa da requisição de saque no Back-Office...")
				lRet := .F.
			EndIf
		EndIf

		If lRet .AND. !lConfCash

			//gravando copia da requisicao na base local
			If len(aRet) >= 8

				U57->(DbSetOrder(1))
				lRecLock := !U57->(DbSeek(xFilial("U57")+alltrim(aRet[4])))
				RecLock("U57", lRecLock)
					for nX := 1 to len(aRet[8])
						If U57->(FieldPos(aRet[8][nX][1])) > 0
							U57->&(aRet[8][nX][1]) := aRet[8][nX][2]
						EndIf
					next nX
					//Forço ficar no valor que tinha de saldo no credito
					U57->U57_VALSAQ := nVlrSqPre
				U57->(MsUnlock())

				U56->(DbSetOrder(1))
				lRecLock := !U56->(DbSeek(U57->(U57_FILIAL+U57_PREFIX+U57_CODIGO)))
				RecLock("U56", lRecLock)
					for nX := 1 to len(aRet[7])
						If U56->(FieldPos(aRet[7][nX][1])) > 0
							U56->&(aRet[7][nX][1]) := aRet[7][nX][2]
						EndIf
					next nX
				U56->(MsUnlock())
				
			EndIf

			//Impressão da requisição
			cDescrCx := "REQUISIÇÃO PRÉ-PAGA SAQUE (DEPÓSITO EM CONTA SAQUE)"
			U_TPDVR002( cCodCli, cLojCli, cPlaca, cCgcMot, cNomMot, nVlrSqPre, nDinheiro, nChTroco, cCodBar, aRet[2], aRet[3], cMotivo, cDescrCx )
			U_SetMsgRod("Requisição baixada com sucesso! Código: " + cCodBar )
		EndIf

		If !lRet
			oGetCod:SetFocus()
			If lHabTra
				DisarmTransaction()
			EndIf
		Else
			If !lConfCash
				If SuperGetMV("TP_ACTCHT",,.F.)
					If Len(aRetChq[02])>0 .and. !Empty(LjGetStation("IMPCHQ")) .AND. !Empty(LjGetStation("PORTCHQ"))
						If MsgYesNo("Deseja realizar a impressão dos cheques troco?","Atenção")
							//realiza a impressao dos cheques troco
							U_TPDVE07B(aRetChq[02],cCodCli,cLojCli)
						EndIf
					EndIf
				EndIf

				//limpa a tela
				U_TPDVA7CL()
			EndIf
		EndIf

		If lHabTra
			EndTran()
		EndIf

	ElseIf nTipoOper==2 //Pós-Paga

		cPrfU56 := U_TRETA32P()
		if !lConfCash
			cNumReq := U_GetU56Num() //GetSX8Num("U56","U56_CODIGO")
			//Segurança: enquanto encontrar a numeracao gerada, pega novo numero
			U56->(DbSetOrder(1)) //U56_FILIAL+U56_PREFIX+U56_CODIGO
			While U56->(DbSeek( xFilial("U56")+cPrfU56+cNumReq ))
				cNumReq := U_GetU56Num() //GetSX8Num("U56","U56_CODIGO")
			enddo
		endif
		If SA1->(FieldPos("A1_XCONDSA")) > 0
			cCondSaq := Posicione("SA1",1,xFilial("SA1")+cCodCli+cLojCli,"A1_XCONDSA")
		EndIf
		
		SA1->(DbSetOrder(1)) //volto indice 1 para validacoes de campos da U56

		If !Empty(cNumReq) .OR. lConfCash

			// Cabeçalho
			if !lConfCash
				aAdd( aCposCab, { 'U56_PREFIX'	, cPrfU56 	} )
				aAdd( aCposCab, { 'U56_CODIGO'	, cNumReq 		} )
			endif
			aAdd( aCposCab, { 'U56_TIPO'	, '2' 			} ) //2=Pos-Paga
			aAdd( aCposCab, { 'U56_CODCLI'	, cCliente 		, .F.} )
			aAdd( aCposCab, { 'U56_LOJA'	, cLojaCli 		, .F.} )
			aAdd( aCposCab, { 'U56_NOME'	, cNomCli 		, .F.} )
			aAdd( aCposCab, { 'U56_CONDSA'  , cCondSaq      } )
			aAdd( aCposCab, { 'U56_FILAUT'	, cFilAut		} )
			aAdd( aCposCab, { 'U56_REQUIS'	, cRequisit 	} )
			aAdd( aCposCab, { 'U56_CARGO'	, cCargo 		} )
			aAdd( aCposCab, { 'U56_TOTAL'	, nValorSq 		} )

			//Itens
			aAux := {}
			aAdd( aAux, { 'U57_PARCEL'	, PadL('1',TamSx3("U57_PARCEL")[1],'0')} )
			aAdd( aAux, { 'U57_VALOR'	, nValorSq     	} )
			aAdd( aAux, { 'U57_VALSAQ'	, nValorSq     	} )
			aAdd( aAux, { 'U57_TUSO' 	, 'S'         	} )
			aAdd( aAux, { 'U57_MOTORI'	, cCgcMot     	} )
			aAdd( aAux, { 'U57_PLACA'	, cPlaca   		} )
			aAdd( aAux, { 'U57_XOPERA'	, cBanco	    } )
			aAdd( aAux, { 'U57_XGERAF'	, 'P'		   	} )
			aAdd( aAux, { 'U57_FILSAQ'	, cFilAnt       } )
			aAdd( aAux, { 'U57_MOTIVO'	, PadR(cMotivo,TamSx3("U57_MOTIVO")[1]) } )
			aAdd( aAux, { 'U57_XPDV'	, PadR(aStation[4],TamSx3("U57_XPDV")[1]) } )
			aAdd( aAux, { 'U57_XESTAC'	, PadR(aStation[2],TamSx3("U57_XESTAC")[1]) } )
			aAdd( aAux, { 'U57_XNUMMO'	, PadR(cNumMov,TamSx3("U57_XNUMMO")[1]) } )
			aAdd( aAux, { 'U57_DATAMO'	, dDataBase		} )
			If lConfCash
				aAdd( aAux, { 'U57_XHORA'	, SubStr(SLW->LW_HRABERT,1,TamSx3("U57_XHORA")[1]) } )
			Else
				aAdd( aAux, { 'U57_XHORA'	, SubStr(Time(),1,TamSx3("U57_XHORA")[1]) } )
			EndIf

			//Grava Vendedor
			If U57->(FieldPos("U57_VEND")) > 0
				aAdd( aAux, { 'U57_VEND' , cVendedor } )
			EndIf

			//Grava Nome Motorista
			If U57->(FieldPos("U57_NOMMOT")) > 0
				aAdd( aAux, { 'U57_NOMMOT' , cNomMot } )
			EndIf

			aAdd( aCposDet, aAux )

			//If ValInc(nValorSq) //TODO  - Valida Saldos de Credito para utilizacao das Requisições POS PAGA (alçadas)

			If U_GravaReq( 'U56', 'U57', aCposCab, aCposDet )

				CursorArrow() //como a tela do cheque troco desabilita o cursorwait, ativo novamente, pqe ainda tem coisas processando...

				If !lConfCash .AND. SuperGetMV("TP_ACTCHT",,.F.)
					//seleção de cheque troco
					cCodBar 	:= AllTrim(U57->U57_PREFIX + U57->U57_CODIGO + U57->U57_PARCEL)
					cDoc		:= SubStr(U56->U56_PREFIX,1,1) + U56->U56_CODIGO
					aRetChq 	:= {}
					aRetChq 	:= U_TPDVE007(nValorSq,{cDoc, cSerie, cCodBar, cCliente, cLojaCli, /*cNaturez*/, aStation[4]/*cPDV*/}) //rotina de selecao de cheque troco
					nDinheiro	:= aRetChq[01]
				Else
					nDinheiro := nValorSq //quando conferencia nao inclui o cheque troco agora
				EndIf

				CursorWait()

				nChTroco := nValorSq - nDinheiro

				If nChTroco > 0
					Reclock("U57",.F.)
					U57->U57_CHTROC := nChTroco
					U57->(MsUnLock())
				EndIf

				If !lConfCash

					if SuperGetMv("ES_ALCADA",.F.,.F.) .AND. !empty(aLogAlcada) 
						for nX := 1 to len(aLogAlcada)
							U_TR037LOG(aLogAlcada[nX][1], aLogAlcada[nX][2], U57->(U57_FILIAL+U57_PREFIX+U57_CODIGO+U57_PARCEL) , aLogAlcada[nX][3])
						next nX
					endif

					U_UREPLICA("U56", 1, U56->(U56_FILIAL+U56_PREFIX+U56_CODIGO), "A")
					U_UREPLICA("U57", 1, U57->(U57_FILIAL+U57_PREFIX+U57_CODIGO+U57_PARCEL), "A")

					//impressao do cupom nao fiscal
					cDescrCx := ""
					If U56->U56_TIPO == '1' .and. U57->U57_TUSO == 'C'
						cDescrCx := "REQUISIÇÃO PRÉ-PAGA CONSUMO (DEPÓSITO EM CONTA CONSUMO)"
					ElseIf U56->U56_TIPO == '2' .and. U57->U57_TUSO == 'C'
						cDescrCx := "REQUISIÇÃO PÓS-PAGA CONSUMO"
					ElseIf U56->U56_TIPO == '1' .and. U57->U57_TUSO == 'S'
						cDescrCx := "REQUISIÇÃO PRÉ-PAGA SAQUE (DEPÓSITO EM CONTA SAQUE)"
					ElseIf U56->U56_TIPO == '2' .and. U57->U57_TUSO == 'S'
						cDescrCx := "REQUISIÇÃO PÓS-PAGA SAQUE (VALE MOTORISTA)"
					EndIf

					//impressão da requisição
					U_TPDVR002( cCodCli, cLojCli, cPlaca, cCgcMot, cNomMot, nValorSq, nDinheiro, nChTroco, cCodBar, cRequisit, cCargo, cMotivo, cDescrCx )

					U_SetMsgRod("Requisição incluida com sucesso! Código: " + cCodBar )

					//limpa a tela
					U_TPDVA7CL()
				EndIf
			Else
				lRet := .F.
			EndIf
		EndIf
		//EndIf

	EndIf

	RestArea( aAreaSA6 )
	RestArea( aArea )

Return lRet

//-------------------------------------------------------
// Busca crédito de cliente na retaguarda
//-------------------------------------------------------
Static Function FindCredCl()
	Local aParam    := {}  // Array de parametros
	Local cCliente  := cCodCli
	Local cLojaCli  := cLojCli
	Local cBusca    := cGetCod
	Local lSaque    := .T. //creditos para saque
	Local lRet		:= .T.

	aNCCsReq := Nil // Resultado generico

	If !Empty(cBusca) .and. VldIncSaq(.F.)

		If lConfCash
			aNCCsReq := U_TPDVE006(cCliente, cLojaCli, cBusca, lSaque, cPlaca, cCgcMot, lConfCash)
		Else
			U_SetMsgRod("Pesquisando crédito do cliente. Aguarde...")
			CursorArrow()
			CursorWait()

			aParam := {cCliente, cLojaCli, cBusca, lSaque, cPlaca, cCgcMot} //(cCliente, cLojaCli, cBusca, lSaque, cPlaca, cCPFMotor)
			aParam := {"U_TPDVE006",aParam}
			If !STBRemoteExecute("_EXEC_RET",aParam,,,@aNCCsReq)
				// Tratamento do erro de conexao
				U_SetMsgRod("Falha de comunicação com o Back-Office...")
				lRet := .F.

			ElseIf aNCCsReq == Nil .OR. Empty(aNCCsReq) .or. valtype(aNCCsReq)<>"A" .or. Len(aNCCsReq) == 0 .OR. valtype(aNCCsReq[1])<>"A" .OR. Len(aNCCsReq[1]) < 15
				// Tratamento para retorno vazio
				U_SetMsgRod("Nota de Crédito não encontrada ou já utilizada!")
				lRet := .F.

			ElseIf Len(aNCCsReq) > 0
				U_SetMsgRod("Foram encontrados"+" "+AllTrim(Str(Len(aNCCsReq)))+" "+"créditos.")

			EndIf
			CursorArrow()
		EndIf

	EndIf

	if lRet
		AtuaListCred()
	endif

Return .T.

//-------------------------------------------------------------------
// Função que faz a atualização do listbox dos creditos: oListGdNcc
//-------------------------------------------------------------------
Static Function AtuaListCred()

	Local nX := 0
	Local aListNcc := {}
	//Local nBkp := oListGdNcc:nAt

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
	If aNCCsReq <> Nil
		For nX:=1 to Len(aNCCsReq)
			//R$ SALDO / TIPO / PREFIXO / NUM / PARCELA / EMISSAO / CODBAR / FILIAL
			aadd(aListNcc,;
			'R$ '+Alltrim(Transform(aNCCsReq[nX][2],PesqPict("SL1","L1_VLRLIQ")))+' / '+;
			AllTrim(aNCCsReq[nX][11])+' / '+;
			AllTrim(aNCCsReq[nX][9])+' / '+;
			AllTrim(aNCCsReq[nX][3])+' / '+;
			AllTrim(aNCCsReq[nX][10])+' / '+;
			DtoC(aNCCsReq[nX][4])+' / '+;
			AllTrim(aNCCsReq[nX][15])+' / '+;
			AllTrim(aNCCsReq[nX][14]);
			)
		Next nX
	EndIf
	oListGdNcc:SetItems(aListNcc)

Return

//-------------------------------------------------------------------
// Carrega o valor do credito selecionado
//-------------------------------------------------------------------
Static Function LoadSelNcc()

	If Empty(oListGdNcc:GetSelText()) //se nao achou negociação, cancelo a tela
		//U_SetMsgRod("Nenhum crédito encontrado!")
		nVlrSqPre := 0
	Else
		If oListGdNcc:nAt > 0 .and. aNCCsReq <> Nil .and. Len(aNCCsReq) >= oListGdNcc:nAt
			nVlrSqPre := aNCCsReq[oListGdNcc:nAt][2]
		Else
			nVlrSqPre := 0
		EndIf
	EndIf

	oVlrSqPre:Refresh()

Return .T.

//-------------------------------------------------------------------
// Incluir requisição POS-PAGA
//-------------------------------------------------------------------
User Function GravaReq(  cMaster, cDetail, aCpoMaster, aCpoDetail )
	Local  oModel, oAux, oStruct
	Local  nI        := 0
	Local  nJ        := 0
	Local  nPos      := 0
	Local  lRet      := .T.
	Local  aAux	     := {}
	Local  nItErro   := 0
	Local  lAux      := .T.

	//Private aDataModel := {}
	Private INCLUI := .T.
	Private ALTERA := .F.

	dbSelectArea( cDetail )
	dbSetOrder( 1 )

	dbSelectArea( cMaster )
	dbSetOrder( 1 )

	// Aqui ocorre o instanciamento do modelo de dados (Model)
	oModel := FWLoadModel( 'TRETA032' )

	// Temos que definir qual a operação deseja: 3 – Inclusão / 4 – Alteração / 5 - Exclusão
	oModel:SetOperation( MODEL_OPERATION_INSERT )

	// Antes de atribuirmos os valores dos campos temos que ativar o modelo
	// Se o Modelo nao puder ser ativado, talvez por uma regra de ativacao
	// o retorno sera .F.
	lRet := oModel:Activate()

	If lRet

		// Instanciamos apenas a parte do modelo referente aos dados de cabeçalho
		oAux    := oModel:GetModel( cMaster + 'MASTER' )

		// Obtemos a estrutura de dados do cabeçalho
		oStruct := oAux:GetStruct()
		aAux	:= oStruct:GetFields()

		If lRet
			For nI := 1 To Len( aCpoMaster )

				// Verifica se os campos passados existem na estrutura do cabeçalho
				If ( nPos := aScan( aAux, { |x| AllTrim( x[3] ) ==  AllTrim( aCpoMaster[nI][1] ) } ) ) > 0

					// È feita a atribuicao do dado aos campo do Model do cabeçalho
					//verifico se irá fazer as validações de campo ou não
					If len(aCpoMaster[nI]) >= 3 .AND. valtype(aCpoMaster[nI][3])=="L" .AND. !aCpoMaster[nI][3]  
						oModel:LoadValue( cMaster + 'MASTER', aCpoMaster[nI][1], aCpoMaster[nI][2] ) 
					Else
						If !( lAux := oModel:SetValue( cMaster + 'MASTER', aCpoMaster[nI][1], aCpoMaster[nI][2] ) )

							// Caso a atribuição não possa ser feita, por algum motivo (validação, por exemplo)
							// o método SetValue retorna .F.
							lRet    := .F.
							Exit

						EndIf
					Endif
				EndIf
			Next
		EndIf
	EndIf

	If lRet
		// Intanciamos apenas a parte do modelo referente aos dados do item
		oAux     := oModel:GetModel( cDetail + 'DETAIL' )

		// Obtemos a estrutura de dados do item
		oStruct  := oAux:GetStruct()
		aAux	 := oStruct:GetFields()

		nItErro  := 0

		For nI := 1 To Len( aCpoDetail )
			// Incluímos uma linha nova
			// ATENCAO: O itens são criados em uma estrura de grid (FORMGRID), portanto já é criada uma primeira linha
			//branco automaticamente, desta forma começamos a inserir novas linhas a partir da 2ª vez

			If nI > 1

				// Incluimos uma nova linha de item

				If  ( nItErro := oAux:AddLine() ) <> nI

					// Se por algum motivo o metodo AddLine() não consegue incluir a linha,
					// ele retorna a quantidade de linhas já
					// existem no grid. Se conseguir retorna a quantidade mais 1
					lRet    := .F.
					Exit

				EndIf

			EndIf

			For nJ := 1 To Len( aCpoDetail[nI] )

				// Verifica se os campos passados existem na estrutura de item
				If ( nPos := aScan( aAux, { |x| AllTrim( x[3] ) ==  AllTrim( aCpoDetail[nI][nJ][1] ) } ) ) > 0

					If !( lAux := oModel:SetValue( cDetail + 'DETAIL', aCpoDetail[nI][nJ][1], aCpoDetail[nI][nJ][2] ) )

						// Caso a atribuição não possa ser feita, por algum motivo (validação, por exemplo)
						// o método SetValue retorna .F.
						lRet    := .F.
						nItErro := nI
						Exit

					EndIf
				EndIf
			Next

			If !lRet
				Exit
			EndIf

		Next

	EndIf

	If lRet

		// Faz-se a validação dos dados, note que diferentemente das tradicionais "rotinas automáticas"
		// neste momento os dados não são gravados, são somente validados.
		If ( lRet := oModel:VldData() )

			// Se o dados foram validados faz-se a gravação efetiva dos dados (commit)
			lRet := oModel:CommitData()

		EndIf
	EndIf

	If !lRet

		// Se os dados não foram validados obtemos a descrição do erro para gerar LOG ou mensagem de aviso
		aErro   := oModel:GetErrorMessage()

		// A estrutura do vetor com erro é:
		//  [1] Id do formulário de origem
		//  [2] Id do campo de origem
		//  [3] Id do formulário de erro
		//  [4] Id do campo de erro
		//  [5] Id do erro
		//  [6] mensagem do erro
		//  [7] mensagem da solução
		//  [8] Valor atribuido
		//  [9] Valor anterior

		AutoGrLog( "Id do formulário de origem:" + ' [' + AllToChar( aErro[1]  ) + ']' )
		AutoGrLog( "Id do campo de origem:     " + ' [' + AllToChar( aErro[2]  ) + ']' )
		AutoGrLog( "Id do formulário de erro:  " + ' [' + AllToChar( aErro[3]  ) + ']' )
		AutoGrLog( "Id do campo de erro:       " + ' [' + AllToChar( aErro[4]  ) + ']' )
		AutoGrLog( "Id do erro:                " + ' [' + AllToChar( aErro[5]  ) + ']' )
		AutoGrLog( "Mensagem do erro:          " + ' [' + AllToChar( aErro[6]  ) + ']' )
		AutoGrLog( "Mensagem da solução:       " + ' [' + AllToChar( aErro[7]  ) + ']' )
		AutoGrLog( "Valor atribuido:           " + ' [' + AllToChar( aErro[8]  ) + ']' )
		AutoGrLog( "Valor anterior:            " + ' [' + AllToChar( aErro[9]  ) + ']' )

		If nItErro > 0
			AutoGrLog( "Erro no Item:              " + ' [' + AllTrim( AllToChar( nItErro  ) ) + ']' )
		EndIf

		MostraErro()

	EndIf

	// Desativamos o Model
	oModel:DeActivate()

Return lRet

//---------------------------------------------------------------------------
//Pega proxima numeração de requisição considerando o prefixo
//---------------------------------------------------------------------------
User Function GetU56Num()

	Local cRet := ""
	//Local uResult := Nil
	Local aStation := STBInfoEst( 1, .T. ) // [1]-CAIXA [2]-ESTACAO [3]-SERIE [4]-PDV [5]-LG_SERNFIS

	//altero na central PDV
	/*
	aParam := {"U56","U56_CODIGO"}
	aParam := {"U_TPGETNUM",aParam}
	If FWHostPing() .AND. STBRemoteExecute("_EXEC_CEN",aParam,NIL,.T.,@uResult)
		If valType(uResult) == "C"
			cRet := uResult
		Else
			U_SetMsgRod("Falha ao buscar numeração para requisição! #2" )
		EndIf
	Else
		U_SetMsgRod("Falha ao buscar numeração para requisição! #1" )
	EndIf
	*/

	//U56_CODIGO (tamanho 8): LG_CODIGO (tamanho 3) + AA1_FUNCAO (tamanho 5)
	DbSelectArea("AA1") //AA1 - Atendentes
	cRet := GETSXENUM("AA1", "AA1_FUNCAO", "AA1_FUNCAO"+cFilAnt)
	ConfirmSx8()

	cRet := aStation[2] + cRet

Return cRet

//-----------------------------------------------------------------------------------------
// Monta grid NewGetDados de Estorno
//-----------------------------------------------------------------------------------------
Static Function MsNewGetEst(oPnl, nTop, nLeft, nBottom, nRight)

	Local aHeaderEx 	:= {}
	Local aColsEx 		:= {}
	Local aAlterFields 	:= {}
	Local aFields 		:= {"U57_PREFIX","U57_CODIGO","U57_PARCEL","U56_TIPO","U57_VALOR","U57_VALSAQ","U57_CHTROC","U57_DATAMO","U57_XHORA","A1_NOME","U57_PLACA","U57_MOTORI","U56_REQUIS","U56_CARGO","U57_MOTIVO","U57_XPDV","U57_XNUMMO","U56_CODCLI","U56_LOJA"}
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

	Aadd(aFieldFill, 0) //recno
	Aadd(aFieldFill, .F.)
	Aadd(aColsEx, aFieldFill)

Return MsNewGetDados():New( nTop, nLeft, nBottom, nRight, , "AllwaysTrue", "AllwaysTrue", "+Field1+Field2", aAlterFields,, 999,;
"AllwaysTrue", "", "AllwaysTrue", oPnl, aHeaderEx, aColsEx)


//----------------------------------------------------------
// Busca as requisições de acordo com filtros, brwose
//----------------------------------------------------------
Static Function BuscaSaq()

	Local cCondicao		:= ""
	Local bCondicao
	Local nX
	Local aLinTemp 		:= {}

	If Empty(dBuscaDt)
		U_SetMsgRod("Informe uma data para a busca!")
		Return
	EndIf

	oMsGetSaq:acols := {}

	//U_SetMsgRod("Buscando requisições PRÉ-PAGA (Back-Office). Aguarde...")

	//CursorArrow()
	//CursorWait()

	//aRet := {}
	//aParam := {cBuscaSaq, dBuscaDt, cBuscaCod, cBuscaLoj, cBuscaPlaca, LJGetStation("LG_PDV")}
	//aParam := {"U_TPDVA07A",aParam}
	//If !STBRemoteExecute("_EXEC_RET",aParam,,,@aRet)
	//	// Tratamento do erro de conexao
	//	U_SetMsgRod("Falha de comunicação com o Back-Office...")
	//
	//ElseIf aRet = Nil .or. Empty(aRet) .or. Len(aRet) == 0
	//	// Tratamento para retorno vazio
	//	U_SetMsgRod("Nenhuma requisição PRÉ-PAGA encontrada!")
	//
	//ElseIf Len(aRet) > 0
	//	U_SetMsgRod("Foram encontrados"+" "+AllTrim(Str(Len(aRet)))+" "+"requisições PRÉ-PAGA(s).")
	//	For nX:=1 to Len(aRet)
	//		aadd(oMsGetSaq:aCols,aClone(aRet[nX]))
	//	Next nX
	//	
	//EndIf

	CursorArrow()

	U_SetMsgRod("Buscando requisições PÓS-PAGA (PDV)...")

	cCondicao := " U57_FILIAL = '" + xFilial("U57") + "'"
	cCondicao += " .AND. U57_DATAMO == STOD('" + DTOS(dBuscaDt) + "')"
	cCondicao += " .AND. U57_XPDV == '" + PadR(LJGetStation("LG_PDV"),TamSx3("U57_XPDV")[1]) + "'"
	If !Empty(cBuscaSaq)
		cCondicao += " .AND. '" + alltrim(cBuscaSaq) + "' $ U57_PREFIX+U57_CODIGO+U57_PARCEL "
	EndIf
	If !Empty(cBuscaPlaca)
		cCondicao += " .AND. (Empty(U57_PLACA) .OR. U57_PLACA = '" + cBuscaPlaca + "')"
	EndIf

	// limpo os filtros da U57
	U57->(DbClearFilter())

	// executo o filtro na U57
	bCondicao 	:= "{|| " + cCondicao + " }"
	U57->(DbSetFilter(&bCondicao,cCondicao))

	// vou para a primeira linha
	U57->(DbGoTop())

	U56->(DbSetOrder(1)) //U56_FILIAL+U56_PREFIX+U56_CODIGO
	SA1->(DbSetOrder(1)) //A1_FILIAL+A1_COD+A1_LOJA

	//{"U57_PREFIX","U57_CODIGO","U57_PARCEL","U56_TIPO","U57_VALOR","U57_VALSAQ","U57_CHTROC","U57_DATAMO","U57_XHORA","A1_NOME","U57_PLACA","U57_MOTORI","U56_REQUIS","U56_CARGO","U57_MOTIVO","U57_XPDV","U57_XNUMMO","U56_CODCLI","U56_LOJA"}
	While U57->(!Eof())

		//Posicione("U56",1,xFilial("U56")+U57->(U57_PREFIX+U57_CODIGO),"U56_TIPO")		
		U56->(DbSeek(U57->(U57_FILIAL+U57_PREFIX+U57_CODIGO)))

		//Posicione("SA1",1,xFilial("SA1")+U56->U56_CODCLI+U56->U56_LOJA,"A1_COD")
		SA1->(DbSeek(xFilial("SA1")+U56->U56_CODCLI+U56->U56_LOJA))

		If !Empty(cBuscaCod) .and. AllTrim(cBuscaCod) <> AllTrim(SA1->A1_COD)
			U57->( DbSkip() )
			Loop
		EndIf

		If !Empty(cBuscaLoj) .and. AllTrim(cBuscaLoj) <> AllTrim(SA1->A1_LOJA)
			U57->( DbSkip() )
			Loop
		EndIf

		aLinTemp := {}
		For nX := 1 to len(oMsGetSaq:aHeader)
			If (oMsGetSaq:aHeader[nX][2]=="LEGENDA")
				Aadd(aLinTemp, iif(U57->U57_XGERAF=="X","BR_PRETO","BR_VERDE") )
			ElseIf Left(oMsGetSaq:aHeader[nX][2],3)=="U57"
				Aadd(aLinTemp, U57->&(oMsGetSaq:aHeader[nX][2]) )
			ElseIf Left(oMsGetSaq:aHeader[nX][2],3)=="U56"
				Aadd(aLinTemp, U56->&(oMsGetSaq:aHeader[nX][2]) )
			Else
				Aadd(aLinTemp, SA1->&(oMsGetSaq:aHeader[nX][2]) )
			EndIf
		next nX

		Aadd(aLinTemp, U57->(RecNo())) //recno
		Aadd(aLinTemp, .F.) //deleted
		aadd(oMsGetSaq:aCols,aClone(aLinTemp))

		U57->( DbSkip() )
	EndDo

	// limpo os filtros da U57
	U57->(DbClearFilter())

	nQtdReg := Len(oMsGetSaq:acols)
	If nQtdReg == 0
		ClearGrid(oMsGetSaq)
	EndIf

	oMsGetSaq:oBrowse:Refresh()
	oQtdReg:Refresh()
	U_SetMsgRod("")
	oMsGetSaq:oBrowse:SetFocus()

Return

//------------------------------------------------------
// função que faz limpeza do grid.
//------------------------------------------------------
Static Function ClearGrid(oGrid)

	Local nX := 0
	Local aFieldFill := {}

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

	Aadd(aFieldFill, 0) //recno
	Aadd(aFieldFill, .F.)

	aadd(oGrid:aCols, aFieldFill)

	oGrid:oBrowse:Refresh()

Return

//----------------------------------------------------------
// Busca requisições PRE-PAGA na retaguarda...
//----------------------------------------------------------
User Function TPDVA07A(cBuscaSaq, dBuscaDt, cBuscaCod, cBuscaLoj, cBuscaPlaca, cPDV)

	Local cCondicao		:= ""
	Local bCondicao
	Local nX
	Local aLinTemp 		:= {}
	Local aLinTemps		:= {}

	cCondicao := " U57_FILIAL = '" + xFilial("U57") + "'"
	cCondicao += " .AND. U57_DATAMO == STOD('" + DTOS(dBuscaDt) + "')"
	cCondicao += " .AND. U57_XPDV == '" + PadR(cPDV,TamSx3("U57_XPDV")[1]) + "'"
	If !Empty(cBuscaSaq)
		cCondicao += " .AND. '" + alltrim(cBuscaSaq) + "' $ U57_PREFIX+U57_CODIGO+U57_PARCEL "
	EndIf
	If !Empty(cBuscaPlaca)
		cCondicao += " .AND. (Empty(U57_PLACA) .OR. U57_PLACA = '" + cBuscaPlaca + "')"
	EndIf

	// limpo os filtros da U57
	U57->(DbClearFilter())

	// executo o filtro na U57
	bCondicao 	:= "{|| " + cCondicao + " }"
	U57->(DbSetFilter(&bCondicao,cCondicao))

	// vou para a primeira linha
	U57->(DbGoTop())

	U56->(DbSetOrder(1)) //U56_FILIAL+U56_PREFIX+U56_CODIGO
	SA1->(DbSetOrder(1)) //A1_FILIAL+A1_COD+A1_LOJA

	aHeader := {"U57_PREFIX","U57_CODIGO","U57_PARCEL","U56_TIPO","U57_VALOR","U57_VALSAQ","U57_CHTROC","U57_DATAMO","U57_XHORA","A1_NOME","U57_PLACA","U57_MOTORI","U56_REQUIS","U56_CARGO","U57_MOTIVO","U57_XPDV","U57_XNUMMO","U56_CODCLI","U56_LOJA"}
	While U57->(!Eof())

		//Posicione("U56",1,xFilial("U56")+U57->(U57_PREFIX+U57_CODIGO),"U56_TIPO")		
		U56->(DbSeek(U57->(U57_FILIAL+U57_PREFIX+U57_CODIGO)))

		//Posicione("SA1",1,xFilial("SA1")+U56->U56_CODCLI+U56->U56_LOJA,"A1_COD")
		SA1->(DbSeek(xFilial("SA1")+U56->U56_CODCLI+U56->U56_LOJA))

		If U56->U56_TIPO = "2"; //2=PÓS-PAGA (lista apenas requisições PRÉ-PAGA)
			.or. (!Empty(cBuscaCod) .and. AllTrim(cBuscaCod) <> AllTrim(SA1->A1_COD))
			U57->( DbSkip() )
			Loop
		EndIf

		aLinTemp := {}
		Aadd(aLinTemp, iif(U57->U57_XGERAF=="X","BR_PRETO","BR_VERDE") )
		For nX := 1 to len(aHeader)
			If Left(aHeader[nX],3)=="U57"
				Aadd(aLinTemp, U57->&(aHeader[nX]) )
			ElseIf Left(aHeader[nX],3)=="U56"
				Aadd(aLinTemp, U56->&(aHeader[nX]) )
			Else
				Aadd(aLinTemp, SA1->&(aHeader[nX]) )
			EndIf
		Next nX

		Aadd(aLinTemp, U57->(RecNo())) //recno
		Aadd(aLinTemp, .F.) //deleted
		aadd(aLinTemps,aClone(aLinTemp))

		U57->( DbSkip() )
	EndDo

	// limpo os filtros da U57
	U57->(DbClearFilter())

Return aLinTemps

//-----------------------------------------------------------------------------------------
// Faz validação e o processamento do estorno
//-----------------------------------------------------------------------------------------
Static Function DoEstorno()

	Local lRet := .T.
	Local nX
	Local nPosTipo := aScan(oMsGetSaq:aHeader,{|x| AllTrim(x[2])=="U56_TIPO"})

	If oMsGetSaq:nAt <= 0 .or. !(oMsGetSaq:acols[oMsGetSaq:nAt][Len(oMsGetSaq:aHeader)+1] > 0)
		U_SetMsgRod("Selecione a requisição a ser estornada!")
		Return .F.

	EndIf

	If oMsGetSaq:aCols[oMsGetSaq:nAt][1] == "BR_PRETO"
		U_SetMsgRod("Requisição já estornada!")
		Return .F.

	EndIf

	If !(oMsGetSaq:aCols[oMsGetSaq:nAt][aScan(oMsGetSaq:aHeader,{|x| AllTrim(x[2])=="U57_XNUMMO"})] = PadR(LjNumMov(),TamSx3("U57_XNUMMO")[1]) .and. ;
	oMsGetSaq:aCols[oMsGetSaq:nAt][aScan(oMsGetSaq:aHeader,{|x| AllTrim(x[2])=="U57_DATAMO"})] = dDataBase)
		U_SetMsgRod("Requisição não pertence ao caixa em operação!")
		Return .F.

	EndIf

	//tenta estornar a requisição pré-paga online no back-office
	If oMsGetSaq:acols[oMsGetSaq:nAt][nPosTipo] == "1" //1-PRÉ-PAGO

		U_SetMsgRod("Realizando o estorno de requisição PRÉ-PAGA (Back-Office). Aguarde...")

		CursorArrow()
		CursorWait()

		lRet := Nil

		nRecNo := oMsGetSaq:acols[oMsGetSaq:nAt][Len(oMsGetSaq:aHeader)+1]
		U57->(DbGoTo(nRecNo))
		aParam := { U57->(U57_FILIAL+U57_PREFIX+U57_CODIGO+U57_PARCEL) }
		aParam := {"U_TPDVA07B",aParam}
		If !STBRemoteExecute("_EXEC_RET",aParam,,,@lRet)
			// Tratamento do erro de conexao
			U_SetMsgRod("Falha de comunicação com o Back-Office...")

		ElseIf lRet = Nil .or. !lRet
			// Tratamento para retorno vazio
			U_SetMsgRod("Ocorreu falha no estorno da requisição PRÉ-PAGA no Back-Office!")

		ElseIf lRet

		EndIf

		If lRet

			//marca como estornado o registro da base local
			U57->(DbGoTo(oMsGetSaq:acols[oMsGetSaq:nAt][Len(oMsGetSaq:aHeader)+1]))
			If U57->(!Eof())

				Reclock("U57", .F.)
					U57->U57_XGERAF := 'X'
					U57->U57_FILSAQ := cFilAnt
				U57->(MsUnlock())

				oMsGetSaq:aCols[oMsGetSaq:nAt][1] := "BR_PRETO"

			EndIf
		
		EndIf

		CursorArrow()

	EndIf

	//realiza o estorno da requisição pos-paga e tbm da requisição pre-paga caso ocorra falha no estorno online
	If !(oMsGetSaq:aCols[oMsGetSaq:nAt][1] == "BR_PRETO")

		U57->(DbGoTo(oMsGetSaq:acols[oMsGetSaq:nAt][Len(oMsGetSaq:aHeader)+1]))

		U56->(DbSetOrder(1)) //U56_FILIAL+U56_PREFIX+U56_CODIGO
		U56->(DbSeek(U57->(U57_FILIAL+U57_PREFIX+U57_CODIGO)))
		
		If U57->(!Eof()) .and. U56->(!Eof())

			Reclock("U57", .F.)
				U57->U57_XGERAF := 'X'
				U57->U57_FILSAQ := cFilAnt
			U57->(MsUnlock())

			//enviando dados para retaguarda
			U_UREPLICA("U56", 1, U56->(U56_FILIAL+U56_PREFIX+U56_CODIGO), "A")
			U_UREPLICA("U57", 1, U57->(U57_FILIAL+U57_PREFIX+U57_CODIGO+U57_PARCEL), "A")

			oMsGetSaq:aCols[oMsGetSaq:nAt][1] := "BR_PRETO"

		EndIf

	EndIf

	//impressao do cupom nao fiscal do cancelamento do saque
	If oMsGetSaq:aCols[oMsGetSaq:nAt][1] = "BR_PRETO"

		_cCodCli	:= oMsGetSaq:aCols[oMsGetSaq:nAt][aScan(oMsGetSaq:aHeader,{|x| AllTrim(x[2])=="U56_CODCLI"})]
		_cLojCli	:= oMsGetSaq:aCols[oMsGetSaq:nAt][aScan(oMsGetSaq:aHeader,{|x| AllTrim(x[2])=="U56_LOJA"})]
		_cPlaca 	:= oMsGetSaq:aCols[oMsGetSaq:nAt][aScan(oMsGetSaq:aHeader,{|x| AllTrim(x[2])=="U57_PLACA"})]
		_cCgcMot 	:= oMsGetSaq:aCols[oMsGetSaq:nAt][aScan(oMsGetSaq:aHeader,{|x| AllTrim(x[2])=="U57_MOTORI"})]
		_nVale 		:= oMsGetSaq:aCols[oMsGetSaq:nAt][aScan(oMsGetSaq:aHeader,{|x| AllTrim(x[2])=="U57_VALSAQ"})]
		_nDinheiro 	:= oMsGetSaq:aCols[oMsGetSaq:nAt][aScan(oMsGetSaq:aHeader,{|x| AllTrim(x[2])=="U57_VALSAQ"})] - oMsGetSaq:aCols[oMsGetSaq:nAt][aScan(oMsGetSaq:aHeader,{|x| AllTrim(x[2])=="U57_CHTROC"})]
		_nCheque 	:= oMsGetSaq:aCols[oMsGetSaq:nAt][aScan(oMsGetSaq:aHeader,{|x| AllTrim(x[2])=="U57_CHTROC"})]
		_cTitulo 	:= AllTrim(oMsGetSaq:aCols[oMsGetSaq:nAt][aScan(oMsGetSaq:aHeader,{|x| AllTrim(x[2])=="U57_PREFIX"})]+oMsGetSaq:aCols[oMsGetSaq:nAt][aScan(oMsGetSaq:aHeader,{|x| AllTrim(x[2])=="U57_CODIGO"})]+oMsGetSaq:aCols[oMsGetSaq:nAt][aScan(oMsGetSaq:aHeader,{|x| AllTrim(x[2])=="U57_PARCEL"})])
		_cRequis	:= oMsGetSaq:aCols[oMsGetSaq:nAt][aScan(oMsGetSaq:aHeader,{|x| AllTrim(x[2])=="U56_REQUIS"})]
		_cCargo		:= oMsGetSaq:aCols[oMsGetSaq:nAt][aScan(oMsGetSaq:aHeader,{|x| AllTrim(x[2])=="U56_CARGO"})]
		_cMotivo	:= oMsGetSaq:aCols[oMsGetSaq:nAt][aScan(oMsGetSaq:aHeader,{|x| AllTrim(x[2])=="U57_MOTIVO"})]

		If oMsGetSaq:acols[oMsGetSaq:nAt][nPosTipo] == "1" //1-PRE-PAGA
			_cTipoReq := "REQUISIÇÃO PRÉ-PAGA SAQUE (DEPÓSITO EM CONTA SAQUE)"
		Else
			_cTipoReq := "REQUISIÇÃO PÓS-PAGA SAQUE (VALE MOTORISTA)"
		EndIf

		U_TPDVR003( _cCodCli, _cLojCli, _cPlaca, _cCgcMot, _nVale, _nDinheiro, _nCheque, _cTitulo, _cRequis, _cCargo, _cMotivo, _cTipoReq )

		U_SetMsgRod("Requisição "+AllTrim(oMsGetSaq:aCols[oMsGetSaq:nAt][aScan(oMsGetSaq:aHeader,{|x| AllTrim(x[2])=="U57_PREFIX"})]+oMsGetSaq:aCols[oMsGetSaq:nAt][aScan(oMsGetSaq:aHeader,{|x| AllTrim(x[2])=="U57_CODIGO"})]+oMsGetSaq:aCols[oMsGetSaq:nAt][aScan(oMsGetSaq:aHeader,{|x| AllTrim(x[2])=="U57_PARCEL"})])+" estornada com sucesso!")

	EndIf

	//-- busca cheques troco do saque para liberá-lo no ambiente PDV
	If lRet <> Nil .and. lRet .and. !Empty(_cTitulo) .AND. SuperGetMV("TP_ACTCHT",,.F.)

		UF2->(DbSetOrder(4)) //UF2_FILIAL+UF2_CODBAR
		UF2->(DbSeek(xFilial("UF2")+_cTitulo))
		aRecUF2 := {}
		While !UF2->(Eof()) .and. UF2->UF2_FILIAL+UF2->UF2_CODBAR == xFilial("UF2")+_cTitulo
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

Return lRet

//------------------------------------------------------
// Realiza o estorno da requisição na retaguarda
//------------------------------------------------------
User Function TPDVA07B(cChaveU57)

	Local lRet := .F.

	DbSelectArea("U57")
	U57->(DbSetOrder(1))
	If U57->(DbSeek(xFilial("U57")+alltrim(cChaveU57)))
		If U57->U57_XGERAF <> "X"
			If Reclock("U57", .F.)

				U57->U57_XGERAF := 'X'
				U57->U57_FILSAQ := cFilAnt
				U57->(MsUnlock())

				lRet := .T.
			EndIf
		EndIf
	EndIf

Return lRet

//------------------------------------------------------
// Realiza a reimpressão de uma requisição
//------------------------------------------------------
Static Function ImpSaque()
	Local nPosTipo := aScan(oMsGetSaq:aHeader,{|x| AllTrim(x[2])=="U56_TIPO"})

	CursorArrow()
	CursorWait()

	If oMsGetSaq:nAt <= 0 .or. !(oMsGetSaq:acols[oMsGetSaq:nAt][Len(oMsGetSaq:aHeader)+1] > 0)
		U_SetMsgRod("Selecione a requisição a ser reimpressa!")
		Return .F.

	EndIf

	//impressao do cupom nao fiscal
	_cCodCli	:= oMsGetSaq:aCols[oMsGetSaq:nAt][aScan(oMsGetSaq:aHeader,{|x| AllTrim(x[2])=="U56_CODCLI"})]
	_cLojCli	:= oMsGetSaq:aCols[oMsGetSaq:nAt][aScan(oMsGetSaq:aHeader,{|x| AllTrim(x[2])=="U56_LOJA"})]
	_cPlaca 	:= oMsGetSaq:aCols[oMsGetSaq:nAt][aScan(oMsGetSaq:aHeader,{|x| AllTrim(x[2])=="U57_PLACA"})]
	_cCgcMot 	:= oMsGetSaq:aCols[oMsGetSaq:nAt][aScan(oMsGetSaq:aHeader,{|x| AllTrim(x[2])=="U57_MOTORI"})]
	_nVale 		:= oMsGetSaq:aCols[oMsGetSaq:nAt][aScan(oMsGetSaq:aHeader,{|x| AllTrim(x[2])=="U57_VALSAQ"})]
	_nDinheiro 	:= oMsGetSaq:aCols[oMsGetSaq:nAt][aScan(oMsGetSaq:aHeader,{|x| AllTrim(x[2])=="U57_VALSAQ"})] - oMsGetSaq:aCols[oMsGetSaq:nAt][aScan(oMsGetSaq:aHeader,{|x| AllTrim(x[2])=="U57_CHTROC"})]
	_nCheque 	:= oMsGetSaq:aCols[oMsGetSaq:nAt][aScan(oMsGetSaq:aHeader,{|x| AllTrim(x[2])=="U57_CHTROC"})]
	_cTitulo 	:= AllTrim(oMsGetSaq:aCols[oMsGetSaq:nAt][aScan(oMsGetSaq:aHeader,{|x| AllTrim(x[2])=="U57_PREFIX"})]+oMsGetSaq:aCols[oMsGetSaq:nAt][aScan(oMsGetSaq:aHeader,{|x| AllTrim(x[2])=="U57_CODIGO"})]+oMsGetSaq:aCols[oMsGetSaq:nAt][aScan(oMsGetSaq:aHeader,{|x| AllTrim(x[2])=="U57_PARCEL"})])
	_cRequis	:= oMsGetSaq:aCols[oMsGetSaq:nAt][aScan(oMsGetSaq:aHeader,{|x| AllTrim(x[2])=="U56_REQUIS"})]
	_cCargo		:= oMsGetSaq:aCols[oMsGetSaq:nAt][aScan(oMsGetSaq:aHeader,{|x| AllTrim(x[2])=="U56_CARGO"})]
	_cMotivo	:= oMsGetSaq:aCols[oMsGetSaq:nAt][aScan(oMsGetSaq:aHeader,{|x| AllTrim(x[2])=="U57_MOTIVO"})]

	If oMsGetSaq:acols[oMsGetSaq:nAt][nPosTipo] == "1" //1-PRE-PAGA
		_cTipoReq := "REQUISIÇÃO PRÉ-PAGA SAQUE (DEPÓSITO EM CONTA SAQUE)"
	Else
		_cTipoReq := "REQUISIÇÃO PÓS-PAGA SAQUE (VALE MOTORISTA)"
	EndIf

	If oMsGetSaq:aCols[oMsGetSaq:nAt][1] == "BR_PRETO"
		U_TPDVR003( _cCodCli, _cLojCli, _cPlaca, _cCgcMot, _nVale, _nDinheiro, _nCheque, _cTitulo, _cRequis, _cCargo, _cMotivo, _cTipoReq )
	Else
		U_TPDVR002( _cCodCli, _cLojCli, _cPlaca, _cCgcMot, "", _nVale, _nDinheiro, _nCheque, _cTitulo, _cRequis, _cCargo, _cMotivo, _cTipoReq )
	EndIf

	CursorArrow()

Return .T.

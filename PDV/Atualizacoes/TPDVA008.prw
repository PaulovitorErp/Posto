#include 'protheus.ch'
#include 'parmtype.ch'
#include 'poscss.ch'
#include "topconn.ch"
#include "TOTVS.CH"

Static cUsrDep := ""
Static oPnlGeral
Static oPnlInc
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
Static oBtnTpSaq, oBtnTpCon
Static nTipoOper := 1 //1-Saque;2-Consumo
Static oCgcMot
Static cCgcMot := Space(TamSX3("U57_MOTORI")[1])
Static oNomMot
Static cNomMot := Space(TamSX3("DA4_NOME")[1])
Static oFilAuto
Static cFilAuto := Space(TamSX3("U56_FILAUT")[1])
Static oGetCod
Static cGetCod := Space(40)
Static oRequisit
Static cRequisit := Space(TamSX3("U56_REQUIS")[1])
Static oCargo
Static cCargo := Space(TamSX3("U56_CARGO")[1])
Static oValorDp
Static nValorDp := 0
Static oBuscaDep
Static cBuscaDep := Space(TamSX3("U57_PREFIX")[1]+TamSX3("U57_CODIGO")[1]+TamSX3("U57_PARCEL")[1])
Static oBuscaDt
Static dBuscaDt := dDataBase
Static oBuscaCod
Static cBuscaCod := Space(TamSX3("A1_COD")[1])
Static oBuscaLoj
Static cBuscaLoj := Space(TamSX3("A1_LOJA")[1])
Static oBuscaPlaca
Static cBuscaPlaca := Space(TamSX3("U57_PLACA")[1])
Static oMsGetDep
Static oQtdReg
Static nQtdReg := 0
Static oObserv
Static cObserv := ""
Static lConfCash := .F.

/*/{Protheus.doc} TPDVA008
Depósito no PDV.

@author pablo
@since 03/06/2019
@version 1.0
@return ${return}, ${return_description}
@param oPnlPrinc, object, descricao
@type function
/*/
User Function TPDVA008(oPnlPrinc, _lConfCash, bConfirm, bCancel)

	Local nWidth, nHeight
	Local oPnlGrid2, oPnlAux2
	Local cCorBg := SuperGetMv("MV_LJCOLOR",,"07334C")// Cor da tela
	Local lMvPswVend := SuperGetMv("TP_PSWVEND",,.F.)
	Local lBlqAI0 	:= SuperGetMv("MV_XBLQAI0",,.F.) .AND. AI0->(FieldPos("AI0_XBLFIL")) > 0 //Habilita bloqueio de venda na filial, olhando para tabela AI0
	Local cFiltro	:= ""
	Default _lConfCash := .F.

	DbSelectArea("U56")
	DbSelectArea("U57")

	nWidth := oPnlPrinc:nWidth/2
	nHeight := oPnlPrinc:nHeight/2
	lConfCash := _lConfCash

	//verifica se o usuário tem permissão para acesso a rotina
	If !lConfCash
		U_TRETA37B("DEPPDV", "DEPOSITO NO PDV")
		cUsrDep := U_VLACESS1("DEPPDV", RetCodUsr())
		If cUsrDep == Nil .OR. Empty(cUsrDep)
			@ 020, 020 SAY oSay1 PROMPT "<h1>Ops!</h1><br>Seu usuário não tem permissão de acesso a rotina de Depósito. Entre em contato com o administrador do sistema." SIZE nWidth-40, 100 OF oPnlPrinc COLORS 0, 16777215 PIXEL HTML
			oSay1:SetCSS( POSCSS (GetClassName(oSay1), CSS_LABEL_FOCAL ))
			Return cUsrDep
		EndIf
	endif
	
	//@ 020, 020 SAY oSay1 PROMPT "<h1>Ops!</h1><br>Em desenvolvimento! Rotina ainda não disponível..." SIZE nWidth-40, 100 OF oPnlPrinc COLORS 0, 16777215 PIXEL HTML
	//oSay1:SetCSS( POSCSS (GetClassName(oSay1), CSS_LABEL_FOCAL ))

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

	//painel geral da tela de depósito (mesmo tamanho da principal)
	oPnlGeral := TPanel():New(000,000,"",oPnlPrinc,NIL,.T.,.F.,,,nWidth,nHeight,.T.,.F.)

	cTitleTela := "INCLUIR"
	@ 002, 002 SAY oSay1 PROMPT ("DEPÓSITO PDV - " + cTitleTela) SIZE nWidth-004, 015 OF oPnlGeral COLORS 0, 16777215 PIXEL CENTER
	oSay1:SetCSS( POSCSS (GetClassName(oSay1), CSS_BTN_FOCAL ))

	//////////////////////// PAINEL INCLUSÃO DE DEPÓSITO //////////////////////////////////////

	//Painel de Inclusão de Depósito
	oPnlInc := TPanel():New(020,000,"",oPnlGeral,NIL,.T.,.F.,,,nWidth,nHeight-020,,.T.,.F.)

	@ 005, 005 SAY oSay5 PROMPT "Placa" SIZE 100, 010 OF oPnlInc COLORS 0, 16777215 PIXEL
	oSay5:SetCSS( POSCSS (GetClassName(oSay5), CSS_LABEL_FOCAL ))
	oPlaca := TGet():New( 015, 005,{|u| iif( PCount()==0,cPlaca,cPlaca:=u) },oPnlInc,70, 013,"@!R NNN-9N99",{|| VldPlaca() },,,,,,.T.,,,{|| .T. },,,,.F.,.F.,,"cPlaca",,,,.T.,.F.)
	oPlaca:SetCSS( POSCSS (GetClassName(oPlaca), CSS_GET_NORMAL ))

	//@ 005, 080 SAY oSay3 PROMPT "CPF/CNPJ do Cliente" SIZE 100, 010 OF oPnlInc COLORS 0, 16777215 PIXEL
	//oSay3:SetCSS( POSCSS (GetClassName(oSay3), CSS_LABEL_FOCAL ))
	//oCgcCli := TGet():New( 015, 080,{|u| iif( PCount()==0,cCgcCli,cCgcCli:=u) },oPnlInc,80, 013, "@!",{|| VldCliente() },,,,,,.T.,,,{|| .T. },,,,.F.,.F.,,"cCgcCli",,,,.T.,.F.)
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
	oNomCli := TGet():New( 015, 165,{|u| iif( PCount()==0,cNomCli,cNomCli:=u)},oPnlInc,nWidth-175, 013, "@!",{|| .T. },,,,,,.T.,,,{|| .T. },,,,.T.,.F.,,"cNomCli",,,,.T.,.F.)
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
	oCgcMot := TGet():New( 045, 005,{|u| iif( PCount()==0,cCgcMot,cCgcMot:=u) },oPnlInc,70, 013,,{|| (Empty(cCgcMot) .OR. CGC(cCgcMot)) .AND. VldMotoris() },,,,,,.T.,,,{|| .T. },,,,.F.,.F.,,"cCgcMot",,,,.T.,.F.)
	oCgcMot:SetCSS( POSCSS (GetClassName(oCgcMot), CSS_GET_NORMAL ))
	TSearchF3():New(oCgcMot,400,250,"DA4","DA4_CGC",{{"DA4_NOME",2}},,{{"DA4_CGC","DA4_NOME"}},,,iif(lConfCash,-40,0))

	@ 035, 080 SAY oSay4 PROMPT "Nome Motorista" SIZE 070, 010 OF oPnlInc COLORS 0, 16777215 PIXEL
	oSay4:SetCSS( POSCSS (GetClassName(oSay4), CSS_LABEL_FOCAL ))
	oNomMot := TGet():New( 045, 080,{|u| iif( PCount()==0,cNomMot,cNomMot:=u)},oPnlInc,nWidth-205, 013, "@!",{|| .T./*bValid*/ },,,,,,.T.,,,{|| .T. },,,,.F.,.F.,,"cNomMot",,,,.T.,.F.)
	oNomMot:SetCSS( POSCSS (GetClassName(oNomMot), CSS_GET_NORMAL ))

	@ 035, nWidth-110 SAY oSay4 PROMPT "Tipo de Uso" SIZE 070, 010 OF oPnlInc COLORS 0, 16777215 PIXEL
	oSay4:SetCSS( POSCSS (GetClassName(oSay4), CSS_LABEL_FOCAL ))
	oBtnTpSaq := TButton():New(045,nWidth-110,"Saque", oPnlInc,{|| nTipoOper:=1, SetTipoSel(nTipoOper) },050,015,,,,.T.,,,,{|| .T. })
	oBtnTpCon := TButton():New(045,nWidth-060,"Consumo", oPnlInc,{|| nTipoOper:=2, SetTipoSel(nTipoOper) },050,015,,,,.T.,,,,{|| .T. })

	@ 065, 005 SAY oSay3 PROMPT "Vendedor" SIZE 100, 010 OF oPnlInc COLORS 0, 16777215 PIXEL
	oSay3:SetCSS( POSCSS (GetClassName(oSay3), CSS_LABEL_FOCAL ))
	oVendedor := TGet():New( 075, 005,{|u| iif( PCount()==0,cVendedor,cVendedor:=u) },oPnlInc,70, 013,,{|| VldVend() },,,,,,.T.,,,{|| .T. },,,,!lConfCash .AND. lMvPswVend,.F.,,"cVendedor",,,,.T.,.F.)
	oVendedor:SetCSS( POSCSS (GetClassName(oVendedor), CSS_GET_NORMAL ))
	if !lMvPswVend
		TSearchF3():New(oVendedor,400,180,"SA3","A3_COD",{{"A3_NOME",2}},"",,,,iif(lConfCash,-40,0))
	endif

	@ 065, 080 SAY oSay4 PROMPT "Nome Vendedor" SIZE 100, 010 OF oPnlInc COLORS 0, 16777215 PIXEL
	oSay4:SetCSS( POSCSS (GetClassName(oSay4), CSS_LABEL_FOCAL ))
	oNomVend := TGet():New( 075, 080,{|u| iif( PCount()==0,cNomVend,cNomVend:=u)},oPnlInc,nWidth-205, 013, "@!",{|| .T./*bValid*/ },,,,,,.T.,,,{|| .T. },,,,.T.,.F.,,"cNomVend",,,,.T.,.F.)
	oNomVend:SetCSS( POSCSS (GetClassName(oNomVend), CSS_GET_NORMAL ))
	oNomVend:lCanGotFocus := .F.

	@ 095, 005 SAY oSay3 PROMPT "Filiais Autorizadas" SIZE 100, 010 OF oPnlInc COLORS 0, 16777215 PIXEL
	oSay3:SetCSS( POSCSS (GetClassName(oSay3), CSS_LABEL_FOCAL ))
	oFilAuto := TGet():New( 105, 005,{|u| iif( PCount()==0,cFilAuto,cFilAuto:=u)},oPnlInc,nWidth-130, 013,,{|| .T./*bValid*/ },,,,,,.T.,,,{|| .T. },,,,.F.,.F.,"U56FIL","M->U56_FILAUT",,,,.T.,.F.)
	oFilAuto:SetCSS( POSCSS (GetClassName(oFilAuto), CSS_GET_NORMAL ))

	@ 125, 005 SAY oSay4 PROMPT "Requisitante" SIZE 070, 010 OF oPnlInc COLORS 0, 16777215 PIXEL
	oSay4:SetCSS( POSCSS (GetClassName(oSay4), CSS_LABEL_FOCAL ))
	oRequisit := TGet():New( 135, 005,{|u| iif( PCount()==0,cRequisit,cRequisit:=u)}, oPnlInc, nWidth-130, 013, PesqPict("U56","U56_REQUIS"),{|| .T./*bValid*/ },,,,,,.T.,,,{|| .T. },,,,.F.,.F.,,"cRequisit",,,,.T.,.F.)
	oRequisit:SetCSS( POSCSS (GetClassName(oRequisit), CSS_GET_NORMAL ))

	@ 155, 005 SAY oSay4 PROMPT "Cargo" SIZE 070, 010 OF oPnlInc COLORS 0, 16777215 PIXEL
	oSay4:SetCSS( POSCSS (GetClassName(oSay4), CSS_LABEL_FOCAL ))
	oCargo := TGet():New( 165, 005,{|u| iif( PCount()==0,cCargo,cCargo:=u)}, oPnlInc, nWidth-130, 013, PesqPict("U56","U56_CARGO"),{|| .T./*bValid*/ },,,,,,.T.,,,{|| .T. },,,,.F.,.F.,,"cCargo",,,,.T.,.F.)
	oCargo:SetCSS( POSCSS (GetClassName(oCargo), CSS_GET_NORMAL ))

	@ 185, 005 SAY oSay8 PROMPT "Observações" SIZE 100, 007 OF oPnlInc COLORS 16777215, 0 PIXEL
	oSay8:SetCSS( POSCSS (GetClassName(oSay8), CSS_LABEL_FOCAL ))
	@ 195, 005 GET oObserv VAR cObserv OF oPnlInc MULTILINE SIZE nWidth-130, 030 COLORS 0, 16777215 PIXEL
	oObserv:SetCSS( POSCSS (GetClassName(oObserv), CSS_GET_NORMAL))

	@ 235, 005 SAY oSay4 PROMPT "Valor do Depósito" SIZE 070, 010 OF oPnlInc COLORS 0, 16777215 PIXEL
	oSay4:SetCSS( POSCSS (GetClassName(oSay4), CSS_LABEL_FOCAL ))
	oValorDp := TGet():New( 245, 005,{|u| iif(PCount()>0,nValorDp:=u,nValorDp)}, oPnlInc, 085, 013, PesqPict("SL4","L4_VALOR"),{|| .T. },,,,,,.T.,,,{|| .T. },,,,.F.,.F.,,"nValorDp",,,,.T.,.F.)
	oValorDp:SetCSS( POSCSS (GetClassName(oValorDp), CSS_GET_NORMAL ))

	nTipoOper:=1
	SetTipoSel(nTipoOper) //configuro operacao inicial na tela

	oBtn1 := TButton():New( nHeight-45,nWidth-75,"Confirmar",oPnlInc,{|| iif(VldIncDep(.T.),iif(bConfirm<>Nil,Eval(bConfirm),),) },070,020,,,,.T.,,,,{|| .T.})
	oBtn1:SetCSS( POSCSS (GetClassName(oBtn1), CSS_BTN_FOCAL ))

	If lConfCash
		oBtn2 := TButton():New( nHeight-45,nWidth-150,"Cancelar",oPnlInc,bCancel,070,020,,,,.T.,,,,{|| .T.})
		oBtn2:SetCSS( POSCSS (GetClassName(oBtn2), CSS_BTN_NORMAL ))
	Else

		oBtn2 := TButton():New( nHeight-45,nWidth-150,"Limpar Tela",oPnlInc,{|| U_TPDVA8CL(.T.) },070,020,,,,.T.,,,,{|| .T.})
		oBtn2:SetCSS( POSCSS (GetClassName(oBtn2), CSS_BTN_NORMAL ))

		oBtn4 := TButton():New( nHeight-45,005,"Listar Depósitos",oPnlInc,{|| cTitleTela := "LISTAGEM", oPnlInc:Hide(), oPnlBrow:Show() },080,020,,,,.T.,,,,{|| .T.})
		oBtn4:SetCSS( POSCSS (GetClassName(oBtn4), CSS_BTN_NORMAL ))

		//////////////////////// BROWSE DOS DEPÓSITOS //////////////////////////////////////

		//Painel de Browse dos Depósitos
		oPnlBrow := TPanel():New(020,000,"",oPnlGeral,NIL,.T.,.F.,,,nWidth,nHeight-020,,.T.,.F.)
		oPnlBrow:Hide()

		@ 005, 005 SAY oSay12 PROMPT "Depósito" SIZE 100, 010 OF oPnlBrow COLORS 0, 16777215 PIXEL
		oSay12:SetCSS( POSCSS (GetClassName(oSay12), CSS_LABEL_FOCAL ))
		oBuscaDep := TGet():New( 015, 005,{|u| iif( PCount()==0,cBuscaDep,cBuscaDep:=u) },oPnlBrow, 070, 013,,{|| /*bValid*/ },,,,,,.T.,,,{|| .T. },,,,.F.,.F.,,"cBuscaDep",,,,.T.,.F.)
		oBuscaDep:SetCSS( POSCSS (GetClassName(oBuscaDep), CSS_GET_NORMAL ))

		//@ 005, 080 SAY oSay12 PROMPT "CPF/CNPJ Cliente" SIZE 100, 010 OF oPnlBrow COLORS 0, 16777215 PIXEL
		//oSay12:SetCSS( POSCSS (GetClassName(oSay12), CSS_LABEL_FOCAL ))
		//oBuscaCpf := TGet():New( 015, 080,{|u| iif( PCount()==0,cBuscaCpf,cBuscaCpf:=u) },oPnlBrow, 080, 013,,{|| /*bValid*/ },,,,,,.T.,,,{|| .T. },,,,.F.,.F.,,"cBuscaCpf",,,,.T.,.F.)
		//oBuscaCpf:SetCSS( POSCSS (GetClassName(oBuscaCpf), CSS_GET_NORMAL ))
		//TSearchF3():New(oBuscaCpf,400,250,"SA1","A1_CGC",{{"A1_NOME",2},{"A1_CGC",3},{"A1_COD",1}},"SA1->A1_MSBLQL<>'1'",{{"A1_NOME","A1_EST","A1_MUN"},{"A1_CGC","A1_NOME","A1_EST","A1_MUN"},{"A1_COD","A1_LOJA","A1_NOME","A1_EST","A1_MUN"}},,,iif(lConfCash,-40,0))
		
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

		oBtn5 := TButton():New( 015, 295,"Buscar",oPnlBrow,{|| BuscaDep() },040,015,,,,.T.,,,,{|| .T.})
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

		oMsGetDep := MsNewGetEst(oPnlAux2, 053, 090, 150, nWidth-5)
		oMsGetDep:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT
		oMsGetDep:oBrowse:SetCSS( StrTran(POSCSS("TGRID", CSS_BROWSE),"gridline-color: white;","") ) //CSS do totvs pdv
		//oMsGetDep:oBrowse:lCanGotFocus := .F.
		oMsGetDep:oBrowse:nScrollType := 0
		oMsGetDep:oBrowse:lHScroll := .F.

		@ (oPnlGrid2:nHeight/2)-22, 010 SAY oQtdReg PROMPT (cValToChar(nQtdReg)+" registros encontrados.") SIZE 150, 010 OF oPnlGrid2 COLORS 0, 16777215 PIXEL
		oQtdReg:SetCSS( POSCSS (GetClassName(oQtdReg), CSS_LABEL_NORMAL))
		@ (oPnlGrid2:nHeight/2)-21, nWidth-090 BITMAP oLeg ResName "BR_VERDE" OF oPnlGrid2 Size 10, 10 NoBorder When .F. PIXEL
		@ (oPnlGrid2:nHeight/2)-22, nWidth-080 SAY oSay14 PROMPT "Ativo" OF oPnlGrid2 Color CLR_BLACK PIXEL
		oSay14:SetCSS( POSCSS (GetClassName(oSay14), CSS_LABEL_NORMAL))
		@ (oPnlGrid2:nHeight/2)-21, nWidth-055 BITMAP oLeg ResName "BR_PRETO" OF oPnlGrid2 Size 10, 10 NoBorder When .F. PIXEL
		@ (oPnlGrid2:nHeight/2)-22, nWidth-045 SAY oSay14 PROMPT "Estornado" OF oPnlGrid2 Color CLR_BLACK PIXEL
		oSay14:SetCSS( POSCSS (GetClassName(oSay14), CSS_LABEL_NORMAL))

		oBtn6 := TButton():New( nHeight-45,005,"Novo Depósito",oPnlBrow,{|| oPnlInc:Show(), oPlaca:SetFocus(), oPnlBrow:Hide(), U_TPDVA8CL(.T.) },060,020,,,,.T.,,,,{|| .T.})
		oBtn6:SetCSS( POSCSS (GetClassName(oBtn6), CSS_BTN_FOCAL ))

		oBtn7 := TButton():New( nHeight-45,070,"Estornar",oPnlBrow,{|| DoEstorno() },060,020,,,,.T.,,,,{|| .T.})
		oBtn7:SetCSS( POSCSS (GetClassName(oBtn7), CSS_BTN_NORMAL ))

		oBtn8 := TButton():New( nHeight-45,135,"Imprimir",oPnlBrow,{|| ImpDeposito() },060,020,,,,.T.,,,,{|| .T.})
		oBtn8:SetCSS( POSCSS (GetClassName(oBtn8), CSS_BTN_NORMAL ))
	EndIf

	oPlaca:SetFocus()

	If lConfCash
		U_TPDVA8CL(.T.)
	EndIf
	
Return cUsrDep

/*/{Protheus.doc} TPDVA8CL
Função para limpar e resetar tela.

@author Totvs GO
@since 03/06/2019
@version 1.0
@return Nil
@type function
/*/
User Function TPDVA8CL(lNoBrowse)

Local lMvPswVend := SuperGetMv("TP_PSWVEND",,.F.)
Default lNoBrowse := .F.

If !lConfCash .AND. Empty(cUsrDep) //se nao tem acesso, nao criou componentes
	Return
EndIf

cTitleTela := "INCLUIR"
cCodCli := Space(TamSX3("A1_COD")[1])
cLojCli := Space(TamSX3("A1_LOJA")[1])
cNomCli := Space(TamSX3("A1_NOME")[1])
cPlaca := Space(TamSX3("U57_PLACA")[1])
cVendedor := Space(TamSX3("U57_VEND")[1])
cNomVend := Space(TamSX3("A3_NOME")[1])
cCgcMot := Space(TamSX3("U57_MOTORI")[1])
cNomMot := Space(TamSX3("DA4_NOME")[1])
cFilAuto := Space(TamSX3("U56_FILAUT")[1])
cGetCod := Space(40)

cRequisit := Space(TamSX3("U56_REQUIS")[1])
cCargo := Space(TamSX3("U56_CARGO")[1])
nValorDp := 0
cBuscaDep := Space(TamSX3("U57_PREFIX")[1]+TamSX3("U57_CODIGO")[1]+TamSX3("U57_PARCEL")[1])
dBuscaDt := dDataBase
cBuscaCod := Space(TamSX3("A1_COD")[1])
cBuscaLoj := Space(TamSX3("A1_LOJA")[1])
cBuscaPlaca := Space(TamSX3("U57_PLACA")[1])
nQtdReg := 0
cObserv := ""

oNomMot:lReadonly := .F.

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
		oBuscaDep:SetFocus()
	Else
		oPlaca:SetFocus()
	EndIf
EndIf

Return

//--------------------------------------------------------------
// Aplica CSS no botão tipo Radio
//--------------------------------------------------------------
Static Function SetTipoSel(nOpcSel)

	Local lRet := .T.
	Local cCssBtn
	Local nX := 0

	If nOpcSel == 1 //Saque

		//deixo botão SAQUE azul
		cCssBtn := POSCSS(GetClassName(oBtnTpSaq), CSS_BTN_FOCAL )
		cCssBtn := StrTran(cCssBtn, "border-radius: 6px;", "border-radius: 3px;")
		oBtnTpSaq:SetCss(cCssBtn)

		//deixo botão CONSUMO branco
		cCssBtn := POSCSS(GetClassName(oBtnTpCon), CSS_BTN_NORMAL )
		cCssBtn := StrTran(cCssBtn, "border-radius: 6px;", "border-radius: 3px;")
		cCssBtn := StrTran(cCssBtn, "font: bold large;", "")
		oBtnTpCon:SetCss(cCssBtn)

		nTipoOper := 1 //1-Saque;2-Consumo
		
	Else

		//deixo botão SAQUE branco
		cCssBtn := POSCSS(GetClassName(oBtnTpSaq), CSS_BTN_NORMAL )
		cCssBtn := StrTran(cCssBtn, "border-radius: 6px;", "border-radius: 3px;")
		cCssBtn := StrTran(cCssBtn, "font: bold large;", "")
		oBtnTpSaq:SetCss(cCssBtn)

		//deixo botão CONSUMO azul
		cCssBtn := POSCSS(GetClassName(oBtnTpCon), CSS_BTN_FOCAL )
		cCssBtn := StrTran(cCssBtn, "border-radius: 6px;", "border-radius: 3px;")
		oBtnTpCon:SetCss(cCssBtn)

		nTipoOper := 2 //1-Saque;2-Consumo

	EndIf

	oBtnTpSaq:Refresh()
	oBtnTpCon:Refresh()

Return .T.

//-----------------------------------------------------------------------------------------
// Monta grid NewGetDados de Estorno
//-----------------------------------------------------------------------------------------
Static Function MsNewGetEst(oPnl, nTop, nLeft, nBottom, nRight)

	Local aHeaderEx 	:= {}
	Local aColsEx 		:= {}
	Local aAlterFields 	:= {}
	Local aFields 		:= {"U57_PREFIX","U57_CODIGO","U57_PARCEL","U56_TIPO","U57_TUSO","U57_VALOR","U57_DATDEP","U57_HORDEP","A1_NOME","U57_PLACA","U57_MOTORI","U56_REQUIS","U56_CARGO","U57_PDVDEP","U57_NUMDEP","U56_CODCLI","U56_LOJA","U56_FILAUT"}
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
								aSort(aCliByGrp,,,{|x,y| x[1]+x[2] < y[1]+y[2]}) //ordem crescente: A1_COD + A1_LOJA
							EndIf

							SA1->(DbSkip())
						EndDo
					EndIf
					If len(aCliByGrp) > 0
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
	Local lBlqAI0 		:= SuperGetMv("MV_XBLQAI0",,.F.) .AND. AI0->(FieldPos("AI0_XBLFIL")) > 0 //Habilita bloqueio de venda na filial, olhando para tabela AI0

	If Empty(cCodCli) .or. Empty(cLojCli)
		cCodCli := Space(TamSX3("A1_COD")[1])
		cLojCli := Space(TamSX3("A1_LOJA")[1])
		cNomCli := Space(TamSX3("A1_NOME")[1])
	Else
		cNomCli := Posicione("SA1",1,xFilial("SA1")+cCodCli+cLojCli,"A1_NOME") //A1_FILIAL+A1_COD+A1_LOJA
		If Empty(cNomCli)
			lRet := .F.
			cMsgErr := "Cliente não cadastrado!"
		ElseIf !lReqCliPad .AND. SA1->A1_COD+SA1->A1_LOJA == GETMV("MV_CLIPAD")+GETMV("MV_LOJAPAD")
			lRet := .F.
			cMsgErr := "Não é permitido fazer depósito para o cliente padrão."
		
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

//----------------------------------------------------------------------------------
// Validação total da tela de inclusão
//----------------------------------------------------------------------------------
Static Function VldIncDep(lConfGrv)

	Local cMsgErr 		:= ""
	Local lRet 			:= .T.
	Local lMVValCargo	:= SuperGetMV("MV_XVALCAR", .F., .T.)

	Default lConfGrv := .F.

	SE4->(DbSetOrder(1)) //E4_FILIAL+E4_CODIGO

	If Empty(cPlaca)
		cMsgErr := "Informe a placa do veículo!"
		lRet := .F.
	ElseIf Empty(cCodCli) .or. Empty(cLojCli)
		cMsgErr := "Informe o Código/Loja do cliente!"
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
	ElseIf Empty(cNomVend)
		cMsgErr := "Vendedor informado não encontrado na base! Verificar cadastro."
		lRet := .F.
	Else
		SA1->(DbSetOrder(1)) //A1_FILIAL+A1_CGC
		If !SA1->(DbSeek(xFilial("SA1")+cCodCli+cLojCli))
			cMsgErr := "Cliente não cadastrado!"
			lRet := .F.
		ElseIf Empty(cFilAuto)
			cMsgErr := "Infome a(s) filial(is) autorizada(s) para saque/consumo do depósito."
			lRet := .F.
		ElseIf !(U_UVldFilB(cFilAuto))
			cMsgErr := "Corrija o conteúdo do campo Filiais Autorizadas."
			lRet := .F.
		ElseIf Empty(cRequisit)
			cMsgErr := "Infome o nome do requisitante."
			lRet := .F.
		ElseIf Empty(cCargo) .And. lMVValCargo
			cMsgErr := "Infome o cargo do requisitante."
			lRet := .F.
		ElseIf Empty(cObserv)
			cMsgErr := "Infome uma observação para o depósito."
			lRet := .F.
		ElseIf nValorDp <= 0
			cMsgErr := "Favor informar o Valor do Depósito."
			lRet := .F.
		EndIf

	EndIf

	//valido database com o date server
	if lRet .AND. !lConfCash .AND. dDataBase <> Date()
		cMsgErr := "A data do sistema esta diferente da data do sistema operacional. Favor efetuar o logoff do sistema."
		lRet := .F.
	endif

	If lRet
		//PE para validação ao acionar botão "Confirmar" no deposito no PDV
		If ExistBlock("TP008VLD")
			lRet := ExecBlock("TP008VLD",.F.,.F.,{lConfCash, cPlaca, cCodCli, cLojCli, cCgcMot, cVendedor, cFilAuto, cRequisit, cCargo, cObserv, nTipoOper, nValorDp})
		EndIf
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
		EndIf
	Else
		If lConfCash
			MsgInfo(cMsgErr, "Atenção")
		Else
			U_SetMsgRod(cMsgErr)
		EndIf
	EndIf

Return lRet

//-------------------------------------------------------------------
// Processa a confirmação...
//-------------------------------------------------------------------
Static Function DoGrava()

	Local aArea := GetArea()
	Local aAreaSA6 := SA6->( GetArea() )
	Local nX
	Local lRet := .T.
	Local aCposCab  := {}
	Local aCposDet  := {}
	Local aAux      := {}
	Local cCliente  := cCodCli
	Local cLojaCli  := cLojCli
	Local cBanco,cAgencia,cNumCon,aStation
	Local cNumMov := iif(lConfCash,SLW->LW_NUMMOV,STDNumMov())
	Local cHoraMov := Time()
	Local cNumReq

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
	cAgencia := SA6->A6_AGENCIA
	cNumCon  := SA6->A6_NUMCON

	if !lConfCash
		cNumReq := U_GetU56Num(lConfCash) //GetSX8Num("U56","U56_CODIGO")
	endif
	
	SA1->(DbSetOrder(1)) //volto indice 1 para validacoes de campos da U56

	If !Empty(cNumReq) .OR. lConfCash

		// Cabeçalho
		if !lConfCash
			aAdd( aCposCab, { 'U56_PREFIX'	, U_TRETA32P() 	} )
			aAdd( aCposCab, { 'U56_CODIGO'	, cNumReq 		} )
		endif
		aAdd( aCposCab, { 'U56_TIPO'	, '1' 			} ) //1=Pré-Paga
		aAdd( aCposCab, { 'U56_CODCLI'	, cCliente 		, .F.} )
		aAdd( aCposCab, { 'U56_LOJA'	, cLojaCli 		, .F.} )
		aAdd( aCposCab, { 'U56_NOME'	, cNomCli 		, .F.} )
		aAdd( aCposCab, { 'U56_BANCO'	, cBanco 		, .F.} )
		aAdd( aCposCab, { 'U56_AGENCI'	, "."	 		, .F.} )
		aAdd( aCposCab, { 'U56_NUMCON'	, "." 			, .F.} )
		aAdd( aCposCab, { 'U56_HIST' 	, PadL('X',TamSx3("U56_HIST")[1],'X')  } )
		aAdd( aCposCab, { 'U56_FILAUT'	, cFilAuto		} )
		aAdd( aCposCab, { 'U56_REQUIS'	, cRequisit 	} )
		aAdd( aCposCab, { 'U56_CARGO'	, cCargo 		} )
		aAdd( aCposCab, { 'U56_OBS'		, cObserv 		} )
		aAdd( aCposCab, { 'U56_TOTAL'	, nValorDp 		} )

		//Itens
		aAux := {}
		aAdd( aAux, { 'U57_PARCEL'	, PadL('1',TamSx3("U57_PARCEL")[1],'0') } )
		aAdd( aAux, { 'U57_VALOR'	, nValorDp     	} )
		aAdd( aAux, { 'U57_TUSO' 	, iif(nTipoOper = 1,'S','C') } )
		aAdd( aAux, { 'U57_MOTORI'	, cCgcMot     	} )
		aAdd( aAux, { 'U57_PLACA'	, cPlaca   		} )
		aAdd( aAux, { 'U57_XGERAF'	, 'P'		   	} )
		aAdd( aAux, { 'U57_FILDEP'	, cFilAnt		} )
		
		aAdd( aAux, { 'U57_OPEDEP'	, cBanco	    } )
		aAdd( aAux, { 'U57_PDVDEP'	, PadR(aStation[4],TamSx3("U57_PDVDEP")[1]) } )
		aAdd( aAux, { 'U57_ESTDEP'	, PadR(aStation[2],TamSx3("U57_ESTDEP")[1]) } )
		aAdd( aAux, { 'U57_NUMDEP'	, PadR(cNumMov,TamSx3("U57_NUMDEP")[1]) } )
		aAdd( aAux, { 'U57_DATDEP'	, dDataBase		} )
		If lConfCash
			aAdd( aAux, { 'U57_HORDEP'	, SubStr(SLW->LW_HRABERT,1,TamSx3("U57_HORDEP")[1]) } )
		Else
			aAdd( aAux, { 'U57_HORDEP'	, SubStr(Time(),1,TamSx3("U57_HORDEP")[1]) } )
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

		If U_GravaReq('U56', 'U57', aCposCab, aCposDet )

			If !lConfCash

				U_UREPLICA("U56", 1, U56->(U56_FILIAL+U56_PREFIX+U56_CODIGO), "A")
				U_UREPLICA("U57", 1, U57->(U57_FILIAL+U57_PREFIX+U57_CODIGO+U57_PARCEL), "A")

				//impressão do depósito
				cTitulo := AllTrim(U57->U57_PREFIX+U57->U57_CODIGO+U57->U57_PARCEL)
				U_TPDVR005( cCodCli, cLojCli, cPlaca, cCgcMot, cNomMot, nValorDp, cTitulo, cRequisit, cCargo )

				U_SetMsgRod("Depósito realizado com sucesso! Código: " + cTitulo )

				//limpa a tela
				U_TPDVA8CL()

			EndIf
		Else
			lRet := .F.
		EndIf

	EndIf

	RestArea( aAreaSA6 )
	RestArea( aArea )

Return lRet


//----------------------------------------------------------
// Busca as requisições de acordo com filtros, brwose
//----------------------------------------------------------
Static Function BuscaDep()

	Local cCondicao		:= ""
	Local bCondicao
	Local nX
	Local aLinTemp 		:= {}

	If Empty(dBuscaDt)
		U_SetMsgRod("Informe uma data para a busca!")
		Return
	EndIf

	oMsGetDep:acols := {}

	CursorArrow()

	U_SetMsgRod("Buscando depósitos no PDV...")

	cCondicao := " U57_FILIAL = '" + xFilial("U57") + "'"
	cCondicao += " .AND. U57_DATDEP = STOD('" + DTOS(dBuscaDt) + "')"
	cCondicao += " .AND. U57_PDVDEP = '" + PadR(LJGetStation("LG_PDV"),TamSx3("U57_PDVDEP")[1]) + "'"
	If !Empty(cBuscaDep)
		cCondicao += " .AND. '" + alltrim(cBuscaDep) + "' $ U57_PREFIX+U57_CODIGO+U57_PARCEL "
	EndIf
	If !Empty(cBuscaPlaca)
		cCondicao += " .AND. (EMPTY(U57_PLACA) .OR. U57_PLACA = '" + cBuscaPlaca + "')"
	EndIf

	// limpo os filtros da U57
	U57->(DbClearFilter())

	// executo o filtro na U57
	bCondicao 	:= "{|| " + cCondicao + " }"
	U57->(DbSetFilter(&bCondicao,cCondicao))

	// vou para a primeira linha
	U57->(DbGoTop())

	//{"U57_PREFIX","U57_CODIGO","U57_PARCEL","U56_TIPO","U57_TUSO","U57_VALOR","U57_DATDEP","U57_HORDEP","A1_NOME","U57_PLACA","U57_MOTORI","U56_REQUIS","U56_CARGO","U57_PDVDEP","U57_NUMDEP","U56_CODCLI","U56_LOJA","U56_FILAUT"}
	While U57->(!Eof())

		Posicione("U56",1,xFilial("U56")+U57->(U57_PREFIX+U57_CODIGO),"U56_TIPO")
		Posicione("SA1",1,xFilial("SA1")+U56->U56_CODCLI+U56->U56_LOJA,"A1_COD")

		If !empty(cBuscaCod) .and. AllTrim(cBuscaCod) <> AllTrim(U56->U56_CODCLI)
			U57->( DbSkip() )
			Loop
		EndIf

		If !empty(cBuscaLoj) .and. AllTrim(cBuscaLoj) <> AllTrim(U56->U56_LOJA)
			U57->( DbSkip() )
			Loop
		EndIf

		aLinTemp := {}
		For nX := 1 to Len(oMsGetDep:aHeader)
			If (oMsGetDep:aHeader[nX][2]=="LEGENDA")
				Aadd(aLinTemp, iif(U57->U57_XGERAF=="X","BR_PRETO","BR_VERDE") )
			ElseIf Left(oMsGetDep:aHeader[nX][2],3)=="U57"
				Aadd(aLinTemp, U57->&(oMsGetDep:aHeader[nX][2]) )
			ElseIf Left(oMsGetDep:aHeader[nX][2],3)=="U56"
				Aadd(aLinTemp, U56->&(oMsGetDep:aHeader[nX][2]) )
			Else
				Aadd(aLinTemp, SA1->&(oMsGetDep:aHeader[nX][2]) )
			EndIf
		Next nX

		Aadd(aLinTemp, U57->(RecNo())) //recno
		Aadd(aLinTemp, .F.) //deleted
		Aadd(oMsGetDep:aCols,aClone(aLinTemp))

		U57->( DbSkip() )
	EndDo

	// limpo os filtros da U57
	U57->(DbClearFilter())

	nQtdReg := Len(oMsGetDep:acols)
	If nQtdReg == 0
		ClearGrid(oMsGetDep)
	EndIf

	oMsGetDep:oBrowse:Refresh()
	oQtdReg:Refresh()
	U_SetMsgRod("")
	oMsGetDep:oBrowse:SetFocus()

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

//-----------------------------------------------------------------------------------------
// Faz validação e o processamento do estorno
//-----------------------------------------------------------------------------------------
Static Function DoEstorno()

	Local lRet := .T.
	Local nX

	If oMsGetDep:nAt <= 0 .or. !(oMsGetDep:acols[oMsGetDep:nAt][Len(oMsGetDep:aHeader)+1] > 0)
		U_SetMsgRod("Selecione a requisição a ser estornada!")
		Return .F.

	EndIf

	If lRet 

		U57->(DbGoTo(oMsGetDep:acols[oMsGetDep:nAt][Len(oMsGetDep:aHeader)+1]))

		If U57->(Eof()) .or. (oMsGetDep:aCols[oMsGetDep:nAt][1] == "BR_PRETO" .or. U57->U57_XGERAF == "X")
			U_SetMsgRod("Requisição já estornada!")
			Return .F.

		EndIf

		If !(U57->U57_NUMDEP = PadR(LjNumMov(),TamSx3("U57_NUMDEP")[1]) .and. ;
		U57->U57_DATDEP = dDataBase)
			U_SetMsgRod("Requisição não pertence ao caixa em operação!")
			Return .F.

		EndIf

		U56->(DbSetOrder(1)) //U56_FILIAL+U56_PREFIX+U56_CODIGO
		U56->(DbSeek(U57->(U57_FILIAL+U57_PREFIX+U57_CODIGO)))

		Reclock("U57", .F.)
			U57->U57_XGERAF := 'X'
			U57->U57_FILDEP := cFilAnt //Filial de Depósito
			U57->U57_FILSAQ := "" //Filial de Saque
		U57->(MsUnlock())

		//enviando dados para retaguarda
		U_UREPLICA("U56", 1, U56->(U56_FILIAL+U56_PREFIX+U56_CODIGO), "A")
		U_UREPLICA("U57", 1, U57->(U57_FILIAL+U57_PREFIX+U57_CODIGO+U57_PARCEL), "A")

		//impressao do cupom nao fiscal - estorno
		_cCodCli    := oMsGetDep:aCols[oMsGetDep:nAt][aScan(oMsGetDep:aHeader,{|x| AllTrim(x[2])=="U56_CODCLI"})]
		_cLojCli	:= oMsGetDep:aCols[oMsGetDep:nAt][aScan(oMsGetDep:aHeader,{|x| AllTrim(x[2])=="U56_LOJA"})]
		_cPlaca 	:= oMsGetDep:aCols[oMsGetDep:nAt][aScan(oMsGetDep:aHeader,{|x| AllTrim(x[2])=="U57_PLACA"})]
		_cCgcMot 	:= oMsGetDep:aCols[oMsGetDep:nAt][aScan(oMsGetDep:aHeader,{|x| AllTrim(x[2])=="U57_MOTORI"})]
		_nVale 		:= oMsGetDep:aCols[oMsGetDep:nAt][aScan(oMsGetDep:aHeader,{|x| AllTrim(x[2])=="U57_VALOR"})]
		_nDinheiro 	:= oMsGetDep:aCols[oMsGetDep:nAt][aScan(oMsGetDep:aHeader,{|x| AllTrim(x[2])=="U57_VALOR"})]
		_nCheque 	:= 0
		_cTitulo 	:= AllTrim(oMsGetDep:aCols[oMsGetDep:nAt][aScan(oMsGetDep:aHeader,{|x| AllTrim(x[2])=="U57_PREFIX"})]+oMsGetDep:aCols[oMsGetDep:nAt][aScan(oMsGetDep:aHeader,{|x| AllTrim(x[2])=="U57_CODIGO"})]+oMsGetDep:aCols[oMsGetDep:nAt][aScan(oMsGetDep:aHeader,{|x| AllTrim(x[2])=="U57_PARCEL"})])
		_cRequis	:= oMsGetDep:aCols[oMsGetDep:nAt][aScan(oMsGetDep:aHeader,{|x| AllTrim(x[2])=="U56_REQUIS"})]
		_cCargo		:= oMsGetDep:aCols[oMsGetDep:nAt][aScan(oMsGetDep:aHeader,{|x| AllTrim(x[2])=="U56_CARGO"})]
		_cMotivo	:= Space(TamSX3("U57_MOTIVO")[1])
		_cTipoReq := "DEPÓSITO NO PDV"

		U_TPDVR003( _cCodCli, _cLojCli, _cPlaca, _cCgcMot, _nVale, _nDinheiro, _nCheque, _cTitulo, _cRequis, _cCargo, _cMotivo, _cTipoReq )

		oMsGetDep:aCols[oMsGetDep:nAt][1] := "BR_PRETO"
		U_SetMsgRod("Requisição "+U57->(U57_PREFIX+U57_CODIGO+U57_PARCEL)+" estornada com sucesso!")

	EndIf

Return lRet

//------------------------------------------------------
// Realiza a reimpressão de uma requisição
//------------------------------------------------------
Static Function ImpDeposito()

	Local nLinha := oMsGetDep:nAt

	CursorArrow()
	CursorWait()

	If nLinha <= 0 .or. !(oMsGetDep:acols[nLinha][Len(oMsGetDep:aHeader)+1] > 0)
		U_SetMsgRod("Selecione a requisição a ser reimpressa!")
		Return .F.

	EndIf

	//impressao do cupom nao fiscal
	_cCodCli	:= oMsGetDep:aCols[nLinha][aScan(oMsGetDep:aHeader,{|x| AllTrim(x[2])=="U56_CODCLI"})]
	_cLojCli	:= oMsGetDep:aCols[nLinha][aScan(oMsGetDep:aHeader,{|x| AllTrim(x[2])=="U56_LOJA"})]
	_cPlaca 	:= oMsGetDep:aCols[nLinha][aScan(oMsGetDep:aHeader,{|x| AllTrim(x[2])=="U57_PLACA"})]
	_cCgcMot 	:= oMsGetDep:aCols[nLinha][aScan(oMsGetDep:aHeader,{|x| AllTrim(x[2])=="U57_MOTORI"})]
	_cNomMot	:= ""
	_nValorDp 	:= oMsGetDep:aCols[nLinha][aScan(oMsGetDep:aHeader,{|x| AllTrim(x[2])=="U57_VALOR"})]
	_nDinheiro 	:= oMsGetDep:aCols[nLinha][aScan(oMsGetDep:aHeader,{|x| AllTrim(x[2])=="U57_VALOR"})]
	_nCheque 	:= 0
	_cTitulo 	:= AllTrim(oMsGetDep:aCols[nLinha][aScan(oMsGetDep:aHeader,{|x| AllTrim(x[2])=="U57_PREFIX"})]+oMsGetDep:aCols[nLinha][aScan(oMsGetDep:aHeader,{|x| AllTrim(x[2])=="U57_CODIGO"})]+oMsGetDep:aCols[nLinha][aScan(oMsGetDep:aHeader,{|x| AllTrim(x[2])=="U57_PARCEL"})])
	_cRequis	:= oMsGetDep:aCols[nLinha][aScan(oMsGetDep:aHeader,{|x| AllTrim(x[2])=="U56_REQUIS"})]
	_cCargo		:= oMsGetDep:aCols[nLinha][aScan(oMsGetDep:aHeader,{|x| AllTrim(x[2])=="U56_CARGO"})]
	_cMotivo	:= Space(TamSX3("U57_MOTIVO")[1])
	_cTipoReq   := "DEPÓSITO NO PDV"

	If oMsGetDep:aCols[nLinha][1] == "BR_PRETO" //Imprimir comprovante CANCELAMENTO de saque/deposito
		U_TPDVR003( _cCodCli, _cLojCli, _cPlaca, _cCgcMot, _nValorDp, _nDinheiro, _nCheque, _cTitulo, _cRequis, _cCargo, _cMotivo, _cTipoReq )
	Else //Imprimir comprovante de Deposito no PDV
		U_TPDVR005( _cCodCli, _cLojCli, _cPlaca, _cCgcMot, _cNomMot, _nValorDp, _cTitulo, _cRequis, _cCargo )
	EndIf

	CursorArrow()

Return .T.

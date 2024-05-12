#include "TOTVS.CH"
#Include "Protheus.ch"
#include "topconn.ch"
#INCLUDE "TBICONN.CH"

#DEFINE cEOL chr(13)+chr(10)

#DEFINE CSS_BOTAO " QPushButton { color: #FFFFFF; font-weight:bold; "+;
	"    background-color: qlineargradient(x1: 0, y1: 0, x2: 0, y2: 1, stop: 0 #3AAECB, stop: 1 #0F9CBF); "+;
	"    border:1px solid #369CB5; "+;
	"    border-radius: 3px; } "+;
	" QPushButton:pressed { "+;
	"    background-color: qlineargradient(x1: 0, y1: 0, x2: 0, y2: 1, stop: 0 #148AA8, stop: 1 #39ACC9); "+;
	"    border:1px solid #369CB5; }";


/*/{Protheus.doc} TRETA023
Rotina para fazer negociação de Preços pelo Cadastro de clientes ou produto.

nOpcX: Opção do Programa - 1=Por Produto; 2=Por Cliente
@author Danilo Brito
@since 17/04/2014
@version 1.0
@return Nulo
@param nOpcX, numeric, descricao
@param lPDV, logical, descricao
@param cCliente, characters, descricao
@param cLoja, characters, descricao
@param cPlaca, characters, descricao
@param cAdmFin, characters, descricao
@param cEmiCh, characters, descricao
@param cLojEmi, characters, descricao
@param cFormPg, characters, descricao
@param cCondPg, characters, descricao
@type function
/*/

User Function TRETA023(nOpcX, lPDV, cCliente, cLoja, cPlaca, cAdmFin, cEmiCh, cLojEmi, cFormPg, cCondPg)

	Local lRet := .T.
	Local nX := 0
	Local aSX3U25
	Local oFontTit := TFont():New('Arial',,22,.T.,.T.)

	Default nOpcX := 0
	Default lPDV := .F.

	Private oDlg01
	Private aSize := MsAdvSize() // Retorna a área útil das janelas Protheus
	Private aInfo := {aSize[1], aSize[2], aSize[3], aSize[4], 2, 2}
	Private aPObj := MsObjSize(aInfo, {{ 100, 110, .T., .F.}, { 100, 100, .T., .T.}, { 100, 000, .T., .F.}})
	Private nPObj := 0
	Private bCampo	:= {|nField| FieldName(nField) }
	//Private aButtons := {}
	Private aGets := {}
	Private aTela := {}
	Private lLimpForm := .T.
	Private lSelFilial := .F. // Gianluka Moraes | 13/07/16 : Controla se irá inserir em mais de uma filial.
	Private nTipoRep := 1
	Private nRecU25 := 0
	Private lShowAll := .F.
	Private lShowVig := .T.

	//Campos do cabeçalho para busca dos dados
	Private oCpCodCli
	Private cCpCodCli := Space(TamSx3("A1_COD")[1])
	Private oCpLojCli
	Private cCpLojCli := Space(TamSx3("A1_LOJA")[1])
	Private oCpNomDes
	Private cCpNomDes := Space(100)
	Private oCpGrpCli
	Private cCpGrpCli := Space(TamSx3("ACY_GRPVEN")[1])
	Private oCpDesGrp
	Private cCpDesGrp := Space(100)
	Private oRadCliPro
	Private lRadCliPro := .T.
	Private oRadGrupo
	Private lRadGrupo := .F.

	Private _cCliente	:= cCliente
	Private _cLoja 		:= cLoja
	Private _cPlaca 	:= cPlaca
	Private _cAdmFin	:= cAdmFin
	Private _cEmiCh 	:= cEmiCh
	Private _cLojEmi	:= cLojEmi
	Private _cFormPg	:= cFormPg
	Private _cCondPg	:= cCondPg

	Private _nRecApv := 0

	// variavel para ordenação de grids
	Private __XVEZ 		:= "0"
	Private __ASC       := .T.

	Private oMSGet1
	Private cOrdem	:= "1"
	Private aOrdem	:= {"1=Data Inic + Hora Inic + Cliente","2=Cliente + Data Inic + Hora Inic"}
	Private aCpOrd	:= {"U25_DTINIC DESC, U25_HRINIC DESC, U25_CLIENT, U25_LOJA, U25_GRPCLI, U25_FORPAG, U25_CONDPG, U25_ADMFIN, U25_EMITEN, U25_LOJEMI",;
		"U25_CLIENT, U25_LOJA, U25_GRPCLI, U25_DTINIC DESC, U25_HRINIC DESC, U25_FORPAG, U25_CONDPG, U25_ADMFIN, U25_EMITEN, U25_LOJEMI"}
	Private cFilGrid := ""

	Private aCores := {	{ "U25_BLQL == 'S'",'BR_PRETO'},;
		{ "U_TRET023D()",'BR_VERDE'},;
		{ ".T.",'BR_VERMELHO'}} //por padrão ja é nao vigente
	//Private aCores := {	{ "U_TRET023D() .AND. ((empty(dtos(U25->U25_DTFIM)) .OR. U25->U25_DTFIM >= DDATABASE) .AND. (U25->U25_DTFIM == DDATABASE .AND. (empty(dtos(U25->U25_HRFIM)) .OR. U25->U25_HRFIM >= SUBSTR(Time(),1,5)))) .AND. U25->U25_DTINIC <= DDATABASE .AND. U25->U25_HRINIC <= SUBSTR(Time(),1,5) .AND. empty(U25_NUMORC)",'BR_VERDE'},;
		//					{ ".T.",'BR_VERMELHO'}} //por padrão ja é nao vigente
	Private aLegen := {	{'BR_PRETO'		,"Preço em aprovação por Alçada"},;
		{'BR_VERDE'		,"Preço Vigente"},;
		{'BR_VERMELHO'	,"Preço Não Vigente"}}

	if nOpcX > 2 .OR. nOpcX < 0
		Help(,,"Atenção",,"Opção do Programa Inválida!.",1,0,,,,,,{""})
		return
	endif

	if lPDV .AND. (_cCliente == Nil .OR. empty(_cCliente) .OR. _cLoja == Nil .OR. empty(_cLoja) .OR. _cPlaca == Nil .OR. empty(_cPlaca) )
		Help( ,, 'Help',, "Informe o Cliente/Loja e Placa para abrir esta opção.", 1, 0 )
		return
	endif

	if nOpcX == 2 //se por cliente
		aOrdem	:= {"1=Data Inic + Hora Inic + Produto","2=Produto + Data Inic + Hora Inic"}
		aCpOrd	:= {"U25_DTINIC DESC, U25_HRINIC DESC, U25_PRODUT, U25_FORPAG, U25_CONDPG, U25_ADMFIN, U25_EMITEN, U25_LOJEMI",;
			"U25_PRODUT, U25_DTINIC DESC, U25_HRINIC DESC, U25_FORPAG, U25_CONDPG, U25_ADMFIN, U25_EMITEN, U25_LOJEMI"}
		if !lPDV
			aPObj   := MsObjSize(aInfo, {{ 100, 20, .T., .F.}, { 100, 110, .T., .F.}, { 100, 100, .T., .T.}, { 100, 000, .T., .F.}})
			nPObj 	:= 1
		endif
	endif

	//Ponto de Entrada tratamentos de acesso ao programa
	//If ExistBlock("UF001ACE")
	//	lRet := ExecBlock("UF001ACE",.F.,.F., {nOpcX, lPdv})
	//	if Type("lRet") == "L" .AND. lRet == .F.
	//		return
	//	endif
	//EndIf

	DbSelectArea("U25")
	U25->(DbSetOrder(nOpcX+1+iif(nOpcX==0,1,0))) //seta ordem de acordo com tipo

	//cria variaveis do alias na memória
	aSX3U25 := FWSX3Util():GetAllFields( "U25" , .T./*lVirtual*/ )
	If !empty(aSX3U25)
		For nX := 1 to len(aSX3U25)
			M->&(aSX3U25[nX]) := CriaVar(aSX3U25[nX], .T.)
		next nX
	endif

	//botões ações relacionadas
	//AADD( aButtons, {"LEGENDA", {|| BrwLegenda("Legenda","Situação do Preço",aLegen) }, "Legenda","Legenda",{|| .T.}} )

	//Criando Tela
	//oDlg01 := TDialog():New(aSize[7],aSize[1],aSize[6],aSize[5],"Negociação de Preços" ,,,,,,,,,.T.)
	DEFINE MSDIALOG oDlg01 TITLE "Negociação de Preços" FROM aSize[7],aSize[1] TO aSize[6],aSize[5] PIXEL OF GetWndDefault() STYLE nOr(WS_VISIBLE, WS_POPUP)

	TSay():New( 10, 10,{|| "Negociação de Preços" }, oDlg01,,oFontTit,,,,.T.,/*nCorGrid*/,,200,16 )

	@ 008, aPObj[1,4]-13 BITMAP oImg ResName "FWSKIN_BTN_DIV" SIZE 10, 09 OF oDlg01 PIXEL NOBORDER
	TBtnBmp2():New( 010,(aPObj[1,4]*2)-14,20,30,'FWSKIN_DELETE_ICO',,,,{|| oDlg01:End() },oDlg01,,,.T. )

	if nOpcX == 2 .AND. !lPDV //cliente
		cCpCodCli := SA1->A1_COD
		cCpLojCli := SA1->A1_LOJA
		cCpNomDes := SA1->A1_NOME

		//TSay():New( aPObj[1,1]+7, 5,{|| "Cliente" }, oDlg01,,,,,,.T.,CLR_BLACK,,50,9 )
		@ aPObj[1,1]+7, 5 CHECKBOX oRadCliPro VAR lRadCliPro PROMPT "Cliente" SIZE 048, 008 OF oDlg01 COLORS 0, 16777215 WHEN !(empty(cCpGrpCli) .OR. empty(cCpCodCli))  ON CHANGE (lRadGrupo:=!lRadCliPro, DoCheckCab(nOpcX)) PIXEL
		oCpCodCli := TGet():New( aPObj[1,1]+5, 40,{|u| iif( PCount()==0,cCpCodCli,cCpCodCli:= u) },oDlg01,50,9,,{|| empty(cCpCodCli+cCpLojCli) .OR. !empty((cCpNomDes := Posicione("SA1",1,xFilial("SA1")+cCpCodCli+cCpLojCli,"A1_NOME"))) }/*bValid*/,,,,.F.,,.T.,,.F.,{|| .F. },.F.,.F.,/*bChange*/,.F.,.F.,"SA1","U25_CLIENT",,,,.T.,.F.)
		oCpLojCli := TGet():New( aPObj[1,1]+5, 95,{|u| iif( PCount()==0,cCpLojCli,cCpLojCli:= u) },oDlg01,20,9,,{|| empty(cCpCodCli+cCpLojCli) .OR. !empty((cCpNomDes := Posicione("SA1",1,xFilial("SA1")+cCpCodCli+cCpLojCli,"A1_NOME"))) }/*bValid*/,,,,.F.,,.T.,,.F.,{|| .F. },.F.,.F.,/*bChange*/,.F.,.F.,,"U25_LOJA",,,,.T.,.F.)

		//nome cliente
		oCpNomDes := TGet():New( aPObj[1,1]+5, 125,{|u| iif( PCount()==0,cCpNomDes,cCpNomDes := u) },oDlg01,100,9,,/*bValid*/,,,,.F.,,.T.,,.F.,{|| .F.},.F.,.F.,/*bChange*/,.F.,.F.,,"cCpNomDes",,,,.T.,.F.)

		cCpGrpCli := SA1->A1_GRPVEN
		cCpDesGrp := Posicione("ACY",1,xFilial("ACY")+cCpGrpCli,"ACY_DESCRI")
		//TSay():New( aPObj[1,1]+7, 230,{|| "Grupo Cli" }, oDlg01,,,,,,.T.,CLR_BLACK,,50,9 )
		@ aPObj[1,1]+7, 240 CHECKBOX oRadGrupo VAR lRadGrupo PROMPT "Grupo Cli" SIZE 048, 008 OF oDlg01 COLORS 0, 16777215 WHEN !(empty(cCpGrpCli) .OR. empty(cCpCodCli))  ON CHANGE (lRadCliPro:=!lRadGrupo, DoCheckCab(nOpcX)) PIXEL
		oCpGrpCli := TGet():New( aPObj[1,1]+5, 280,{|u| iif( PCount()==0,cCpGrpCli,cCpGrpCli:= u) },oDlg01,50,9,,{|| empty(cCpGrpCli) .OR. !empty((cCpDesGrp := Posicione("ACY",1,xFilial("ACY")+cCpGrpCli,"ACY_DESCRI"))) }/*bValid*/,,,,.F.,,.T.,,.F.,{|| .F. },.F.,.F.,/*bChange*/,.F.,.F.,"ACY","U25_GRPCLI",,,,.T.,.F.)

		//desc grupo cliente
		oCpDesGrp := TGet():New( aPObj[1,1]+5, 335,{|u| iif( PCount()==0,cCpDesGrp,cCpDesGrp := u) },oDlg01,100,9,,/*bValid*/,,,,.F.,,.T.,,.F.,{|| .F.},.F.,.F.,/*bChange*/,.F.,.F.,,"cCpDesGrp",,,,.T.,.F.)
	endif

	//seta variáveis chaves para ja vir preenhido
	CriaVarM(nOpcX,lPdv)

	EnChoice( "U25",,4,,,,,aPObj[1+nPObj],GetFieldEdit(nOpcx, lPDV)) //cria campos na parte de cima, para inclusão

	//Definindo botões
	oBtnInc := TButton():New( aPObj[2+nPObj,1], aPObj[2+nPObj,2], "Incluir Preço", oDlg01, {|| IIF( obrigatorio(aGets,aTela),DoInclui(nOpcX, lPdv),NIL) }, 45, 12,,,.F.,.T.,.F.,,.F.,,,.F. )
	oBtnInc:SetCSS(CSS_BOTAO)
//		TButton():New( aPObj[2+nPObj,1], aPObj[2+nPObj,2]+50, "Excluir Preço", oDlg01, {|| IIF( ValidExc(),DoExclui(nOpcX, lPdv),NIL) }, 45, 12,,,.F.,.T.,.F.,,.F.,,,.F. )
	TButton():New( aPObj[2+nPObj,1], aPObj[2+nPObj,2]+50, "Encerrar Preço", oDlg01, {|| DoEncerra(nOpcX, lPdv) }, 45, 12,,,.F.,.T.,.F.,,.F.,,,.F. )
	TCheckBox():New( aPObj[2+nPObj,1]+3, aPObj[2+nPObj,2]+100,'Limpar tela ao incluir', {|u| iif( PCount()==0,lLimpForm,lLimpForm:= u) },oDlg01,100,12,,,,,,,,.T.,,,)
	TCheckBox():New( aPObj[2+nPObj,1]+3, aPObj[2+nPObj,2]+170,'Selecionar Filiais ?', {|u| iif( PCount()==0,lSelFilial,lSelFilial:= u) },oDlg01,100,12,,,,,,,,.T.,,,) // Gianluka Moraes | 13/07/16 : Flag para selecionar se irá inserir em mais de uma filial.

	TSay():New( aPObj[2+nPObj,1]+3, aPObj[2+nPObj,2]+240,{|| "Replicar:"},oDlg01,,,,,,.T.,,,250,9 )
	aItems := {'Preco Venda','Desc/Acresc'}
	oRdMenu := TRadMenu():New (aPObj[2+nPObj,1]+2,aPObj[2+nPObj,2]+265,aItems,,oDlg01,,,,,,,,100,12,,,,.T.,.T.)
	oRdMenu:bSetGet := {|u| iif(PCount()==0,nTipoRep,nTipoRep:=u)}

	TCheckBox():New( aPObj[2+nPObj,1]+3, aPObj[2+nPObj,4]-190, 'Mostrar só vigentes.', {|u| iif( PCount()==0,lShowVig,lShowVig:= u) },oDlg01,100,12,,{|| Processa({|| LoadOGet1(nOpcX, lPdv, .T.)},"Aguarde...","Carregando registros...",.T.) },,,,,,.T.,,,)
	TCheckBox():New( aPObj[2+nPObj,1]+3, aPObj[2+nPObj,4]-120, 'Mostrar todos preços.', {|u| iif( PCount()==0,lShowAll,lShowAll:= u) },oDlg01,100,12,,{|| Processa({|| LoadOGet1(nOpcX, lPdv, .T.)},"Aguarde...","Carregando registros...",.T.) },,,,,,.T.,,,)
	TButton():New( aPObj[2+nPObj,1], aPObj[2+nPObj,4]-45, "Filtrar Preços", oDlg01, {|| DoFiltro(nOpcX, lPdv) }, 45, 12,,,.F.,.T.,.F.,,.F.,,,.F. )

	//#IFDEF TOP
	//TSay():New( aPObj[2+nPObj,1]+3, aPObj[2+nPObj,4]-196,{|| "Ordenar por:" }, oDlg01,,,,,,.T.,CLR_BLACK,,85,9 )
	//TComboBox():New(aPObj[2+nPObj,1]+1, aPObj[2+nPObj,4]-163, {|u| iif( PCount()==0,cOrdem,cOrdem:= u) },aOrdem, 115, 9, oDlg01,,{|| LoadOGet1(nOpcX, lPdv, .T.) }, /*bValid*/,,,.T.,,,,{|| .T.},,,,"cOrdem")
	TSay():New( aPObj[2+nPObj,3]+5, aPObj[2+nPObj,4]-100,{|| if(empty(cFilGrid),"","(Os itens listados estão filtrados)") }, oDlg01,,,,,,.T.,CLR_RED,,250,9 )
	//#ELSE
	//TSay():New( aPObj[2+nPObj,1]+3, aPObj[2+nPObj,4]-130,{|| if(empty(cFilGrid),"","(Os itens abaixo estão filtrados)") }, oDlg01,,,,,,.T.,CLR_RED,,250,9 )
	//#ENDIF

	oMSGet1 := GetDados1(oDlg01,nOpcX, lPdv)
	oMSGet1:oBrowse:bHeaderClick := {|oObj,nCol| if(nCol > 0, (U_UOrdGrid(@oMSGet1, @nCol), oMSGet1:Refresh()), )}
	Processa({|| LoadOGet1(nOpcX, lPdv, .F.)},"Aguarde...","Carregando registros...",.T.) //carrega dados iniciais

	@ aPObj[2+nPObj,3]+5, 10 BITMAP oLeg ResName "BR_VERDE" OF oDlg01 Size 10, 10 NoBorder When .F. PIXEL
	@ aPObj[2+nPObj,3]+5, 20 SAY "Preço Vigente" OF oDlg01 Color CLR_BLACK PIXEL

	@ aPObj[2+nPObj,3]+5, 60 BITMAP oLeg ResName "BR_VERMELHO" OF oDlg01 Size 10, 10 NoBorder When .F. PIXEL
	@ aPObj[2+nPObj,3]+5, 70 SAY "Preço NÃO Vigente    (considerando data base e hora atual)" OF oDlg01 Color CLR_BLACK PIXEL

	//enchoice bar
	//oDlg01:bInit := {|| EnchoiceBar(oDlg01, {|| oDlg01:End()},{|| oDlg01:End()},.F.,@aButtons,0,"U25") }
	oDlg01:lCentered := .T.

	oDlg01:Activate()

Return

//----------------------------------------------------
// ação ao marcar checkbox
//----------------------------------------------------
Static Function DoCheckCab(nOpcX)

	CriaVarM(nOpcX)

	oRadCliPro:Refresh()
	oRadGrupo:Refresh()
	GetDRefresh()

Return

/*
_____________________________________________________________________________
¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦
¦¦+-----------------------------------------------------------------------+¦¦
¦¦¦Programa  ¦ InPadEnch 	¦ Autor ¦ Danilo Brito    ¦ Data ¦ 17/04/2014 ¦¦¦
¦¦+----------+------------------------------------------------------------¦¦¦
¦¦¦Descriçào ¦ Reseta form, com inicializadores padrão de cada campo      ¦¦¦
¦¦+----------+------------------------------------------------------------¦¦¦
¦¦¦Uso       ¦ Posto Inteligente			                              ¦¦¦
¦¦+-----------------------------------------------------------------------+¦¦
¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦
¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
*/
Static Function InPadEnch(nOpcX, lPdv)

	Local nX := 0
	Local aSX3U25

	if !lLimpForm
		U25->(DbGoTo(nRecU25))
		aSX3U25 := FWSX3Util():GetAllFields( "U25" , .T./*lVirtual*/ )
		If !empty(aSX3U25)
			For nX := 1 to len(aSX3U25)
				If X3Uso(GetSx3Cache(aSX3U25[nX],"X3_USADO")) .and. cNivel >= GetSx3Cache(aSX3U25[nX],"X3_NIVEL")
					if GetSx3Cache(aSX3U25[nX],"X3_CONTEXT") == "V"
						M->&(aSX3U25[nX]) := CriaVar(aSX3U25[nX], .T.)
					else
						M->&(aSX3U25[nX]) := U25->&(aSX3U25[nX])
					endif
				Endif
			next nX
		endif
	else
		U25->(DbGoBottom())
		U25->(DbSkip())

		aSX3U25 := FWSX3Util():GetAllFields( "U25" , .T./*lVirtual*/ )
		If !empty(aSX3U25)
			For nX := 1 to len(aSX3U25)
				If X3Uso(GetSx3Cache(aSX3U25[nX],"X3_USADO")) .and. cNivel >= GetSx3Cache(aSX3U25[nX],"X3_NIVEL")
					if GetSx3Cache(aSX3U25[nX],"X3_CONTEXT") == "V"
						if GetSx3Cache(aSX3U25[nX],"X3_TIPO") == "N"
							M->&(aSX3U25[nX]) := 0
						else
							M->&(aSX3U25[nX]) := " " //limpo memoria
						endif
					else
						M->&(aSX3U25[nX]) := CriaVar(aSX3U25[nX], .T.)
					endif
				Endif
			next nX
		endif
	endif

	//seta variáveis chaves para ja vir preenhido
	CriaVarM(nOpcX,lPdv)

Return

//seta variáveis chaves para ja vir preenhido
Static Function CriaVarM(nOpcX,lPdv)

	//seta variáveis chaves para ja vir preenhido
	if nOpcX == 1 //se por produto
		M->U25_PRODUT := SB1->B1_COD
		M->U25_DESPRO := SB1->B1_DESC
		if U25->( FieldPos("U25_DESPBA") ) > 0
			M->U25_PRCTAB := U_URetPrec(M->U25_PRODUT,,.F.)
			M->U25_PRCBAS := U_URetPrBa(M->U25_PRODUT,M->U25_FORPAG,M->U25_CONDPG,M->U25_ADMFIN,0,M->U25_DTINIC,M->U25_HRINIC)
		endif
	else //por cliente
		if lPDV
			DbSelectArea("SA1")
			SA1->(DbSetOrder(1))
			if SA1->(DbSeek(xFilial("SA1")+_cCliente+_cLoja))
				M->U25_CLIENT := SA1->A1_COD
				M->U25_LOJA	  := SA1->A1_LOJA
				M->U25_NOMCLI := SA1->A1_NOME
				M->U25_FLAGVD := "S"
				M->U25_PLACA  := _cPlaca
				if _cAdmFin <> Nil .AND. !empty(_cAdmFin)
					M->U25_ADMFIN := _cAdmFin
					M->U25_DESADM := POSICIONE('SAE',1,XFILIAL('SAE')+_cAdmFin,'AE_DESC')
				endif
				if _cEmiCh <> Nil .AND. !empty(_cEmiCh)
					M->U25_EMITEN := _cEmiCh
				endif
				if _cLojEmi <> Nil .AND. !empty(_cLojEmi)
					M->U25_LOJEMI := _cLojEmi
				endif
				if _cEmiCh <> Nil .AND. !empty(_cEmiCh) .AND. _cLojEmi <> Nil .AND. !empty(_cLojEmi)
					M->U25_NOMEMI := U_TRET023H("SA1",1,XFILIAL("SA1")+_cEmiCh+_cLojEmi,"A1_NOME")
				endif
				if _cFormPg <> Nil .AND. !empty(_cFormPg)
					M->U25_FORPAG := _cFormPg
				endif
				if _cCondPg <> Nil .AND. !empty(_cCondPg)
					M->U25_CONDPG := _cCondPg
				endif
				M->U25_DTINIC  := dDataBase
				M->U25_DTFIM  := dDataBase
				M->U25_HRFIM  := "23:59"
			else
				Help( ,, 'Help',, "Informe o Cliente/Loja e Placa para abrir esta opção.", 1, 0 )
				Return
			endif
		else
			if lRadCliPro
				M->U25_CLIENT := cCpCodCli
				M->U25_LOJA	  := cCpLojCli
				M->U25_GRPCLI := space(len(M->U25_GRPCLI))
				M->U25_NOMCLI := cCpNomDes
			else
				M->U25_CLIENT := space(len(M->U25_CLIENT))
				M->U25_LOJA	  := space(len(M->U25_LOJA))
				M->U25_GRPCLI := cCpGrpCli
				M->U25_NOMCLI := cCpDesGrp
			endif
		endif
	endif

Return

/*
_____________________________________________________________________________
¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦
¦¦+-----------------------------------------------------------------------+¦¦
¦¦¦Programa  ¦ GetFieldEdit ¦ Autor ¦ Danilo Brito     ¦ Data ¦ 17/04/2014 ¦¦¦
¦¦+----------+------------------------------------------------------------¦¦¦
¦¦¦Descriçào ¦ Pega campos que podem ser editados. Utilizado para         ¦¦¦
¦¦¦          ¦ bloquear campos na enchoice								  ¦¦¦
¦¦+----------+------------------------------------------------------------¦¦¦
¦¦¦Uso       ¦ Posto Inteligente			                              ¦¦¦
¦¦+-----------------------------------------------------------------------+¦¦
¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦
¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
*/
Static Function GetFieldEdit(nOpc, lPDV)

	Local aArea := GetArea()
	Local aCposAlt := {}
	Local aSX3U25, nX

	aSX3U25 := FWSX3Util():GetAllFields( "U25" , .T./*lVirtual*/ )
	If !empty(aSX3U25)
		For nX := 1 to len(aSX3U25)
			If X3Uso(GetSx3Cache(aSX3U25[nX],"X3_USADO")) .and. cNivel >= GetSx3Cache(aSX3U25[nX],"X3_NIVEL")

				if nOpc == 1 //por produto
					if alltrim(aSX3U25[nX]) == "U25_PRODUT"
						LOOP
					endif
				elseif nOpc == 2 //por cliente
					if alltrim(aSX3U25[nX]) $ "U25_CLIENT/U25_LOJA/U25_GRPCLI"
						LOOP
					endif
				endif

				if lPDV
					if alltrim(aSX3U25[nX]) $ "U25_FLAGVD/U25_PLACA/U25_DTINIC"
						LOOP
					endif
					//opcionais
					if _cAdmFin <> Nil .AND. !empty(_cAdmFin) .AND. alltrim(aSX3U25[nX]) == "U25_ADMFIN"
						LOOP
					endif
					if _cEmiCh <> Nil .AND. !empty(_cEmiCh) .AND. alltrim(aSX3U25[nX]) == "U25_EMITEN"
						LOOP
					endif
					if _cLojEmi <> Nil .AND. !empty(_cLojEmi) .AND. alltrim(aSX3U25[nX]) == "U25_LOJEMI"
						LOOP
					endif
					if _cFormPg <> Nil .AND. !empty(_cFormPg) .AND. alltrim(aSX3U25[nX]) == "U25_FORPAG"
						LOOP
					endif
					if _cCondPg <> Nil .AND. !empty(_cCondPg) .AND. alltrim(aSX3U25[nX]) == "U25_CONDPG"
						LOOP
					endif
				endif

				aadd(aCposAlt, aSX3U25[nX])

			Endif
		next nX
	endif

	RestArea(aArea)
Return aCposAlt

/*
_____________________________________________________________________________
¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦
¦¦+-----------------------------------------------------------------------+¦¦
¦¦¦Programa  ¦ GetDados1   ¦ Autor ¦ Danilo Brito     ¦ Data ¦ 17/04/2014 ¦¦¦
¦¦+----------+------------------------------------------------------------¦¦¦
¦¦¦Descriçào ¦ Estrutura do Grid de Itens da Negociaçao. 			      ¦¦¦
¦¦¦          ¦ 															  ¦¦¦
¦¦+----------+------------------------------------------------------------¦¦¦
¦¦¦Uso       ¦ Posto Inteligente			                              ¦¦¦
¦¦+-----------------------------------------------------------------------+¦¦
¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦
¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
*/
Static Function GetDados1(oComp,nOpcX, lPdv)

	Local aArea := GetArea()
	Local aCmpNot := {}
	Local aTemp := {}
	Local aHeader := {}
	Local aCols := {}
	Local aAlterFields := {}
	Local nX, aSX3U25

	/*if nOpcX == 1 //se por produto
   		aCmpNot := {"U25_PRODUT","U25_DESPRO"}
   	elseif nOpcX == 2 //por cliente
	 	aCmpNot := {"U25_CLIENT","U25_LOJA","U25_NOMCLI",}
 	else
 		return
   	endif */

	aHeader := {{ '',"LEG",'@BMP',2,0,'','€€€€€€€€€€€€€€','C','','V'},{},{},{},{},{}}

	//cria variaveis do alias na memória
	aSX3U25 := FWSX3Util():GetAllFields( "U25" , .T./*lVirtual*/ )
	If !empty(aSX3U25)
		For nX := 1 to len(aSX3U25)
			If (X3Uso(GetSx3Cache(aSX3U25[nX],"X3_USADO")) .OR. GetSx3Cache(aSX3U25[nX],"X3_BROWSE") == 'S') .and. cNivel >= GetSx3Cache(aSX3U25[nX],"X3_NIVEL")

				if aScan(aCmpNot, alltrim(aSX3U25[nX])) == 0 //somente se não achar

					aTemp := U_UAHEADER(aSX3U25[nX])

					//os 6 primeiros campos do grid são de posição fixa
					if alltrim(aSX3U25[nX]) == "U25_DTINIC"
						aHeader[2] := aTemp
					elseif alltrim(aSX3U25[nX]) == "U25_HRINIC"
						aHeader[3] := aTemp
					elseif alltrim(aSX3U25[nX]) == "U25_PRCBAS"
						aHeader[4] := aTemp
					elseif alltrim(aSX3U25[nX]) == "U25_PRCVEN"
						aHeader[5] := aTemp
					elseif alltrim(aSX3U25[nX]) == "U25_DESPBA"
						aHeader[6] := aTemp
					else
						AADD( aHeader, aTemp)
					endif
				Endif

			Endif
		next nX
	endif

	//validando posições fixas
	for nX := 1 to 4
		if len(aHeader[nX]) == 0
			Help(,,"Atenção",,"Campos obrigatorios da rotina não estão configurados corretamente na base SX3.",1,0,,,,,,{""})
			return Nil
		endif
	next nX

	RestArea(aArea)

Return MsNewGetDados():New(aPObj[2+nPObj,1]+15,aPObj[2+nPObj,2],aPObj[2+nPObj,3],aPObj[2+nPObj,4],, ;
		"AllwaysTrue", "AllwaysTrue",, aAlterFields, 1/*nFreeze*/, 9999, "AllwaysTrue", "", "AllwaysTrue", oComp, aHeader, aCols)

/*
_____________________________________________________________________________
¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦
¦¦+-----------------------------------------------------------------------+¦¦
¦¦¦Programa  ¦ LoadOGet1   ¦ Autor ¦ Danilo Brito     ¦ Data ¦ 17/04/2014 ¦¦¦
¦¦+----------+------------------------------------------------------------¦¦¦
¦¦¦Descriçào ¦ Carrega Grid de Itens da Negociaçao.						  ¦¦¦
¦¦¦          ¦ 															  ¦¦¦
¦¦+----------+------------------------------------------------------------¦¦¦
¦¦¦Uso       ¦ Posto Inteligente			                              ¦¦¦
¦¦+-----------------------------------------------------------------------+¦¦
¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦
¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
*/
Static Function LoadOGet1(nOpcX, lPdv, lRefresh)

	Local cQry := ""
	Local cMyAlias := ""
	Local cMyRecno := 0
	Local nI := 0
	Local cCondicao		:= ""
	Local bCondicao
	Local nNumRows := 0
	Local choraini := Time()
	Local cCorLeg := 'BR_VERMELHO'
	Local lPAtivo := .F.
	Local aRetU0G := {}	//U0G_PRCBAS, U0G_DTINIC, U0G_HRINIC, U0G_USHIST, U0G_DTHIST, U0G_HRHIST
	Local bGetUser := {|cCod| FWGETUSERNAME(cCod) }
	Local lNgDesc := SuperGetMV("MV_XNGDESC",,.T.) //Ativa negociação pelo valor de desconto: U25_DESPBA
	Local cSGBD 	 	:= Upper(AllTrim(TcGetDB()))	// Guarda Gerenciador de banco de dados

	DbSelectArea("U25")
	U25->(DbSetOrder(nOpcX+1+iif(nOpcX==0,1,0)))

	#IFDEF TOP

		cMyAlias := "QRYTMP"

		//fazer select e add registros retornados no acols
		If Select(cMyAlias) > 0
			QRYTMP->(DbCloseArea())
		Endif

		if lShowAll .OR. "ORACLE" $ cSGBD //Oracle 
			cQry := " SELECT U25.R_E_C_N_O_ "
		else
			cQry := " SELECT TOP 100 U25.R_E_C_N_O_ "
		endif
		cQry += " FROM "+RetSqlName("U25")+" U25 "
		cQry += " WHERE U25.D_E_L_E_T_ <> '*' "
		cQry += " 	AND U25_FILIAL = '"+xFilial("U25")+"' "

		//filtro da opção
		if nOpcX == 1 //se por produto
			cQry += "	AND U25_PRODUT = '"+SB1->B1_COD+"' "
		elseif nOpcX == 2 //por cliente
			if lPDV
				cQry += "	AND ((U25_CLIENT||U25_LOJA) = '"+SA1->A1_COD+SA1->A1_LOJA+"' ) "
			else
				if empty(cCpGrpCli)
					cQry += "	AND ((U25_CLIENT||U25_LOJA) = '"+cCpCodCli+cCpLojCli+"' ) "
				else
					cQry += "	AND ((U25_CLIENT||U25_LOJA) = '"+cCpCodCli+cCpLojCli+"' OR U25_GRPCLI = '"+cCpGrpCli+"') "
				endif
			endif
		endif

		if lShowVig
			cQry += "	AND U25_DTINIC||U25_HRINIC <= '"+ DTOS(DDATABASE) + SUBSTR(Time(),1,5) + "' "
			cQry += "  AND (U25_DTFIM = ' ' OR U25_DTFIM||U25_HRFIM >= '"+ DTOS(DDATABASE) + SUBSTR(Time(),1,5) + "' ) "
		endif

		if lPDV
			cQry += "	AND U25_FLAGVD = 'S' "
			cQry += "	AND U25_NUMORC = '' "
			cQry += "	AND U25_PLACA = '"+_cPlaca+"' "
			//opcionais
			if _cAdmFin <> Nil .AND. !empty(_cAdmFin)
				cQry += "	AND U25_ADMFIN = '"+_cAdmFin+"' "
			endif
			if _cEmiCh <> Nil .AND. !empty(_cEmiCh)
				cQry += "	AND U25_EMITEN = '"+_cEmiCh+"' "
			endif
			if _cLojEmi <> Nil .AND. !empty(_cLojEmi)
				cQry += "	AND U25_LOJEMI = '"+_cLojEmi+"' "
			endif
			if _cFormPg <> Nil .AND. !empty(_cFormPg)
				cQry += "	AND U25_FORPAG = '"+_cFormPg+"' "
			endif
			if _cCondPg <> Nil .AND. !empty(_cCondPg)
				cQry += "	AND U25_CONDPG = '"+_cCondPg+"' "
			endif
		endif

		if lRefresh .AND. !empty(cFilGrid)
			cQry += " AND " + cFilGrid
		endif

		if !lShowAll .AND. "ORACLE" $ cSGBD //Oracle 
			cQry += " AND ROWNUM <= 100"
		endif

		if val(cOrdem) > len(aCpOrd) .or. val(cOrdem) < 0
			cOrdem := "1" //segurança para evitar "array out of bounds"
		endif

		if val(cOrdem) > 0 .and. len(aCpOrd) > 0 .and. val(cOrdem) <= len(aCpOrd)
			cQry += "	ORDER BY " + aCpOrd[val(cOrdem)]
		endif

		cQry := ChangeQuery(cQry)
		TcQuery cQry NEW Alias "QRYTMP"

	#ELSE

		cMyAlias := "U25"

		cCondicao := " U25_FILIAL == '"+xFilial("U25")+"' "

		//filtro da opção
		if nOpcX == 1 //se por produto
			cCondicao += "	.AND. U25_PRODUT == '"+SB1->B1_COD+"' "
		elseif nOpcX == 2 //por cliente
			if lPDV
				cCondicao += "	.AND. ((U25_CLIENT+U25_LOJA) == '"+SA1->A1_COD+SA1->A1_LOJA+"' ) "
			else
				if empty(cCpGrpCli)
					cCondicao += "	.AND. ((U25_CLIENT+U25_LOJA) == '"+cCpCodCli+cCpLojCli+"' ) "
				else
					cCondicao += "	.AND. ((U25_CLIENT+U25_LOJA) == '"+cCpCodCli+cCpLojCli+"' .OR. U25_GRPCLI = '"+cCpGrpCli+"') "
				endif
			endif
		endif

		if lPDV
			cCondicao += "	.AND. U25_FLAGVD == 'S' "
			cCondicao += "	.AND. empty(U25_NUMORC) "
			cCondicao += "	.AND. U25_PLACA == '"+_cPlaca+"' "
			//opcionais
			if _cAdmFin <> Nil .AND. !empty(_cAdmFin)
				cCondicao += "	.AND. U25_ADMFIN == '"+_cAdmFin+"' "
			endif
			if _cEmiCh <> Nil .AND. !empty(_cEmiCh)
				cCondicao += "	.AND. U25_EMITEN == '"+_cEmiCh+"' "
			endif
			if _cLojEmi <> Nil .AND. !empty(_cLojEmi)
				cCondicao += "	.AND. U25_LOJEMI == '"+_cLojEmi+"' "
			endif
			if _cFormPg <> Nil .AND. !empty(_cFormPg)
				cCondicao += "	.AND. U25_FORPAG == '"+_cFormPg+"' "
			endif
			if _cCondPg <> Nil .AND. !empty(_cCondPg)
				cCondicao += "	.AND. U25_CONDPG == '"+_cCondPg+"' "
			endif
		endif

		if lRefresh .AND. !empty(cFilGrid)
			cCondicao += " .AND. " + cFilGrid
		endif

		// limpo os filtros da U25
		U25->(DbClearFilter())

		// executo o filtro na U25
		bCondicao 	:= "{|| " + cCondicao + " }"
		U25->(DbSetFilter(&bCondicao,cCondicao))
		U25->(DbGoTop())

	#ENDIF

	DbSelectArea("U25")
	aSize(oMSGet1:aCols, 0)

	ProcRegua(100)

	While (cMyAlias)->(!EOF()) .AND. (lShowAll .OR. nNumRows <= 100)

		IncProc("Carregando Preços Negociados..." )

		if cMyAlias == "U25"
			cMyRecno := U25->(Recno())
		else
			cMyRecno := QRYTMP->R_E_C_N_O_
			U25->(DbGoTo(cMyRecno))
		endif

		cCorLeg := U25Legend() //cor a legenda: Preto (preço bloqueado), Verde (preço ativo) ou Vermelho (preço vencido)
		lPAtivo := (cCorLeg == 'BR_VERDE') //preço ativo
		aRetU0G := U_URetU0G(U25->U25_PRODUT, U25->U25_FORPAG, U25->U25_CONDPG, U25->U25_ADMFIN, {U25->U25_DTINIC,U25->U25_HRINIC,U25->U25_DTFIM,U25->U25_HRFIM}, lPAtivo)

		aadd(oMSGet1:aCols, Array(Len(oMSGet1:aHeader)+2))

		For nI := 1 To Len(oMSGet1:aHeader)
			if AllTrim(oMSGet1:aHeader[nI][2]) == "LEG"
				oMSGet1:aCols[Len(oMSGet1:aCols), nI] := cCorLeg
			else
				If AllTrim(oMSGet1:aHeader[nI][2]) == "U25_PRCVEN" .and. lNgDesc // tratamento pra o campo U25_PRCVEN (campo "virtual")
					nPrcBas := U_URetPrBa(U25->U25_PRODUT, U25->U25_FORPAG, U25->U25_CONDPG, U25->U25_ADMFIN, 0, U25->U25_DTINIC, U25->U25_HRINIC)
					oMSGet1:aCols[Len(oMSGet1:aCols),nI] := (nPrcBas - U25->U25_DESPBA)
				ElseIf AllTrim(oMSGet1:aHeader[nI][2]) == "U25_PRBOLD" .and. lNgDesc // tratamento pra o campo U25_PRBOLD
					oMSGet1:aCols[Len(oMSGet1:aCols),nI] := aRetU0G[1]
				ElseIf AllTrim(oMSGet1:aHeader[nI][2]) == "U25_PRVOLD" .and. lNgDesc // tratamento pra o campo U25_PRVOLD
					nPrcBas := aRetU0G[1]
					oMSGet1:aCols[Len(oMSGet1:aCols),nI] := Iif(aRetU0G[1]=0,0,(nPrcBas - U25->U25_DESPBA))
				ElseIf AllTrim(oMSGet1:aHeader[nI][2]) == "U25_DTINRE" .and. lNgDesc // tratamento pra o campo U25_DTINRE
					oMSGet1:aCols[Len(oMSGet1:aCols),nI] := aRetU0G[2]
				ElseIf AllTrim(oMSGet1:aHeader[nI][2]) == "U25_HRINRE" .and. lNgDesc // tratamento pra o campo U25_HRINRE
					oMSGet1:aCols[Len(oMSGet1:aCols),nI] := aRetU0G[3]
				ElseIf AllTrim(oMSGet1:aHeader[nI][2]) == "U25_USHIST" .and. lNgDesc // tratamento pra o campo U25_USHIST
					oMSGet1:aCols[Len(oMSGet1:aCols),nI] := aRetU0G[4]
				ElseIf AllTrim(oMSGet1:aHeader[nI][2]) == "U25_NUHIST" .and. lNgDesc // tratamento pra o campo U25_NUHIST
					oMSGet1:aCols[Len(oMSGet1:aCols),nI] := Eval(bGetUser, aRetU0G[4])
				ElseIf AllTrim(oMSGet1:aHeader[nI][2]) == "U25_DTHIST" .and. lNgDesc // tratamento pra o campo U25_DTHIST
					oMSGet1:aCols[Len(oMSGet1:aCols),nI] := aRetU0G[5]
				ElseIf AllTrim(oMSGet1:aHeader[nI][2]) == "U25_HRHIST" .and. lNgDesc // tratamento pra o campo U25_HRHIST
					oMSGet1:aCols[Len(oMSGet1:aCols),nI] := aRetU0G[6]
				ElseIf oMSGet1:aHeader[nI][10] == "R" // Campo é real.
					oMSGet1:aCols[Len(oMSGet1:aCols),nI] := U25->&(oMSGet1:aHeader[nI,2])  //FieldGet(FieldPos(oMSGet1:aHeader[nI,2])) // Carrega o conteudo do campo.
				Else
					oMSGet1:aCols[Len(oMSGet1:aCols),nI] := &(oMSGet1:aHeader[nI,12])
				EndIf
			endif
		Next nI
		oMSGet1:aCols[Len(oMSGet1:aCols),Len(oMSGet1:aHeader)+1] := cMyRecno
		oMSGet1:aCols[Len(oMSGet1:aCols),Len(oMSGet1:aHeader)+2] := .F.

		nNumRows++
		(cMyAlias)->(DbSkip())
	EndDo

	if cMyAlias == "U25"
		U25->(DbClearFilter())
	else
		QRYTMP->(DbCloseArea())
	endif

	if len(oMSGet1:aCols) == 0 //Se não tem itens, adiciona linha em branco
		U25->(DbGoBottom())
		U25->(DbSkip())

		aadd(oMSGet1:aCols, Array(Len(oMSGet1:aHeader) + 2))

		For nI := 1 To Len(oMSGet1:aHeader)
			If oMSGet1:aHeader[nI][2] == "LEG"
				oMSGet1:aCols[1, nI] := ""
			Else
				If !Empty(GetSx3Cache(oMSGet1:aHeader[nI][2],"X3_CAMPO"))
					If oMSGet1:aHeader[nI][8] == "C"
						//If ExistIni(oMSGet1:aHeader[nI][2])
						//	oMSGet1:aCols[1, nI] := InitPad(oMSGet1:aHeader[nI][12])
						//Else
						oMSGet1:aCols[1, nI] := SPACE(oMSGet1:aHeader[nI][4])
						//EndIF
					ElseIf oMSGet1:aHeader[nI][8] == "N"
						oMSGet1:aCols[1, nI] := 0
					ElseIf oMSGet1:aHeader[nI][8] == "D"
						oMSGet1:aCols[1, nI] := CTOD("  /  /  ")
					ElseIf oMSGet1:aHeader[nI][8] == "M"
						oMSGet1:aCols[1, nI] := ""
					Else //boleano
						oMSGet1:aCols[1, nI] := .F.
					EndIf
				Else
					oMSGet1:aCols[1, nI] := CriaVar(oMSGet1:aHeader[nI, 2], .T.)
				EndIf
			EndIf
		Next nI

		oMSGet1:aCols[1,Len(oMSGet1:aHeader)+1] := 0
		oMSGet1:aCols[1,Len(oMSGet1:aHeader)+2] := .F.

	Endif

	InPadEnch(nOpcX, lPdv)

	if lRefresh
		oMSGet1:Refresh()
	endif

Return

/*
_____________________________________________________________________________
Função que define campos chaves da tabela U25
¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
*/
User Function TRET023A(aCampos,lSoCps,lFlagVd)

	Local aRet 			:= {"",""}
	Local aCpsChav 		:= {"U25_PRODUT","U25_CLIENT","U25_LOJA","U25_GRPCLI","U25_FORPAG","U25_CONDPG"}
	Local nX			:= 0
	Local nPosCampos	:= 0

	Default lSoCps := .F.
	Default lFlagVd := .F.

	if !lFlagVd
		aadd(aCpsChav, "U25_ADMFIN")
		aadd(aCpsChav, "U25_EMITEN")
		aadd(aCpsChav, "U25_LOJEMI")
		aadd(aCpsChav, "U25_PLACA")
	endif

	if lSoCps
		aRet := aClone(aCpsChav)
	else

		if aCampos == Nil
			aRet[1] := "U25->U25_FILIAL"
			aRet[2] := U25->U25_FILIAL
			for nX := 1 to len(aCpsChav)
				aRet[1] += "+"+Alltrim(aCpsChav[nX])
				aRet[2] += U25->&(aCpsChav[nX])
			next nX
		else
			aRet[1] := "U25->U25_FILIAL"
			aRet[2] := xFilial("U25")

			for nX := 1 to len(aCpsChav)
				
				// verifico se o campo existe
				nPosCampos := aScan(aCampos,{|x| Trim(x[1])== Alltrim(aCpsChav[nX])})

				// caso tenha encontrado o campo adiciono no retorno
				If nPosCampos > 0
					aRet[1] += "+"+Alltrim(aCpsChav[nX])
					aRet[2] += aCampos[nPosCampos][2]
				EndIf

			next nX

		endif
	endif
Return aRet

/*
_____________________________________________________________________________
¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦
¦¦+-----------------------------------------------------------------------+¦¦
¦¦¦Programa  ¦ TRET023B   ¦ Autor ¦ Danilo Brito      ¦ Data ¦ 17/04/2014 ¦¦¦
¦¦+----------+------------------------------------------------------------¦¦¦
¦¦¦Descriçào ¦ Faz validação para inclusão de uma nova regra negociação.  ¦¦¦
¦¦¦          ¦ 															  ¦¦¦
¦¦+----------+------------------------------------------------------------¦¦¦
¦¦¦Uso       ¦ Posto Inteligente			                              ¦¦¦
¦¦+-----------------------------------------------------------------------+¦¦
¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦
¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
*/
User Function TRET023B( aCampos, cSeq, cLog)

	Local nPosProd := aScan(aCampos,{|x| Trim(x[1])== "U25_PRODUT"})
	Local nPosDesP := aScan(aCampos,{|x| Trim(x[1])== "U25_DESPRO"})
	Local nPosCli  := aScan(aCampos,{|x| Trim(x[1])== "U25_CLIENT"})
	Local nPosLoja := aScan(aCampos,{|x| Trim(x[1])== "U25_LOJA"})
	Local nPosNmCli := aScan(aCampos,{|x| Trim(x[1])== "U25_NOMCLI"})
	Local nPosGrpC := aScan(aCampos,{|x| Trim(x[1])== "U25_GRPCLI"})
	Local nPosForma := aScan(aCampos,{|x| Trim(x[1])== "U25_FORPAG"})
	Local nPosCond := aScan(aCampos,{|x| Trim(x[1])== "U25_CONDPG"})
	Local nPosDsNeg := aScan(aCampos,{|x| Trim(x[1])== "U25_DESCPG"})
	Local nPosAdmF := aScan(aCampos,{|x| Trim(x[1])== "U25_ADMFIN"})
	Local nPosDsAd := aScan(aCampos,{|x| Trim(x[1])== "U25_DESADM"})
	Local nPosEmit := aScan(aCampos,{|x| Trim(x[1])== "U25_EMITEN"})
	Local nPosLojEm := aScan(aCampos,{|x| Trim(x[1])== "U25_LOJEMI"})
	Local nPosNmEmi := aScan(aCampos,{|x| Trim(x[1])== "U25_NOMEMI"})
	Local nPosDtIn := aScan(aCampos,{|x| Trim(x[1])== "U25_DTINIC"})
	Local nPosHrIn := aScan(aCampos,{|x| Trim(x[1])== "U25_HRINIC"})
	Local nPosPrcV := aScan(aCampos,{|x| Trim(x[1])== "U25_PRCVEN"})
	Local nPosDesc := aScan(aCampos,{|x| Trim(x[1])== "U25_DESPBA"})
	Local nPosFlag := aScan(aCampos,{|x| Trim(x[1])== "U25_FLAGVD"})
	Local nPosDtFim := aScan(aCampos,{|x| Trim(x[1])== "U25_DTFIM"})
	Local nPosHrFim := aScan(aCampos,{|x| Trim(x[1])== "U25_HRFIM"})
	Local nPosPlaca := aScan(aCampos,{|x| Trim(x[1])== "U25_PLACA"})
	Local nPosVlrMin := aScan(aCampos,{|x| Trim(x[1])== "U25_VLRMIN"})

	Local aArea := GetArea()
	Local aAreaSA1 := SA1->(GetArea())
	Local aAreaSB1 := SB1->(GetArea())
	Local aAreaU44 := U44->(GetArea())
	Local aAreaU25 := U25->(GetArea())
	Local lRet := .T.
	Local nMargMin := 0 //margem mínima
	Local nMargDes := 0 //margem desejada
	Local nVDescMax := 0 //Valor desconto Máximo
	Local nPDescMax := 0 //% desconto máximo
	Local nPrcCusto := 0 //preço de custo do produto
	Local nPrcTab := 0 //preço de venda padrão
	Local cGrpCliVld := Space(6)
	Local cMsgSeq   := iif(cSeq==Nil,"","Item Seq.: "+cSeq+cEOL)
	Local cErro := ""
	Local _cPadrao
	Local aChaves := {}
	Local _aUsuario
	Local aGrupos := {}
	Local _cCodUsr
	Local cSacado	:= ""
	Local lNoMsg	:= cLog<>Nil
	Local cMsgLog	:= ""
	Local cFormaX := ""
	Local cMV_XFLTPDV := SuperGetMv("MV_XFLTPDV",,"") //filiais que ja são totvspdv

	/*/ MV_XATUPRC - tipo de negociação no Totvs PDV
	.T. - Trabalha com preço maior que o preço de tabela (não tem desconto, ajuste preço unitário)
	.F. - Trabalha com desconto no preço de tabela (não ajusta preço unitário, trabalha com desconto)
	/*/
	Local lAltVrUnit := SuperGetMv("MV_XATUPRC",.T./*lHelp*/,.T./*uPadrao*/)

	cFormaX := aCampos[nPosForma][2]

	//DANILO: alteração de CCP e CDP para CC e CD
	if cFilAnt $ cMV_XFLTPDV
		if Alltrim(cFormaX) == "CCP"
			aCampos[nPosForma][2] :=  "CC "
		elseif Alltrim(cFormaX) == "CDP"
			aCampos[nPosForma][2] :=  "CD "
		elseif Alltrim(cFormaX) == "CR"
			aCampos[nPosForma][2] :=  "NB "
		endif
	endif

	if lRet .AND. (nPosProd==0 .OR. Empty(aCampos[nPosProd][2]) )
		if lNoMsg
			cMsgLog := "Informe um produto para incluir o preço negociado."
		else
			U_XHELP("PRODUTO", cMsgSeq+"Informe um produto para incluir o preço negociado.", "Informe um produto para incluir o preço negociado.")
		endif
		lRet := .F.
	endif

	if lRet .AND. (nPosProd==0 .OR. Posicione("SB1",1,xFilial("SB1")+aCampos[nPosProd][2],"B1_MSBLQL") == "1" )
		if lNoMsg
			cMsgLog := "Produto bloqueado. Não é permitido negociar preços para este produto e estiver bloqueado. Acesse o menu 'Cadastros >> Produtos' e verifique o campo de bolqueio (B1_MSBLQL)."
		else
			U_XHELP("PRODUTO", cMsgSeq+"Produto bloqueado. Não é permitido negociar preços para este produto e estiver bloqueado.", "Acesse o menu 'Cadastros >> Produtos' e verifique o campo de bolqueio (B1_MSBLQL).")
		endif
		lRet := .F.
	endif

	if lRet .AND. (nPosPrcV==0 .OR. aCampos[nPosPrcV][2] <= 0 )
		if lNoMsg
			cMsgLog := "Campo de Preço Negociado não preenchido. Preencha o campo Preço Negociado (U25_PRCVEN)."
		else
			U_XHELP('GETOBG', cMsgSeq+"Campo de Preço Negociado não preenchido.", "Preencha o campo Preço Negociado (U25_PRCVEN).")
		endif
		lRet := .F.
	endif

	if lRet .AND. !lAltVrUnit .AND. (nPosDesc==0 .OR. aCampos[nPosDesc][2] <= 0 )
		if lNoMsg
			cMsgLog := "Campo de Desc/Acresc Preco Base não preenchido. Preencha o campo Desc/Acresc Preco Base (U25_DESPBA)."
		else
			U_XHELP('GETOBG', cMsgSeq+"Campo de Desc/Acresc Preco Base não preenchido.", "Preencha o campo Desc/Acresc Preco Base (U25_DESPBA).")
		endif
		lRet := .F.
	endif

	if lRet .AND. (nPosForma==0 .OR. nPosCond==0 .OR. (!empty(aCampos[nPosForma][2]) .AND. empty(aCampos[nPosCond][2])) .OR. (!empty(aCampos[nPosCond][2]) .AND. empty(aCampos[nPosForma][2]))   )
		if lNoMsg
			cMsgLog := "Campo Negociação não preenchido. Preencha os campos de Negociação (Forma + Condição)."
		else
			U_XHELP('GETOBG', cMsgSeq+"Campo Negociação não preenchido.", "Preencha os campos de Negociação (Forma + Condição).")
		endif
		lRet := .F.
	endif

	if lRet .AND. (nPosCli==0 .OR. nPosLoja==0 .OR. nPosGrpC==0 .OR. empty(aCampos[nPosCli][2]+aCampos[nPosLoja][2]+aCampos[nPosGrpC][2]+aCampos[nPosForma][2]+aCampos[nPosCond][2]))
		if lNoMsg
			cMsgLog := "Campos chaves não preenchidos. Preencha um Cliente ou Grupo Cliente ou Negociação Pagamento para incluir um preço negociado."
		else
			U_XHELP('GETOBG', cMsgSeq+"Campos chaves não preenchidos.", "Preencha um Cliente ou Grupo Cliente ou Negociação Pagamento para incluir um preço negociado.")
		endif
		lRet := .F.
	endif

	// verifico se o campo flar existe
	If nPosFlag > 0

		if lRet .AND. aCampos[nPosFlag][2]=="S" .AND. (empty(aCampos[nPosDtFim][2]) .OR. empty(aCampos[nPosHrFim][2]))
			if lNoMsg
				cMsgLog := "Data/Hora de fim obrigatórios para preços marcados para utilizar apenas em uma venda. Preencha uma Data/Hora de Fim."
			else
				U_XHELP('GETOBG', cMsgSeq+"Data/Hora de fim obrigatórios para preços marcados para utilizar apenas em uma venda.", "Preencha uma Data/Hora de Fim.")
			endif
			lRet := .F.
		endif

		if lRet .AND. aCampos[nPosFlag][2]=="S" .AND. aCampos[nPosDtFim][2] > (aCampos[nPosDtIn][2]+1)
			if lNoMsg
				cMsgLog := "Data máxima para fim do preço é "+ DTOC((aCampos[nPosDtIn][2]+1)) + ". Preencha uma Data/Hora de Fim que seja igual ou inferior a data máxima para fim do preço."
			else
				U_XHELP('GETOBG', cMsgSeq+"Data máxima para fim do preço é "+ DTOC((aCampos[nPosDtIn][2]+1)) + ".", "Preencha uma Data/Hora de Fim que seja igual ou inferior a data máxima para fim do preço.")
			endif
			lRet := .F.
		endif

		if lRet .AND. aCampos[nPosFlag][2]=="S" .AND. empty(aCampos[nPosPlaca][2])
			if lNoMsg
				cMsgLog := "Campo Placa obrigatório para preços marcados para utilizar apenas em uma venda. Preencha uma Placa para utilização do preço negociado."
			else
				U_XHELP('GETOBG', cMsgSeq+"Campo Placa obrigatório para preços marcados para utilizar apenas em uma venda.", "Preencha uma Placa para utilização do preço negociado.")
			endif
			lRet := .F.
		endif

	EndIf

	if lRet .AND. !empty(aCampos[nPosForma][2]+aCampos[nPosCond][2])
		_cPadrao := Posicione("U44",1,xFilial("U44")+aCampos[nPosForma][2]+aCampos[nPosCond][2],"U44_PADRAO")
		if empty(_cPadrao)
			if lNoMsg
				cMsgLog := "Negociação de Pagamento (Forma de Pgto + Condição de Pgto) não cadastrada. Acesse o menu 'Negociação de Pagamento' e faça cadastro da forma e condição."
			else
				U_XHELP('EXISTCHAV', cMsgSeq+"Negociação de Pagamento (Forma de Pgto + Condição de Pgto) não cadastrada.", "Acesse o menu 'Negociação de Pagamento' e faça cadastro da forma e condição.")
			endif
			lRet := .F.
		elseif _cPadrao == 'N' .AND. !empty(aCampos[nPosCli][2]+aCampos[nPosLoja][2]+aCampos[nPosGrpC][2])  //se não é padrão
			//verifica se bloqueia ou não
			lRet := U_TRET022D(aCampos[nPosForma][2],aCampos[nPosCond][2],aCampos[nPosCli][2],aCampos[nPosLoja][2],aCampos[nPosProd][2], !lNoMsg, @cMsgLog, aCampos[nPosGrpC][2])
		endif
	endif

	if lRet .AND. !empty(aCampos[nPosAdmF][2])
		if empty(aCampos[nPosForma][2])
			if lNoMsg
				cMsgLog := "Foi informado uma Adm Financeira mas não foi informado uma Negociação de Pagamento (Forma de Pgto + Condição de Pgto)."
			else
				U_XHELP('EXISTCHAV', cMsgSeq+"Foi informado uma Adm Financeira mas não foi informado uma Negociação de Pagamento (Forma de Pgto + Condição de Pgto).", "Informe uma 'Negociação de Pagamento'.")
			endif
			lRet := .F.
		elseif Alltrim(Posicione("SAE",1,xFilial("SAE",)+aCampos[nPosAdmF][2],"AE_TIPO")) <> Alltrim(aCampos[nPosForma][2])
			if lNoMsg
				cMsgLog := "O tipo da Adm Financeira (tipo "+Alltrim(SAE->AE_TIPO)+") não é o mesmo do informado no campo Forma de Pgto."
			else
				U_XHELP('EXISTCHAV', cMsgSeq+"O tipo da Adm Financeira (tipo "+Alltrim(SAE->AE_TIPO)+") não é o mesmo do informado no campo Forma de Pgto.", "Informa uma Adm Financeira do tipo ["+Alltrim(aCampos[nPosForma][2])+"].")
			endif
			lRet := .F.
		endif
	endif

	if lRet //mesmas chaves
		aChaves := U_TRET023A(aCampos)
		DbSelectArea("U25")
		U25->(DbSetOrder(2))
		U25->(DbSeek(aChaves[2]))
		while U25->(!Eof()) .AND. &(aChaves[1]) == aChaves[2]

			if DTOS(U25->U25_DTINIC)+U25->U25_HRINIC >= DTOS(aCampos[nPosDtIn][2])+aCampos[nPosHrIn][2]
				//if U25->U25_DTINIC >= aCampos[nPosDtIn][2] .AND. U25->U25_HRINIC >= aCampos[nPosHrIn][2]
				if lNoMsg
					cMsgLog := "Já existe preço negociado com data/hora superior ou igual."
				else
					Help('',1,'EXISTCHAV',,cMsgSeq+"Já existe preço negociado com data/hora superior ou igual."+cEOL+;
						"Produto: " + aCampos[nPosProd][2] +cEOL+;
						iif(empty(aCampos[nPosCli][2]+aCampos[nPosLoja][2]),"","Cliente/Loja: "+aCampos[nPosCli][2]+"/"+aCampos[nPosLoja][2]+cEOL)+;
						iif(empty(aCampos[nPosGrpC][2]),"","Grupo Cli: " + aCampos[nPosGrpC][2]+cEOL)+;
						iif(empty(aCampos[nPosForma][2]+aCampos[nPosCond][2]),"","Forma/Condição: "+aCampos[nPosForma][2]+"/"+aCampos[nPosCond][2])+cEOL+;
						iif(empty(aCampos[nPosAdmF][2]),"","Adm. Financ.: "+aCampos[nPosAdmF][2])+cEOL+;
						iif(empty(aCampos[nPosEmit][2]+aCampos[nPosLojEm][2]),"","Emit. CH/Loja: "+aCampos[nPosEmit][2]+"/"+aCampos[nPosLojEm][2]+cEOL),1,0)
				endif
				lRet := .F.
				exit
			endif

			U25->(DbSkip())
		enddo
	endif

	// verifico se o campo flar existe
	If nPosFlag > 0

		if lRet .AND. aCampos[nPosFlag][2]=="S"  //quando flag venda, verificando chaves mais genéricas (so até condição)
			aChaves := U_TRET023A(aCampos,,.T.)
			DbSelectArea("U25")
			U25->(DbSetOrder(2))
			U25->(DbSeek(aChaves[2]))
			while U25->(!Eof()) .AND. &(aChaves[1]) == aChaves[2]

				if empty(U25->U25_ADMFIN) .AND. empty(U25->U25_EMITEN+U25->U25_LOJEMI) .AND. ;
						DTOS(U25->U25_DTINIC)+U25->U25_HRINIC <= DTOS(aCampos[nPosDtIn][2])+aCampos[nPosHrIn][2] .AND. ;
						( empty(U25->U25_DTFIM) .OR. DTOS(U25->U25_DTFIM)+U25->U25_HRFIM >= DTOS(aCampos[nPosDtIn][2])+aCampos[nPosHrIn][2] )

					if lNoMsg
						cMsgLog := "Já existe preço negociado para uma venda com estas chaves."
					else
						Help('',1,'EXISTCHAV',,cMsgSeq+"Já existe preço negociado para chave:"+cEOL+;
							"Produto: " + aCampos[nPosProd][2] +cEOL+;
							iif(empty(aCampos[nPosCli][2]+aCampos[nPosLoja][2]),"","Cliente/Loja: "+aCampos[nPosCli][2]+"/"+aCampos[nPosLoja][2]+cEOL)+;
							iif(empty(aCampos[nPosGrpC][2]),"","Grupo Cli: " + aCampos[nPosGrpC][2]+cEOL)+;
							iif(empty(aCampos[nPosForma][2]+aCampos[nPosCond][2]),"","Forma/Condição: "+aCampos[nPosForma][2]+"/"+aCampos[nPosCond][2]+cEOL),1,0)
					endif
					lRet := .F.
					exit
				endif

				U25->(DbSkip())
			enddo
		endif

	EndIf

	if lRet
		nPrcTab := U_URetPrec(aCampos[nPosProd][2],@cErro,.F.) //busca preço padrão atual
		if !empty(cErro)
			if lNoMsg
				cMsgLog := cErro + " Para inclur uma negociação de preços para este produto, favor cadastrar primeiramente o preço padrão no menu 'Tabela de Preços'."
			else
				U_XHELP("PREÇO PADRAO", cMsgSeq + cErro, "Para inclur uma negociação de preços para este produto, favor cadastrar primeiramente o preço padrão no menu 'Tabela de Preços'.")
			endif
			lRet := .F.
		endif
	endif

	//verificando se preço negociado é maior que preço padrão
	if lRet .AND. ((aCampos[nPosPrcV][2] > nPrcTab) .AND. !lAltVrUnit)
		if lNoMsg
			cMsgLog := "Preço Negociado deve ser menor que preço padrão. Preço Padrão: " + alltrim(Transform(nPrcTab,PesqPict("DA1","DA1_PRCVEN")))
		else
			Help('',1,'PRCVEN',,cMsgSeq+"Preço Negociado deve ser menor que preço padrão."+cEOL;
				+"Preço Padrão: " + alltrim(Transform(nPrcTab,PesqPict("DA1","DA1_PRCVEN"))),1,0)
		endif
		lRet := .F.
	endif

	if lRet
		Posicione("SB1",1,xFilial("SB1")+aCampos[nPosProd][2],"B1_COD")
		if !empty(aCampos[nPosCli][2]+aCampos[nPosLoja][2])
			cGrpCliVld := Posicione("SA1",1,xFilial("SA1")+aCampos[nPosCli][2]+aCampos[nPosLoja][2],"A1_GRPVEN")
		endif
	endif

	if !lRet .AND. lNoMsg //se é pra gerar log
		cLog := cMsgSeq
		cLog += "Produto: " + aCampos[nPosProd][2]+" "+ aCampos[nPosDesP][2] +cEOL+;
			iif(empty(aCampos[nPosCli][2]+aCampos[nPosLoja][2]),"","Cliente/Loja: "+aCampos[nPosCli][2]+"/"+aCampos[nPosLoja][2]+" "+aCampos[nPosNmCli][2]+cEOL)+;
			iif(empty(aCampos[nPosGrpC][2]),"","Grupo Cli: " + aCampos[nPosGrpC][2]+" "+aCampos[nPosNmCli][2]+cEOL)+;
			iif(empty(aCampos[nPosForma][2]+aCampos[nPosCond][2]),"","Forma/Condição: "+aCampos[nPosForma][2]+"/"+aCampos[nPosCond][2]+" "+aCampos[nPosDsNeg][2]+cEOL)+;
			iif(empty(aCampos[nPosAdmF][2]),"","Adm. Financ.: "+aCampos[nPosAdmF][2]+" "+aCampos[nPosDsAd][2]+cEOL)+;
			iif(empty(aCampos[nPosEmit][2]+aCampos[nPosLojEm][2]),"","Emit. CH/Loja: "+aCampos[nPosEmit][2]+"/"+aCampos[nPosLojEm][2]+" "+aCampos[nPosNmEmi][2]+cEOL)
		cLog += "-> Mensagem: " + cMsgLog
	endif

	aCampos[nPosForma][2] := cFormaX

	RestArea(aAreaU25)
	RestArea(aAreaU44)
	RestArea(aAreaSB1)
	RestArea(aAreaSA1)
	RestArea(aArea)

Return lRet

/*
_____________________________________________________________________________
¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦
¦¦+-----------------------------------------------------------------------+¦¦
¦¦¦Programa  ¦ ValidExc    ¦ Autor ¦ Danilo Brito     ¦ Data ¦ 17/04/2014 ¦¦¦
¦¦+----------+------------------------------------------------------------¦¦¦
¦¦¦Descriçào ¦ Faz validação para exclusão de uma regra negociação.  	  ¦¦¦
¦¦¦          ¦ 															  ¦¦¦
¦¦+----------+------------------------------------------------------------¦¦¦
¦¦¦Uso       ¦ Posto Inteligente			                              ¦¦¦
¦¦+-----------------------------------------------------------------------+¦¦
¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦
¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
*/
Static Function ValidExc()
	Local lRet := .T.
	Local cChave := ""
	Local aChaves

	//cadastra rotina para controle de acesso
	U_TRETA37B("U25DEL", "EXCLUSÃO DE PREÇO NEGOCIADO")

	//verifica se o usuário tem permissão para acesso a rotina
	cUsrCmp := U_VLACESS1("U25DEL", RetCodUsr())
	if cUsrCmp == Nil .OR. empty(cUsrCmp)
		Return
	endif

	if oMSGet1:aCols[oMSGet1:nAt,Len(oMSGet1:aHeader)+1] > 0

		if oMSGet1:aCols[oMSGet1:nAt,1] <> "BR_VERDE"
			Help('',1,'NOTDEL',,"O preço selecionado não está vigente. Ação não permitida.",1,0)
			lRet := .F.
		endif

		if lRet
			lRet := MsgYesNo("Deseja realmente excluir o item de preço selecionado?","Atenção!")
		endif

		if lRet
			DbSelectArea("U25")
			U25->(DbSetOrder(2))

			//posiciona no registro
			U25->(DbGoTO(oMSGet1:aCols[oMSGet1:nAt,Len(oMSGet1:aHeader)+1]))
			aChaves := U_TRET023A()

			U25->(DbSkip()) //passo para o próximo
			if U25->(!Eof()) .AND. &(aChaves[1]) == aChaves[2]
				Help('',1,'NOTDEL',,"Existe preço negociado com data superior a este registro. Exclusão não permitida!",1,0)
				lRet := .F.
			elseif U25->U25_BLQL == 'S'
				Help('',1,'NOTDEL',,"Preço em aprovação por alçada. Ação não Permitida.",1,0)
				lRet := .F.
			endif
		endif

		//posiciona no registro
		U25->(DbGoTO(oMSGet1:aCols[oMSGet1:nAt,Len(oMSGet1:aHeader)+1]))

		//Ponto de Entrada validação de exclusão de item
		//If lRet .AND. ExistBlock("UF001DOK")
		//	lRet := ExecBlock("UF001DOK",.F.,.F.)
		//	if Type("lRet") == "L" .AND. lRet == .F.
		//		return
		//	endif
		//EndIf

	else
		Help(,,"Atenção",,"Selecione um preço para exclusão.",1,0,,,,,,{""})
	endif

Return lRet

/*
_____________________________________________________________________________
¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦
¦¦+-----------------------------------------------------------------------+¦¦
¦¦¦Programa  ¦ DoInclui   ¦ Autor ¦ Danilo Brito      ¦ Data ¦ 17/04/2014 ¦¦¦
¦¦+----------+------------------------------------------------------------¦¦¦
¦¦¦Descriçào ¦ Faz inclusão de uma nova regra negociação.  				  ¦¦¦
¦¦¦          ¦ 															  ¦¦¦
¦¦+----------+------------------------------------------------------------¦¦¦
¦¦¦Uso       ¦ Posto Inteligente			                              ¦¦¦
¦¦+-----------------------------------------------------------------------+¦¦
¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦
¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
*/
Static Function DoInclui(nOpcX, lPdv)

	Local aCampos := {}
	Local nCntFor := 0
	Local cCampo := ""
	Local aFiliais := {} // Gianluka Moraes | 13/07/16 : Guarda as filiais que serão selecionadas, caso usuário queria incluir em mais de uma.

	Private lMultiFil := .F. // Gianluka Moraes | 13/07/16 : Controla se usuário realmente vai inserir registros em mais de uma filial.
	Private lCancMultiFil := .F. // Gianluka Moraes | 13/07/16 : Controla se usuário clicou no botão Cancelar
	Private oNwGetDad // Gianluka Moraes | 13/07/16 : Caso seja inclusao em varias filiais, uso este objeto pra pegar o aCols com os preços digitados pelo usuário e alterar a estrutura do array aCampos.
	Private _MSG	 := {| cStr | oSay:cCaption := (cStr) , ProcessMessages() } // Gianluka Moraes | 13/07/16 : Exibir mensagens no processamento

	//cadastra rotina para controle de acesso
	U_TRETA37B("UFT001", "INCLUIR NEGOCIAÇÃO DE PREÇOS")

	//verifica se o usuário tem permissão para acesso a rotina
	cUsrCmp := U_VLACESS1("UFT001", RetCodUsr())
	if cUsrCmp == Nil .OR. empty(cUsrCmp)
		Return
	endif

	dbSelectArea("U25")
	U25->(dbSetOrder(2))
	For nCntFor := 1 To U25->(FCount())
		cCampo := U25->(FieldName(nCntFor))
		AAdd(aCampos, {cCampo, M->&(cCampo) })
	Next nCntFor

	/**********************************************************************
	* Gianluka Moraes | 13/07/16 : Inclusão em várias filiais             *
	***********************************************************************/
	If lSelFilial
		aFiliais := fFilial()
		If !lCancMultiFil .and. (Len(aFiliais) > 0)
			//For x:=1 To Len( aFiliais )
			//	If aFiliais[x,1]
					TelaSelFil(aFiliais, aCampos)
					If lCancMultiFil
						Help(,,"Atenção",,"Operação cancelada",1,0,,,,,,{""})
						InPadEnch(nOpcX, lPdv) //limpa form
						Return
					Else
						lMultiFil := .T.
					EndIf
			//	EndIf
			//Next x
		Else
			Help(,,"Atenção",,"Operação cancelada",1,0,,,,,,{""})
			InPadEnch(nOpcX, lPdv) //limpa form
			Return
		EndIf

	EndIf

    If !lMultiFil
		if U_TRET023B(aCampos)

			//Ponto de Entrada tratamentos de validação
			//If ExistBlock("UF001IOK")
			//	lRet := ExecBlock("UF001IOK",.F.,.F.)
			//	if Type("lRet") == "L" .AND. lRet == .F.
			//		return
			//	endif
			//EndIf

			U_TRET023C("I", aCampos) //faz inclusão
			nRecU25 := U25->(Recno())
			InPadEnch(nOpcX, lPdv) //limpa form
			//TODO: melhorar logica para apenas incluir o item no browse e nao recarregar tudo
			Processa({|| LoadOGet1(nOpcX, lPdv, .T.)},"Aguarde...","Carregando registros...",.T.) //carrega dados
		endif
	Else
		FWMsgRun(, {|oSay| 	InsMultFil( @oSay, nOpcx, lPdv, aFiliais, aCampos ) }, "Aguarde", "Carregando registros" ) // Chama rotina para incluir em todas as filiais selecionadas.
	EndIf
Return

/*
_____________________________________________________________________________
¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦
¦¦+-----------------------------------------------------------------------+¦¦
¦¦¦Programa  ¦ TRET023C	  ¦ Autor ¦ Danilo Brito      ¦ Data ¦ 17/04/2014 ¦¦¦
¦¦+----------+------------------------------------------------------------¦¦¦
¦¦¦Descriçào ¦ Faz inclusão de uma nova regra negociação.  				  ¦¦¦
¦¦¦          ¦ 															  ¦¦¦
¦¦+----------+------------------------------------------------------------¦¦¦
¦¦¦Uso       ¦ Posto Inteligente			                              ¦¦¦
¦¦+-----------------------------------------------------------------------+¦¦
¦¦¦Parametros¦ cTipoInc = I-Manual; R-Rotina At Preço; A-Automatica Job   ¦¦¦
¦¦¦          ¦ cProduto = Código do Produto								  ¦¦¦
¦¦¦          ¦ cCliente/cLoja = Cliente do preço negociado				  ¦¦¦
¦¦¦          ¦ cForPag/cCondPag/cAdmFin = condição para preço neg.		  ¦¦¦
¦¦¦          ¦ dDtInic/cHrInic = Início vigencia						  ¦¦¦
¦¦¦          ¦ nPrcVen = Preço de venda negociado						  ¦¦¦
¦¦¦          ¦ cObserv = Obervações do preço							  ¦¦¦
¦¦+-----------------------------------------------------------------------+¦¦
¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦
¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
*/
User function TRET023C(cTipoInc, aCampos)

	Local lRet := .T.
	Local nX := 1
	Local dDtInic, cHrInic
	Local aChaves := {}
	Local cChvRep := ""
	Local cOBS	:= ""
	Local aEnvia := {}
	Local cFormaX := ""
	Local cMV_XFLTPDV := SuperGetMv("MV_XFLTPDV",,"") //filiais que ja são totvspdv

	if cTipoInc == "I"
		cOBS := "(Rotina: Inclusão Manual. "
	elseif cTipoInc == "R"
		cOBS := "(Rotina: Atualização Preços. "
	elseif cTipoInc == "A"
		cOBS := "(Rotina: JOB Perda Desconto. "
	elseif cTipoInc == "X"
		cOBS := "(Rotina: Importação. "
	endif

	cOBS += "Data/Hora: "+DTOC(Date())+" "+Time()+". Usuário: "+iif(IsBlind(),"JOB",RetCodUsr())+")"

	cFormaX := aCampos[aScan(aCampos,{|x| Trim(x[1])== "U25_FORPAG"})][2]

	//DANILO: alteração de CCP e CDP para CC e CD
	if cFilAnt $ cMV_XFLTPDV
		if Alltrim(cFormaX) == "CCP"
			aCampos[aScan(aCampos,{|x| Trim(x[1])== "U25_FORPAG"})][2] :=  "CC "
		elseif Alltrim(cFormaX) == "CDP"
			aCampos[aScan(aCampos,{|x| Trim(x[1])== "U25_FORPAG"})][2] :=  "CD "
		elseif Alltrim(cFormaX) == "CR"
			aCampos[aScan(aCampos,{|x| Trim(x[1])== "U25_FORPAG"})][2] :=  "NB "
		endif
	endif

	//////////////////////Gravando data de fim do registro anterior /////////////////////
	//	aScan(aCampos,{|x| Trim(x[1])== "U25_PRODUT"})
	dDtInic := aCampos[aScan(aCampos,{|x| Trim(x[1])== "U25_DTINIC"})][2] //Quintais ajustado de 2 para 1 a posicao
	cHrInic := aCampos[aScan(aCampos,{|x| Trim(x[1])== "U25_HRINIC"})][2]

	aChaves := U_TRET023A(aCampos)

	//posicionando no ultimo preço
	DbSelectArea("U25")
	U25->(DbSetOrder(2))
	U25->(DbSeek(aChaves[2]))
	while U25->(!Eof()) .AND. &(aChaves[1]) == aChaves[2]
		if DTOS(U25->U25_DTINIC)+U25->U25_HRINIC >= DTOS(dDtInic)+cHrInic
			//If U25->U25_DTINIC >= dDtInic .AND. U25->U25_HRINIC >= cHrInic
			Return .F.
		Endif
		U25->(DbSkip())
	enddo
	U25->(DbSkip(-1)) //faz posicionar no ultimo registro com mesmas configurações

	Begin Transaction

		if U25->(!Eof()) .AND. &(aChaves[1]) == aChaves[2]
			//Faz alteraçao, preenchendo os campos data fim com mesma data de início.
			if empty(U25->U25_DTFIM) .OR. DTOS(U25->U25_DTFIM)+U25->U25_HRFIM > DTOS(dDtInic)+cHrInic
				RecLock("U25", .F.)
				U25->U25_DTFIM := dDtInic
				U25->U25_HRFIM := cHrInic
				U25->U25_OBS := U25->U25_OBS + CHR(13)+CHR(10) + "Encerramento automatico pela inclusao de novo preço " + cOBS
				U25->(MsUnlock())
				U_UREPLICA("U25", 1, U25->U25_FILIAL+U25->U25_REPLIC, "A")
			endif
		endif

		DbSelectArea("U25")

		cChvRep := GetIdRepl()

		//////////////////////Gravando novo registro /////////////////////
		//faço um incluir bem rapido para ja garantir a numeração
		RecLock("U25", .T.) //inclui
		U25->U25_FILIAL := xFilial("U25")
		U25->U25_REPLIC := cChvRep
		U25->(MsUnlock())

		RecLock("U25", .F.) //altera colocando demais dados
		U25->U25_USER 	:= iif(IsBlind(),"JOB",RetCodUsr())
		U25->U25_DATA 	:= Date()
		U25->U25_HORA 	:= Time()
		U25->U25_TIPOAJ := cTipoInc //I-Manual; R-Rotina At Preço; A-Automatica Job; X=Importa

		for nX := 1 to len(aCampos)
			if !(alltrim(aCampos[nX][1]) $ "U25_FILIAL/U25_USER/U25_DATA/U25_HORA/U25_TIPOAJ/U25_REPLIC/U25_BLQL/U25_MSEXP")
				U25->&(aCampos[nX][1]) := aCampos[nX][2]
			endif
		next nX

		U25->(MsUnlock())

	End Transaction

	aCampos[aScan(aCampos,{|x| Trim(x[1])== "U25_FORPAG"})][2] := cFormaX

	//Verifica se alçada tem aprovador......
	// Caso tem aprovador o preço minimo ficará bloqueadoaté ser obtida a resposta do aprovador
	//if Type("_nRecApv") == "U"
	//	Private _nRecApv := 0
	//endif
	//if _nRecApv > 0
	//
	//	U17->(DbSetOrder(1))
	//	U17->(DbGoTO(_nRecApv))
	//	aAprov := StrToKarr(U17->U17_USERAP,";")
	//	For nK :=1 to Len(aAprov)
	//
	//		PswOrder(1) // Ordem por Id do usuario
	//
	//		// Efetuo a pesquisa, definindo se pesquiso usuário ou grupo
	//		If PswSeek(aAprov[nK],.T.)
	//
	//		   // Obtenho o resultado conforme vetor // 3 vetor de usuario
	//		   _aRetUser := PswRet(1)
	//		   _cNomUser := Alltrim(_aRetUser[1][2])
	//		   _cMailUser := Alltrim(_aRetUser[1][14])
	//		EndIf
	//
	//	    // Rotina que monta o processo de Workflow
	//		cMailID := U_WFALCADA(,"U17")
	//
	//		If !empty(cMailId)
	//
	//			cAviso:="Solicitação de aprovacao do proço mínimo do produto "+SM0->M0_NOMECOM
	//			//cDestino:=aMail[nK]
	//			//cLink:=cHttpServer+"messenger/emp" + cEmpAnt + "/alcu23/" + cMailID + ".htm"
	//			cLinkIn:="http://s.rfs7.com:8000/messenger/emp02/alcada/" + cMailID + ".htm"
	//			//Envia email de Aviso
	//			xHTM := '<HTML><BODY>'
	//			xHTM += '<hr>'
	//			xHTM += '<p  style="word-spacing: 0; line-height: 100%; margin-top: 0; margin-bottom: 0">'
	//			xHTM += '<b><font face="Verdana" SIZE=3>'+cAviso+' &nbsp; em '+dtoc(date())+'&nbsp;&nbsp;&nbsp;'+time()+'</b></p>'
	//			xHTM += '<hr>'
	//			xHTM += '<br>'
	//			xHTM += '<b><font face="Verdana" SIZE=3> Prezado(a) '+_cNomUser+'</b></p>'
	//			xHTM += '<br>'
	//			xHTM += 'Favor clicar no link abaixo para aprovação/rejeição do preço minimo em referencia<BR> <br>'
	//			xHTM += "<a href="+cLinkIn+"?user="+aAprov[nK]+" title="+cLinkIn+">Verificar Caixa</a> "
	//			xHTM += '</BODY></HTML>'
	//			//u_EnviarEMail('','Aviso - '+cAviso+'','Aviso - '+cAviso+'',xHTM,.t.,cDestino)
	//
	//			oMail := LTpSendMail():New(alltrim(_cMailUser), "Aprovação do preço minimo", xHTM)
	//			oMail:SetEchoMsg(.F.) //desabilita mensagens de erro
	//			oMail:Send() //envia o email.
	//
	//			AADD(aEnvia,{aAprov[nK],_cNomUser,cMailId})
	//
	//		EndIf
	//	Next nK
	//
	//	//gravação na tabela auxilar de aprovação das alçadas
	//	If Len(aEnvia) > 0
	//		_cCodAlc := GetSx8Num("UAB","UAB_COD")
	//
	//		RecLock("UAB",.T.)
	//			UAB->UAB_FILIAL := xFilial("UAB")
	//			UAB->UAB_COD 	:= _cCodAlc
	//			UAB->UAB_IDALCA := "U17"
	//			UAB->UAB_DESCAL := "ALÇADA PREÇO MINIMO"
	//			UAB->UAB_ALIAS 	:= "U25"
	//			UAB->UAB_REGIST := Alltrim(Str(U25->(RECNO())))
	//			UAB->UAB_HIST 	:= ""
	//			UAB->UAB_LC 	:= 0
	//			UAB->UAB_LCCHQ 	:= 0
	//			UAB->UAB_LCRS 	:= 0
	//			UAB->UAB_RISCO 	:= ""
	//			UAB->UAB_NAPROV := U17->U17_NAPROV
	//		UAB->(MsUnlock())
	//
	//		ConfirmSx8()
	//
	//		For nI := 1 To Len(aEnvia)
	//			RecLock("UAC",.T.)
	//				UAC->UAC_FILIAL 	:= xFilial("UAC")
	//				UAC->UAC_COD 		:= _cCodAlc
	//				UAC->UAC_IDWORK 	:= aEnvia[nI][3]
	//				UAC->UAC_CODUSU 	:= aEnvia[nI][1]
	//				UAC->UAC_NOMUSU 	:= aEnvia[nI][2]
	//				UAC->UAC_APROVA 	:= "N"
	//				UAC->UAC_DTAPRO 	:= STOD("        ")
	//			UAC->(MsUnlock())
	//		Next nI
	//
	//		RecLock("U25",.F.)
	//			U25->U25_BLQL := "S"
	//		U25->(MsUnlock())
	//
	//	EndIf
	//
	//Else
	//	RecLock("U25",.F.)
	//		U25->U25_BLQL := "N"
	//	U25->(MsUnlock())
	//EndIf

	RecLock("U25",.F.)
	U25->U25_BLQL := "N"
	U25->(MsUnlock())

	//envia dados do preço incluido para pdv
	//U_UREPLICA("U25",1,U25->U25_FILIAL+U25->U25_PRODUT+U25->U25_CLIENT+U25->U25_LOJA+U25->U25_FORPAG+U25->U25_CONDPG+U25->U25_ADMFIN+U25->U25_EMITEN+U25->U25_LOJEMI+U25->U25_PLACA+DTOS(U25->U25_DTINIC)+U25->U25_HRINIC, "I")
	U_UREPLICA("U25", 1, U25->U25_FILIAL+U25->U25_REPLIC, "I")
	DbSelectArea("U25")

	//Ponto de Entrada após inclusão de um item
	//If ExistBlock("UF001INC")
	//	ExecBlock("UF001INC",.F.,.F., cTipoInc)
	//EndIf

Return lRet

/*--------------------------------------------------------------------------*/
/*---- PEGA IDENTIFICADOR DO REPLICA ---------------------------------------*/
/*--------------------------------------------------------------------------*/
User Function TR023IDR()
Return GetIdRepl()
Static Function GetIdRepl()

	Local cCondicao		:= ""
	Local bCondicao
	Local aArea := GetArea()
	Local aAreaU25 := U25->(GetArea())

	Local cIdReplic := "0000001"
	Local cPrefix := ""

	DbSelectArea("U25")
	U25->(DbSetOrder(1))

	#IFDEF TOP

		cIdReplic := GETSXENUM( "U25" , "U25_REPLIC" )
		ConfirmSx8()

		//segurança para nao duplicar
		While U25->(DbSeek(xFilial("U25")+cIdReplic ))
			cIdReplic := GETSXENUM( "U25" , "U25_REPLIC" )
			ConfirmSx8()
		enddo

	#ELSE

		cPrefix := "P"

		cCondicao := "	U25_FILIAL == '"+xFilial("U25")+"' "
		cCondicao += "	.AND. '"+cPrefix+"' == SubStr(U25_REPLIC,1,1)  "

		// limpo os filtros da U25
		U25->(DbClearFilter())

		// executo o filtro na U25
		bCondicao 	:= "{|| " + cCondicao + " }"
		U25->(DbSetFilter(&bCondicao,cCondicao))
		U25->(DbGoBottom())

		if U25->(!Eof())
			cIdReplic := SOMA1(U25->U25_REPLIC)
		else
			cIdReplic := cPrefix+cIdReplic
		endif

		U25->(DbClearFilter())

	#ENDIF

	RestArea(aAreaU25)
	RestArea(aArea)

Return cIdReplic


/*
_____________________________________________________________________________
¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦
¦¦+-----------------------------------------------------------------------+¦¦
¦¦¦Programa  ¦ DoExclui   ¦ Autor ¦ Danilo Brito      ¦ Data ¦ 17/04/2014 ¦¦¦
¦¦+----------+------------------------------------------------------------¦¦¦
¦¦¦Descriçào ¦ Faz exclusão de uma regra negociação.   					  ¦¦¦
¦¦¦          ¦ 															  ¦¦¦
¦¦+----------+------------------------------------------------------------¦¦¦
¦¦¦Uso       ¦ Posto Inteligente			                              ¦¦¦
¦¦+-----------------------------------------------------------------------+¦¦
¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦
¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
*/
Static Function DoExclui(nOpcX, lPdv)

	Local cChvRep := ""
	Local nX

	Begin Transaction

		DbSelectArea("U25")

		if oMSGet1:aCols[oMSGet1:nAt,Len(oMSGet1:aHeader)+1] > 0

			U25->(DbGoTO(oMSGet1:aCols[oMSGet1:nAt,Len(oMSGet1:aHeader)+1]))

			cChvRep := U25->U25_FILIAL+U25->U25_REPLIC

			RecLock("U25", .F.)
			U25->U25_OBS := U25->U25_OBS + CHR(13)+CHR(10) + "Exclusão Manual (Data/Hora: "+DTOC(Date())+" "+Time()+". Usuário: "+iif(IsBlind(),"JOB",RetCodUsr())+")"
			U25->(DbDelete())
			U25->(MsUnlock())

			U_UREPLICA("U25", 1, cChvRep, "E")

			//limpa variáveis
			DbSelectArea("U25")
			For nX := 1 To FCount()
				cCampo := alltrim(Eval(bCampo, nX))
				if !(cCampo $ "U25_PRODUT/U25_CLIENT/U25_LOJA/U25_GRPCLI") .OR. nOpcX == 0
					M->&(cCampo) := CriaVar(FieldName(nX), .T.)
				endif
			Next nX

			//Ponto de Entrada após exclusão de um item
			//If ExistBlock("UF001EXC")
			//	ExecBlock("UF001EXC",.F.,.F., {nOpcX, lPdv})
			//EndIf

			//TODO: melhorar logica aqui, para excluir apenas a linha selecionada.
			Processa({|| LoadOGet1(nOpcX, lPdv, .T.)},"Aguarde...","Carregando registros...",.T.) //carrega dados

		endif

	End Transaction

Return

/*
_____________________________________________________________________________
¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦
¦¦+-----------------------------------------------------------------------+¦¦
¦¦¦Programa  ¦ DoFiltro   ¦ Autor ¦ Danilo Brito      ¦ Data ¦ 24/04/2014 ¦¦¦
¦¦+----------+------------------------------------------------------------¦¦¦
¦¦¦Descriçào ¦ Faz filtro na mostragem dos itens de regra negociação.     ¦¦¦
¦¦¦          ¦ 															  ¦¦¦
¦¦+----------+------------------------------------------------------------¦¦¦
¦¦¦Uso       ¦ Posto Inteligente			                              ¦¦¦
¦¦+-----------------------------------------------------------------------+¦¦
¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦
¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
*/
Static Function DoFiltro(nOpcX, lPdv)

	Local aArea := GetArea()

	#IFDEF TOP
		cFilGrid := BuildExpr("U25",,cFilGrid,.T.)
	#ELSE
		cFilGrid := BuildExpr("U25",,cFilGrid,.F.)
	#ENDIF

	Processa({|| LoadOGet1(nOpcX, lPdv, .T.)},"Aguarde...","Carregando registros...",.T.) //carrega dados

	RestArea(aArea)

Return

/*
_____________________________________________________________________________
¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦
¦¦+-----------------------------------------------------------------------+¦¦
¦¦¦Programa  ¦ DoEncerra  ¦ Autor ¦ Danilo Brito      ¦ Data ¦ 24/04/2014 ¦¦¦
¦¦+----------+------------------------------------------------------------¦¦¦
¦¦¦Descriçào ¦ Abre Dlg para informar data e hora de fim para o preço.    ¦¦¦
¦¦¦          ¦ 															  ¦¦¦
¦¦+----------+------------------------------------------------------------¦¦¦
¦¦¦Uso       ¦ Posto Inteligente			                              ¦¦¦
¦¦+-----------------------------------------------------------------------+¦¦
¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦
¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
*/
Static Function DoEncerra(nOpcX, lPdv)

	Local lRet := .T., nX
	Local cbkpCad := iif(type("cCadastro")=="C",cCadastro,"")
	Local cLogEncFil := ""
	Private oDlg02
	Private nConfirm := 0
	Private dDatFim := dDataBase
	Private cHoraFim := SubStr(Time(),1,5)//"23:59"
	Private aBtns := {}
	Private bConfirm := {|| iif( empty(dtos(dDatFim)) .OR. len(alltrim(cHoraFim)) < 5 , Help('',1,'DATA',,"Campos Data e Hora de fim devem ser preenchidos.",1,0), (nConfirm:=1,oDlg02:End()) ) }
	Private oNwGetEnc

	//cadastra rotina para controle de acesso
	U_TRETA37B("U25DEL", "EXCLUSÃO DE PREÇO NEGOCIADO")

	//verifica se o usuário tem permissão para acesso a rotina
	cUsrCmp := U_VLACESS1("U25DEL", RetCodUsr())
	if cUsrCmp == Nil .OR. empty(cUsrCmp)
		Return
	endif

	if oMSGet1:aCols[oMSGet1:nAt,Len(oMSGet1:aHeader)+1] > 0

		DbSelectArea("U25")
		U25->(DbGoTO(oMSGet1:aCols[oMSGet1:nAt,Len(oMSGet1:aHeader)+1]))

		if U25->U25_BLQL <> 'S'

			if !empty(U25->U25_DTFIM)
				dDatFim := U25->U25_DTFIM
				cHoraFim := U25->U25_HRFIM
			endif

			If empty(U25->U25_DTFIM)

				cCadastro := "Encerrar Preços"

				if lSelFilial
					oDlg02 := TDialog():New(0,0,450,800,"Encerrar Preço Negociado" ,,,,,,,,,.T.)
				else
					oDlg02 := TDialog():New(0,0,150,420,"Encerrar Preço Negociado" ,,,,,,,,,.T.)
				endif

				TSay():New( 35, 5,{|| "Esta opção irá alterar a data e hora de vigência finais do(s) preço(s) selecionado(s)." }, oDlg02,,,,,,.T.,CLR_BLACK,,480,9 )
				TSay():New( 42, 5,{|| "Preencha os campos a seguir:" }, oDlg02,,,,,,.T.,CLR_BLACK,,480,9 )

				TSay():New( 57,008,{|| "Data Fim" }, oDlg02,,,,,,.T.,CLR_BLUE,,30,9 )
				TGet():New( 55,040,{|u| iif( PCount()==0,dDatFim,dDatFim:= u) },oDlg02,060,009,,{|| dDatFim >= Date() }/*bValid*/,,,,.F.,,.T.,,.F.,{|| .T.},.F.,.F.,/*bChange*/,.F.,.F.,,"U25_DTFIM",,,,.T.,.F.)
				TSay():New( 57,120,{|| "Hora Fim" }, oDlg02,,,,,,.T.,CLR_BLUE,,30,9 )
				TGet():New( 55,150,{|u| iif( PCount()==0,cHoraFim,cHoraFim:= u) },oDlg02,030,009,"99:99",{|| iif(dDatFim==Date(),cHoraFim>=Time().AND.cHoraFim<"24:00",cHoraFim<"24:00") }/*bValid*/,,,,.F.,,.T.,,.F.,{|| .T.},.F.,.F.,/*bChange*/,.F.,.F.,,"U25_HRFIM",,,,.T.,.F.)

				if lSelFilial
					TSay():New( 90, 5,{|| "Preços com mesma chave encontrados nas filiais: (delete a linha dos que não desejar encerrar)" }, oDlg02,,,,,,.T.,CLR_BLACK,,480,9 )
					fMSNewEncerra()
				endif

				//enchoice bar
				oDlg02:bInit := {|| EnchoiceBar(oDlg02, bConfirm,{|| oDlg02:End()},,@aBtns) }
				oDlg02:lCentered := .T.

				oDlg02:Activate()

				cCadastro := cbkpCad

				if nConfirm == 1

					if lSelFilial

						for nX := 1 to len(oNwGetEnc:aCols)
							if !oNwGetEnc:aCols[nX,Len(oNwGetEnc:aHeader)+2] //se nao deletado
								U25->(DbGoTO(oNwGetEnc:aCols[nX,Len(oNwGetEnc:aHeader)+1]))

								cLogEncFil += "Encerrar na filial "+oNwGetEnc:aCols[nX,1]+" - "+Alltrim(oNwGetEnc:aCols[nX,2])+" "
								if empty(DTOS(dDatFim)+cHoraFim) .OR. U25->(DTOS(U25_DTINIC)+U25_HRINIC) < DTOS(dDatFim)+cHoraFim

									EncerrLck(dDatFim,cHoraFim) //faz lock

									cLogEncFil += "realizado com sucesso."+ Chr(13)+Chr(10)
								else
									cLogEncFil += "não foi possível, favor verificar." + Chr(13)+Chr(10)
								endif
							endif
						next nX

						U_XHELP("Log de Inclusões", cLogEncFil, "")
						Processa({|| LoadOGet1(nOpcX, lPdv, .T.)},"Aguarde...","Carregando registros...",.T.) //carrega dados

					else

						U25->(DbGoTO(oMSGet1:aCols[oMSGet1:nAt,Len(oMSGet1:aHeader)+1]))

						if empty(DTOS(dDatFim)+cHoraFim) .OR. U25->(DTOS(U25_DTINIC)+U25_HRINIC) < DTOS(dDatFim)+cHoraFim

							if U25->U25_FLAGVD=="S" .AND. dDatFim > (U25->U25_DTINIC + 1)
								Help('',1,'GETOBG',,"Data máxima para fim do preço é "+ DTOC((U25->U25_DTINIC + 1)) + ".",1,0)
								DoEncerra(nOpcX, lPdv)
							else

								//Ponto de Entrada validação de Encerra item
								//If lRet .AND. ExistBlock("UF001EOK")
								//	lRet := ExecBlock("UF001EOK",.F.,.F.)
								//	if Type("lRet") == "L" .AND. lRet == .F.
								//		return
								//	endif
								//EndIf

								if lRet
									if oMSGet1:aCols[oMSGet1:nAt,Len(oMSGet1:aHeader)+1] > 0
										EncerrLck(dDatFim,cHoraFim) //faz lock
									endif

									//TODO: melhorar logica aqui, para apenas encerrar preço posicionado
									Processa({|| LoadOGet1(nOpcX, lPdv, .T.)},"Aguarde...","Carregando registros...",.T.) //carrega dados
								endif

							endif
						else
							Help('',1,'DATA',,"Data/Hora de fim deve ser superior a Data/Hora início do registro.",1,0)
							DoEncerra(nOpcX, lPdv)
						endif
					endif

				endif
			Else
				Help('',1,'HELP',,"O Preço Negociado já foi encerrado.",1,0)
			EndIf
		else
			Help(,,"Atenção",,"Preço em aprovação. Ação não permitida.",1,0,,,,,,{""})
		endif
	else
		Help(,,"Atenção",,"Selecione um preço para encerrar.",1,0,,,,,,{""})
	endif

Return

//monta grid do encerrar por filial
Static Function fMSNewEncerra()

	Local aAltCpo 		:= {}
	Local aHeaderEx 	:= {}
	Local aHeadGrid 	:= {}
	Local aCmpGrid 		:= {}
	Local aColsEx 		:= {}
	Local aFieldFill	:= {}
	Local nX, cQry, cCliente, nPrcBas, nPrcVen
	Local xFilAnt := cFilAnt

	// Somente Header dos campos que quero jogar na Grid.
	Aadd( aHeadGrid, "U25_FILIAL")
	Aadd( aHeadGrid, "U25_DESFOR" ) //para descriçaõ da filal
	Aadd( aHeadGrid, "U25_PRCBAS" ) // Preço Base na filial
	Aadd( aHeadGrid, "U25_PRCVEN" )
	Aadd( aHeadGrid, "U25_DESPBA" )
	Aadd( aHeadGrid, "U25_PRODUT" )
	Aadd( aHeadGrid, "U25_FORPAG" )
	Aadd( aHeadGrid, "U25_CONDPG" )
	Aadd( aHeadGrid, "U25_CLIENT" )
	Aadd( aHeadGrid, "U25_LOJA" )
	Aadd( aHeadGrid, "U25_GRPCLI" )
	Aadd( aHeadGrid, "A1_NOME" ) // Trazer o nome do cliente ou grupo
	Aadd( aHeadGrid, "U25_ADMFIN" )

	//Define as propriedades dos campos
	For nX:=1 To Len( aHeadGrid )
		If !Empty(GetSx3Cache(aHeadGrid[nX],"X3_CAMPO"))
			aadd(aHeaderEx, U_UAHEADER(aHeadGrid[nX]) )
			if aHeadGrid[nX]=="U25_DESFOR"
				aHeaderEx[len(aHeaderEx)][1] := "Nome Filial"
			endif
		EndIf
	Next nX

	if empty(U25->U25_GRPCLI)
		cCliente := RETFIELD("SA1",1,xFilial("SA1")+U25->U25_CLIENT+U25->U25_LOJA,"A1_NOME")
	else
		cCliente := RETFIELD("ACY",1,XFILIAL("ACY")+U25->U25_GRPCLI,"ACY_DESCRI")
	endif

	cQry := "SELECT U25.R_E_C_N_O_ AS U25RECNO" + cEOL
	cQry += " FROM " + RetSqlName("U25") + " U25" + cEOL
	cQry += " WHERE U25.D_E_L_E_T_ <> '*'" + cEOL
	cQry += " AND U25_DTFIM = ' ' " + cEOL
	cQry += " AND U25_CLIENT = '"+U25->U25_CLIENT+"' AND U25_LOJA = '"+U25->U25_LOJA +"'" + cEOL
	cQry += " AND U25_GRPCLI = '"+U25->U25_GRPCLI+"'" + cEOL
	cQry += " AND U25_FORPAG = '"+U25->U25_FORPAG+"' AND U25_CONDPG = '"+U25->U25_CONDPG+"'" + cEOL
	cQry += " AND U25_PRODUT = '"+U25->U25_PRODUT+"'" + cEOL
	cQry += " AND U25_BLQL <> 'S'" + cEOL
	cQry += " ORDER BY U25_FILIAL" + cEOL

	If Select("QRYEST") > 0
		QRYEST->(DbCloseArea())
	EndIf

	cQry := ChangeQuery(cQry)
	TcQuery cQry New Alias "QRYEST" // Cria uma nova area com o resultado do query
	QRYEST->(dbGoTop())

	While QRYEST->(!Eof())

		U25->(DbGoTo(QRYEST->U25RECNO))

		cFilAnt := U25->U25_FILIAL
		nPrcBas := U_URetPrBa(U25->U25_PRODUT, U25->U25_FORPAG, U25->U25_CONDPG, U25->U25_ADMFIN, 0, U25->U25_DTINIC, U25->U25_HRINIC)
		nPrcVen := (nPrcBas - U25->U25_DESPBA)

		aFieldFill	:= {}
		Aadd( aFieldFill, U25->U25_FILIAL )
		Aadd( aFieldFill, FWFilialName(,U25->U25_FILIAL) ) //para descriçaõ da filal
		Aadd( aFieldFill, nPrcBas ) // Preço Base na filial
		Aadd( aFieldFill, nPrcVen ) //U25->U25_PRCVEN
		Aadd( aFieldFill, U25->U25_DESPBA )
		Aadd( aFieldFill, U25->U25_PRODUT )
		Aadd( aFieldFill, U25->U25_FORPAG )
		Aadd( aFieldFill, U25->U25_CONDPG )
		Aadd( aFieldFill, U25->U25_CLIENT )
		Aadd( aFieldFill, U25->U25_LOJA )
		Aadd( aFieldFill, U25->U25_GRPCLI )
		Aadd( aFieldFill, cCliente ) // Trazer o nome do cliente ou grupo
		Aadd( aFieldFill, U25->U25_ADMFIN )
		Aadd( aFieldFill, QRYEST->U25RECNO )
		Aadd( aFieldFill, .F.)  //delet

		Aadd(aCmpGrid, aFieldFill)

		QRYEST->(DbSkip())
	enddo

	QRYEST->(DbCloseArea())

	oNwGetEnc := msNewGetDados():New( 100, 005, 200, 395, GD_DELETE, "AlwaysTrue", "AlwaysTrue",, aAltCpo,,, "AlwaysTrue", "", "AlwaysTrue",oDlg02, aHeaderEx, aCmpGrid )

	cFilAnt := xFilAnt

Return

//Faz Recklock do encerramento o preço posicionado
Static Function EncerrLck(_dDtFim,_cHrFim)

	Begin Transaction

		RecLock("U25", .F.)
		U25->U25_OBS   := U25->U25_OBS + CHR(13)+CHR(10) + "Encerramento Manual (Data/Hora: "+DTOC(Date())+" "+Time()+". Usuário: "+iif(IsBlind(),"JOB",RetCodUsr())+")"
		U25->U25_DTFIM := _dDtFim
		U25->U25_HRFIM := _cHrFim
		U25->(MsUnlock())

	End Transaction

	U_UREPLICA("U25", 1, U25->U25_FILIAL+U25->U25_REPLIC, "A")
	DbSelectArea("U25")

Return

/*
_____________________________________________________________________________
¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦
¦¦+-----------------------------------------------------------------------+¦¦
¦¦¦Programa  ¦ U25Legend   ¦ Autor ¦ Danilo Brito     ¦ Data ¦ 15/05/2014 ¦¦¦
¦¦+----------+------------------------------------------------------------¦¦¦
¦¦¦Descriçào ¦ Retorna qual legenda do registro U25. 					  ¦¦¦
¦¦+----------+------------------------------------------------------------¦¦¦
¦¦¦Uso       ¦ Posto Inteligente			                              ¦¦¦
¦¦+-----------------------------------------------------------------------+¦¦
¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦
¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
*/
Static Function U25Legend()

	Local aAreaU25 := GetArea("U25")
	Local cCor := ""
	Local nX
	Local nRecU25 := U25->(Recno())

	for nX := 1 to len(aCores)
		if &(aCores[nX][1])
			cCor := aCores[nX][2]
			exit
		endif
	next nX

	RestArea(aAreaU25)
	U25->(DbGoTo(nRecU25))

Return cCor

/*
_____________________________________________________________________________
¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦
¦¦+-----------------------------------------------------------------------+¦¦
¦¦¦Programa  ¦ TRET023D    ¦ Autor ¦ Danilo Brito     ¦ Data ¦ 15/05/2014 ¦¦¦
¦¦+----------+------------------------------------------------------------¦¦¦
¦¦¦Descriçào ¦ descobre se o item U25 está vigente ou não.				  ¦¦¦
¦¦+----------+------------------------------------------------------------¦¦¦
¦¦¦Uso       ¦ Posto Inteligente			                              ¦¦¦
¦¦+-----------------------------------------------------------------------+¦¦
¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦
¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
*/
User Function TRET023D()

	Local lRet := .T.
	//Local aChaves := U_TRET023A()
	Local dDtIni := U25->U25_DTINIC
	Local cHrIni := U25->U25_HRINIC
	Local nRecno := U25->(Recno())

	/*DbSelectArea("U25")
	U25->(DbSetOrder(2))
	U25->(DbSeek(aChaves[2]))
	while U25->(!Eof()) .AND. &(aChaves[1]) == aChaves[2]

		if U25->(Recno()) != nRecno .AND. U25->U25_DTINIC <= dDataBase
			if DTOS(U25->U25_DTINIC)+U25->U25_HRINIC >= DTOS(dDtIni)+cHrIni
				lRet := .F.
				exit
			endif
		endif

		U25->(DbSkip())
	enddo

	U25->(DbGoTo(nRecno))
	*/

	if lRet
		lRet := .F.
		if (empty(U25->U25_DTFIM) .OR. DTOS(U25->U25_DTFIM)+U25->U25_HRFIM >= DTOS(DDATABASE)+SUBSTR(Time(),1,5) )
			if DTOS(U25->U25_DTINIC)+U25->U25_HRINIC <= DTOS(DDATABASE) + SUBSTR(Time(),1,5)
				if empty(U25_NUMORC)
					lRet := .T.
				endif
			endif
		endif
	endif


Return lRet

/*
_____________________________________________________________________________
¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦
¦¦+-----------------------------------------------------------------------+¦¦
¦¦¦Programa  ¦ TRET023E    ¦ Autor ¦ Danilo Brito     ¦ Data ¦ 15/05/2014 ¦¦¦
¦¦+----------+------------------------------------------------------------¦¦¦
¦¦¦Descriçào ¦ faz validação dos campos forma e condição pagto.			  ¦¦¦
¦¦+----------+------------------------------------------------------------¦¦¦
¦¦¦Uso       ¦ Posto Inteligente			                              ¦¦¦
¦¦+-----------------------------------------------------------------------+¦¦
¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦
¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
*/
User Function TRET023E(cCampo)

	Local lRet := .T.
	Local nPosForPg

	Local nX

	if FunName() == 'TRETA024'
		nX := oMSNewGe2:nAt
		nPosForPg:= aScan(aHeader2,{|x| Trim(x[2])=="U25_FORPAG"})
		if cCampo == 'U25_FORPAG'
			lRet := empty(M->U25_FORPAG) .OR. ExistCpo("U44",M->U25_FORPAG)
		elseif cCampo == 'U25_CONDPG'
			lRet := empty(M->U25_CONDPG) .OR. ExistCpo("U44",aDados2[nX][nPosForPg] +M->U25_CONDPG)
		endif
	else
		if cCampo == 'U25_FORPAG'
			lRet := empty(M->U25_FORPAG) .OR. ExistCpo("U44",M->U25_FORPAG)
		elseif cCampo == 'U25_CONDPG'
			lRet := empty(M->U25_CONDPG) .OR. ExistCpo("U44",M->U25_FORPAG+M->U25_CONDPG)
		elseif cCampo == 'U0A_FORPAG'
			lRet := empty(M->U0A_FORPAG) .OR. ExistCpo("U44",M->U0A_FORPAG)
		elseif cCampo == 'U0A_CONDPG'
			lRet := empty(M->U0A_CONDPG) .OR. ExistCpo("U44",M->U0A_FORPAG+M->U0A_CONDPG)
		elseif cCampo == 'U0B_FORPAG'
			lRet := empty(M->U0B_FORPAG) .OR. ExistCpo("U44",M->U0B_FORPAG)
		elseif cCampo == 'U0B_CONDPG'
			lRet := empty(M->U0B_CONDPG) .OR. ExistCpo("U44",M->U0B_FORPAG+M->U0B_CONDPG)
		endif
	endif

Return lRet

/*
_____________________________________________________________________________
¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦
¦¦+-----------------------------------------------------------------------+¦¦
¦¦¦Programa  ¦ TRET023F    ¦ Autor ¦ Danilo Brito     ¦ Data ¦ 15/05/2014 ¦¦¦
¦¦+----------+------------------------------------------------------------¦¦¦
¦¦¦Descriçào ¦ faz validação dos campos forma e condição pagto.			  ¦¦¦
¦¦+----------+------------------------------------------------------------¦¦¦
¦¦¦Uso       ¦ Posto Inteligente			                              ¦¦¦
¦¦+-----------------------------------------------------------------------+¦¦
¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦
¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
*/
User Function TRET023F()

	Local lRet := .T.
	Local nPosForPg
	Local nPosCond
	Local nX

	if FunName() == 'TRETA024'
		nX := oMSNewGe2:nAt
		nPosForPg:= aScan(aHeader2,{|x| Trim(x[2])=="U25_FORPAG"})
		lRet := U44->U44_FORMPG==aDados2[nX][nPosForPg]
	else
		lRet := U44->U44_FORMPG==M->U25_FORPAG
	endif

Return lRet


//Função para inicializador padrão de campos virtuais, para nao desposicionar produto/cliente
User Function TRET023H(_cAlias, _nInd, _cChav, _cRet, lCli)

	Local aArea := GetArea(_cAlias)
	Local cRecEnt := &(_cAlias)->(Recno())
	Local cRet := ""
	Default lCli := .F.

	if lCli
		if empty(U25->U25_CLIENT+U25->U25_LOJA)
			_cAlias := "ACY"
			aArea := GetArea(_cAlias)
			cRecEnt := &(_cAlias)->(Recno())
			cRet := POSICIONE("ACY",1,XFILIAL("ACY")+U25->U25_GRPCLI,"ACY_DESCRI")                                                      
		else
			_cAlias := "SA1"
			aArea := GetArea(_cAlias)
			cRecEnt := &(_cAlias)->(Recno())
			cRet := POSICIONE("SA1",1,XFILIAL("SA1")+U25->U25_CLIENT+U25->U25_LOJA,"A1_NOME")                                                      
		endif
	else
		//if type("INCLUI")=="U" .OR. (!INCLUI)
		cRet := POSICIONE(_cAlias, _nInd, _cChav, _cRet)
		//endif
	endif	

	&(_cAlias)->(DbGoTo(cRecEnt))
	RestArea(aArea)

Return cRet

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³TRET023I  ºAutor  ³Microsiga           º Data ³  12/03/15   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³ Processa retorno da alçada de aprovação do preço		      º±±
±±º          ³ Minimo                                                     º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ AP                                                         º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/

User function TRET023I(nOpcao,oProcess)

	Local _nQtdAprov	:= 0
	Local _nAprov		:= 0
	Private lMsErroAuto := .F.
	Default nOpcao		:= 0
//Conout("TRETA023 - "+str(nopcao))
	if nOpcao > 0
		cResposta:=oProcess:oHtml:RetByName("RBAPROVA")
		cProcesso:=oProcess:fProcessID
		//Conout("TRETA023 - "+cResposta)
		//Conout("TRETA023 - "+cProcesso)
		DbSelectArea("UAC")
		UAC->(DbSetOrder(2))
		If UAC->(DbSeek(xFilial("UAC")+cProcesso))
			_CodAprov := UAC->UAC_COD

			If cResposta == "1"
				RecLock("UAC",.F.)
				UAC->UAC_APROVA := "S"
				UAC->UAC_DTAPRO := dDataBase
				UAC->(MsUnlock())
			Else
				RecLock("UAC",.F.)
				UAC->UAC_APROVA := "N"
				UAC->UAC_DTAPRO := dDataBase
				UAC->(MsUnlock())
			EndIf

			UAC->(DbSetOrder(1))
			If UAC->(DbSeek(xFilial("UAC")+_CodAprov))
				_nAprov := Posicione("UAB",1,xFilial("UAB")+_CodAprov,"UAB_NAPROV")
				_cRegistro := Posicione("UAB",1,xFilial("UAB")+_CodAprov,"UAB_REGIST")
				DbSelectArea("U25")
				U25->(DbGoTo(Val(_cRegistro)))
				_nQtdAprov:=0

				While UAC->(!Eof()) .And. UAC->UAC_FILIAL+UAC->UAC_COD == xFilial("UAC")+_CodAprov
					If UAC->UAC_APROVA == "S"
						_nQtdAprov++
					EndIf
					UAC->(DbSkip())
				EndDo

			EndIf
		Endif

	EndIf

	If _nQtdAprov >= _nAprov
		If !(U25->U25_BLQL == "N")
			RecLock("U25",.F.)
			U25->U25_BLQL := "N"
			U25->(MsUnlock())
			U_UREPLICA("U25", 1, U25->U25_FILIAL+U25->U25_REPLIC, "A")
		EndIf
	EndIf

Return

/*--------------------------------------------------------------------------------------------------
Função: fFilial
Tipo: Função Estática
Descrição: Abre uma checkbox para o usuário selecionar as filiais que deseja buscar as informações
Uso: Posto Inteligente
Parâmetros:
Retorno:
----------------------------------------------------------------------------------------------------
Atualizações:
- 30/03/2016 - Gianluka Moraes de Sousa - Construção Inicial do Fonte
--------------------------------------------------------------------------------------------------*/

Static Function fFilial(aLisFil)

Local aFilsCalc:={}

// Variaveis utilizadas na selecao de categorias
Local oChkQual,lQual,oQual,cVarQ

// Carrega bitmaps
Local oOk       := LoadBitmap( GetResources(), "LBOK")
Local oNo       := LoadBitmap( GetResources(), "LBNO")

// Variaveis utilizadas para lista de filiais
Local lStat		:= .F.
Local nPos 		:= 0
Local aAreaSM0	:= SM0->( GetArea() )
//Local aFilsCalc := FWLoadSM0()
Local oDlg

DEFAULT aLisFil := {}

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Carrega filiais da empresa corrente                          ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
DbSelectArea("SM0")
DbSeek(cEmpAnt)
Do While ! Eof() .And. SM0->M0_CODIGO == cEmpAnt

	lStat := .f.

	nPos := aScan( aLisFil,{ |x| x[2] = Alltrim(SM0->M0_CODFIL) } )

	If nPos > 0
		lStat := aLisFil[nPos,1]
	EndIf

	Aadd(aFilsCalc,{lStat,Alltrim(SM0->M0_CODFIL),Alltrim(SM0->M0_FILIAL),SM0->M0_CGC})

	dbSkip()
EndDo

RestArea(aAreaSM0)

If Len(aFilsCalc) > 0

	DEFINE MSDIALOG oDlg TITLE OemToAnsi("Seleção de Filiais") STYLE DS_MODALFRAME From 145,0 To 445,628 OF oMainWnd PIXEL
	oDlg:lEscClose := .F.
	@ 05,15 TO 125,300 LABEL OemToAnsi("Marque as Filiais a serem consideradas no processamento") OF oDlg  PIXEL
	@ 15,20 CHECKBOX oChkQual VAR lQual PROMPT OemToAnsi("Inverte Selecao") SIZE 50, 10 OF oDlg PIXEL ON CLICK (AEval(aFilsCalc, {|z| z[1] := If(z[1]==.T.,.F.,.T.)}), oQual:Refresh(.F.))
	@ 30,20 LISTBOX oQual VAR cVarQ Fields HEADER "",OemToAnsi("Filial"),OemToAnsi("Nome"),OemToAnsi("CNPJ") SIZE 273,090 ON DBLCLICK (aFilsCalc:=MtFClTroca(oQual:nAt,aFilsCalc),oQual:Refresh()) NoScroll OF oDlg PIXEL
	oQual:SetArray(aFilsCalc)
	oQual:bLine := { || {If(aFilsCalc[oQual:nAt,1],oOk,oNo),aFilsCalc[oQual:nAt,2],aFilsCalc[oQual:nAt,3]}}
	DEFINE SBUTTON FROM 134,240 TYPE 1 ACTION If(MtFCalOk(aFilsCalc,.T.,.T.),oDlg:End(),) ENABLE OF oDlg
	DEFINE SBUTTON FROM 134,270 TYPE 2 ACTION (lCancMultiFil:=.T.,oDlg:End()) ENABLE OF oDlg

	ACTIVATE MSDIALOG oDlg CENTERED
Else
	Help(,,"Atenção",,"Sem Filial",1,0,,,,,,{""})
EndIf

Return aFilsCalc

/*--------------------------------------------------------------------------------------------------
Função: MtFCalOk
Tipo: Função Estática
Descrição: Checa marcacao das filiais
Uso:  ExpA1 = Array com a selecao das filiais
      ExpL1 = Valida array de filiais (.t. se ok e .f. se cancel)
      ExpL2 = Mostra tela de aviso no caso de inconsistencia
Parâmetros:
Retorno:
----------------------------------------------------------------------------------------------------
Atualizações:
- 30/03/2016 - Gianluka Moraes de Sousa - Construção Inicial do Fonte
--------------------------------------------------------------------------------------------------*/

Static Function MtFCalOk(aFilsCalc,lValidaArray,lMostraTela)
 Local lRet:=.F.
 Local nx:=0

 Default lMostraTela := .T.

 If !lValidaArray
  aFilsCalc := {}
  lRet := .T.
 Else
 // Checa marcacoes efetuadas
  For nx:=1 To Len(aFilsCalc)
   If aFilsCalc[nx,1]
    lRet:=.T.
   EndIf
  Next nx
 // Checa se existe alguma filial marcada na confirmacao
  If !lRet
   	Help(,,"Atenção",,"Deve ser selecionada ao menos uma filial para o processamento.",1,0,,,,,,{""})
  EndIf
 EndIf

Return lRet

/*--------------------------------------------------------------------------------------------------
Função: MtFClTroca
Tipo: Função Estática
Descrição: Troca marcador entre x e branco
Uso:  ExpN1 = Linha onde o click do mouse ocorreu
	  ExpA2 = Array com as opcoes para selecao
Parâmetros:
Retorno:
----------------------------------------------------------------------------------------------------
Atualizações:
- 30/03/2016 - Gianluka Moraes de Sousa - Construção Inicial do Fonte
--------------------------------------------------------------------------------------------------*/
Static Function MtFClTroca(nIt,aArray)
	 aArray[nIt,1] := !aArray[nIt,1]
Return aArray


/*--------------------------------------------------------------------------------------------------
Função: TelaSelFil
Tipo: Função Estática
Descrição: Monta a tela com as filiais escolhidas para alterar o preço de venda para cada uma delas.
Uso:  ExpA1 = Array com as filiais selecionadas
	  ExpA2 = Array com os campos utilizados na inclusão do registro
Parâmetros:
Retorno:
----------------------------------------------------------------------------------------------------
Atualizações:
- 13/07/2016 - Gianluka Moraes de Sousa - Construção Inicial do Fonte
--------------------------------------------------------------------------------------------------*/
Static Function TelaSelFil( aFiliais, aCampos )

	Local oButton1
	Local oButton2
	Local oGroup1
	Local oSay1
	Local lFechaX := .F.
	Local xFilAnt := cFilAnt
	Static oDlg


	DEFINE MSDIALOG oDlg TITLE "Negocição de Preços" FROM 000, 000 TO 500, 1400 COLORS 0, 16777215 PIXEL

		fMSNewGe1( aFiliais, aCampos )
		@ 009, 002 GROUP oGroup1 TO 062, 235 PROMPT "Inclusão por Filiais" OF oDlg COLOR 0, 16777215 PIXEL
		@ 028, 007 SAY oSay1 PROMPT "Selecione o valor desejado para cada filial." SIZE 109, 007 OF oDlg COLORS 0, 16777215 PIXEL
		@ 193, 235 BUTTON oButton1 PROMPT "Confirmar" SIZE 084, 031 OF oDlg PIXEL ACTION ( lFechaX:=.T.,cFilAnt:=xFilAnt, oDlg:End() )
		@ 193, 345 BUTTON oButton2 PROMPT "Cancelar" SIZE 084, 031 OF oDlg PIXEL ACTION ( lFechaX:=lCancMultiFil:=.T.,cFilAnt:=xFilAnt,oDlg:End() )

	ACTIVATE MSDIALOG oDlg CENTERED VALID lFechaX // Impede o usuário de fechar a janela pelo "X"
Return

Static Function fMSNewGe1( aFiliais, aCampos )

	Local aAltCpo 		:= {}
	Local aHeaderEx 	:= {}
	Local aHeadGrid 	:= {}
	Local aCmpGrid 		:= {}
	Local aColsEx 		:= {}
	Local aFieldFill	:= {}
	Local cCliente		:= "" // Pegar o nome do cliente.

	Local nPosFil 		:= aScan(aCampos, {|x| AllTrim(x[1])=="U25_FILIAL"	})
	Local nPosPro 		:= aScan(aCampos, {|x| AllTrim(x[1])=="U25_PRODUT"	})
	Local nPosForPg 	:= aScan(aCampos, {|x| AllTrim(x[1])=="U25_FORPAG"	})
	Local nPosCondPg	:= aScan(aCampos, {|x| AllTrim(x[1])=="U25_CONDPG"	})
	Local nPosAdmPg		:= aScan(aCampos, {|x| AllTrim(x[1])=="U25_ADMFIN"	})
	Local nPosCodCli 	:= aScan(aCampos, {|x| AllTrim(x[1])=="U25_CLIENT"	})
	Local nPosLojCli 	:= aScan(aCampos, {|x| AllTrim(x[1])=="U25_LOJA"	})
	Local nPosValor		:= aScan(aCampos, {|x| AllTrim(x[1])=="U25_PRCVEN"	})
	Local nPosDesco		:= aScan(aCampos, {|x| AllTrim(x[1])=="U25_DESPBA"	})
	Local nPosDtIni		:= aScan(aCampos, {|x| AllTrim(x[1])=="U25_DTINIC"	})
	Local nPosHrIni		:= aScan(aCampos, {|x| AllTrim(x[1])=="U25_HRINIC"	})

	Local nX
	Local xFilAnt := cFilAnt

	// Somente Header dos campos que quero jogar na Grid.
	Aadd( aHeadGrid, { aCampos[nPosFil,    1] 	})
	Aadd( aHeadGrid, { "A1_NOME"    }) // Trazer o nome da filial
	Aadd( aHeadGrid, { "U25_PRCBAS" }) // Preço Base na filial
	Aadd( aHeadGrid, { aCampos[nPosValor,  1] 	})
	Aadd( aHeadGrid, { aCampos[nPosDesco,  1] 	})
	Aadd( aHeadGrid, { aCampos[nPosPro,    1] 	})
	Aadd( aHeadGrid, { aCampos[nPosForPg,  1] 	})
	Aadd( aHeadGrid, { aCampos[nPosCondPg, 1] 	})
	Aadd( aHeadGrid, { aCampos[nPosAdmPg,  1] 	})
	Aadd( aHeadGrid, { aCampos[nPosCodCli, 1] 	})
	Aadd( aHeadGrid, { aCampos[nPosLojCli, 1] 	})
	Aadd( aHeadGrid, { "A1_NOME"    } ) // Trazer o nome do cliente
	Aadd( aHeadGrid, { aCampos[nPosDtIni,  1] 	})
	Aadd( aHeadGrid, { aCampos[nPosHrIni,  1] 	})

	cCliente := RETFIELD("SA1",1,xFilial("SA1")+aCampos[nPosCodCli,2]+aCampos[nPosLojCli,2],"A1_NOME")

	// Somente contéudo dos campos que quero jogar na Grid, criando um aCols para cada filial que o usuario selecionou.
	For nX:=1 To Len(aFiliais)
		If aFiliais[nX,1]

			cFilAnt := aFiliais[nX,2]
			nPrcBas := U_URetPrBa(aCampos[nPosPro,2], aCampos[nPosForPg,2], aCampos[nPosCondPg,2], aCampos[nPosAdmPg,2], 0, aCampos[nPosDtIni,2], aCampos[nPosHrIni,2])
			If nTipoRep = 2 //replica o desconto para outras filiais
				nPrcVen := (nPrcBas - aCampos[nPosDesco,2])
				nDescon := aCampos[nPosDesco,2]
			Else //replica o preço de venda para outras filiais
				nPrcVen := aCampos[nPosValor,2]
				nDescon := (nPrcBas - aCampos[nPosValor,2])
			EndIf

			If nPrcVen > 0 .and. nPrcBas > 0
				Aadd( aCmpGrid, { aFiliais[nX,2], aFiliais[nX,3], nPrcBas, nPrcVen, nDescon, aCampos[nPosPro,2], aCampos[nPosForPg,2], aCampos[nPosCondPg,2], aCampos[nPosAdmPg,2], aCampos[nPosCodCli,2], aCampos[nPosLojCli,2], cCliente, aCampos[nPosDtIni,2], aCampos[nPosHrIni,2], .F. })
			Else
				Aadd( aCmpGrid, { aFiliais[nX,2], aFiliais[nX,3], nPrcBas, nPrcBas,       0, aCampos[nPosPro,2], aCampos[nPosForPg,2], aCampos[nPosCondPg,2], aCampos[nPosAdmPg,2], aCampos[nPosCodCli,2], aCampos[nPosLojCli,2], cCliente, aCampos[nPosDtIni,2], aCampos[nPosHrIni,2], .F. })
			EndIf

		EndIf
	Next nX

	// Campos que o usuário poderá alterar.
	aAltCpo := {"U25_PRCVEN","U25_DESPBA","U25_PRODUT","U25_DTINIC","U25_HRINIC"}

	//Define as propriedades dos campos
	For nX:=1 To Len( aHeadGrid )
		If !Empty(GetSx3Cache(aHeadGrid[nX][1],"X3_CAMPO"))
			aadd(aHeaderEx, U_UAHEADER(aHeadGrid[nX][1]) )
		EndIf
	Next nX

	oNwGetDad := msNewGetDados():New( 071, 001, 167, 700, GD_UPDATE, "AlwaysTrue", "AlwaysTrue",, aAltCpo,,, "U_TRET023J", "", "AlwaysTrue", , aHeaderEx, aCmpGrid )

	cFilAnt := xFilAnt

Return

/*--------------------------------------------------------------------------------------------------
Função: InsMultFil
Tipo: Função Estática
Descrição: Realiza as inclusões dos registros nas filiais selecionadas.
Uso:  ExpA1 = Array com as filiais selecionadas
      ExpA2 = Array com os campos utilizados na inclusão dos registros
Parâmetros:
Retorno:
----------------------------------------------------------------------------------------------------
Atualizações:
- 13/07/2016 - Gianluka Moraes de Sousa - Construção Inicial do Fonte
--------------------------------------------------------------------------------------------------*/
Static Function InsMultFil( oSay, nOpcX, lPdv, aFiliais, aCampos )

	Local aHeader	:= oNwGetDad:aHeader
	Local aCols 	:= oNwGetDad:aCols
	Local lInsere	:= .T.
	Local xFilAnt 	:= cFilAnt
	Local aFilSel	:= {} // Irá guardar somente as filiais que foram selecionadas.
	Local cLog		:= ""
	Local x, nX

	// Posição dos campos no array aCampos que é o que iremos alterar
	Local nPosFilA 	:= aScan(aCampos, {|x| AllTrim(x[1])=="U25_FILIAL"	})
	Local nPosPrcA 	:= aScan(aCampos, {|x| AllTrim(x[1])=="U25_PRCVEN"	})
	Local nPosDesA 	:= aScan(aCampos, {|x| AllTrim(x[1])=="U25_DESPBA"	})
	Local nPosProA	:= aScan(aCampos, {|x| AllTrim(x[1])=="U25_PRODUT"	}) // GMdS | 03-04-2017 : Adicionado após solicitação da Margarete.

	// Posição dos campos no array do GetDados, onde ?o usuário informou os valores por filiais.
	Local nPosFilB	:= aScan(aHeader, {|x| AllTrim(x[2])=="U25_FILIAL"	})
	Local nPosPrcB	:= aScan(aHeader, {|x| AllTrim(x[2])=="U25_PRCVEN"	})
	Local nPosDesB	:= aScan(aHeader, {|x| AllTrim(x[2])=="U25_DESPBA"	})
	Local nPosProB	:= aScan(aHeader, {|x| AllTrim(x[2])=="U25_PRODUT"	}) // GMdS | 03-04-2017 : Adicionado após solicitação da Margarete.

	For nX:=1 To Len(aFiliais)
    	If aFiliais[nX][1]
    		Aadd( aFilSel, { aFiliais[nX][2] })
    	EndIf
	Next nX

	// Neste laço, faço as validações para cada linha, de cada filial.
//	Eval( _MSG,"Aguarde...")
	For x:=1 To Len(aFilSel)

		cFilAnt := aCols[x, nPosFilB] // Mudo para a filial em que o registro será inserido.

		aCampos[nPosFilA, 2] := aCols[x, nPosFilB]
		aCampos[nPosPrcA, 2] := aCols[x, nPosPrcB]
		aCampos[nPosDesA, 2] := aCols[x, nPosDesB]
		aCampos[nPosProA, 2] := aCols[x, nPosProB] // GMdS | 03-04-2017 : Adicionado após solicitação da Margarete.

		If U_TRET023B(aCampos)

			//Ponto de Entrada tratamentos de validação
			//If ExistBlock("UF001IOK")
			//	lRet := ExecBlock("UF001IOK",.F.,.F.)
			//	if Type("lRet") == "L" .AND. lRet == .F.
			//		return
			//	EndIf
			//endif

			// Se tudo foi validado, insiro a informação
			U_TRET023C("I", aCampos) //faz inclusão
			nRecU25 := U25->(Recno())
	        cLog += "Inclusão na filial "+cFilAnt+" - "+AllTrim(RetField('SM0',1,cEmpAnt+cFilAnt,'M0_FILIAL'))+" realizada com sucesso." + Chr(13)+Chr(10)
		Else
			cLog += "Não foi possível incluir na filial "+cFilAnt+" - "+AllTrim( RetField('SM0',1,cEmpAnt+cFilAnt,'M0_FILIAL') ) + ", favor verificar." + Chr(13)+Chr(10)
			Help(,,"Atenção",,"Foram encontradas inconsistencias nas validações das informações, favor verificar!"+Chr(13)+Chr(10)+"Filial: "+cFilAnt+" - "+AllTrim( RetField('SM0',1,cEmpAnt+cFilAnt,'M0_FILIAL') ),1,0,,,,,,{""})
		EndIf
	Next x

	cFilAnt := xFilAnt // Volto para a filial logada antes de recarregar o browse.

	InPadEnch(nOpcX, lPdv) //limpa form
	//TODO: melhorar logica para apenas incluir o item no browse e nao recarregar tudo
	Processa({|| LoadOGet1(nOpcX, lPdv, .T.)},"Aguarde...","Carregando registros...",.T.) //carrega dados

	//Help(,,"Log de Inclusões",,cLog,1,0,,,,,,{""})
	U_XHELP("Log de Inclusões", cLog, "")

Return





/*/{Protheus.doc} TRET023L
Deleta os preços sem Negociação de Pagamento

@author pablocavalcante
@since 28/06/2016
@version undefined

@type function
/*/

Function U_TRET023L(cEmp,cFil)

Local aArea		:= GetArea()
Local oProcess
Local lEnd 		:= .F.
Local cLog 		:= ""
Local lOk       := .T.

Default cEmp  := "02"
Default cFil  := "0101"

Static oSay

RpcSetType(3)
RpcSetEnv(cEmp,cFil)

	FWMsgRun(, {|oSay| lOk := U_TRET023K(@oSay, @cLog) }, "Aguarde! Processando...", "Processamento ajuste..." )

	//oProcess := MsNewProcess():New({|lEnd| UAJUSDUP(@oProcess, @lEnd, @cLog) },"Aguarde! Processando...","Processamento ajuste...",.T.)
	//oProcess:Activate()

	If !Empty(cLog)

		cFileLog := MemoWrite( CriaTrab( , .F. ) + ".log", cLog )
		Define Font oFont Name "Arial" Size 7, 16
		Define MsDialog oDlgDet Title "Log Gerado" From 3, 0 to 340, 417 Pixel

		@ 5, 5 Get oMemo Var cLog Memo Size 200, 145 Of oDlgDet Pixel
		oMemo:bRClicked := { || AllwaysTrue() }
		oMemo:oFont     := oFont

		Define SButton From 153, 175 Type  1 Action oDlgDet:End() Enable Of oDlgDet Pixel // Apaga
		Define SButton From 153, 145 Type 13 Action ( cFile := cGetFile( cMask, "" ), If( cFile == "", .T., ;
		MemoWrite( cFile, cLog ) ) ) Enable Of oDlgDet Pixel

		Activate MsDialog oDlgDet Center

	EndIf

	RestArea(aArea)

Return

//
// Reprocessamento... AJUSTE PRECOS SEM NEGOCIACOES DE PAGAMENTO
//
User Function TRET023K(oSay, cLog, cCodCli, cLojCli, cGrpCli, cFormPG, cCondPG)

Local aArea := GetArea()
Local lOk   := .T.
Local _cUser := RetCodUsr()

Default cCodCli := ""
Default cLojCli := ""
Default cGrpCli := ""
Default cFormPG := ""
Default cCondPG := ""

	//Conout("############ <TRET023L> - AJUSTE PRECOS SEM NEGOCIACOES DE PAGAMENTO #############")
	//Conout(">> DATA: "+ DToC(Date()) +" - HORA: " + Time())
	//Conout("")

	cLog += ">> INICIO - DELETA OS PRECOS SEM NEGOCIACOES DE PAGAMENTO " + cEOL
	cLog += ">> DATA: "+ DToC(Date()) +" - HORA: " + Time()
	cLog += cEOL

	cLog += cEOL
	cLog += " >> SELECAO DOS REGISTROS..." + cEOL

	cQry := "SELECT U25.R_E_C_N_O_ AS U25RECNO" + cEOL
	cQry += " FROM " + RetSqlName("U25") + " U25" + cEOL
	cQry += " INNER JOIN " + RetSqlName("U44") + " U44 ON (U44.D_E_L_E_T_ <> '*' AND U44_FILIAL = U25_FILIAL AND U44_FORMPG = U25_FORPAG AND U44_CONDPG = U25_CONDPG AND U44_PADRAO = 'N')" + cEOL
	cQry += " WHERE U25.D_E_L_E_T_ <> '*'" + cEOL
	cQry += " AND U25_FILIAL = '"+xFilial("U25")+"'" + cEOL
	//somente com data de fim dentro da vigencia
	cQry += " AND U25_DTINIC <= '"+DTOS(date())+"'" + cEOL
	cQry += " AND ((U25_DTFIM = '"+DTOS(CTOD(""))+"' AND U25_HRFIM = '') OR (U25_DTFIM||U25_HRFIM >= '"+DTOS(date())+SUBSTR(Time(),1,5)+"'))" + cEOL
	If !Empty(cCodCli) .and. !Empty(cLojCli)
		cQry += " AND U25_CLIENT = '"+cCodCli+"' AND U25_LOJA = '"+cLojCli+"'" + cEOL
	EndIf
	If !Empty(cGrpCli)
		cQry += " AND U25_GRPCLI = '"+cGrpCli+"'" + cEOL
	EndIf
	If !Empty(cFormPG) .and. !Empty(cCondPG)
		cQry += " AND U25_FORPAG = '"+cFormPG+"' AND U25_CONDPG = '"+cCondPG+"'" + cEOL
	EndIf
	cQry += " AND U25_NUMORC = ''" + cEOL //para trazer somente preços que nao foram utilizdos em venda específica
	cQry += " AND U25_BLQL <> 'S'" + cEOL
	cQry += " AND NOT EXISTS (SELECT * FROM " + RetSqlName("U53") + " U53 WHERE U53.U53_FILIAL = U25.U25_FILIAL AND U53.D_E_L_E_T_ <> '*' AND U53_FORMPG = U25_FORPAG AND U53_CONDPG = U25_CONDPG AND U53_GRPVEN = U25_GRPCLI AND U53_CODCLI = U25_CLIENT AND U53_LOJA = U25_LOJA AND U53_TPRGNG = 'R')" + cEOL
	cQry += " ORDER BY U25_FILIAL, U25_CLIENT, U25_LOJA, U25_GRPCLI, U25_FORPAG, U25_CONDPG" + cEOL

	cLog += cEOL
	cLog += " >> QUERY: "
	cLog += cEOL
	cLog += cEOL
	cLog += cQry
	cLog += cEOL
	cLog += cEOL

	If Select("QRYU25") > 0
		QRYU25->(DbCloseArea())
	EndIf

	cQry := ChangeQuery(cQry)
	TcQuery cQry New Alias "QRYU25" // Cria uma nova area com o resultado do query

	nCount := 0
	nRegis := 0

	QRYU25->(dbEval({|| nCount++}))
	QRYU25->(dbGoTop())

	//oProcess:SetRegua1(nCount)
	If !IsBlind()
		fPrint(@oSay,"Foram selecionados " + StrZero(nCount,10) + " registros...")
	EndIf

	DbSelectArea("U25")
	U25->(DbSetOrder(1))

	While QRYU25->(!Eof())

		If nRegis > 1000 //houve cancelamento do processo
			Exit
		EndIf

		U25->(DbGoTo(QRYU25->U25RECNO))
		If U25->(!Eof())
			If !IsBlind()
				fPrint(@oSay,"Preço Negociado: " + U25->U25_FORPAG+"/"+U25->U25_CONDPG+" "+AllTrim(POSICIONE("U44",1,xFilial("U44")+U25->U25_FORPAG+U25->U25_CONDPG,"U44_DESCRI")) + "...")
			EndIf

			cMsgLog := ""
			lNoMsg  := .T.
			lRet := U_TRET022D(U25->U25_FORPAG, U25->U25_CONDPG, U25->U25_CLIENT, U25->U25_LOJA, U25->U25_PRODUT, !lNoMsg, @cMsgLog, U25->U25_GRPCLI)
			If !lRet
				lOk  := .F.
			EndIf
			If !Empty(cMsgLog) .and. !lRet
				nRegis++
				cLog += cEOL

				cLog += "Produto: " + U25->U25_PRODUT+" "+ POSICIONE("SB1",1,XFILIAL("SB1")+U25->U25_PRODUT,"B1_DESC") +cEOL+;
					iif(empty(U25->U25_CLIENT+U25->U25_LOJA),"","Cliente/Loja: "+U25->U25_CLIENT+"/"+U25->U25_LOJA+" "+POSICIONE("SA1",1,XFILIAL("SA1")+U25->U25_CLIENT+U25->U25_LOJA,"A1_NOME")+cEOL)+;
					iif(empty(U25->U25_GRPCLI),"","Grupo Cli: " +U25->U25_GRPCLI+" "+POSICIONE("ACY",1,XFILIAL("ACY")+U25->U25_GRPCLI,"ACY_DESCRI")+cEOL)+;
					iif(empty(U25->U25_FORPAG+U25->U25_CONDPG),"","Forma/Condição: "+U25->U25_FORPAG+"/"+U25->U25_CONDPG+" "+POSICIONE("U44",1,xFilial("U44")+U25->U25_FORPAG+U25->U25_CONDPG,"U44_DESCRI")+cEOL)+;
					iif(empty(U25->U25_ADMFIN),"","Adm. Financ.: "+U25->U25_ADMFIN+" "+POSICIONE('SAE',1,XFILIAL('SAE')+U25->U25_ADMFIN,'AE_DESC')+cEOL)+;
					iif(empty(U25->U25_EMITEN+U25->U25_LOJEMI),"","Emit. CH/Loja: "+U25->U25_EMITEN+"/"+U25->U25_LOJEMI+" "+POSICIONE("SA1",1,xFilial("SA1")+U25->U25_EMITEN+U25->U25_LOJEMI,"A1_NOME")+cEOL)
				cLog += "-> Mensagem: " + cMsgLog

				RecLock("U25",.F.)
					U25->U25_MSEXP  := ""
					U25->U25_HREXP  := ""
					U25->U25_OBS    := AllTrim(U25->U25_OBS) + CHR(13)+CHR(10) + "Encerramento Automático |TRET023L| (Data/Hora: "+DTOC(Date())+" "+Time()+". Usuário: "+iif(IsBlind(),"JOB",_cUser)+")"
					U25->U25_DTFIM  := Date()
					U25->U25_HRFIM  := Time()
					//U25->(DbDelete())
				U25->(MsUnlock())
				U_UREPLICA("U25", 1, U25->U25_FILIAL+U25->U25_REPLIC, "A")

			EndIf

		EndIf

		QRYU25->(DbSkip())
	EndDo

	If Select("QRYU25") > 0
		QRYU25->(DbCloseArea())
	EndIf

	cLog += cEOL
	cLog += ">> FIM - PROCESSAMENTO... " + cEOL
	cLog += ">> DATA: "+ DToC(Date()) +" - HORA: " + Time()

	//conout(cLog)

Return lOk

//--------------------------------------------------------------
/*/{Protheus.doc} fPrint
Description
Atualiza a Exibicao na tela

Cliente Diversos
@param xParam Parameter Description
@return xRet Return Description
@author TOTVS GOIAS
@since 14/12/2016
/*/
//--------------------------------------------------------------
Static Function fPrint(oSay,cMsg)
	oSay:cCaption := (cMsg)
	ProcessMessages()
Return()

/*/{Protheus.doc} TRET023J
Ajuste do cFilAnt na alteração de preço das filiais

@author pablo
@since 26/04/2019
@version 1.0
@return ${return}, ${return_description}

@type function
/*/
User Function TRET023J()

Local cCampo 	:= ReadVar()

Do Case
	// Esta troca de filial é realizada, pois na função U_URETPREC é utilizado xFilial puxando a filial logada.
	Case "U25_PRCVEN"$cCampo .or. "U25_DESPBA"$cCampo .or. "U25_PRODUT"$cCampo .or. "U25_DTINIC"$cCampo .or. "U25_HRINIC"$cCampo
		cFilAnt := oNwGetDad:aCols[oNwGetDad:nAt][GdFieldPos("U25_FILIAL", oNwGetDad:aHeader)]
End Case

Return .T.

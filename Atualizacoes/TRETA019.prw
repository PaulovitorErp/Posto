#INCLUDE "TOTVS.CH"
#INCLUDE "Protheus.ch"
#INCLUDE "topconn.ch"
#INCLUDE "TBICONN.CH"

/*/{Protheus.doc} TRETA019
Rotina de Importação de Extrato de Operadora Cartão POS

@author Danilo Brito
@since 19/08/2014
@version 1.0
@return Nil
@type function
/*/
User Function TRETA019

	//variáveis que serão usadas na rotina como um todo
	Private cCadastro := "Importação Extrato de Operadoras Cartão"
	Private aDadosFil := {}
	Private aHeaderFil:= {}
	Private aBandOper := {} //relacionamento bandeiras por operadoras {{oper,{{AdmFin,Bandeira},...}},...}
	Private cFilTaSE1 := ""

	// variavel para ordenação de grids
	Private __XVEZ 		:= "0"
	Private __ASC       := .T.

	Private cNFRecu := SuperGetMv("MV_XNFRECU",.F.,"XPROTH/XCOPIA/XSEFAZ/XXML") //Tipos de recuperação de NF

	TelaFiltro()

Return

//--------------------------------------------------------------
/*/{TRETA019.PRW} TelaFiltro
Description
Chama tela de parametros para importação.

@param xParam Parameter Description
@return xRet Return Description
@author Danilo Brito
@since 19/08/2014
/*/
//--------------------------------------------------------------
Static Function TelaFiltro()

	//variáveis para manipular Dlg
	Local bOk := {|| iif(DoValidFil(), TelaFatura(), ) }
	Local bCancel := {|| oDlgFil:End() }
	Local aButtons := {}
	Local oBtnOpen

	//Objetos da tela
	Static oDlgFil
	Private oMSNewGeFil
	Private aMSEmptyFil := {}
	Private oLayout
	Private oDesLay
	Private oArquivo
	Private oConsCab
	Private oDtEmis1
	Private oDtEmis2
	Private oImgOper
	Private oBandeira
	Private oTipCard

	//Campos da tela
	Private cLayout
	Private cDesLay
	Private cArquivo
	Private lConsCab
	Private dDtEmis1
	Private dDtEmis2
	Private cMaskFile
	Private cTpFile
	Private cBandeira
	Private cTipCard

	Private aComboTip := {"Ambos - CC/CD","CC - Cartão Crédito","CD - Cartão Débito"}

	FilLimpaCpos()

	oDlgFil := TDialog():New(0,0,540,700,cCadastro,,,,,,,,,.T.)

	TSay():New( 35,05,{|| "Esta rotina tem por objetivo importar extratos das operadoras de cartão, conforme parâmetros configurados nesta tela, e gerar fatura. " }, oDlgFil,,,,,,.T.,CLR_BLUE,,500,9 )
	TSay():New( 45,220,{|| iif(empty(cFilTaSE1),"","(os títulos de processamento estão filtrados)") }, oDlgFil,,,,,,.T.,CLR_RED,,200,9 )
	
	TGroup():Create(oDlgFil,50,2,145,350,' Adicionar arquivo/extrato da operadora ',,,.T.)

	TSay():New( 67,10,{|| "Layout Operad." }, oDlgFil,,,,,,.T.,CLR_BLACK,,50,9 )
	oLayout := TGet():New( 65, 55, {|u| iif( PCount()==0,cLayout,cLayout:= u) },oDlgFil,40,9,,{|| ValidU98() },,,,.F.,,.T.,,.F.,{|| .T.},.F.,.F.,/*bChange*/,.F.,.F.,"U98","U98_CODIGO",,,,.T.,.F.)
	oDesLay := TGet():New( 65, 95, {|u| iif( PCount()==0,cDesLay,cDesLay:= u) },oDlgFil,150,9,,/*bValid*/,,,,.F.,,.T.,,.F.,{|| .F.},.F.,.F.,/*bChange*/,.F.,.F.,,"U98_NOME",,,,.T.,.F.)

	TGroup():Create(oDlgFil,65,260,115,345,'',,,.T.)
	oImgOper := TBitmap():New( 070, 284, 037, 025,,"",.T.,oDlgFil,,,.F.,.T.,,"",.T.,,.T.,,.F. )
	oImgOper:lAutoSize := .F.

	TSay():New( 80,10,{|| "Arquivo" }, oDlgFil,,,,,,.T.,CLR_BLACK,,50,9 )
	oArquivo := TGet():New( 78, 55, {|u| iif( PCount()==0,cArquivo,cArquivo:= u) },oDlgFil,160,9,,/*bValid*/,,,,.F.,,.T.,,.F.,{|| .T.},.F.,.F.,/*bChange*/,.F.,.F.,,"cArquivo",,,,.T.,.F.)
	DEFINE SBUTTON oBtnOpen FROM 078, 218 TYPE 14 OF oDlgFil ENABLE ACTION DoSelFile()

	TSay():New( 93,10,{|| "Dt.Emissão De" }, oDlgFil,,,,,,.T.,CLR_BLACK,,50,9 )
	oDtEmis1 := TGet():New( 91, 55, {|u| iif( PCount()==0,dDtEmis1,dDtEmis1:= u) },oDlgFil,60,9,,/*bValid*/,,,,.F.,,.T.,,.F.,{|| .T.},.F.,.F.,/*bChange*/,.F.,.F.,,"E1_EMISSAO",,,,.T.,.F.)

	TSay():New( 93,125,{|| "Dt.Emissão Até" }, oDlgFil,,,,,,.T.,CLR_BLACK,,50,9 )
	oDtEmis2 := TGet():New( 91, 166, {|u| iif( PCount()==0,dDtEmis2,dDtEmis2:= u) },oDlgFil,60,9,,/*bValid*/,,,,.F.,,.T.,,.F.,{|| .T.},.F.,.F.,/*bChange*/,.F.,.F.,,"E1_EMISSAO",,,,.T.,.F.)

	TSay():New( 106,10,{|| "Bandeira" }, oDlgFil,,,,,,.T.,CLR_BLACK,,50,9 )
	oBandeira := TComboBox():New(104, 55, {|u| If(PCount()>0,cBandeira:=u,cBandeira)}, {""} , 160, 012, oDlgFil, Nil,{|| .T./*bChange*/ },/*bValid*/,,,.T.,,Nil,Nil,{|| .T. } )

	TSay():New( 119,10,{|| "Tipo Cartão" }, oDlgFil,,,,,,.T.,CLR_BLACK,,50,9 )
	oTipCard := TComboBox():New(117, 55, {|u| If(PCount()>0,cTipCard:=u,cTipCard)}, aComboTip , 80, 012, oDlgFil, Nil,{|| .T./*bChange*/ },/*bValid*/,,,.T.,,Nil,Nil,{|| .T. } )

	oConsCab := TCheckBox():New(131,10,'Considerar cabeçalho (primeira linha) do arquivo',{|u| iif( PCount()==0,lConsCab,lConsCab:= u) },oDlgFil,250,9,,,,,,,,.T.,,,)

	If ExistBlock("TR019AJU")
		TButton():New( 127, 218, "Ajusta Arq.", oDlgFil, {|| ExecBlock("TR019AJU",.F.,.F.,{cArquivo}) }, 37, 12,,,.F.,.T.,.F.,,.F.,,,.F. )
	endif

	TButton():New( 127, 215, "Fil. Títulos", oDlgFil, {|| DoFiltro() }, 40, 12,,,.F.,.T.,.F.,,.F.,,,.F. )
	TButton():New( 127, 260, "Adicionar", oDlgFil, {|| DoAddArq() }, 40, 12,,,.F.,.T.,.F.,,.F.,,,.F. )
	TButton():New( 127, 305, "Excluir", oDlgFil, {|| DoExcArq() }, 40, 12,,,.F.,.T.,.F.,,.F.,,,.F. )

	TGroup():Create(oDlgFil,148,2,265,350,' Arquivos selecionados ',,,.T.)

	oMSNewGeFil := fMSNewGeFil(oDlgFil)
	oMSNewGeFil:oBrowse:bHeaderClick := {|oBrw1,nCol| if(nCol > 0, U_UOrdGrid(@oMSNewGeFil, @nCol), )}
	aDadosFil := oMSNewGeFil:aCols //defino aDadosFil mesmo que aCols

	oDlgFil:bInit := {|| (EnchoiceBar(oDlgFil, bOk, bCancel,.F.,@aButtons,0,"SE1"), MudaBtnOk(oDlgFil,"Processar"))}
	oDlgFil:lCentered := .T.
	oDlgFil:Activate()

Return

//---------------------------------------------------------------
// muda nome do botão confirmar da enchoicebar
//---------------------------------------------------------------
Static Function MudaBtnOk(oObjDlg, cNewCap)
	Local nX := 0
	if oObjDlg:aControls <> Nil
		for nX := 1 to len(oObjDlg:aControls)
			if valtype(oObjDlg:aControls[nX])=="O"
				if "TBROWSEBUTTON" == Alltrim(Upper(oObjDlg:aControls[nX]:ClassName()))
					if oObjDlg:aControls[nX]:cCaption == OemToAnsi( "Confirmar" )
						oObjDlg:aControls[nX]:cCaption := OemToAnsi( cNewCap )
						oObjDlg:aControls[nX]:Refresh()
						exit
					endif
				endif
			endif
		next nX
	endif
return

//---------------------------------------------------------------
// cria grid de arquivos para processamento.
//---------------------------------------------------------------
Static Function fMSNewGeFil(oComp)

	Local aAlterFields := {}
	Local cTrue := "AllwaysTrue"

	Aadd(aHeaderFil,{ 'Layout'			,'LAYOUT'  		,'@!'	,TamSx3("U98_CODIGO")[1],0,'','€€€€€€€€€€€€€€','C','','','',''})
	aadd(aMSEmptyFil, space(TamSx3("U98_CODIGO")[1]))

	Aadd(aHeaderFil,{ 'Desc. Layout'	,'NOMELAY'		,'@!'	,TamSx3("U98_NOME")[1],0,'','€€€€€€€€€€€€€€','C','','','',''})
	aadd(aMSEmptyFil, space(TamSx3("U98_NOME")[1]))

	Aadd(aHeaderFil,{ 'Arquivo'			,'ARQUIVO'		,''		,300					,0,'','€€€€€€€€€€€€€€','C','','','',''})
	aadd(aMSEmptyFil, space(300))

	Aadd(aHeaderFil,{ 'Dt.Emissão De'	,'EMISSAODE'	,''		,TamSx3("E1_EMISSAO")[1],0,'','€€€€€€€€€€€€€€','D','','','',''})
	aadd(aMSEmptyFil, stod(""))

	Aadd(aHeaderFil,{ 'Dt.Emissão Até'	,'EMISSAOATE'	,''		,TamSx3("E1_EMISSAO")[1],0,'','€€€€€€€€€€€€€€','D','','','',''})
	aadd(aMSEmptyFil, stod(""))

	Aadd(aHeaderFil,{ 'Bandeira'		,'BANDEIRA'		,'@!'	,TamSx3("AE_COD")[1],0,'','€€€€€€€€€€€€€€','C','','','',''})
	aadd(aMSEmptyFil, space(TamSx3("AE_COD")[1]))

	Aadd(aHeaderFil,{ 'Desc. Bandeira'	,'NOMEBAND'		,'@!'	,TamSx3("AE_DESC")[1],0,'','€€€€€€€€€€€€€€','C','','','',''})
	aadd(aMSEmptyFil, space(TamSx3("AE_DESC")[1]))

	Aadd(aHeaderFil,{ 'Cabeçalho'		,'CABECALHO'	,'@BMP'	,2					 ,0,'','€€€€€€€€€€€€€€','C','','','',''})
	aadd(aMSEmptyFil, "LBNO")

	Aadd(aHeaderFil,{ 'T.Cartão'		,'TIPCARD'		,'@!'	,2 ,0,'','€€€€€€€€€€€€€€','C','','','',''})
	aadd(aMSEmptyFil, space(2))

	aadd(aMSEmptyFil, .F.) //deleted
	aAdd(aDadosFil, aClone(aMSEmptyFil))

Return MsNewGetDados():New( 157,05,260,347,,cTrue, cTrue,, aAlterFields,, 99, cTrue, "", cTrue, oComp, aHeaderFil, aDadosFil)

//---------------------------------------------------------------
// Limpa campos da tela de filtros.
//---------------------------------------------------------------
Static Function FilLimpaCpos()

	cLayout := Space(TamSx3("U98_CODIGO")[1])
	cDesLay := Space(TamSx3("U98_NOME")[1])
	cArquivo := space(300)
	lConsCab := .F.
	dDtEmis1 := stod("")
	dDtEmis2 := stod("")
	cMaskFile:= ""
	cTpFile  := ""
	cBandeira := Space(TamSx3("MDE_CODIGO")[1])
	cTipCard := "Ambos - CC/CD"

	if type("oImgOper")=="O"
		oImgOper:SetEmpty()
		oImgOper:Refresh()
	endif

Return

//---------------------------------------------------------------
// Faz refresh dos campos da tela de filtros.
//---------------------------------------------------------------
Static Function FilRefreshCpos()

	oLayout:Refresh()
	oDesLay:Refresh()
	oArquivo:Refresh()
	oConsCab:Refresh()
	oDtEmis1:Refresh()
	oDtEmis2:Refresh()
	oBandeira:Refresh()
	oMSNewGeFil:Refresh()

Return

//---------------------------------------------------------------
// Abre tela de seleção do arquivo a ser importado.
//---------------------------------------------------------------
Static Function DoSelFile()

	if empty(cMaskFile)
		MsgInfo("Selecione uma operadora!","Atençao")
	else
		cArquivo := cGetFile( cMaskFile, "Selecione o arquivo.", 1, iif(empty(cArquivo),'C:\',cArquivo), .F., nOR( GETF_LOCALHARD, GETF_LOCALFLOPPY ),.T., .T. )
		if empty(cArquivo)
			cArquivo := space(300)
		endif
	endif

	FilRefreshCpos()

Return

//---------------------------------------------------------------
// Adiciona dados do arquivo no acols da tela de filtro
//---------------------------------------------------------------
Static Function DoAddArq()

	Local nPosX := 0

	if empty(cLayout)
		MsgInfo("Preencha o campo Layout Operadora.","Atençao")
		return
	endif

	if empty(cArquivo)
		MsgInfo("Selecione um arquivo.","Atençao")
		return
	else
		if UPPER(right(alltrim(cArquivo),len(cTpFile))) != cTpFile
			MsgInfo("Selecione um arquivo do tipo *."+cTpFile,"Atençao")
			return
		endif
		if !File(alltrim(cArquivo))
			MsgInfo("Arquivo não pode ser localizado.","Atençao")
			return
		endif
	endif

	if empty(dtos(dDtEmis1)) .or. empty(dtos(dDtEmis2))
		MsgInfo("Preencha o intervalo de datas de emissão do título.","Atençao")
		return
	else
		if dDtEmis1 > dDtEmis2
			MsgInfo("Datas de emissão não preenchidas corretamente.","Atençao")
			return
		endif
	endif

	nPosX := aScan(aDadosFil, {|x| x[1]+x[3]==cLayout+cArquivo })
	if nPosX > 0
		MsgInfo("Este arquivo já foi adicionado para esta operadora.","Atençao")
		return
    endif

	if empty(aDadosFil[1][1]) //limpa aDadosFil
		aSize(aDadosFil,0)
	endif

	aAdd(aDadosFil, {cLayout, cDesLay, cArquivo, dDtEmis1, dDtEmis2, cBandeira, SubStr(oBandeira:aItems[oBandeira:nAt],5), iif(lConsCab,"LBOK","LBNO"), UPPER(SubStr(oTipCard:aItems[oTipCard:nAt],1,2)), .F./*deleted*/})

	FilLimpaCpos()
	FilRefreshCpos()

Return

//---------------------------------------------------------------
// Exclui linha do arquivo selecionado no acols da tela de filtro
//---------------------------------------------------------------
Static Function DoExcArq()

	if empty(aDadosFil[1][1])
		return
	endif

	aDel(aDadosFil, oMSNewGeFil:nAt)
	ASize(aDadosFil, len(aDadosFil)-1)

	if len(aDadosFil) == 0
		aAdd(aDadosFil, aClone(aMSEmptyFil))
	endif

Return

//---------------------------------------------------------------
// Cria filtro da tabela SE1
//---------------------------------------------------------------
Static Function DoFiltro()
	Local aArea := GetArea()
	cFilTaSE1 := BuildExpr("SE1",,cFilTaSE1,.T.)
	RestArea(aArea)
Return

//---------------------------------------------------------------
// Faz validação do campo Operadora e faz gatilhos necessários
//---------------------------------------------------------------
Static Function ValidU98()

	Local lRet := .T.
	Local lLimpa := .T.
	Local aMyBandei := {''}

	if !empty(cLayout)
		DbSelectArea("U98")
		U98->(DbSetOrder(2))
		if !U98->(DbSeek(xFilial("U98")+cLayout))
			Help('',1,'LAYOUT',,"Layout não localizado. Configure um layout no cadastro 'Layout X Operadoras'",1,0)
		 	lRet := .F.
		endif

		//faz gatilhos
		if lRet
			lLimpa := .F.
			cDesLay := U98->U98_NOME

			//set imagem
			oImgOper:Load(NIL, "\dirdoc\img\img_operad_"+Alltrim(xFilial("MDE"))+Alltrim(Posicione("MDE",1,xFilial("MDE")+U98->U98_OPERAD,"MDE_CODSIT"))+".png" )
			oImgOper:lStretch 	:= .T.
			oImgOper:Refresh()

			//tipo de arquivo
			if U98->U98_TIPARQ == "1" //1=TXT
				cMaskFile := "Arquivo txt (*.txt) |*.TXT | "
				cTpFile := "TXT"
			elseif U98->U98_TIPARQ == "2" //2=CSV
				cMaskFile := "Arquivos csv (*.csv) |*.CSV | "
				cTpFile := "CSV"
			elseif U98->U98_TIPARQ == "3" //3=XLS
				cMaskFile := "Arquivos xls (*.xls) |*.XLS | "
				cTpFile := "XLS"
			elseif U98->U98_TIPARQ == "4" //4=XLSX
				cMaskFile := "Arquivos xlsx (*.xlsx) |*.XLSX | "
				cTpFile := "XLSX"
			endif

			//buscando bandeiras da operadora, e montando combobox bandeira
			If Select("QRYSAE") > 0
				QRYSAE->(DbCloseArea())
			Endif
			cQry := " SELECT DISTINCT MDE_CODIGO, MDE_DESC "
			cQry += " FROM "+RetSqlName("MDE")+" MDE "
			cQry += " INNER JOIN "+RetSqlName("SAE")+" SAE "
			cQry += " ON SAE.D_E_L_E_T_ <> '*' "
			cQry += " 	AND AE_FILIAL = '"+xFilial("SAE")+"' "
			cQry += " 	AND AE_ADMCART = MDE_CODIGO "
			cQry += " WHERE MDE.D_E_L_E_T_ <> '*' "
			cQry += " 	AND MDE_FILIAL = '"+xFilial("MDE")+"' "
			cQry += " 	AND AE_REDEAUT = '"+U98->U98_OPERAD+"' "
			cQry += " ORDER BY MDE_CODIGO "

			cQry := ChangeQuery(cQry)
			TcQuery cQry NEW Alias "QRYSAE"
			while QRYSAE->(!Eof())
				aadd(aMyBandei, QRYSAE->MDE_CODIGO +"="+QRYSAE->MDE_DESC )
				QRYSAE->(DbSkip())
			enddo
			QRYSAE->(DbCloseArea())

			oBandeira:SetItems(aMyBandei)

		endif
	endif

	if lLimpa
		cMaskFile := ""
		cTpFile := ""
		cDesLay := ""
		cArquivo := space(300)
		oImgOper:SetEmpty()
		oImgOper:Refresh()
		oBandeira:SetItems(aMyBandei)
	endif

	FilRefreshCpos()

Return lRet

//---------------------------------------------------------------
// Faz validação dos campos da tela de filtros.
//---------------------------------------------------------------
Static Function DoValidFil()

	Local lRet := .T.
	Local cQry := ""
	Local nX
	Local cOpeX := ""
	Local nPosX := 0

	if lRet .AND. empty(aDadosFil[1][1])
		MsgInfo("Selecione pelo menos um arquivo para processamento.","Atençao")
		lRet := .F.
	endif

	if lRet

		//buscando operadoras
		DbSelectArea("U98")
		U98->(DbSetOrder(2))
		for nX:=1 to len(aDadosFil)
			U98->(DbSeek(xFilial("U98")+aDadosFil[nX][1]))
			cOpeX += "'" + U98->U98_OPERAD + "'"
			if nX != len(aDadosFil)
				cOpeX += ","
			endif
		next nX

		//buscando bandeiras da operadora, e montando array aBandOper
		If Select("QRYSAE") > 0
			QRYSAE->(DbCloseArea())
		Endif
		cQry := " SELECT AE_COD, AE_ADMCART, AE_REDEAUT, AE_TIPO "
		cQry += " FROM "+RetSqlName("SAE")+" SAE "
		cQry += " WHERE SAE.D_E_L_E_T_ <> '*' "
		cQry += " 	AND AE_FILIAL = '"+xFilial("SAE")+"' "
		cQry += " 	AND AE_REDEAUT IN ("+cOpeX+") "
		cQry += " ORDER BY AE_REDEAUT "

		cQry := ChangeQuery(cQry)
		TcQuery cQry NEW Alias "QRYSAE"
		if QRYSAE->(!Eof())
			cOpeX := "" //QRYSAE->AE_REDEAUT
			while QRYSAE->(!Eof())
				if QRYSAE->AE_REDEAUT != cOpeX
					aadd(aBandOper, {QRYSAE->AE_REDEAUT,{}} )
				endif

				cOpeX := QRYSAE->AE_REDEAUT

				nPosX := aScan(aBandOper, {|x| x[1]==QRYSAE->AE_REDEAUT })
				aadd(aBandOper[nPosX][2], {QRYSAE->AE_COD,QRYSAE->AE_ADMCART, Alltrim(QRYSAE->AE_TIPO)} )

				QRYSAE->(DbSkip())
			enddo
		endif

		//validando operadoras se tem bandeiras vinculadas (SAE)
		for nX:=1 to len(aDadosFil)
			U98->(DbSeek(xFilial("U98")+aDadosFil[nX][1]))
			nPosX := aScan(aBandOper, {|x| x[1] == U98->U98_OPERAD })
			if nPosX == 0
				MsgInfo("Não há bandeiras vinculadas a operadora do layout "+Alltrim(aDadosFil[nX][2])+". Verifique cadastro de Adm. Financeira.","Atençao")
				lRet := .F.
				exit
			endif
		next nX
	endif

Return lRet


//*********************************************************************************
// DAQUI PARA BAIXO SÃO FUNÇÔES PARA TELA DE FATURA
//*********************************************************************************

//--------------------------------------------------------------
/*/{TRETA019.PRW} TelaFatura
Description
Chama tela geral da rotina.

@param xParam Parameter Description
@return xRet Return Description
@author Danilo Brito
@since 19/08/2014
/*/
//--------------------------------------------------------------
Static Function TelaFatura()

    Local nX, nY
    Local nPosLay := aScan(aHeaderFil,{|x| AllTrim(x[2])=="LAYOUT"})
	Local nPosArq := aScan(aHeaderFil,{|x| AllTrim(x[2])=="ARQUIVO"})
	Local nPosDt1 := aScan(aHeaderFil,{|x| AllTrim(x[2])=="EMISSAODE"})
	Local nPosDt2 := aScan(aHeaderFil,{|x| AllTrim(x[2])=="EMISSAOATE"})
	Local nPosBan := aScan(aHeaderFil,{|x| AllTrim(x[2])=="BANDEIRA"})
	Local nPosNBa := aScan(aHeaderFil,{|x| AllTrim(x[2])=="NOMEBAND"})
	Local nPosCab := aScan(aHeaderFil,{|x| AllTrim(x[2])=="CABECALHO"})
	Local nPosTCa := aScan(aHeaderFil,{|x| AllTrim(x[2])=="TIPCARD"})
	Local nPosX := 0

	//enchoicebar
	Local bOk := {|| iif(aTFolder[1][oTFolder:nOption]=="XXX",MsgInfo("Ação não permitida. Selecione a aba da operadora.","Atençao"), MsAguarde({|| aTFolder[3][oTFolder:nOption]:DoGeraFatura() },"Aguarde...","Processando Fatura...") ) }
	Local bCancel := {|| oDlg062:End() }
	Local aButtons := {}

	//variáveis da tela
	Local aCoors := FWGetDialogSize(oMainWnd)  
	Local oLayer := FWLayer():new()
	Local oPnlTelaInc, oPCabInc, oPGrInc

	Local aFiles := {}
	Local _cTipCard := ""

	Private oDlg062
	Private oTFolder
	Private aTFolder := {{},{},{}} //{{operadora},{tiulo aba},{objeto classe aba}}
	Private aLegenda := {{'BR_VERDE'	,"Título em Aberto"},;
					 	{'BR_VERMELHO'	,"Título Baixado"  },;
						{'BR_AMARELO'	,"Origem NF Recuperada " }}

	//objetos aba inconsistência
	Private oComboLay
	Private aComboLay := {}
	Private cComboLay := ""
	Private cLayAtivo := ""

	//Quantidade e nomes das Abas, uma pra cada layout
	DbSelectArea("U98")
	U98->(DbSetOrder(2)) //Layout + Operadora
	for nX:=1 to len(aDadosFil)
		U98->(DbSeek(xFilial("U98")+aDadosFil[nX][nPosLay]))
		if aScan(aTFolder[1], U98->U98_CODIGO ) == 0

			aadd(aTFolder[1], U98->U98_CODIGO )
			aadd(aTFolder[2], Capital(U98->U98_NOME) )
			aadd(aComboLay ,U98->U98_CODIGO+"="+Capital(U98->U98_NOME))
			if nX == 1
				cComboLay := U98->U98_CODIGO
				cLayAtivo := cComboLay
			endif

		endif
	next nX
	aadd(aTFolder[1],"XXX") //Aba Adicional, Inconsistências
	aadd(aTFolder[2],"Inconsistências") //Aba Adicional, Inconsistências

	//começa montagem do DLG
	DEFINE MSDIALOG oDlg062 TITLE cCadastro FROM aCoors[1], aCoors[2] To aCoors[3], aCoors[4] PIXEL OF GetWndDefault() STYLE nOr(WS_VISIBLE, WS_POPUP)

	//Cria objeto das abas
	oTFolder := TFolder():New( 00, 00, aTFolder[2],,oDlg062,,,,.T.,,100,100 )
	oTFolder:Align := CONTROL_ALIGN_ALLCLIENT

	oPnlTelaInc := tPanel():New(00,00,,oTFolder:aDialogs[len(aTFolder[1])],,,,,,100,100)
	oPnlTelaInc:Align := CONTROL_ALIGN_ALLCLIENT

	oLayer:init(oPnlTelaInc,.F.)
	oLayer:addLine('CABINC', 008, .T.)
	oLayer:addLine('GRDINC', 092, .F.)
	oPCabInc := oLayer:GetLinePanel('CABINC')
	oPGrInc := oLayer:GetLinePanel('GRDINC')

	//cria objetos das abas de layouts
	for nX:= 1 to len(aTFolder[1])-1 //codigos dos layouts

		DbSelectArea("U98")
		U98->(DbSetOrder(2)) //Layout + Operadora
		U98->(DbSeek(xFilial("U98")+aTFolder[1][nX]))

		aFiles := {}

		//add arquivos no objeto do layout
		for nY := 1 to len(aDadosFil)
			if aDadosFil[nY][1] == aTFolder[1][nX] //se arquivo for deste layout
				aadd(aFiles, {;
					aDadosFil[nY][nPosArq], ; //[1] - arquivo extrato
					aDadosFil[nY][nPosDt1], ; //[2] - data emissao 1
					aDadosFil[nY][nPosDt2], ; //[3] - data emissao 2
					aDadosFil[nY][nPosCab]=="LBOK", ; //[4] - considera cabeçalho
					aDadosFil[nY][nPosBan], ; //[5] - bandeira
					aDadosFil[nY][nPosNBa], ; //[6] - nome da Bandeira
					aDadosFil[nY][nPosTCa] 	}) //[7] - tipo cartão
				
				_cTipCard := Alltrim(aDadosFil[nY][nPosTCa])
			endif
		next nY

		//Cria instâncias da classe UT019ABA, uma pra cada layout
		//UT019ABA():New(_cLayout, _aFiles, _oDlgAba, _oDlgInc )
		oAbaTemp := UT019ABA():New( aTFolder[1][nX], aClone(aFiles), oTFolder:aDialogs[nX], oPGrInc)
		aadd(aTFolder[3], oAbaTemp )

		//Adicionando bandeiras da operadora na tela
		nPosX := aScan(aBandOper, {|x| x[1]== U98->U98_OPERAD })
		for nY:=1 to len(aBandOper[nPosX][2])
			//DoAddBand(cAdmFin, cCodBand)
			if !empty(_cTipCard) .AND. _cTipCard == "CC" .AND. aBandOper[nPosX][2][nY][3] != "CC"
				LOOP 
			endif
			if !empty(_cTipCard) .AND. _cTipCard == "CD" .AND. aBandOper[nPosX][2][nY][3] != "CD"
				LOOP 
			endif

			aTFolder[3][nX]:DoAddBand(aBandOper[nPosX][2][nY][1], aBandOper[nPosX][2][nY][2])
		next nY

	next nX
	aadd(aTFolder[3], Nil) //Aba Adicional, Inconsistências

	//Campos e Botões da aba inconsistências
	TSay():New( 007, 005, {|| "Mostrar Inconsistências da Layout:" }, oPCabInc,,,,,,.T.,CLR_BLACK,,110,9 )
	oComboLay := TComboBox():New(005, 110, {|u| iif( PCount()==0,cComboLay,cComboLay:= u) },aComboLay, 100, 12, oPCabInc,,{|| DoSelOper() }, /*bValid*/,,,.T.,,,,{|| .T.},,,,"cComboLay")
	TSay():New( 013, 000,{|| Repl("_",oPCabInc:nWidth/2) }, oPCabInc,,,,,,.T.,CLR_HGRAY,,oPCabInc:nWidth/2,9 )

	TButton():New( 005, (oPCabInc:nWidth/2)-215, "Excluir Item", oPCabInc, {|| aTFolder[3][aScan(aTFolder[1], {|x| x == cComboLay })]:DoExcluiItExt() }, 50, 12,,,.F.,.T.,.F.,,.F.,,,.F. )
	TButton():New( 005, (oPCabInc:nWidth/2)-160, "Relacionar", oPCabInc, {|| aTFolder[3][aScan(aTFolder[1], {|x| x == cComboLay })]:DoRelaciona() }, 45, 12,,,.F.,.T.,.F.,,.F.,,,.F. )
	TButton():New( 005, (oPCabInc:nWidth/2)-110, "Alterar Título", oPCabInc, {|| aTFolder[3][aScan(aTFolder[1], {|x| x == cComboLay })]:DoAlteraTit(2) }, 50, 12,,,.F.,.T.,.F.,,.F.,,,.F. )
	TButton():New( 005, (oPCabInc:nWidth/2)-055, "Buscar Título", oPCabInc, {|| aTFolder[3][aScan(aTFolder[1], {|x| x == cComboLay })]:DoBuscaRapida() }, 50, 12,,,.F.,.T.,.F.,,.F.,,,.F. )

	aTFolder[3][1]:ShowPnlInc() //mostra painel inconsistencias da primeira operadora

	aAdd(aButtons,{"LEGENDA" ,{|| BrwLegenda("Legenda","Situação Título",aLegenda) },"Legenda","Legenda"} )
	aAdd(aButtons,{"TITULO" ,{|| DoAltSacado(oTFolder:nOption, aTFolder[3][aScan(aTFolder[1], {|x| x == cComboLay })]) },"Alterar Sacado","Alterar Sacado"} )

	oDlg062:bInit := {|| (EnchoiceBar(oDlg062, bOk, bCancel,.F.,@aButtons,0,"SE1"), ;
							MudaBtnOk(oDlg062,"Gerar Faturas"), ;
							MsAguarde({|| iif(DoCarregaDados(),, oDlg062:End()) },"Aguarde...","Processando importação....",.T.);
							)}

	oDlg062:lCentered := .T.
	oDlg062:Activate()

Return

//---------------------------------------------------------------
// Funçao do Change do combo de operadora (aba inconsitencias)
// Faz mudança de operadora a mostrar na aba.
//---------------------------------------------------------------
Static Function DoSelOper()

	Local nPosOld := aScan(aTFolder[1], {|x| x == cLayAtivo })
	Local nPosNew := aScan(aTFolder[1], {|x| x == cComboLay })

	if cLayAtivo != cComboLay

		aTFolder[3][nPosOld]:HidePnlInc() //oculta painel anterior
		aTFolder[3][nPosNew]:ShowPnlInc() //mostra painel novo

		cLayAtivo := cComboLay
	endif

Return

//---------------------------------------------------------------
// faz a estrutura do MsNewGetDados Extrato,
//---------------------------------------------------------------
Static Function GoToIncons(cLayout)

	if cComboLay <> cLayout
		cComboLay := cLayout
		oComboLay:Refresh()
		DoSelOper()
	endif
	oTFolder:SetOption(len(aTFolder[1]))

Return

//---------------------------------------------------------------
// Faz processamento de leitura do arquivo, e comparação com títulos.
//---------------------------------------------------------------
Static Function DoCarregaDados()

	Local nX := 0
	Local lRet := .T.

	ProcRegua(len(aTFolder[1]))

	for nX := 1 to len(aTFolder[1])-1
		IncProc("Layout "+ aTFolder[2][nX])

		if !aTFolder[3][nX]:DoImpExtrato() //faz leitura dos arquivos deste layout
			lRet := .F.
			EXIT
		endif

	next nX

Return lRet


//*********************************************************************************
// DAQUI PARA BAIXO É A IMPLEMENTAÇÃO DA CLASSE QUE MONTA AS ABAS DAS OPERADORAS
//*********************************************************************************

/*
_____________________________________________________________________________
¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦
¦¦+-----------------------------------------------------------------------+¦¦
¦¦¦Programa  ¦ UT019ABA	   ¦ Autor ¦ Totvs            ¦ Data ¦ 05/11/2013 ¦¦¦
¦¦+----------+------------------------------------------------------------¦¦¦
¦¦¦Descriçào ¦ Classe que monta aba da operadora.				 		  ¦¦¦
¦¦¦          ¦                                                            ¦¦¦
¦¦+----------+------------------------------------------------------------¦¦¦
¦¦¦Uso       ¦ TOTVS - GO		                                          ¦¦¦
¦¦+-----------------------------------------------------------------------+¦¦
¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦
¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
*/
CLASS UT019ABA

    //campos construtores
    DATA cCodLay	//codigo do layout
    DATA cNmLayout	//nome do layout
    DATA cOperad	//código da operadora
    DATA cNmOper	//nome da operadora
    DATA oDlgAba 	//objeto onde será construida a tela
	DATA oDlgInc	//objeto onde será construido painel inconsistencias

	//variávies de processamento
	DATA aFiles		//array com os dados dos arquivos para busca
	DATA aTitulos	//array com os dados dos títulos encontrados {recno,...}
	DATA aExtrato	//array com os dados do extrato {{{campo, valor, lCompara},...},...}
	DATA cCpVlrEx	//posição da coluna valor do extrato
	DATA cCpVlrDiv  //campo SE1 que será comparado com valor do extrato
	DATA nXMrgVal	//define o margem de valor para comparacao

	//variáveis grid
	DATA oGetDados  //NewGetDados da aba
	DATA aHeader	//aHeader do NewGetDados
	DATA aDados		//aCols do NewGetDados
	DATA aEmptyLin	//linha em branco do acols do NewGetDados
	DATA nMarca  	//Variavel de controle da função DoMarcaTodos
	DATA xVez		//Variavel de controle da função DoMarcaTodos

	//variaveis dados fatura
	DATA nVlrDesc	//valor Descontos
	DATA nVlrAcre	//valor Acrescimos
	DATA nVlrAlug	//valor Aluguel POS
	DATA nVlrTaxas	//valor das taxas
	DATA nVlrOutr	//valor Outras Despesas
	DATA nVlrTotal  //valor total fatura
	DATA nVlrBruto	//vlr bruto titulos
	DATA cObserv	//Observações
	DATA dVencFat	//Data Vencimento da fatura
	DATA aValAcess	//Valores acessorios
	DATA oGetVlAces //GetDados

	//variáveis total por bandeiras
	DATA oScrBand	//Scroll panel das bandeiras
	DATA aBandeiras //Vetor das bandeiras(todas) da operadora {{cCodBand, oImagem, cImagem, oTotCC, nTotCC, oTotCD, nTotCD, oTotGeral, nTotGeral},...}
	DATA aBandFil	//Vetor bandeiras dos filtros
	DATA aAdmFin	//Vetor com códigos das Adm. Financeiras da operadora
	DATA aAdmBand	//Vetor com códigos das Adm. Financeiras da operadora+Bandeira

	//variaveis totalizadores
	DATA aObjTotaliz	//vetor com objetos totalizadores {}
	DATA nQtdGer    	//Qtd Registros Geral
	DATA nQtdInc		//Qtd Registros Inconsistentes
	DATA nQtdSel		//Qtd Registros Selecionados
	DATA nQtdArq		//Qtd Registros Arquivo Não Vinculados
	DATA nVlTotE1Ger 	//Valor Total SE1 Registros Geral
	DATA nVlTotE1Inc	//Valor Total SE1 Registros Inconsistentes
	DATA nVlTotE1Sel	//Valor Total SE1 Registros Selecionados
	DATA nVlTotBE1Ger 	//Valor Total BRUTO SE1 Registros Geral
	DATA nVlTotBE1Inc	//Valor Total BRUTO SE1 Registros Inconsistentes
	DATA nVlTotBE1Sel	//Valor Total BRUTO SE1 Registros Selecionados
	DATA nVlTotExGer 	//Valor Total Extrato Registros Geral
	DATA nVlTotExInc	//Valor Total Extrato Registros Inconsistentes
	DATA nVlTotExSel	//Valor Total Extrato Registros Selecionados

	//variaveis painel inconsistencias
	DATA oPnlInc		//painel inconsistências
	DATA oMSNewGeE1		//NewGetDados titulos Inconsistencia
	DATA aDadosSE1 		//aCols do NewGetDados titulos Inconsistencia
	DATA aHeaderSE1 	//aHeader do NewGetDados titulos Inconsistencia
	DATA aMSEmptyE1 	//linha em branco do acols do NewGetDados titulos Inconsistencia
	DATA oMSNewGeEx		//NewGetDados extrato Inconsistencia
	DATA aDadosExt 		//aCols do NewGetDados extrato Inconsistencia
	DATA aHeaderExt 	//aHeader do NewGetDados extrato Inconsistencia
	DATA aMSEmptyEx 	//linha em branco do acols do NewGetDados extrato Inconsistencia

	DATA cCodCli
	DATA cLojCli

	//variaveis para busca de titulos
	DATA cFilSE1
	DATA lAllBand
	DATA oMsNewSE1
	DATA aBuscaSE1

	//Método Construtor da Classe
	METHOD New(_cLayout, _aFiles, _oDlgAba, _oDlgInc ) CONSTRUCTOR

	//Definição dos Metodos da Classe
	METHOD DoTela()				//Faz construção da aba da operadora
	METHOD DoNewGetPri() 		//Faz montagem do NewGetDados da aba operadora
	METHOD DoAddBand(cAdmFin, cCodBand)  //Adiciona bandeira no painel bandeiras
	METHOD DoAddPnlTot(oPnl)	//Constroi campos totalizadores no painel
	METHOD DoMarcar(oGrid)		//Controle de marcação do NewGetDados da aba operadora
	METHOD DoMarcaTodos(oGrid, nPosIf, xComp, lDesmarca) //Controle de marcação do NewGetDados da aba operadora
	METHOD DoPnlInc()			//Faz construção do painel de Inconsistencias
	METHOD ShowPnlInc()			//Mostra painel de Inconsistencias
	METHOD HidePnlInc()			//Oculta painel de Inconsistencias
	METHOD DoNewGetSE1()		//Faz montagem do NewGetDados Titulos Inconsistencia
	METHOD DoNewGetExt()		//Faz montagem do NewGetDados Extrato Inconsistencia
	METHOD DoDesvinc()			//Desvincula o item posicionado no Grid Principal
	METHOD DoRelaciona(nRecE1,nRecEx) //Faz vínculo entre o itens posicionados inconsistencia
	METHOD DoAddTitInc(nRecE1)	//Adiciona item no grid de titulo inconsitencias
	METHOD DoAddExtInc(nRecEx)	//Adiciona item extrato no grid inconsitencias
	METHOD DoAlteraTit(nTipo)	//Chama tela de alteração do título (nTipo: 1=Grid Principal, 2=Grid Incons.)
	METHOD DoBuscaRapida()   	//Chama tela de busca rapida de titulo, e relaciona ao item do extrato
	METHOD DoExcluiItExt()		//Exclui um item do extrato
	METHOD DoGeraFatura()		//Gera fatura dos titulos selecionados
	METHOD DoQryTitulos()		//Faz busca dos títulos a receber que serão comparados ao arquivo de importação
	METHOD DoImpExtrato()		//faz importação do extrato da operadora, verifica tipo
	METHOD DoImpTXT()			//faz imprtação do arquivo TXT
	METHOD DoImpCSV()			//faz imprtação do arquivo CSV
	METHOD DoImpXLS()			//faz imprtação do arquivo XLS
	METHOD DoVerSacado()		//faz comparação do sacado antes do processamento dos arquivos
	METHOD DoComparaArq()		//faz comparação entre dados do extrato e titulos
	METHOD DoAtuTotal()			//faz atualização dos totalizadores
	METHOD DoAtuLinSE1(nRecE1, nRecEx, nAt) //atualiza linha recarregando dados da SE1
	METHOD DoMsGetSE1()
	METHOD DoBuscaSE1()
	METHOD PrBuscaSE1()
	METHOD DoTelaAuxFat(cNomeBand)
	METHOD ValidFatu()
	METHOD AtTotAux()
	METHOD DoNewGetVlA(oPnl)
	METHOD AjuVlrDiv()
	METHOD DoAjuVlrDiv()

ENDCLASS

//---------------------------------------------------------------
// Método Construtor da Classe. Passar objeto da aba.
//---------------------------------------------------------------
METHOD New(_cLayout, _aFiles, _oDlgAba, _oDlgInc ) CLASS UT019ABA

	if _oDlgAba <> Nil .AND. valtype(_oDlgAba) <> "O"
		Alert("Parâmetro incorreto para Classe UT019ABA")
		return Nil
	endif

	::nXMrgVal := 0

	//campos construtores
	DbSelectArea("U98")
	U98->(DbSetOrder(2)) //codigo + operadora
	if U98->(DbSeek(xFilial("U98")+_cLayout ))
		::cCodLay	:= U98->U98_CODIGO
		::cNmLayout	:= U98->U98_NOME
		::cOperad	:= U98->U98_OPERAD
		if U98->(FieldPos("U98_MRGVAL")) > 0
			::nXMrgVal	:= U98->U98_MRGVAL
		endif

		if ::nXMrgVal = 0
			::nXMrgVal	:= SuperGetMv("MV_XMRGVAL",,0) // Gianluka Moraes | 07-01-17 : Parametro com margem de tolerancia na busca dos titulos.
			if valtype(::nXMrgVal) <> "N"
				::nXMrgVal := val(::nXMrgVal)
			endif
		endif

		DbSelectArea("MDE")
		MDE->(DbSetOrder(1))
		MDE->(DbSeek(xFilial("MDE")+::cOperad))
		::cNmOper	:= MDE->MDE_DESC

		::aFiles	:= _aFiles //array dos arquivos {{_cArquivo, _dDtEmis1, _dDtEmis2, _lConsCab, _cBandeira, _cNmBand, _cTipCard}...}

		::oDlgAba	:= _oDlgAba
		::oDlgInc	:= _oDlgInc
	else
		Alert("Layout nao localizado!")
		return Nil
	endif

	//variávies de processamento
	::aTitulos	:= {}
	::aExtrato	:= {}
	::cCpVlrEx  := ""
	::cCpVlrDiv := "E1_VALOR"

	//variáveis grid
	::aHeader := {}
	::aDados := {}
	::aEmptyLin := {}
	::nMarca  	:= 0
	::xVez	 	:= "0"

	//variaveis dados fatura
	::nVlrDesc := 0
	::nVlrAcre := 0
	::nVlrAlug := 0
	::nVlrTaxas := 0
	::nVlrOutr := 0
	::aValAcess := {}

	::nVlrTotal := 0
	::nVlrBruto := 0
	::cObserv  := space(TamSx3("E1_HIST")[1])
	::cCodCli  := space(TamSx3("A1_COD")[1])
	::cLojCli  := space(TamSx3("A1_LOJA")[1])
	::dVencFat := STOD("")

	//variáveis total por bandeiras
	::aBandeiras := {}
	::aBandFil := {}
	::aAdmFin := {}
	::aAdmBand	:= {}

	//variaveis totalizadores
	::aObjTotaliz := {}
	::nQtdGer	:= 0
	::nQtdInc	:= 0
	::nQtdArq	:= 0
	::nQtdSel	:= 0
	::nVlTotE1Ger := 0
	::nVlTotE1Inc := 0
	::nVlTotE1Sel := 0
	::nVlTotBE1Ger := 0
	::nVlTotBE1Inc := 0
	::nVlTotBE1Sel := 0
	::nVlTotExGer := 0
	::nVlTotExInc := 0
	::nVlTotExSel := 0

	//variaveis painel inconsistencias
	::aDadosSE1 := {}
	::aHeaderSE1 := {}
	::aMSEmptyE1 := {}
	::aDadosExt := {}
	::aHeaderExt := {}
	::aMSEmptyEx := {}

	//variaveis para busca de titulos
	::cFilSE1 := ""
	::lAllBand := .F.
	::aBuscaSE1 := {}

	//Processamento Inicial
	::DoTela() //faz montagem da tela
	::DoPnlInc() //faz montagem do painel inconsistencias
	::HidePnlInc() //oculta painel inconsistencias

Return Self

//---------------------------------------------------------------
// Método para montar tela
//---------------------------------------------------------------
METHOD DoTela() CLASS UT019ABA

	Local oPnlTela //painel Dados Fatura
	Local nX
	Local oLayer        := FWLayer():new()
	Local oPCabTit,oPGrTit,oPTotBan,oPTotGer, oGrp1
	Local oImgOperad 

	oPnlTela := tPanel():New(00,00,,::oDlgAba,,,,,,100,100)
	oPnlTela:Align := CONTROL_ALIGN_ALLCLIENT

	oLayer:init(oPnlTela,.F.)
	oLayer:addLine('CABTIT', 008, .F.)
	oLayer:addLine('GRDTIT', 044, .F.)
	oLayer:addLine('SPC1', 001, .F.)
	oLayer:addLine('TOTBAN', 022, .F.)
	oLayer:addLine('SPC2', 001, .F.)
	oLayer:addLine('TOTGER', 014, .F.)
	oPCabTit := oLayer:GetLinePanel('CABTIT')
	oPGrTit := oLayer:GetLinePanel('GRDTIT')
	oPTotBan := oLayer:GetLinePanel('TOTBAN')
	oPTotGer := oLayer:GetLinePanel('TOTGER')

	::lAllBand := .F.
	for nX := 1 to len(::aFiles)
		if empty(::aFiles[nX][5]) //se um dos arquivos nao colocou bandeira
			::lAllBand := .T.
		else
			if aScan(::aBandFil, ::aFiles[nX][5]) == 0
				aadd(::aBandFil, ::aFiles[nX][5])
			endif
		endif
	next nX
	
	oImgOperad := TBitmap():New( 002, 002, 027, 018,,"\dirdoc\img\img_operad_"+Alltrim(xFilial("MDE"))+Posicione("MDE",1,xFilial("MDE")+::cOperad,"MDE_CODSIT")+".png",.T.,oPCabTit,,,.F.,.T.,,"",.T.,,.T.,,.F. )
	oImgOperad:lAutoSize := .F.
	oImgOperad:lStretch 	:= .T.

	TSay():New( 007, 035, {|| "Títulos relacionados com Extrato" }, oPCabTit,,,,,,.T.,CLR_BLACK,,110,9 )
	TSay():New( 013, 000,{|| Repl("_",(oPCabTit:nWidth/2)) }, oPCabTit,,,,,,.T.,CLR_HGRAY,,oPCabTit:nWidth/2,9 )

	//Botões de ação GetDados
	TButton():New( 005, (oPCabTit:nWidth/2)-260, "Ajusta Vlr.Div.", oPCabTit, {|| ::AjuVlrDiv() }, 60, 12,,,.F.,.T.,.F.,,.F.,,,.F. )
	TButton():New( 005, (oPCabTit:nWidth/2)-195, "Desvincular", oPCabTit, {|| ::DoDesvinc() }, 50, 12,,,.F.,.T.,.F.,,.F.,,,.F. )
	TButton():New( 005, (oPCabTit:nWidth/2)-140, "Alterar Título", oPCabTit, {|| ::DoAlteraTit(1) }, 60, 12,,,.F.,.T.,.F.,,.F.,,,.F. )
	TButton():New( 005, (oPCabTit:nWidth/2)-75, "Ver Inconsistências", oPCabTit, {|| GoToIncons(::cCodLay) }, 70, 12,,,.F.,.T.,.F.,,.F.,,,.F. )

	::DoNewGetPri(oPGrTit)

	//Totalizadores Por Bandeiras
	::oScrBand := TScrollBox():New(oPTotBan,000,000,100,100,.F.,.T.,.T.)
	::oScrBand:Align := CONTROL_ALIGN_ALLCLIENT

	//Totalizadores Por Operadora
	oGrp1 := TGroup():Create(oPTotGer, 0,0,10,10,,,,.T.)
	oGrp1:Align := CONTROL_ALIGN_ALLCLIENT
	::DoAddPnlTot(oPTotGer)

Return

//---------------------------------------------------------------
// Faz montagem do NewGetDados da aba
//---------------------------------------------------------------
METHOD DoNewGetPri(oPnl) CLASS UT019ABA

	Local aAlterFields := {}
	Local aHeadTmp := {}
	Local cTrue := "AllwaysTrue"

	Aadd(::aHeader,{ ' ','MARK','@BMP',2,0,'','€€€€€€€€€€€€€€','C','','','',''})
	aAdd(::aEmptyLin, "LBNO")

	Aadd(::aHeader,{ '',"LEG",'@BMP',2,0,'','€€€€€€€€€€€€€€','C','','V'})
	aAdd(::aEmptyLin, "BR_BRANCO")

	aHeadTmp := U_UAHEADER("E1_EMISSAO")
	aHeadTmp[1] := "Dt. Venda"
	aadd(::aHeader, aClone(aHeadTmp) )
	aAdd(::aEmptyLin, STOD(""))

	aHeadTmp := U_UAHEADER("E1_VLRREAL")
	aHeadTmp[1] := "Valor Extrato"
	aHeadTmp[2] := "E1_VALORE"
	aadd(::aHeader, aClone(aHeadTmp) )
	aAdd(::aEmptyLin, 0 )

	aHeadTmp := U_UAHEADER("E1_VLRREAL")
	aadd(::aHeader, aClone(aHeadTmp) )
	aAdd(::aEmptyLin, 0 )

	aHeadTmp := U_UAHEADER("AE_TAXA")
	aHeadTmp[1] += " (%)"
	aadd(::aHeader, aClone(aHeadTmp) )
	aAdd(::aEmptyLin, 0 )

	aHeadTmp := U_UAHEADER("E1_VALOR")
	aHeadTmp[1] := "Valor Líquido"
	aHeadTmp[2] := "E1_VALORL"
	aadd(::aHeader, aClone(aHeadTmp) )
	aAdd(::aEmptyLin, 0 )

	aHeadTmp[1] := "Vlr. Diverg."
	aHeadTmp[2] := "E1_VALORD"
	aadd(::aHeader, aClone(aHeadTmp) )
	aAdd(::aEmptyLin, 0 )

	AddCamposSE1(::cOperad, ::cCodLay, @::aHeader, @::aEmptyLin, .T.) //campos do titulo

	AddCamposExt(::cOperad, ::cCodLay, @::aHeader, @::aEmptyLin, .F.) //campos do extrato

	aAdd(::aEmptyLin, 0) //recno E1
	aAdd(::aEmptyLin, 0) //recno Ex
	aAdd(::aEmptyLin, .F.) //deleted
	aAdd(::aDados, aClone(::aEmptyLin))

	::oGetDados := MsNewGetDados():New( 000,000,100,100,,;
			cTrue, cTrue,, aAlterFields,, 999, cTrue, "", cTrue, oPnl, ::aHeader, ::aDados)
	::oGetDados:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT

	::oGetDados:oBrowse:bHeaderClick := {|oBrw,nCol,aDim| if(::oGetDados:oBrowse:nColPos<>111 .and. nCol == 1,(::DoMarcaTodos(::oGetDados, 2, "BR_VERDE"),oBrw:SetFocus()), if(nCol > 1, U_UOrdGrid(@::oGetDados, @nCol), ))}
	::oGetDados:oBrowse:bLDblClick := {|| iif(::aDados[::oGetDados:nAt][2]=="BR_VERDE",::DoMarcar(::oGetDados),) }

	::aDados := ::oGetDados:aCols //defino aDadosFil mesmo que aCols

Return

//---------------------------------------------------------------
// Adiciona bandeira no painel ::oScrBand
//---------------------------------------------------------------
METHOD DoAddBand(cAdmFin, cCodBand) CLASS UT019ABA

	Local nHSpacePxl := 100 //espaço horizontal de uma bandeira para outra
	Local nAtBand := 0
	Local nPosBand := 0

	aAdd(::aAdmFin, cAdmFin) // adm fin de todas as bandeiras vinculadas a essa operadora

	//faço um vetor com as adm financeira de cada bandeira especificada
	if !empty(::aBandFil) .AND. aScan(::aBandFil, cCodBand) > 0
		if ( nPosBand:=aScan(::aAdmBand, {|x| x[1]==cCodBand }) ) > 0
			aAdd(::aAdmBand[nPosBand][2], cAdmFin)
		else
			aAdd(::aAdmBand, {cCodBand, {cAdmFin}} ) //adm fin apenas das bandeira dos filtros
		endif
	endif

	if aScan(::aBandeiras, {|x| x[1] == cCodBand}) > 0
		Return
	endif

	if ::lAllBand .OR. aScan(::aBandFil, cCodBand) > 0
		DbSelectArea("MDE")
		MDE->(DbSetOrder(1))
		if MDE->(DbSeek(xFilial("MDE")+cCodBand))

			aadd(::aBandeiras, array(11)) //{{cCodBand, oImagem, cImagem, oTipoOp, cTipoOp, oTotGeral, nTotGeral},...}
			nAtBand := len(::aBandeiras)

			TGroup():Create(::oScrBand,00,(nAtBand*nHSpacePxl)-nHSpacePxl+1,52,(nAtBand*nHSpacePxl)-5,' '+alltrim(MDE->MDE_DESC)+' ',,,.T.)

			::aBandeiras[nAtBand][1] := cCodBand

			::aBandeiras[nAtBand][2] := TBitmap():New( 010, (nAtBand*nHSpacePxl)-nHSpacePxl+5, 038, 025,,"",.T.,::oScrBand,,,.F.,.T.,,"",.T.,,.T.,,.F. )
			::aBandeiras[nAtBand][2]:lAutoSize := .F.

			::aBandeiras[nAtBand][3] := "\dirdoc\img\img_band_"+Alltrim(xFilial("MDE"))+Alltrim(Posicione("MDE",1,xFilial("MDE")+cCodBand,"MDE_CODSIT"))+".png"
			::aBandeiras[nAtBand][2]:Load(NIL, ::aBandeiras[nAtBand][3] )
			::aBandeiras[nAtBand][2]:lStretch 	:= .T.
			::aBandeiras[nAtBand][2]:Refresh()

			TSay():New( 10,(nAtBand*nHSpacePxl)-nHSpacePxl+60,{|| "Tipo Oper.:" }, ::oScrBand,,,,,,.T.,CLR_BLACK,,50,9 )
			if alltrim(MDE->MDE_TIPO) == "CC"
				::aBandeiras[nAtBand][5] := "Crédito"
			elseif alltrim(MDE->MDE_TIPO) == "CD"
				::aBandeiras[nAtBand][5] := "Débito"
			else //outras
				::aBandeiras[nAtBand][5] := MDE->MDE_TIPO
			endif
			@ 20, (nAtBand*nHSpacePxl)-nHSpacePxl+60 SAY ::aBandeiras[nAtBand][4] VAR ::aBandeiras[nAtBand][5] SIZE 50, 9 OF ::oScrBand COLOR CLR_BLUE PIXEL
			
			TSay():New( 30,(nAtBand*nHSpacePxl)-nHSpacePxl+2,{|| Repl("_",nHSpacePxl) }, ::oScrBand,,,,,,.T.,CLR_HGRAY,,nHSpacePxl-8,9 )
			TSay():New( 40,(nAtBand*nHSpacePxl)-nHSpacePxl+5,{|| "Total:" }, ::oScrBand,,,,,,.T.,CLR_BLACK,,50,9 )
			::aBandeiras[nAtBand][7] := 0
			@ 40, (nAtBand*nHSpacePxl)-nHSpacePxl+40 SAY ::aBandeiras[nAtBand][6] VAR ::aBandeiras[nAtBand][7] SIZE 50, 9 OF ::oScrBand PICTURE PesqPict("SE1","E1_VALOR") RIGHT COLOR CLR_BLUE PIXEL

		endif
	endif

Return

//---------------------------------------------------------------
// Constroi campos totalizadores no painel
//---------------------------------------------------------------
METHOD DoAddPnlTot(oPnl) CLASS UT019ABA

	Local nObj := len(::aObjTotaliz)
	Local nPxlRight := oPnl:nWidth / 2

	TSay():New( 07, 05, {|| "Qtd Registros Vinculados:" }, oPnl,,,,,,.T.,CLR_BLACK,,150,9 )
	(aadd(::aObjTotaliz, Nil) , nObj++)
	@ 07, 50 SAY ::aObjTotaliz[nObj] VAR ::nQtdGer SIZE 50, 9 OF oPnl RIGHT COLOR CLR_BLUE PIXEL

	TSay():New( 17, 05, {|| "Qtd Registros Selecionados:" }, oPnl,,,,,,.T.,CLR_BLACK,,150,9 )
	(aadd(::aObjTotaliz, Nil) , nObj++)
	@ 17, 50 SAY ::aObjTotaliz[nObj] VAR ::nQtdSel SIZE 50, 9 OF oPnl RIGHT COLOR CLR_BLUE PIXEL

	TSay():New( 27, 05, {|| "Qtd Títulos Não Vinculados:" }, oPnl,,,,,,.T.,CLR_BLACK,,150,9 )
	(aadd(::aObjTotaliz, Nil) , nObj++)
	@ 27, 50 SAY ::aObjTotaliz[nObj] VAR ::nQtdInc SIZE 50, 9 OF oPnl RIGHT COLOR CLR_BLUE PIXEL

	TSay():New( 37, 05, {|| "Qtd Reg. Arq. Não Vinculados:" }, oPnl,,,,,,.T.,CLR_BLACK,,150,9 )
	(aadd(::aObjTotaliz, Nil) , nObj++)
	@ 37, 50 SAY ::aObjTotaliz[nObj] VAR ::nQtdArq SIZE 50, 9 OF oPnl RIGHT COLOR CLR_BLUE PIXEL

	TSay():New( 00, (nPxlRight*0.30)+108, {|| "(liquido)" }, oPnl,,,,,,.T.,CLR_GRAY,,150,9 )
	TSay():New( 00, (nPxlRight*0.30)+165, {|| "(bruto)" }, oPnl,,,,,,.T.,CLR_GRAY,,150,9 )

	TSay():New( 07, nPxlRight*0.30, {|| "Valor Total Títulos Vinculados:" }, oPnl,,,,,,.T.,CLR_BLACK,,150,9 )
	(aadd(::aObjTotaliz, Nil) , nObj++)
	@ 07, (nPxlRight*0.30)+75 SAY ::aObjTotaliz[nObj] VAR ::nVlTotE1Ger SIZE 50, 9 OF oPnl PICTURE PesqPict("SE1","E1_VALOR") RIGHT COLOR CLR_BLUE PIXEL
	(aadd(::aObjTotaliz, Nil) , nObj++)
	@ 07, (nPxlRight*0.30)+130 SAY ::aObjTotaliz[nObj] VAR ::nVlTotBE1Ger SIZE 50, 9 OF oPnl PICTURE PesqPict("SE1","E1_VALOR") RIGHT COLOR CLR_BLUE PIXEL

	TSay():New( 17, nPxlRight*0.30, {|| "Valor Total Títulos Selecionados:" }, oPnl,,,,,,.T.,CLR_BLACK,,150,9 )
	(aadd(::aObjTotaliz, Nil) , nObj++)
	@ 17, (nPxlRight*0.30)+75 SAY ::aObjTotaliz[nObj] VAR ::nVlTotE1Sel SIZE 50, 9 OF oPnl PICTURE PesqPict("SE1","E1_VALOR") RIGHT COLOR CLR_BLUE PIXEL
	(aadd(::aObjTotaliz, Nil) , nObj++)
	@ 17, (nPxlRight*0.30)+130 SAY ::aObjTotaliz[nObj] VAR ::nVlTotBE1Sel SIZE 50, 9 OF oPnl PICTURE PesqPict("SE1","E1_VALOR") RIGHT COLOR CLR_BLUE PIXEL

	TSay():New( 27, nPxlRight*0.30, {|| "Valor Total Títulos Não Vinculados:" }, oPnl,,,,,,.T.,CLR_BLACK,,150,9 )
	(aadd(::aObjTotaliz, Nil) , nObj++)
	@ 27, (nPxlRight*0.30)+75 SAY ::aObjTotaliz[nObj] VAR ::nVlTotE1Inc SIZE 50, 9 OF oPnl PICTURE PesqPict("SE1","E1_VALOR") RIGHT COLOR CLR_BLUE PIXEL
	(aadd(::aObjTotaliz, Nil) , nObj++)
	@ 27, (nPxlRight*0.30)+130 SAY ::aObjTotaliz[nObj] VAR ::nVlTotBE1Inc SIZE 50, 9 OF oPnl PICTURE PesqPict("SE1","E1_VALOR") RIGHT COLOR CLR_BLUE PIXEL


	TSay():New( 07, nPxlRight*0.66, {|| "Valor Total Extrato Vinculados:" }, oPnl,,,,,,.T.,CLR_BLACK,,150,9 )
	(aadd(::aObjTotaliz, Nil) , nObj++)
	@ 07, (nPxlRight*0.66)+75 SAY ::aObjTotaliz[nObj] VAR ::nVlTotExGer SIZE 50, 9 OF oPnl PICTURE PesqPict("SE1","E1_VALOR") RIGHT COLOR CLR_BLUE PIXEL

	TSay():New( 17, nPxlRight*0.66, {|| "Valor Total Extrato Selecionados:" }, oPnl,,,,,,.T.,CLR_BLACK,,150,9 )
	(aadd(::aObjTotaliz, Nil) , nObj++)
	@ 17, (nPxlRight*0.66)+75 SAY ::aObjTotaliz[nObj] VAR ::nVlTotExSel SIZE 50, 9 OF oPnl PICTURE PesqPict("SE1","E1_VALOR") RIGHT COLOR CLR_BLUE PIXEL

	TSay():New( 27, nPxlRight*0.66, {|| "Valor Total Extrato Não Vinulados:" }, oPnl,,,,,,.T.,CLR_BLACK,,150,9 )
	(aadd(::aObjTotaliz, Nil) , nObj++)
	@ 27, (nPxlRight*0.66)+75 SAY ::aObjTotaliz[nObj] VAR ::nVlTotExInc SIZE 50, 9 OF oPnl PICTURE PesqPict("SE1","E1_VALOR") RIGHT COLOR CLR_BLUE PIXEL

Return

//---------------------------------------------------------------
// Marca linha do acols
//---------------------------------------------------------------
METHOD DoMarcar(oGrid) CLASS UT019ABA

	if oGrid:aCols[oGrid:nAt][1] == "LBOK"
		oGrid:aCols[oGrid:nAt][1] := "LBNO"
	else
		oGrid:aCols[oGrid:nAt][1] := "LBOK"
	endif

	oGrid:oBrowse:Refresh()
	::DoAtuTotal()

return

//---------------------------------------------------------------
// Marca todas linhas do acols
//---------------------------------------------------------------
METHOD DoMarcaTodos(oGrid, nPosIf, xComp, lDesmarca) CLASS UT019ABA

	Local nX
	Default nPosIf := 0
	Default xComp := ""
	Default lDesmarca := .F.

	if lDesmarca
		for nX := 1 to LEN(oGrid:aCols)
			oGrid:aCols[nX][1] := "LBNO"
		Next nX
		oGrid:oBrowse:Refresh()
		return
	endif

	if ::xVez == "0"
		::xVez := "1"
	else
		if ::xVez == "1"
			::xVez := "2"
		endif
	endif

	If ::xVez == "2"
		If ::nMarca == 0
			for nX := 1 to LEN(oGrid:aCols)
				if nPosIf > 0 .AND. xComp <> Nil
			 		if oGrid:aCols[nX][nPosIf] == xComp
			 			oGrid:aCols[nX][1] := "LBOK"
			 		endif
				else
					oGrid:aCols[nX][1] := "LBOK"
				endif
			Next nX
			::nMarca := 1
		Else
			for nX := 1 to LEN(oGrid:aCols)
				oGrid:aCols[nX][1] := "LBNO"
			Next nX
			::nMarca := 0
		Endif
		::xVez:="0"

		oGrid:oBrowse:Refresh()
		::DoAtuTotal()
	Endif

Return

//---------------------------------------------------------------
// Faz montagem do painel
//---------------------------------------------------------------
METHOD DoPnlInc() CLASS UT019ABA

	Local oGrp1, oGrp2, oGrp3
	Local oPnlTotal
	Local oPExtrato, oPTitulos

	::oPnlInc  := FWLayer():new()
	::oPnlInc:init(::oDlgInc,.F.)
	::oPnlInc:addLine('GRIDS', 070, .F.)
	::oPnlInc:addLine('SPC1', 001, .F.)
	::oPnlInc:addLine('TOTAL', 029, .F.)
	::oPnlInc:addCollumn('EXTRATO', 049.8, .F., 'GRIDS')
	::oPnlInc:addCollumn('SPC1', 0.2, .F., 'GRIDS')
	::oPnlInc:addCollumn('TITULOS', 049.8, .F., 'GRIDS')

	oPExtrato := ::oPnlInc:GetColPanel('EXTRATO', 'GRIDS')
	oPTitulos := ::oPnlInc:GetColPanel('TITULOS', 'GRIDS')
	oPnlTotal := ::oPnlInc:GetLinePanel('TOTAL')

	oGrp1 := TGroup():Create(oPExtrato, 0, 0, 10,10,' Itens Extrato não encontrados no Contas a Receber ',,,.T.)
	oGrp1:Align := CONTROL_ALIGN_ALLCLIENT
	::DoNewGetExt(oGrp1) //grid extrato

	oGrp2 := TGroup():Create(oPTitulos, 0,0,10,10,' Títulos CR não encontrados no Extrato ',,,.T.)
	oGrp2:Align := CONTROL_ALIGN_ALLCLIENT
	::DoNewGetSE1(oGrp2) //grid titulos

	oGrp3 := TGroup():Create(oPnlTotal, 0,0,10,10,,,,.T.)
	oGrp3:Align := CONTROL_ALIGN_ALLCLIENT
	::DoAddPnlTot(oPnlTotal)

Return

//---------------------------------------------------------------
// mostra painel de inconsistencias
//---------------------------------------------------------------
METHOD ShowPnlInc() CLASS UT019ABA
	::oPnlInc:Show()
Return

//---------------------------------------------------------------
// oculta painel de inconsistencias
//---------------------------------------------------------------
METHOD HidePnlInc() CLASS UT019ABA
	::oPnlInc:Hide()
Return

//---------------------------------------------------------------
// cria grid inconsistencias SE1
//---------------------------------------------------------------
METHOD DoNewGetSE1(oPnl) CLASS UT019ABA

	Local aAlterFields := {}
	Local cTrue := "AllwaysTrue"

	Aadd(::aHeaderSE1,{ ' ','MARK','@BMP',2,0,'','€€€€€€€€€€€€€€','C','','','',''})
	aAdd(::aMSEmptyE1, "LBNO")

	Aadd(::aHeaderSE1,{ '',"LEG",'@BMP',2,0,'','€€€€€€€€€€€€€€','C','','V'})
	aAdd(::aMSEmptyE1, "BR_BRANCO")

	AddCamposSE1(@::cOperad, @::cCodLay, @::aHeaderSE1, @::aMSEmptyE1)

	aAdd(::aMSEmptyE1, 0) //recno
	aAdd(::aMSEmptyE1, .F.) //deleted
	aAdd(::aDadosSE1, aClone(::aMSEmptyE1))

	::oMSNewGeE1 := MsNewGetDados():New( 0, 0,100,100,,;
				cTrue, cTrue,, aAlterFields,, 99, cTrue, "", cTrue, oPnl, ::aHeaderSE1, ::aDadosSE1)
	::oMSNewGeE1:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT

	::oMSNewGeE1:oBrowse:bLDblClick := {|| ( ::DoMarcaTodos(::oMSNewGeE1,,,.T.), iif(::aDadosSE1[::oMSNewGeE1:nAt][len(::aHeaderSE1)+1]>0,::DoMarcar(::oMSNewGeE1),) ) }
	::oMSNewGeE1:oBrowse:bHeaderClick := {|oBrw1,nCol| if(nCol > 1, U_UOrdGrid(@::oMSNewGeE1, @nCol), )}

	::aDadosSE1 := ::oMSNewGeE1:aCols //defino aDadosSE1 mesmo que aCols

Return

//---------------------------------------------------------------
// cria campos grid para extrato
//---------------------------------------------------------------
Static Function AddCamposSE1(_cOperad, _cCodLay, _aHeader, _aEmpty, lPrincipal)

	//TODO: adicionar campo E1_ADM
	Local nX := 0
	Local aCposE1 := {"E1_PREFIXO","E1_NUM","E1_PARCELA","E1_TIPO","E1_EMISSAO","E1_VLRREAL","E1_VALOR","E1_ACRESC","E1_DECRESC","E1_CLIENTE","E1_LOJA","E1_NOMCLI","E1_NSUTEF","E1_DOCTEF","E1_CARTAUT"}
	Local aHeadTmp
	Local cTipoCp := ""
	Default lPrincipal := .F.

	DbSelectArea("U99")
 	U99->(DbSetOrder(1))
	if U99->(DbSeek(xFilial("U99")+_cOperad+_cCodLay))
		while U99->(!Eof()) .AND. U99->U99_FILIAL+U99->U99_OPERAD+U99->U99_CODIGO == xFilial("U99")+_cOperad+_cCodLay
			if U99->U99_UTILIZ == "C" //comparação pega da X3
				if aScan(aCposE1, alltrim(U99->U99_CAMPO))==0 //se nao tem o campo
					aadd( aCposE1, alltrim(U99->U99_CAMPO))
				endif
		    endif
			U99->(DbSkip())
		enddo
	endif

	for nX := 1 to len(aCposE1)
		if !lPrincipal .OR. !(alltrim(aCposE1[nX]) $ "E1_VLRREAL")
			cTipoCp := GetSx3Cache(aCposE1[nX],"X3_TIPO")
			if Valtype(cTipoCp)=="C" //se campo existe
				aHeadTmp := U_UAHEADER(aCposE1[nX])
				aadd(_aHeader, aClone(aHeadTmp) )
				if cTipoCp == "D"
					aAdd(_aEmpty, STOD(""))
				else
					aAdd(_aEmpty, CriaVar(aCposE1[nX]))
				endif
			endif
		endif
	next nX

return

//---------------------------------------------------------------
// cria grid inconsistencias extrato
//---------------------------------------------------------------
METHOD DoNewGetExt(oPnl) CLASS UT019ABA

	Local aAlterFields := {}
	Local cTrue := "AllwaysTrue"

	Aadd(::aHeaderExt,{ ' ','MARK','@BMP',2,0,'','€€€€€€€€€€€€€€','C','','','',''})
	aAdd(::aMSEmptyEx, "LBNO")

 	AddCamposExt(::cOperad, ::cCodLay, @::aHeaderExt, @::aMSEmptyEx)

	aAdd(::aMSEmptyEx, 0) //recno
	aAdd(::aMSEmptyEx, .F.) //deleted
	aAdd(::aDadosExt, aClone(::aMSEmptyEx))

	::oMSNewGeEx := MsNewGetDados():New( 0, 0,100,100,,;
				cTrue, cTrue,, aAlterFields,, 99, cTrue, "", cTrue, oPnl, ::aHeaderExt, ::aDadosExt)
	::oMSNewGeEx:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT

	::oMSNewGeEx:oBrowse:bLDblClick := {|| ( ::DoMarcaTodos(::oMSNewGeEx,,,.T.), iif(::aDadosExt[::oMSNewGeEx:nAt][len(::aHeaderExt)+1]>0,::DoMarcar(::oMSNewGeEx),) ) }
	::oMSNewGeEx:oBrowse:bHeaderClick := {|oBrw1,nCol| if(nCol > 1, U_UOrdGrid(@::oMSNewGeEx, @nCol), )}

	::aDadosExt := ::oMSNewGeEx:aCols //defino aDadosExt mesmo que aCols

Return

//---------------------------------------------------------------
// cria campos grid para extrato
//---------------------------------------------------------------
Static Function AddCamposExt(cOperad, _cCodLay, _aHeader, _aEmpty, lAddComp)

	Local cTipoCp, aHeadTmp
	Default lAddComp := .T.

	DbSelectArea("U99")
 	U99->(DbSetOrder(1))
	if U99->(DbSeek(xFilial("U99")+cOperad+_cCodLay))
		while U99->(!Eof()) .AND. U99->U99_FILIAL+U99->U99_OPERAD+U99->U99_CODIGO == xFilial("U99")+cOperad+_cCodLay

			if U99->U99_UTILIZ == "C" //comparação pega da X3
				if lAddComp
					cTipoCp := GetSx3Cache(U99->U99_CAMPO,"X3_TIPO")
					if Valtype(cTipoCp)=="C" //se campo existe
						aHeadTmp := U_UAHEADER(U99->U99_CAMPO)
						aHeadTmp[1] := AllTrim(U99->U99_TITULO)
						aadd(_aHeader, aClone(aHeadTmp) )
						if cTipoCp == "D"
							aAdd(_aEmpty, STOD(""))
						else
							aAdd(_aEmpty, CriaVar(U99->U99_CAMPO))
						endif
					endif
				endif
			elseif U99->U99_UTILIZ == "V" //visualizaçao pega da U99
				if U99->U99_TIPOCP == "C" //se caractere
					aAdd(_aHeader,{ AllTrim(U99->U99_TITULO),alltrim(U99->U99_CAMPO)+U99->U99_ITEM,'',iif(U99->U99_TAMANH>0,U99->U99_TAMANH,30),0,'','€€€€€€€€€€€€€€','C','','','',''})
					aAdd(_aEmpty, space(iif(U99->U99_TAMANH>0,U99->U99_TAMANH,30)))
				elseif U99->U99_TIPOCP == "N" //se numerico 
					aHeadTmp := U_UAHEADER("E1_VALOR")
					aHeadTmp[1] := AllTrim(U99->U99_TITULO)
					aHeadTmp[2] := alltrim(U99->U99_CAMPO)+U99->U99_ITEM
					aadd(_aHeader, aClone(aHeadTmp) )
					aAdd(_aEmpty, 0)
				elseif U99->U99_TIPOCP == "D"
					aHeadTmp := U_UAHEADER("E1_VENCTO")
					aHeadTmp[1] := AllTrim(U99->U99_TITULO)
					aHeadTmp[2] := alltrim(U99->U99_CAMPO)+U99->U99_ITEM
					aadd(_aHeader, aClone(aHeadTmp) )
					aAdd(_aEmpty, STOD(""))
				endif
			endif

			U99->(DbSkip())
		enddo
	endif

Return

//---------------------------------------------------------------
// Desvincula o item posicionado no Grid Principal
//---------------------------------------------------------------
METHOD DoDesvinc() CLASS UT019ABA

	if ::aDados[::oGetDados:nAt][2] == "BR_BRANCO"
		MsgInfo("Você deve posicionar em um registro para desvincular.","Atençao")
		return
	endif

	if ::DoAddExtInc( ::aDados[::oGetDados:nAt][len(::aHeader)+2] )
		if ::DoAddTitInc( ::aDados[::oGetDados:nAt][len(::aHeader)+1] )
			//removendo linha vinculada
		    aDel(::aDados, ::oGetDados:nAt)
			ASize(::aDados, len(::aDados)-1)
			if len(::aDados) <= 0
				aAdd(::aDados, aClone(::aEmptyLin))
			endif

			::DoAtuTotal()
		endif
	endif

Return

//---------------------------------------------------------------
// Faz vínculo entre o itens posicionados inconsistencia
//---------------------------------------------------------------
METHOD DoRelaciona(nRecE1,nRecEx) CLASS UT019ABA

	Local nX, nZ, nPosAux
	Local nPosMarkE1 := 0
	Local nPosMarkEx := 0
	Local lTransf := .F.
	Local nPosEx := 0
	Local nPosCpEx := 0
	Local nPosVlrE := 0
	Local lAjSE1Ext := SuperGetMv("TP_AJE1EXT",,.F.) //define se ajusta campos NSU e DOC da SE1 conforme extrato
	Default nRecE1 := 0
	Default nRecEx := 0

	if nRecE1 == 0 .OR. nRecEx == 0
		for nX := 1 to len(::aDadosSE1)
			if ::aDadosSE1[nX][1] == "LBOK"
				nPosMarkE1 := nX
			endif
		next nX
		if nPosMarkE1 == 0
			MsgInfo("Selecione um título para fazer o relacionamento.","Atençao")
			return
		endif

		for nX := 1 to len(::aDadosExt)
			if ::aDadosExt[nX][1] == "LBOK"
				nPosMarkEx := nX
			endif
		next nX
		if nPosMarkEx == 0
			MsgInfo("Selecione um item do extrato para fazer o relacionamento.","Atençao")
			return
		endif
		if ::aDadosExt[nPosMarkEx][len(::aDadosExt[nPosMarkEx])] == .T. //se está deletado
			MsgInfo("O item do extrato selecionado está excluido. Não é possível utilizá-lo.","Atençao")
			return
		endif

		lTransf := .T.
		nRecE1 := ::aDadosSE1[nPosMarkE1][len(::aHeaderSE1)+1]
		nRecEx := ::aDadosExt[nPosMarkEx][len(::aHeaderExt)+1]
	endif

	nPosEx :=  aScan(::aExtrato, {|x| x[len(x)][2]==nRecEx }) //posicao do item do extrato
	nPosVlrE := aScan(::aExtrato[nPosEx], {|x| alltrim(x[1]) == Alltrim(::cCpVlrEx) })

	if lTransf .AND. (lAjSE1Ext .OR. MsgYesNo("Relacionado com sucesso! Deseja também ajustar informações titulo conforme item extrato? ", "Atenção") )
			
		SE1->(DbGoTo(nRecE1))
		Reclock("SE1",.F.)
		
		nPosAux := aScan(::aExtrato[nPosEx], {|x| alltrim(x[1]) == "E1_NSUTEF" })
		if nPosAux > 0
			SE1->E1_NSUTEF := ::aExtrato[nPosEx][nPosAux][2]
		endif
		
		nPosAux := aScan(::aExtrato[nPosEx], {|x| alltrim(x[1]) == "E1_CARTAUT" })
		if nPosAux > 0
			SE1->E1_CARTAUT := ::aExtrato[nPosEx][nPosAux][2]
		endif
		
		SE1->(MsUnlock())

	endif

	//Adicionar titulo e item extrato no grid principal
	//verifica se tem que adicionar nova linha
	if len(::aDados) > 1 .OR. ::aDados[1][2] != "BR_BRANCO"
		aAdd(::aDados, aClone(::aEmptyLin))
	endif

	::DoAtuLinSE1(nRecE1, nRecEx, len(::aDados)) //campos do titulo

	//preenchendo campos do extrato
	for nZ := 1 to len(::aHeader)
		if Alltrim(::aHeader[nZ][2]) $ "MARK/LEG" .OR. "E1_" $ Alltrim(::aHeader[nZ][2])
		else
			nPosCpEx := aScan(::aExtrato[nPosEx], {|x| alltrim(x[1]) == Alltrim(::aHeader[nZ][2]) })
			if nPosCpEx > 0
				::aDados[len(::aDados)][nZ] := ::aExtrato[nPosEx][nPosCpEx][2]
			endif
		endif
	next nZ
	::aDados[len(::aDados)][nZ] 	:= nRecE1 //recno E1
	::aDados[len(::aDados)][(nZ+1)] := nRecEx //recno Ex

	if lTransf
	    //removento titulo do grid inconsistencia
	    aDel(::aDadosSE1, nPosMarkE1)
		ASize(::aDadosSE1, len(::aDadosSE1)-1)
		if len(::aDadosSE1) <= 0
			aAdd(::aDadosSE1, aClone(::aMSEmptyE1))
		endif

		//removendo item extrato do grid inconsistencia
		aDel(::aDadosExt, nPosMarkEx)
		ASize(::aDadosExt, len(::aDadosExt)-1)
		if len(::aDadosExt) <= 0
			aAdd(::aDadosExt, aClone(::aMSEmptyEx))
		endif
	endif

	//faz refresh nos elementos.
	::oGetDados:oBrowse:Refresh()
	::oMSNewGeE1:oBrowse:Refresh()
	::oMSNewGeEx:oBrowse:Refresh()
	::DoAtuTotal()

Return

//---------------------------------------------------------------
// atualiza linha posicionada do acols prnicipal, com dados atuais do titulo
//---------------------------------------------------------------
METHOD DoAtuLinSE1(nRecE1, nRecEx, nAt) CLASS UT019ABA

Local nX, _nValor1
Local nPosEx := 0
Local nPosVlrE := 0
Local aMyDados
Local aMyHeader

if nRecE1 <= 0
	return
endif

if nRecEx > 0
	nPosEx :=  aScan(::aExtrato, {|x| x[len(x)][2]==nRecEx }) //posicao do item do extrato
	nPosVlrE := aScan(::aExtrato[nPosEx], {|x| alltrim(x[1]) == Alltrim(::cCpVlrEx) })

	aMyDados := ::aDados
	aMyHeader := ::aHeader
else
	aMyDados := ::aDadosSE1
	aMyHeader := ::aHeaderSE1
endif

DbSelectArea("SE1")
SE1->(DbGoTo( nRecE1 )) //recno

DbSelectArea("SL1")
SL1->(DbSetOrder(2)) // L1_FILIAL+L1_SERIE+L1_DOC+L1_PDV

For nX := 1 to len(aMyHeader)

	if Alltrim(aMyHeader[nX][2]) == "MARK"
		if !empty(dtos(SE1->E1_BAIXA))
			aMyDados[nAt][nX] := "LBNO"
		endif
	elseif Alltrim(aMyHeader[nX][2]) == "LEG"
		
		if SL1->(DbSeek(xFilial("SL1")+SE1->E1_PREFIXO+SE1->E1_NUM)) .And.;
			 SL1->L1_CLIENTE == SE1->E1_CLIENTE .And.;
			 SL1->L1_LOJA == SE1->E1_LOJA .And.;
			 SL1->L1_STATUS $ cNFRecu
			
			aMyDados[nAt][nX] := "BR_AMARELO"
		else
			aMyDados[nAt][nX] := iif(SE1->E1_STATUS=="A", "BR_VERDE", "BR_VERMELHO")
		endif

	elseif Alltrim(aMyHeader[nX][2]) == "E1_VALORE"
	    If nPosVlrE>0
		aMyDados[nAt][nX] := ::aExtrato[nPosEx][nPosVlrE][2]
		Else
		aMyDados[nAt][nX] := 0
		Endif
	elseif Alltrim(aMyHeader[nX][2]) == "E1_VALORL"
		aMyDados[nAt][nX] := (SE1->E1_VALOR + SE1->E1_ACRESC - SE1->E1_DECRESC)
	elseif Alltrim(aMyHeader[nX][2]) == "E1_VALORD"
		_nValor1:=IIF(nPosVlrE>0,::aExtrato[nPosEx][nPosVlrE][2],0)
		aMyDados[nAt][nX] := (SE1->&(::cCpVlrDiv) + SE1->E1_ACRESC - SE1->E1_DECRESC) - _nValor1
		if aMyDados[nAt][nX] < 0
			aMyDados[nAt][nX] *= -1
		endif
	elseif Alltrim(aMyHeader[nX][2]) == "AE_TAXA"

		aMyDados[nAt][nX] := Round(100 - (SE1->E1_VALOR * 100 / SE1->E1_VLRREAL), 2)//taxa real
		//TODO: trocar busca pelo campo E1_ADM
		cTaxaSAE := Posicione("SAE",1,xFilial("SAE")+Alltrim(SE1->E1_CLIENTE),"AE_TAXA") //taxa adm fin

		//se a diferença da taxa é minima, é questão de arredondamento no calculo
		//nesse caso pego a taxa da SAE para apresentar na tela
		if Round(SE1->E1_VLRREAL - ((SE1->E1_VLRREAL*cTaxaSAE)/100),2) == SE1->E1_VALOR .Or. ;
				Abs(cTaxaSAE - aMyDados[nAt][nX]) <= 0.01
			aMyDados[nAt][nX] := cTaxaSAE
		endif

	elseif "E1_" $ Alltrim(aMyHeader[nX][2])
		If SE1->(FieldPos(aMyHeader[nX][2])) > 0
			aMyDados[nAt][nX] := SE1->&(aMyHeader[nX][2])
		endif
	endif

next nX

Return


//---------------------------------------------------------------
// Adiciona item no grid de titulo inconsitencias
//---------------------------------------------------------------
METHOD DoAddTitInc(nRecE1) CLASS UT019ABA

	Local nZ
	Local lRet := .F.

	if aScan(::aTitulos, nRecE1) > 0 //validando se o recno está no aTitulos

		SE1->(DbGoTo(nRecE1)) //posiciona a partir do recno

		DbSelectArea("SL1")
		SL1->(DbSetOrder(2)) // L1_FILIAL+L1_SERIE+L1_DOC+L1_PDV

		//verifica se tem que adicionar nova linha
		if len(::aDadosSE1) > 1 .OR. ::aDadosSE1[1][len(::aHeaderSE1)+1] > 0
			aAdd(::aDadosSE1, aClone(::aMSEmptyE1))
		endif

		//preenchendo campos
		for nZ := 1 to len(::aHeaderSE1)
			if Alltrim(::aHeaderSE1[nZ][2]) == "MARK"
			elseif Alltrim(::aHeaderSE1[nZ][2]) == "LEG"
				if SL1->(DbSeek(xFilial("SL1")+SE1->E1_PREFIXO+SE1->E1_NUM)) .And.;
					 SL1->L1_CLIENTE == SE1->E1_CLIENTE .And.;
					 SL1->L1_LOJA == SE1->E1_LOJA .And.;
			 		 SL1->L1_STATUS $ cNFRecu

					::aDadosSE1[len(::aDadosSE1)][nZ] := "BR_AMARELO"
				else
					::aDadosSE1[len(::aDadosSE1)][nZ] := iif(empty(dtos(SE1->E1_BAIXA)), "BR_VERDE", "BR_VERMELHO")
				endif
			else
				::aDadosSE1[len(::aDadosSE1)][nZ] := SE1->&(::aHeaderSE1[nZ][2])
			endif
		next nZ
		::aDadosSE1[len(::aDadosSE1)][nZ] := nRecE1 //recno

		lRet := .T.
		::oMSNewGeE1:oBrowse:Refresh()
	endif

Return lRet

//---------------------------------------------------------------
// Adiciona item extrato no grid inconsitencias
//---------------------------------------------------------------
METHOD DoAddExtInc(nRecEx) CLASS UT019ABA

	Local nZ
	Local lRet := .F.
	Local nPosEx := 0

	nPosEx :=  aScan(::aExtrato, {|x| x[len(x)][2]==nRecEx })

	if nPosEx > 0 //validando se o recno está no aTitulos

		//verifica se tem que adicionar nova linha
		if len(::aDadosExt) > 1 .OR. ::aDadosExt[1][len(::aHeaderExt)+1] > 0
			aAdd(::aDadosExt, aClone(::aMSEmptyEx))
		endif

		//preenchendo campos
		for nZ := 1 to len(::aHeaderExt)
			if Alltrim(::aHeaderExt[nZ][2]) == "MARK"
			else
				::aDadosExt[len(::aDadosExt)][nZ] := ::aExtrato[nPosEx][aScan(::aExtrato[nPosEx], {|x| alltrim(x[1]) == alltrim(::aHeaderExt[nZ][2]) })][2]
			endif
		next nZ
		::aDadosExt[len(::aDadosExt)][nZ] := nRecEx //recno

		lRet := .T.
		::oMSNewGeEx:oBrowse:Refresh()
	endif

Return lRet

//---------------------------------------------------------------
// Exclui um item do extrato
//---------------------------------------------------------------
METHOD DoExcluiItExt() CLASS UT019ABA

	Local nX
	Local nPosMarkEx := 0

	for nX := 1 to len(::aDadosExt)
		if ::aDadosExt[nX][1] == "LBOK"
			nPosMarkEx := nX
		endif
	next nX
	if nPosMarkEx == 0
		MsgInfo("Selecione um item do extrato.","Atençao")
		return
	endif

	if !::aDadosExt[nPosMarkEx][len(::aDadosExt[nPosMarkEx])] .AND. !MsgYesNo("Confirma exclusão do item selecionado do extrato?","Excluir")
		return
	endif

	::aDadosExt[nPosMarkEx][1] := "LBOK"
	::aDadosExt[nPosMarkEx][len(::aDadosExt[nPosMarkEx])] := !::aDadosExt[nPosMarkEx][len(::aDadosExt[nPosMarkEx])] //inverte deleted
	::oMSNewGeEx:oBrowse:Refresh()

Return

//---------------------------------------------------------------
// Chama tela de alteração do título (nTipo: 1=Grid Principal, 2=Grid Incons.)
//---------------------------------------------------------------
METHOD DoAlteraTit(nTipo) CLASS UT019ABA

	Local cBkpCad := cCadastro
    Local nPosMarkE1 := 0
    Local nRecSE1 := 0
	Local cBkpOrigem := ""

    //variáveis para manipular Dlg
	Local bOk := {|| (lOK:=.T.,oDlgAlt:End()) }
	Local bCancel := {|| (lCancela:=.T.,oDlgAlt:End()) }
	Local aButtons := {}
	Local aFin040 := {}

	Local nVlrAnt := 0	// GMdS | Valor Anterior para log.
	Local nAcrAnt := 0  // GMdS | Acrescimo para log.
	Local nDecAnt := 0  // GMdS | Decrescimo para log.

	Local nX

	//campos da tela
	Static oDlgAlt
	Private nAcresc := 0
	Private nDecresc := 0
	Private nVlTotal := 0
	Private _nVlrReal := 0
	Private _nVlrLiq	 := 0
	Private _nPTaxa := 0
	Private _nVlrTaxa := 0
	Private lOK := lCancela := .F.

	//verifica se o usuário tem permissão para acesso a rotina
	U_TRETA37B("ALT062", "ALTERAR TITULO - ROTINA IMPORTAR EXTRATO OPERADORAS")
	cUsrCmp := U_VLACESS1("ALT062", RetCodUsr())
	if cUsrCmp == Nil .OR. empty(cUsrCmp)
		Return
	endif

	DbSelectArea("SE1")
	if nTipo == 1
		if ::aDados[::oGetDados:nAt][len(::aHeader)+1] > 0
			SE1->(DbGoTo(::aDados[::oGetDados:nAt][len(::aHeader)+1]))
		endif
	else
		for nX := 1 to len(::aDadosSE1)
			if ::aDadosSE1[nX][1] == "LBOK"
				nPosMarkE1 := nX
				EXIT
			endif
		next nX
		if nPosMarkE1 == 0
			MsgInfo("Selecione um título para alteração.","Atençao")
			return
		endif
		if ::aDadosSE1[nPosMarkE1][len(::aHeaderSE1)+1] > 0
			SE1->(DbGoTo( ::aDadosSE1[nPosMarkE1][len(::aHeaderSE1)+1] ))
		endif
	endif

	if SE1->(!Eof())
		nRecSE1 := SE1->(Recno())

		if !empty(DTOS(SE1->E1_BAIXA))
			MsgInfo("O título selecionado já foi baixado.","Atençao")
			return
		endif

		if SE1->E1_VLRREAL <= 0 .AND. MsgYesNo("O valor real (E1_VLRREAL) do titulo está inconsistente. Deseja corrigir colocando conteúdo do Valor (E1_VALOR)?","Atençao")
			RecLock("SE1", .F.)
				SE1->E1_VLRREAL := SE1->E1_VALOR
			SE1->(MsUnlock())
		elseif SE1->E1_VLRREAL <= 0
			MsgInfo("O título selecionado está inconsistente. Campo valor real (E1_VLRREAL) sem preenchimento ou com valor incorreto. Entre em contato com TI para manutenção.","Atençao")
			return
		endif

		nAcresc 	:= SE1->E1_ACRESC
		nDecresc 	:= SE1->E1_DECRESC
		_nVlrReal 	:= SE1->E1_VLRREAL
		_nPTaxa 	:= 100-(SE1->E1_VALOR * 100 / SE1->E1_VLRREAL)
		_nVlrTaxa 	:= SE1->E1_VLRREAL - SE1->E1_VALOR
		_nVlrLiq	:= SE1->E1_VLRREAL * (1-(_nPTaxa / 100)) //E1_VALOR
		nVlTotal 	:= _nVlrLiq + nAcresc - nDecresc

		nVlrAnt		:= SE1->E1_VALOR 	// GMdS | Valor para log.
		nAcrAnt 	:= SE1->E1_ACRESC  	// GMdS | Acrescimo para log.
		nDecAnt		:= SE1->E1_DECRESC	// GMdS | Decrescimo para log.

		cCadastro := "Alterar Título"

		oDlgAlt := TDialog():New(0,0,360,550,"",,,,,,,,,.T.)

		TGroup():Create(oDlgAlt,32,2,107,275,' Dados do Título ',,,.T.)

        TSay():New( 45,10,{|| "Prefixo: <b>" + SE1->E1_PREFIXO + "</b>"}, oDlgAlt,,,,,,.T.,CLR_BLACK,,200,9,,,,,,.T. )
        TSay():New( 45,50,{|| "Num. Título: <b>" + SE1->E1_NUM + "</b>"}, oDlgAlt,,,,,,.T.,CLR_BLACK,,200,9 ,,,,,,.T. )
        TSay():New( 45,120,{|| "Parcela: <b>" + SE1->E1_PARCELA + "</b>"}, oDlgAlt,,,,,,.T.,CLR_BLACK,,200,9 ,,,,,,.T. )
        TSay():New( 45,230,{|| "Tipo: <b>" + SE1->E1_TIPO + "</b>"}, oDlgAlt,,,,,,.T.,CLR_BLACK,,200,9 ,,,,,,.T. )
		//TODO: adicionar campo E1_ADM
        TSay():New( 57,10,{|| "Sacado: <b>" + SE1->E1_CLIENTE + "/" + SE1->E1_LOJA + " - " + SE1->E1_NOMCLI + "</b>"}, oDlgAlt,,,,,,.T.,CLR_BLACK,,200,9 ,,,,,,.T. )

        TSay():New( 69,10,{|| "Dt. Emissão: <b>" + DTOC(SE1->E1_EMISSAO) + "</b>"}, oDlgAlt,,,,,,.T.,CLR_BLACK,,200,9 ,,,,,,.T. )
        TSay():New( 69,120,{|| "Valor Real: <b>" + Alltrim(Transform(SE1->E1_VLRREAL,"@E 9,999,999,999,999.99")) + "</b>"}, oDlgAlt,,,,,,.T.,CLR_BLACK,,200,9 ,,,,,,.T. )
        TSay():New( 69,230,{|| "Taxa: <b>" + Alltrim(Transform(100-(SE1->E1_VALOR * 100 / SE1->E1_VLRREAL),"@E 999.99")) + "</b>"}, oDlgAlt,,,,,,.T.,CLR_BLACK,,200,9 ,,,,,,.T. )

		TSay():New( 81,10,{|| "Dt. Vencto.: <b>" + DTOC(SE1->E1_VENCREA) + "</b>"}, oDlgAlt,,,,,,.T.,CLR_BLACK,,200,9 ,,,,,,.T. )
        TSay():New( 81,120,{|| "Valor Líquido: <b>" + Alltrim(Transform(SE1->E1_VALOR,"@E 9,999,999,999,999.99")) + "</b>"}, oDlgAlt,,,,,,.T.,CLR_BLACK,,200,9 ,,,,,,.T. )

        TSay():New( 93,10,{|| "Código NSU/DOC: <b>" + SE1->E1_NSUTEF + "</b>"}, oDlgAlt,,,,,,.T.,CLR_BLACK,,200,9 ,,,,,,.T. )
        TSay():New( 93,120,{|| "Código Autorização: <b>" + SE1->E1_CARTAUT + "</b>"}, oDlgAlt,,,,,,.T.,CLR_BLACK,,200,9 ,,,,,,.T. )

		TGroup():Create(oDlgAlt,110,2,179,275,' Taxa / Acréscimos / Decréscimos ',,,.T.)

		TSay():New( 120,010,{|| "Valor Real" }, oDlgAlt,,,,,,.T.,CLR_BLACK,,50,9 )
		TGet():New( 118,045, {|u| iif( PCount()==0,_nVlrReal,_nVlrReal:= u) },oDlgAlt,60,9,PesqPict("SE1","E1_VLRREAL"),/*bValid*/,,,,.F.,,.T.,,.F.,{|| .F. },.F.,.F.,/*bChange*/,.F.,.F.,,"E1_VLRREAL",,,,.T.,.F.)

		TSay():New( 135,010,{|| "% Taxa" }, oDlgAlt,,,,,,.T.,CLR_BLACK,,50,9 )
		TGet():New( 133,045, {|u| iif( PCount()==0,_nPTaxa,_nPTaxa:= u) },oDlgAlt,60,9,PesqPict("SAE","AE_TAXA"),/*bValid*/,,,,.F.,,.T.,,.F.,{|| .T. },.F.,.F.,{|| _nVlrLiq := Round( SE1->E1_VLRREAL * (1-(_nPTaxa / 100)) ,TAMSX3("E1_VLRREAL")[2] ), _nVlrTaxa := SE1->E1_VLRREAL - _nVlrLiq , nVlTotal:= _nVlrLiq + nAcresc - nDecresc }/*bChange*/,.F.,.F.,,"AE_TAXA",,,,.T.,.F.)

		TSay():New( 150,010,{|| "Vlr Taxa" }, oDlgAlt,,,,,,.T.,CLR_BLACK,,50,9 )
		TGet():New( 148,045, {|u| iif( PCount()==0,_nVlrTaxa,_nVlrTaxa:= u) },oDlgAlt,60,9,PesqPict("SE1","E1_VALOR"),{|| _nVlrTaxa < SE1->E1_VLRREAL }/*bValid*/,,,,.F.,,.T.,,.F.,{|| .T. },.F.,.F.,{|| _nVlrLiq := Round(SE1->E1_VLRREAL-_nVlrTaxa,TAMSX3("E1_VLRREAL")[2]), _nPTaxa := 100-(_nVlrLiq * 100 / SE1->E1_VLRREAL)  , nVlTotal:= _nVlrLiq + nAcresc - nDecresc }/*bChange*/,.F.,.F.,,"AE_TAXA",,,,.T.,.F.)

		TSay():New( 165,010,{|| "Valor Líquido" }, oDlgAlt,,,,,,.T.,CLR_BLACK,,50,9 )
		TGet():New( 163,045, {|u| iif( PCount()==0,_nVlrLiq,_nVlrLiq:= u) },oDlgAlt,60,9,PesqPict("SE1","E1_VALOR"),/*bValid*/,,,,.F.,,.T.,,.F.,{|| .F. },.F.,.F.,/*bChange*/,.F.,.F.,,"E1_VALOR",,,,.T.,.F.)

		TSay():New( 120,120,{|| "Acréscimos (+)" }, oDlgAlt,,,,,,.T.,CLR_BLACK,,50,9 )
		TGet():New( 118,180, {|u| iif( PCount()==0,nAcresc,nAcresc:= u) },oDlgAlt,60,9,PesqPict("SE1","E1_ACRESC"),/*bValid*/,,,,.F.,,.T.,,.F.,{|| nDecresc == 0 },.F.,.F.,{|| nVlTotal:= _nVlrLiq + nAcresc - nDecresc }/*bChange*/,.F.,.F.,,"E1_ACRESC",,,,.T.,.F.)

		TSay():New( 135,120,{|| "Decréscimos (-)" }, oDlgAlt,,,,,,.T.,CLR_BLACK,,50,9 )
		TGet():New( 133,180, {|u| iif( PCount()==0,nDecresc,nDecresc:= u) },oDlgAlt,60,9,PesqPict("SE1","E1_DECRESC"),/*bValid*/,,,,.F.,,.T.,,.F.,{|| nAcresc == 0 },.F.,.F.,{|| nVlTotal:= _nVlrLiq + nAcresc - nDecresc }/*bChange*/,.F.,.F.,,"E1_DECRESC",,,,.T.,.F.)

		TSay():New( 150,120,{|| "Valor a Baixar (=)" }, oDlgAlt,,,,,,.T.,CLR_BLACK,,50,9 )
		TGet():New( 148,180, {|u| iif( PCount()==0,nVlTotal,nVlTotal:= u) },oDlgAlt,60,9,PesqPict("SE1","E1_VALOR"),/*bValid*/,,,,.F.,,.T.,,.F.,{|| .F. },.F.,.F.,/*bChange*/,.F.,.F.,,"E1_VALOR",,,,.T.,.F.)

		oDlgAlt:bInit := {|| EnchoiceBar(oDlgAlt, bOk, bCancel,.F.,@aButtons,nRecSE1,"SE1") }
		oDlgAlt:lCentered := .T.
		oDlgAlt:Activate()

		cCadastro := cBkpCad

		if lOK .AND. !lCancela

			//Montando array para execauto
			AADD(aFin040, {"E1_FILIAL"	,SE1->E1_FILIAL		,Nil } )
			AADD(aFin040, {"E1_PREFIXO"	,SE1->E1_PREFIXO	,Nil } )
			AADD(aFin040, {"E1_NUM"		,SE1->E1_NUM		,Nil } )
			AADD(aFin040, {"E1_PARCELA"	,SE1->E1_PARCELA  	,Nil } )
			AADD(aFin040, {"E1_TIPO"	,SE1->E1_TIPO	   	,Nil } )
			AADD(aFin040, {"E1_CLIENTE"	,SE1->E1_CLIENTE	,Nil } )
			AADD(aFin040, {"E1_LOJA"	,SE1->E1_LOJA		,Nil } )

			AADD(aFin040, {"E1_VALOR"   ,_nVlrLiq	,Nil})

			AADD(aFin040, {"E1_ACRESC"	,nAcresc	,Nil } )
			AADD(aFin040, {"E1_SDACRES"	,nAcresc	,Nil } )
			AADD(aFin040, {"E1_DECRESC"	,nDecresc	,Nil } )
			AADD(aFin040, {"E1_SDDECRE"	,nDecresc	,Nil } )

			lMsErroAuto := .F. // variavel interna da rotina automatica
			lMsHelpAuto := .F.

			//apaga a origem para ser possível alteração/exclusão do titulo
			cBkpOrigem := SE1->E1_ORIGEM
			RecLock("SE1",.F.)
				SE1->E1_ORIGEM := ""
			SE1->(MsUnlock())

			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³ Chama a funcao de gravacao automatica do FINA040                        ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			MSExecAuto({|x,y| FINA040(x,y)},aFin040, 4)

			//volta a origem 
			RecLock("SE1",.F.)
				SE1->E1_ORIGEM := cBkpOrigem
			SE1->(MsUnlock())

			if lMsErroAuto
				MostraErro()
			else

				//fazendo refreshs
				if nTipo == 1
					::DoAtuLinSE1(::aDados[::oGetDados:nAt][len(::aHeader)+1], ::aDados[::oGetDados:nAt][len(::aHeader)+2], ::oGetDados:nAt)
					::oGetDados:oBrowse:Refresh()
				else
					::DoAtuLinSE1(::aDadosSE1[nPosMarkE1][len(::aHeaderSE1)+1], 0, ::oMSNewGeE1:nAt)
					::oMSNewGeE1:oBrowse:Refresh()
				endif

				::DoAtuTotal()

			endif

			DbUnlockAll()
		endif
	else
		MsgInfo("Selecione um título!","Atençao")
    endif

Return

//---------------------------------------------------------------
// Monta getdados da tela de busca titulos
//---------------------------------------------------------------
METHOD DoMsGetSE1() CLASS UT019ABA

	Local aAlterFields := {}
	Local cTrue := "AllwaysTrue"

	aAdd(::aBuscaSE1, aClone(::aMSEmptyE1))

	::oMsNewSE1 := MsNewGetDados():New( 006, 006, 154, 246,,cTrue, cTrue,, aAlterFields,, 99, cTrue, "", cTrue, oDlgSE1, ::aHeaderSE1, ::aBuscaSE1)

	::oMsNewSE1:oBrowse:bHeaderClick := {|oBrw,nCol,aDim| if(::oMsNewSE1:oBrowse:nColPos<>111 .and. nCol == 1,(::DoMarcaTodos(::oMsNewSE1, 2, "BR_VERDE"),oBrw:SetFocus()), if(nCol > 1, U_UOrdGrid(@::oMsNewSE1, @nCol), ))}
	::oMsNewSE1:oBrowse:bLDblClick := {|| iif(::aBuscaSE1[::oMsNewSE1:nAt][2]=="BR_VERDE",::DoMarcar(::oMsNewSE1),) }

	::aBuscaSE1 := ::oMsNewSE1:aCols //defino aDadosSE1 mesmo que aCols

Return

//---------------------------------------------------------------
// Faz a busca dos titulos de acordo com os filtros
//---------------------------------------------------------------

METHOD DoBuscaSE1(lRefresh, lFiltra, lRapida) CLASS UT019ABA
	//adicionado o MsAguarde para usuário aguardar o processamento...
	MsAguarde({|| ::PrBuscaSE1(lRefresh, lFiltra, lRapida) },"Aguarde...","Buscando títulos de acordo com os filtros...")
Return

METHOD PrBuscaSE1(lRefresh, lFiltra, lRapida) CLASS UT019ABA

	//variaveis para busca de titulos
	Local aArea := GetArea()
	Local cQry := ""
	Local cAdmFin := ""
	Local nPosEmissao := aScan(::aHeaderExt ,{|x| AllTrim(x[2]) == "E1_EMISSAO"})
	Local nPosVlrReal := aScan(::aHeaderExt ,{|x| AllTrim(x[2]) == "E1_VLRREAL"})
	Local nX, nZ

	Default lRefresh := .F.
	Default lFiltra := .F.
	Default lRapida := .F.

	if lFiltra //abre tela de filtros
		::cFilSE1 := BuildExpr("SE1",,::cFilSE1,.T.)
	endif

	cAdmFin := "'"+::aAdmFin[1]+"'"
	for nX := 2 to len(::aAdmFin)
		cAdmFin += ",'"+::aAdmFin[nX]+"'"
	next nX

	//fazer select e add registros retornados no acols
	If Select("SE1BUSCA") > 0
		SE1BUSCA->(DbCloseArea())
	Endif

	cQry := " SELECT SE1.R_E_C_N_O_ "
	cQry += " FROM "+RetSqlName("SE1")+" SE1 "
	cQry += " WHERE SE1.D_E_L_E_T_ <> '*' "
	cQry += " 	AND SE1.E1_FILIAL = '"+xFilial("SE1")+"' "
	cQry += " 	AND SE1.E1_STATUS = 'A' "
	cQry += " 	AND SE1.E1_TIPO IN ('CC ','CD ') " //add para trazer somente titulos de cartao

	If lRapida
		If Empty(AllTrim(cNSU)) .AND. Empty(AllTrim(cCodAut))
			If Val(cMrgDias) > 0
				cQry += "	AND SE1.E1_EMISSAO BETWEEN '" +DToS(::aDadosExt[::oMsNewGeEx:nAt][nPosEmissao]-Val(cMrgDias))+"'"
				cQry += "	AND '" +DToS(::aDadosExt[::oMsNewGeEx:nAt][nPosEmissao]+Val(cMrgDias))+ "' "
			Else
				cQry += " 	AND SE1.E1_EMISSAO <= '"+DToS(ddatabase)+"' " //add para nao trazer titulos com emissao superior a data base
			EndIf
			If nMrgVal > 0
				cQry += " AND SE1.E1_VLRREAL <= " + cValToChar(::aDadosExt[::oMsNewGeEx:nAt][nPosVlrReal]+nMrgVal)
				cQry += " AND SE1.E1_VLRREAL >= " + cValToChar(::aDadosExt[::oMsNewGeEx:nAt][nPosVlrReal]-nMrgVal)
			EndIf
		Else
			If !Empty(AllTrim(cNSU)) .AND. !Empty(AllTrim(cCodAut))
				cQry += " AND ( SE1.E1_NSUTEF = '" + AllTrim(cNSU) + "' OR SE1.E1_NSUTEF LIKE '%" + AllTrim(cNSU) + "%' "
				cQry += " OR SE1.E1_CARTAUT = '" + AllTrim(cCodAut) + "' OR SE1.E1_CARTAUT LIKE '%" + AllTrim(cCodAut) + "%' ) "
			ElseIf !Empty(AllTrim(cNSU))
				cQry += " AND ( SE1.E1_NSUTEF = '" + AllTrim(cNSU) + "' OR SE1.E1_NSUTEF LIKE '%" + AllTrim(cNSU) + "%' ) "
			Else
				cQry += " AND ( SE1.E1_CARTAUT = '" + AllTrim(cCodAut) + "' OR SE1.E1_CARTAUT LIKE '%" + AllTrim(cCodAut) + "%' ) "
			EndIf
		EndIf
	Else
		cQry += " 	AND SE1.E1_EMISSAO <= '"+DToS(ddatabase)+"' " //add para nao trazer titulos com emissao superior a data base
	EndIf

	cQry += "	AND SE1.E1_SALDO > 0 "

	if lChkOper
		//TODO: trocar busca pelo campo E1_ADM
		cQry += " 	AND LTRIM(RTRIM(E1_CLIENTE)) IN ("+iif(empty(cAdmFin),"''",cAdmFin)+") "
	endif

	if !empty(::cFilSE1)
   		cQry += " AND " + ::cFilSE1
   	endif

	cQry := ChangeQuery(cQry)
	TcQuery cQry NEW Alias "SE1BUSCA"

	DbSelectArea("SE1")
	aSize(::aBuscaSE1, 0)

	While SE1BUSCA->(!EOF())

		SE1->(DbGoTo(SE1BUSCA->R_E_C_N_O_))

		DbSelectArea("SL1")
		SL1->(DbSetOrder(2)) // L1_FILIAL+L1_SERIE+L1_DOC+L1_PDV

		if aScan(::aTitulos, SE1BUSCA->R_E_C_N_O_) == 0 //tratamento para nao aparecer os que ja estao na tela.

			//verifica se tem que adicionar nova linha
			aAdd(::aBuscaSE1, aClone(::aMSEmptyE1))

			//preenchendo campos
			for nZ := 1 to len(::aHeaderSE1)
				if Alltrim(::aHeaderSE1[nZ][2]) == "MARK"
				elseif Alltrim(::aHeaderSE1[nZ][2]) == "LEG"
					if SL1->(DbSeek(xFilial("SL1")+SE1->E1_PREFIXO+SE1->E1_NUM)) .And.;
						SL1->L1_CLIENTE == SE1->E1_CLIENTE .And.;
						SL1->L1_LOJA == SE1->E1_LOJA .And.;
						SL1->L1_STATUS $ cNFRecu
					
						::aBuscaSE1[len(::aBuscaSE1)][nZ] := "BR_AMARELO"
					else
						::aBuscaSE1[len(::aBuscaSE1)][nZ] := iif(empty(dtos(SE1->E1_BAIXA)), "BR_VERDE", "BR_VERMELHO")
					endif
				else
					::aBuscaSE1[len(::aBuscaSE1)][nZ] := SE1->&(::aHeaderSE1[nZ][2])
				endif
			next nZ
			::aBuscaSE1[len(::aBuscaSE1)][nZ] := SE1BUSCA->R_E_C_N_O_ //recno

		endif

		SE1BUSCA->(DbSkip())
	EndDo

	if len(::aBuscaSE1) <= 0
		aAdd(::aBuscaSE1, aClone(::aMSEmptyE1))
	endif

	if lRefresh
		::oMsNewSE1:Refresh()
		if !empty(::cFilSE1)
			oSayFilter:Show()
		else
			oSayFilter:Hide()
		endif
	endif

	RestArea(aArea)

Return

//---------------------------------------------------------------
// Gera fatura dos titulos selecionados
//---------------------------------------------------------------
METHOD DoGeraFatura() CLASS UT019ABA

	Local aReg := {}
	Local aLinAux
	Local nX := 0, nY := 0
	Local oLeg
	Local oBranco	:= LoadBitmap(GetResources(),"BR_BRANCO")
	Local oAzul		:= LoadBitmap(GetResources(),"BR_AZUL")
	Local oVermelho	:= LoadBitmap(GetResources(),"BR_VERMELHO")
	Local aCpoComp  := {}
	Local cFatura 	:= ""
	Local _nVlrReal	:= _nVlrLiq := 0
	Local aFatBand 	:= {} //{{CodCLi, {array dos titulos}, NomeCli, codBandiera}, ...}
	Local nPosTmp := 0
	Local cBandSAE := ""
	Local lFatFat	:= .F.
	Local nPosDiverg := aScan(::aHeader,{|x| AllTrim(x[2]) == "E1_VALORD" })
	Local lAvalInc := SuperGetMV("MV_XAVINEX",,.T.) //avalia inconsistencias de extrato?

	if ::nQtdSel <= 0
    	MsgInfo("Selecione pelo menos um título para gerar fatura.","Atençao")
    	Return
    endif

	//verifica se tem inconsistências de extrato
	if lAvalInc .AND. (len(::aDadosExt) > 1 .OR. ::aDadosExt[1][len(::aHeaderExt)+1] > 0)
		for nX := 1 to len(::aDadosExt)
			if ::aDadosExt[nX][len(::aDadosExt[nX])] == .F. //se não está deletado
				MsgInfo("Layout: "+ alltrim(::cCodLay) + "-" + alltrim(::cNmLayout) +chr(13)+chr(10) ;
							+"Há inconsistências de itens do extrato a resolver." +chr(13)+chr(10),"Atençao")
				Return
			endif
		next nX
	endif

	for nX := 1 to len(::aDados)
		if ::aDados[nX][nPosDiverg] > 0 //se há divergência de valor
			MsgInfo("Layout: "+ alltrim(::cCodLay) + "-" + alltrim(::cNmLayout) +chr(13)+chr(10) ;
						+"Há divergências de valor nos itens a serem faturados." +chr(13)+chr(10),"Atençao")
			Return
		endif
	next nX

    DbSelectArea("SE1")

	//separando titulos por bandeira
	for nX := 1 to len(::aDados)

	    if ::aDados[nX][1] == "LBOK"
		    SE1->(DbGoTo(::aDados[nX][len(::aHeader)+1]))

			//TODO: trocar busca pelo campo E1_ADM
	    	cBandSAE := Posicione("SAE",1,xFilial("SAE")+Alltrim(SE1->E1_CLIENTE),"AE_ADMCART")
			if empty(cBandSAE)
				MsgInfo("Cliente "+SE1->E1_CLIENTE+" do Titulo " + SE1->E1_PREFIXO + "/" + SE1->E1_NUM + " não é uma Adm Financeira, ou está sem vínculo com uma operadora." +chr(13)+chr(10),"Atençao")
				Return
			endif

	    	//{{Cod Client, {array dos titulos}, NomeBandeira, cBandSAE}, ...}
			//TODO: trocar quebra array pelo campo E1_ADM
		    if (nPosTmp := aScan(aFatBand, {|x| x[4] == cBandSAE }) ) > 0
		    	aAdd(aFatBand[nPosTmp][2], aClone(::aDados[nX]) )
		    else
		    	aAdd(aFatBand, {SE1->E1_CLIENTE, {}, Posicione("MDE",1,xFilial("MDE")+cBandSAE,"MDE_DESC"), cBandSAE } )
		    	aAdd(aFatBand[len(aFatBand)][2], aClone(::aDados[nX]) )
		    endif
		endif

	next nX

	if empty(aFatBand)
		MsgInfo("Selecione pelo menos um título para gerar fatura.","Atençao")
		Return
	endif

	If MsgYesNo("Haverá o faturamento dos registros selecionados, separando por bandeira. Deseja continuar?","Atençao")

		//gerando as faturas para cada Bandeira
		for nX := 1 to len(aFatBand)

			aReg := {}
			_nVlrLiq := 0
			_nVlrReal := 0

			For nY := 1 to len(aFatBand[nX][2])

				SE1->(DbGoTo(aFatBand[nX][2][nY][len(::aHeader)+1]))

				//Legenda
				Do Case
					Case AllTrim(SE1->E1_TIPO) = 'FT' .And. SE1->E1_SALDO > 0
						oLeg := oAzul
					Case AllTrim(SE1->E1_TIPO) = 'FT' .And. SE1->E1_SALDO == 0
						oLeg := oVermelho
					OtherWise
						oLeg := oBranco
				EndCase

				If AllTrim(SE1->E1_TIPO) == "FT" //Dentre os registros selecionados há fatura
					lFatFat := .T.
				Endif

				aLinAux := U_TRE017CP(3)
				aLinAux[1] := .T. //mark
				aLinAux[2] := oLeg
				aLinAux[U_TRE017CP(5, "nPosFilial")] := SE1->E1_FILIAL
				if len(cFilAnt) <> len(AlltriM(xFilial("SE1")))
					aLinAux[U_TRE017CP(5, "nPosFilOri")] := SE1->E1_FILORIG
				endif
				aLinAux[U_TRE017CP(5, "nPosTipo")] := SE1->E1_TIPO
				aLinAux[U_TRE017CP(5, "nPosPrefixo")] := SE1->E1_PREFIXO
				aLinAux[U_TRE017CP(5, "nPosNumero")] := SE1->E1_NUM
				aLinAux[U_TRE017CP(5, "nPosParcela")] := SE1->E1_PARCELA
				aLinAux[U_TRE017CP(5, "nPosPortado")] := SE1->E1_PORTADO
				aLinAux[U_TRE017CP(5, "nPosDeposit")] := SE1->E1_AGEDEP
				aLinAux[U_TRE017CP(5, "nPosNConta")] := SE1->E1_CONTA
				aLinAux[U_TRE017CP(5, "nPosPlaca")] := Transform(SE1->E1_XPLACA,"@!R NNN-9N99")
				aLinAux[U_TRE017CP(5, "nPosCliente")] := SE1->E1_CLIENTE
				aLinAux[U_TRE017CP(5, "nPosLoja")] := SE1->E1_LOJA
				aLinAux[U_TRE017CP(5, "nPosNome")] := SE1->E1_NOMCLI
				aLinAux[U_TRE017CP(5, "nPosEmissao")] := DToC(SE1->E1_EMISSAO)
				aLinAux[U_TRE017CP(5, "nPosVencto")] := DToC(SE1->E1_VENCTO)
				aLinAux[U_TRE017CP(5, "nPosValor")] := Transform(SE1->E1_VALOR,"@E 9,999,999,999,999.99")
				aLinAux[U_TRE017CP(5, "nPosSaldo")] := Transform(SE1->E1_SALDO,"@E 9,999,999,999,999.99")
				aLinAux[U_TRE017CP(5, "nPosDescont")] := Transform(SE1->E1_DESCONT,"@E 9,999,999,999,999.99")
				aLinAux[U_TRE017CP(5, "nPosMulta")] := Transform(SE1->E1_MULTA,"@E 9,999,999,999,999.99")
				aLinAux[U_TRE017CP(5, "nPosJuros")] := Transform(SE1->E1_JUROS,"@E 9,999,999,999,999.99")
				aLinAux[U_TRE017CP(5, "nPosAcresc")] := Transform(SE1->E1_ACRESC,"@E 9,999,999,999,999.99")
				aLinAux[U_TRE017CP(5, "nPosDecres")] := Transform(SE1->E1_DECRESC,"@E 9,999,999,999,999.99")
				aLinAux[U_TRE017CP(5, "nPosVlAcess")] := FValAcess(SE1->E1_PREFIXO,SE1->E1_NUM,SE1->E1_PARCELA,SE1->E1_TIPO,SE1->E1_CLIENTE,SE1->E1_LOJA,SE1->E1_NATUREZ, Iif(Empty(SE1->E1_BAIXA),.F.,.T.),"","R",dDataBase,,SE1->E1_MOEDA,1,SE1->E1_TXMOEDA)
				aLinAux[U_TRE017CP(5, "nPosFatura")] := space(9)
				aLinAux[U_TRE017CP(5, "nPosRecno")] := SE1->(Recno())
				aLinAux[U_TRE017CP(5, "nPosNsuTef")] := SE1->E1_NSUTEF
				aLinAux[U_TRE017CP(5, "nPosDocTef")] := SE1->E1_DOCTEF
				aLinAux[U_TRE017CP(5, "nPosCartAu")] := SE1->E1_CARTAUT

				AAdd(aReg, aLinAux)

		   		_nVlrLiq  += SE1->E1_VALOR + SE1->E1_ACRESC - SE1->E1_DECRESC
		   		_nVlrReal += iif(SE1->E1_VLRREAL > 0 .And. SE1->E1_VLRREAL <> SE1->E1_VALOR,SE1->E1_VLRREAL,SE1->E1_VALOR) + SE1->E1_ACRESC - SE1->E1_DECRESC

			next nY

			if len(aReg) > 0

				::nVlrBruto := _nVlrReal
				::nVlrTaxas := _nVlrReal - _nVlrLiq
			    ::nVlrAcre := 0
			    ::nVlrDesc := 0
			    ::nVlrAlug := 0
			    ::nVlrOutr := 0
				::aValAcess := {}

				::nVlrTotal := _nVlrLiq
				::dVencFat := stod("")

				if ::DoTelaAuxFat(aFatBand[nX][3]) //abre tela dados complementares
					aCpoComp := {}
					DbSelectArea("SA1")
					SA1->(DbSetOrder(1))
					if SA1->(DbSeek(xFilial("SA1")+aFatBand[nX][1]+"01" ))
						if (::nVlrDesc + ::nVlrAlug + ::nVlrOutr - ::nVlrAcre) > 0 //+::nVlrTaxas
							aAdd(aCpoComp , {"E1_DECRESC", (::nVlrDesc + ::nVlrAlug + ::nVlrOutr - ::nVlrAcre), NIL}) //+::nVlrTaxas
						elseif (::nVlrAcre - ::nVlrDesc - ::nVlrAlug - ::nVlrOutr) > 0
							aAdd(aCpoComp , {"E1_ACRESC" , (::nVlrAcre - ::nVlrDesc - ::nVlrAlug - ::nVlrOutr), NIL}) //-::nVlrTaxas
						endif
						aAdd(aCpoComp , {"E1_HIST"	 , ::cObserv, NIL})
						aAdd(aCpoComp , {"E1_VLRREAL", _nVlrReal , NIL}) //valor real da fatura
						
						if SE1->(FIELDPOS("E1_XVALPOS")) > 0
							aAdd(aCpoComp , {"E1_XVALPOS", ::nVlrAlug, NIL})
						endif
						if SE1->(FIELDPOS("E1_XVLDESP")) > 0
							aAdd(aCpoComp , {"E1_XVLDESP", ::nVlrOutr, NIL})
						endif

						if !empty(::dVencFat)
							aAdd(aCpoComp , {"E1_VENCTO"	, ::dVencFat , NIL}) //data vencimento fatura
						endif

						//Função que gera fatura 
					    aRetFat := U_TRETE016(aReg,SA1->A1_COD,SA1->A1_LOJA,3,,lFatFat,,,,,,,,,,aCpoComp, lFatFat, ::aValAcess)
					    
					    if len(aRetFat) > 0 //se gerou tudo ok

							cFatura := aRetFat[1][1]

							If !Empty(cFatura)
								// Incluído por Wellington Gonçalves para baixar a fatura automática
								if MsgYesNo("Deseja baixar agora a fatura "+cFatura+" gerada?","Atençao")
									BaixaSE1(cFatura)
								endif
							endif
						Endif

						DbUnlockAll()
					else
						MsgInfo("Cliente da Adm. Financeira "+aFatBand[nX][1]+" não está na base de dados. Entre em contato com departamento de TI.","Atençao")
					endif

				endif
			else
				MsgInfo("Selecione pelo menos um título para gerar fatura.","Atençao")
				Return
			endif

		next nX

		//atualizo status dos titulos no grid
		for nX := 1 to len(::aDados)
			::DoAtuLinSE1(::aDados[nX][len(::aHeader)+1], ::aDados[nX][len(::aHeader)+2], nX)
		next nX

		//LIMPAR CAMPOS QUANDO GERAR FATURA
	    ::nVlrAcre := 0
	    ::nVlrDesc := 0
	    ::nVlrAlug := 0
	    ::nVlrOutr := 0

		::oGetDados:oBrowse:Refresh()
		::DoAtuTotal()

	endif

Return

//---------------------------------------------------------------
// telinha auxiliar da fatura para digitar acrescimos e decrescimos da fatura
//---------------------------------------------------------------
METHOD DoTelaAuxFat(cNomeBand) CLASS UT019ABA

    Local lRet := .F.
	Local nX
	Local lTxAcessor := SuperGetMV("MV_XTXACES",,.F.) //habilita uso de valores acessórios
	Local nPixHAcess := iif(lTxAcessor, 70, 0)
	Local nPixWAcess := iif(lTxAcessor, 100, 0)
	Local oPnlFatura, oPnlGrid

	if FKC->(FieldPos("FKC_XTXCAR")) == 0 //se nao criou o campo, desabilita parametro
		lTxAcessor := .F.
		nPixHAcess := 0
		nPixWAcess := 0
	endif

    Private _oTotAux
    Private nOpcx := 0
	Private oDlgAuxFat

	if lTxAcessor
		bVldVlrAces := {|nVlrInf| ::oGetVlAces:aCols[::oGetVlAces:nAt][3]:=nVlrInf, ::AtTotAux(.T.) }
	endif
	
	DEFINE MSDIALOG oDlgAuxFat TITLE "Confirmar Fatura" FROM 000, 000  TO 420+(nPixHAcess*2), 300+(nPixWAcess*2) COLORS 0, 16777215 PIXEL

	oPnlFatura := tPanel():New(00,00,,oDlgAuxFat,,,,,,100,100)
	oPnlFatura:Align := CONTROL_ALIGN_ALLCLIENT

	TSay():New( 05, 05, {|| "Haverá o faturamento dos registros selecionados da operadora/bandeira "+alltrim(::cNmOper) + " " + alltrim(cNomeBand)+"." }, oPnlFatura,,,,,,.T.,CLR_BLUE,,145+nPixWAcess,20 )

	//Dados da Fatura
	TGroup():Create(oPnlFatura,25,05,170+nPixHAcess,145+nPixWAcess,' Dados de Fatura ',,,.T.)

	TSay():New( 38, 10, {|| "Valor Bruto:" }, oPnlFatura,,,,,,.T.,CLR_BLACK,,50,9 )
	TGet():New( 36, 85+nPixWAcess, {|u| iif( PCount()==0,::nVlrBruto,::nVlrBruto:= u) }, oPnlFatura,55,9,PesqPict("SE1","E1_VALOR"),/*bValid*/,,,,.F.,,.T.,,.F.,{|| .F.},.F.,.F.,/*bChange*/,.F.,.F.,,"E1_VALOR",,,,.F.,.T.)

	TSay():New( 51, 10, {|| "Taxas Transação(-):" }, oPnlFatura,,,,,,.T.,CLR_BLACK,,50,9 )
	TGet():New( 49, 85+nPixWAcess, {|u| iif( PCount()==0,::nVlrTaxas,::nVlrTaxas:= u) }, oPnlFatura,55,9,PesqPict("SE1","E1_DECRESC"),/*bValid*/,,,,.F.,,.T.,,.F.,{|| .F.},.F.,.F.,{|| ::AtTotAux(lTxAcessor) }/*bChange*/,.F.,.F.,,"E1_DECRESC",,,,.F.,.T.)

	TSay():New( 64, 10, {|| "Descontos (-):" }, oPnlFatura,,,,,,.T.,CLR_BLACK,,50,9 )
	TGet():New( 62, 85+nPixWAcess, {|u| iif( PCount()==0,::nVlrDesc,::nVlrDesc:= u) }, oPnlFatura,55,9,PesqPict("SE1","E1_DESCONT"),/*bValid*/,,,,.F.,,.T.,,.F.,{|| .T.},.F.,.F.,{|| ::AtTotAux(lTxAcessor) }/*bChange*/,.F.,.F.,,"E1_DESCONT",,,,.T.,.F.)

	TSay():New( 77, 10, {|| "Acréscimos (+):" }, oPnlFatura,,,,,,.T.,CLR_BLACK,,50,9 )
	TGet():New( 75, 85+nPixWAcess, {|u| iif( PCount()==0,::nVlrAcre,::nVlrAcre:= u) }, oPnlFatura,55,9,PesqPict("SE1","E1_ACRESC"),/*bValid*/,,,,.F.,,.T.,,.F.,{|| .T.},.F.,.F.,{|| ::AtTotAux(lTxAcessor) }/*bChange*/,.F.,.F.,,"E1_ACRESC",,,,.T.,.F.)

	if lTxAcessor
		TSay():New( 90, 10, {|| "Outras Taxas / Valores Acessórios (-):" }, oPnlFatura,,,,,,.T.,CLR_BLACK,,200,9 )
		
		oPnlGrid := tPanel():New(100,10,,oDlgAuxFat,,,,,,230,nPixHAcess+5)
		::DoNewGetVlA(oPnlGrid)

	else
		TSay():New( 90, 10, {|| "Aluguel POS (-):" }, oPnlFatura,,,,,,.T.,CLR_BLACK,,50,9 )
		TGet():New( 88, 85+nPixWAcess, {|u| iif( PCount()==0,::nVlrAlug,::nVlrAlug:= u) }, oPnlFatura,55,9,PesqPict("SE1","E1_DECRESC"),/*bValid*/,,,,.F.,,.T.,,.F.,{|| .T.},.F.,.F.,{|| ::AtTotAux(lTxAcessor) }/*bChange*/,.F.,.F.,,"E1_DECRESC",,,,.T.,.F.)

		TSay():New( 103, 10, {|| "Outras Desp. (-):" }, oPnlFatura,,,,,,.T.,CLR_BLACK,,50,9 )
		TGet():New( 101, 85+nPixWAcess, {|u| iif( PCount()==0,::nVlrOutr,::nVlrOutr:= u) }, oPnlFatura,55,9,PesqPict("SE1","E1_DECRESC"),/*bValid*/,,,,.F.,,.T.,,.F.,{|| .T.},.F.,.F.,{|| ::AtTotAux(lTxAcessor) }/*bChange*/,.F.,.F.,,"E1_DECRESC",,,,.T.,.F.)
	endif

	TSay():New( 116 + nPixHAcess, 10, {|| "Vlr Total Fatura:" }, oPnlFatura,,,,,,.T.,CLR_BLACK,,50,9 )
	_oTotAux := TGet():New( 114 + nPixHAcess, 85+nPixWAcess, {|u| iif( PCount()==0,::nVlrTotal,::nVlrTotal:= u) }, oPnlFatura,55,9,PesqPict("SE1","E1_VALOR"),/*bValid*/,,,,.F.,,.T.,,.F.,{|| .F.},.F.,.F.,/*bChange*/,.F.,.F.,,"E1_VALOR",,,,.F.,.T.)

	TSay():New( 129 + nPixHAcess, 10, {|| "Data Recebimento" }, oPnlFatura,,,,,,.T.,CLR_BLACK,,50,9 )
	TGet():New( 127 + nPixHAcess, 85+nPixWAcess, {|u| iif( PCount()==0,::dVencFat,::dVencFat:= u) }, oPnlFatura,55,9,,/*bValid*/,,,,.F.,,.T.,,.F.,{|| .T.},.F.,.F.,/*bChange*/,.F.,.F.,,"E1_VENCTO",,,,.T.,.T.)

	TSay():New( 142 + nPixHAcess, 10, {|| "Observações" }, oPnlFatura,,,,,,.T.,CLR_BLACK,,50,9 )
	TGet():New( 151 + nPixHAcess, 10, {|u| iif( PCount()==0,::cObserv,::cObserv:= u) }, oPnlFatura,130+nPixWAcess,9,,/*bValid*/,,,,.F.,,.T.,,.F.,{|| .T.},.F.,.F.,/*bChange*/,.F.,.F.,,"E1_HIST",,,,.T.,.F.)

    TSay():New( 177 + nPixHAcess, 10, {|| "Confirma Faturamento?" }, oPnlFatura,,,,,,.T.,CLR_BLUE,,140,9 )

	@ 190 + nPixHAcess, 105+nPixWAcess BUTTON oButton2 PROMPT "Confirmar" SIZE 040, 012 OF oPnlFatura ACTION iif( ::ValidFatu(), (nOpcx := 1,oDlgAuxFat:End()) ,) PIXEL
    @ 190 + nPixHAcess, 060+nPixWAcess BUTTON oButton3 PROMPT "Cancelar" SIZE 040, 012 OF oPnlFatura ACTION (nOpcx := 0,oDlgAuxFat:End()) PIXEL

	ACTIVATE MSDIALOG oDlgAuxFat CENTERED

	if nOpcx == 1
		lRet := .T.

		if lTxAcessor
			for nX := 1 to len(::oGetVlAces:aCols)
				if ::oGetVlAces:aCols[nX][3] > 0
					aAdd(::aValAcess, {::oGetVlAces:aCols[nX][5], ::oGetVlAces:aCols[nX][3]}) 
				endif
			next nX
		endif
	endif

Return lRet

//---------------------------------------------------------------
// Valida tela dados adicionais da fatura
//---------------------------------------------------------------
METHOD ValidFatu() CLASS UT019ABA

	Local lRet := .T.

	if !empty(::dVencFat) .AND. ::dVencFat < dDatabase
		MsgInfo("Data de Recebimento deve ser maior que data base do sistema.","Atençao")
		lRet := .F.
	endif

Return lRet

//---------------------------------------------------------------
// Atualiza total da telinha auxiliar da fatura
//---------------------------------------------------------------
METHOD AtTotAux(lTxAcessor) CLASS UT019ABA

	Local nX, nVlrAcess
	Default lTxAcessor := .F.

	::nVlrTotal := ::nVlrBruto - ::nVlrTaxas - ::nVlrDesc + ::nVlrAcre - ::nVlrAlug - ::nVlrOutr

	if lTxAcessor
		For nX := 1 to len(::oGetVlAces:aCols)
			
			nVlrAcess := ::oGetVlAces:aCols[nX][3]
			if nVlrAcess > 0
				if ::oGetVlAces:aCols[nX][4] == '1'  //percentual
					if ::oGetVlAces:aCols[nX][2] == '-'
						::nVlrTotal -= Round((::nVlrBruto - ::nVlrTaxas) * (nVlrAcess / 100), 2)
					else
						::nVlrTotal += Round((::nVlrBruto - ::nVlrTaxas) * (nVlrAcess / 100), 2)
					endif
				elseif ::oGetVlAces:aCols[nX][4] == '2'  //valor
					if ::oGetVlAces:aCols[nX][2] == '-'
						::nVlrTotal -= nVlrAcess
					else
						::nVlrTotal += nVlrAcess
					endif
				endif
			endif
			
		next nX
	endif

	_oTotAux:Refresh()

Return .T.

//---------------------------------------------------------------
// Faz montagem do NewGetDados Valores acessorios
//---------------------------------------------------------------
METHOD DoNewGetVlA(oPnl) CLASS UT019ABA

	Local aAlterFields := {"FKD_VALOR"}
	Local aHeadTmp := {}
	Local cTrue := "AllwaysTrue"
	Local aHeader := {}
	Local aColsEx := {}
	Local aEmptyLin := {}

	aHeadTmp := U_UAHEADER("FKC_DESC")
	aHeadTmp[4] := 25
	aadd(aHeader, aClone(aHeadTmp) )
	aAdd(aEmptyLin, Space(40))

	Aadd(aHeader,{ ' ','SINAL','@!',1,0,'','€€€€€€€€€€€€€€','C','','','',''})
	aAdd(aEmptyLin, " " )

	aHeadTmp := U_UAHEADER("FKD_VALOR")
	aHeadTmp[4] := 12
	aHeadTmp[6] := "Positivo(M->FKD_VALOR) .AND. Eval(bVldVlrAces, M->FKD_VALOR)"
	aadd(aHeader, aClone(aHeadTmp) )
	aAdd(aEmptyLin, 0 )

	aHeadTmp := U_UAHEADER("FKC_TPVAL")
	aadd(aHeader, aClone(aHeadTmp) )
	aAdd(aEmptyLin, Space(1) )

	aHeadTmp := U_UAHEADER("FKD_CODIGO")
	aadd(aHeader, aClone(aHeadTmp) )
	aAdd(aEmptyLin, Space(6) )

	aAdd(aEmptyLin, .F.) //deleted

	//Busco os valores acessorios na base
	If Select("QRYFKC") > 0
		QRYFKC->(DbCloseArea())
	Endif

	cQry := " SELECT FKC_CODIGO, FKC_DESC, FKC_ACAO, FKC_TPVAL "
	cQry += " FROM "+RetSqlName("FKC")+"  "
	cQry += " WHERE D_E_L_E_T_ = ' ' "
	cQry += " 	AND FKC_FILIAL = '"+xFilial("FKC")+"' "
	cQry += " 	AND FKC_ATIVO = '1' " //so ativos
	cQry += " 	AND FKC_APLIC = '3' " //fixa
	cQry += " 	AND FKC_PERIOD = '1' " //periodo unico
	cQry += "	AND FKC_RECPAG IN ('2','3') " //carteira receber ou ambas
	cQry += "	AND FKC_XTXCAR = 'S' " //carteira receber ou ambas
	cQry += " ORDER BY FKC_CODIGO "

	cQry := ChangeQuery(cQry)
	TcQuery cQry NEW Alias "QRYFKC"
	if QRYFKC->(!Eof())
		while QRYFKC->(!Eof())

			aadd(aColsEx, {;
				QRYFKC->FKC_DESC ,;
				iif(QRYFKC->FKC_ACAO == '2', "-", "+") ,;
				0,;
				QRYFKC->FKC_TPVAL ,;
				QRYFKC->FKC_CODIGO ,;
				.F. ; //deleted
			})

			QRYFKC->(DbSkip())
		enddo
	endif
	QRYFKC->(DbCloseArea())

	if empty(aColsEx)
		aadd(aColsEx, aEmptyLin)
	endif

	::oGetVlAces := MsNewGetDados():New( 000,000,100,100,GD_UPDATE,;
			cTrue, cTrue,, aAlterFields,, 999, cTrue, "", cTrue, oPnl, aHeader, aColsEx)
	::oGetVlAces:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT

Return

//---------------------------------------------------------------
// Faz busca dos títulos a receber que serão comparados ao arquivo de importação
//---------------------------------------------------------------
METHOD DoQryTitulos(_dDtEmis1, _dDtEmis2, _cBandeira, _cTipCard) CLASS UT019ABA

	Local cQry := ""
	Local cAdmFin := ""
	Local nX
	Local nPosBand := 0

	if empty(_cBandeira) //se nao tem bandeira no filtro
		cAdmFin := "'"+::aAdmFin[1]+"'"
		for nX := 2 to len(::aAdmFin)
			cAdmFin += ",'"+::aAdmFin[nX]+"'"
		next nX
	else
		nPosBand := aScan(::aAdmBand, {|x| x[1] == _cBandeira }) //posição das adm fin da bandeira
		if nPosBand > 0
			cAdmFin := "'"+::aAdmBand[nPosBand][2][1]+"'"
			for nX := 2 to len(::aAdmBand[nPosBand][2])
				cAdmFin += ",'"+::aAdmBand[nPosBand][2][nX]+"'"
			next nX
		endif
	endif

	If Select("QRYSE1") > 0
		QRYSE1->(DbCloseArea())
	Endif

	if !empty(cAdmFin)
		cQry := " SELECT SE1.R_E_C_N_O_ "
		cQry += " FROM "+RetSqlName("SE1")+" SE1 "
		cQry += " WHERE SE1.D_E_L_E_T_ <> '*' "
		cQry += " 	AND E1_FILIAL = '"+xFilial("SE1")+"' "
		cQry += " 	AND E1_EMISSAO BETWEEN '"+dtos(_dDtEmis1)+"' AND '"+dtos(_dDtEmis2)+"' "
		//TODO: trocar busca pelo campo E1_ADM
		cQry += " 	AND LTRIM(RTRIM(E1_CLIENTE)) IN ("+cAdmFin+") "
		cQry += " 	AND E1_STATUS = 'A' " //para trazer apenas titulos em aberto
		cQry += "	AND E1_SALDO > 0 " //com saldo
		If UPPER(AllTrim(_cTipCard)) == "CC"
			cQry += " 	AND E1_TIPO IN ('CC ') " //add para trazer somente titulos de cartao de credito
		ElseIf UPPER(AllTrim(_cTipCard)) == "CD"
			cQry += " 	AND E1_TIPO IN ('CD ') " //add para trazer somente titulos de cartao de debito
		Else
			cQry += " 	AND E1_TIPO IN ('CC ','CD ') " //add para trazer somente titulos de cartao
		EndIf
		If !Empty(cFilTaSE1)
   			cQry += " AND " + cFilTaSE1
   		EndIf
		//cQry += "	AND E1_TIPO NOT IN ('RA ','NCC') " //fora adiantamentos
		cQry += " ORDER BY E1_EMISSAO, E1_PREFIXO, E1_NUM, E1_PARCELA, E1_TIPO "

		cQry := ChangeQuery(cQry)
		TcQuery cQry NEW Alias "QRYSE1"
		if QRYSE1->(!Eof())
			while QRYSE1->(!Eof())

				if aScan(::aTitulos, QRYSE1->R_E_C_N_O_) == 0
					aadd(::aTitulos, QRYSE1->R_E_C_N_O_)
				endif

				QRYSE1->(DbSkip())
			enddo
		endif

		QRYSE1->(DbCloseArea())
	else
		MsgAlert("Não foi encontradas administradoras amarradas a operadora e bandeira informadas.","Atençao")
	endif
Return

//---------------------------------------------------------------
// faz importação do extrato da operadora
//---------------------------------------------------------------
METHOD DoImpExtrato() CLASS UT019ABA

	Local lRet := .T.
	Local nX := 0
	Local nPosValE
	Local lVerSac := SuperGetMV("MV_XCTRSAC",,.F.) //define se irá sugerir troca de sacado durante a importação do extrato

	//aFiles={{_cArquivo, _dDtEmis1, _dDtEmis2, _lConsCab, _cBandeira, _cNmBand, _cTipCard}...}
	For nX := 1 to len(::aFiles) //todos os arquivos

		if lRet
			DbSelectArea("U98")
			U98->(DbSetOrder(2))
			U98->(DbSeek(xFilial("U98")+::cCodLay))

			if U98->U98_TIPARQ == "1" //1=TXT
				lRet := ::DoImpTXT(::aFiles[nX])
			elseif U98->U98_TIPARQ == "2" //2=CSV
				lRet := ::DoImpCSV(::aFiles[nX])
			elseif U98->U98_TIPARQ == "3" .OR. U98->U98_TIPARQ == "4" //3=XLS ; 4=XLSX
				lRet := ::DoImpXLS(::aFiles[nX])
			endif

			If lRet .AND. lVerSac
				::DoVerSacado(::aFiles[nX][1],::aFiles[nX][5]) // GMdS
			EndIf

			if lRet
				::DoQryTitulos(::aFiles[nX][2], ::aFiles[nX][3], ::aFiles[nX][5], ::aFiles[nX][7]) //faz busca de títulos
			endif
		endif

	Next nX

	if lRet
		::DoComparaArq() //faz comparação entre extrato e titulos

		//Excluindo itens extrato negativos
		nPosValE := aScan(::aHeaderExt,{|x| AllTrim(x[2]) == alltrim(::cCpVlrEx) })
		For nX := 1 to len(::aDadosExt)
			if ::aDadosExt[nX][nPosValE] <= 0
				::aDadosExt[nX][len(::aDadosExt[nX])] := .T.
			endif
		next nX
		::oMSNewGeEx:oBrowse:Refresh()

		//busca titulos pelo primeiro nivel que talvez se encaixe aos itens inconsistentes
		If lVerSac
			For nX := 1 to len(::aFiles) //todos os arquivos
				::DoVerSacado(::aFiles[nX][1], ::aFiles[nX][5], .T., ::aFiles[nX][7]) // GMdS
			Next nX
		endif
	endif
	
Return lRet

//---------------------------------------------------------------
// faz importação do extrato da operadora
// aFile = {_cArquivo, _dDtEmis1, _dDtEmis2, _lConsCab, _cBandeira, _cNmBand, _cTipCard}
//---------------------------------------------------------------
METHOD DoImpTXT(aFile) CLASS UT019ABA

	Local lRet := .T.
	Local nHdl := FT_FUse(aFile[1])
	Local nCount := 0
	Local cLinha := ""
	Local nPosField := 0
	Local cCampo := ""
	Local aExtTmp := {}
	Local lLinNotImp := .F.

	//se houve erro na abertura do arquivo
	If nHdl == -1
	    MsgAlert("O arquivo de nome "+aFile[1]+" nao pode ser aberto!","Atencao!")
	    Return .F.
	Endif

	// Posiciona na primeira linha
	FT_FGoTop()

	if !aFile[4] .AND. !FT_FEOF()
		FT_FSKIP() // Se Pula cabeçalho
	endif

	While !FT_FEOF()
		cLinha  := FT_FReadLn() // lê a linha

		//verifica se a linha está em branco, se estiver pula
		If Empty(AllTrim(cLinha))
			FT_FSkip()
			Loop
		EndIf

		aExtTmp := {}
		lLinNotImp := .F.

		//lendo estrutura do arquivo
		DbSelectArea("U99")
	 	U99->(DbSetOrder(1))
		if U99->(DbSeek(xFilial("U99")+::cOperad+::cCodLay))
			while U99->(!Eof()) .AND. U99->U99_FILIAL+U99->U99_OPERAD+U99->U99_CODIGO == xFilial("U99")+::cOperad+::cCodLay

				if ((U99->U99_POSINI+U99->U99_TAMANH) <= 0 .OR. (U99->U99_POSINI+U99->U99_TAMANH-1) > len(cLinha) )
					//MsgAlert("O arquivo de nome "+aFile[1]+" nao está estruturado conforme cadastro Operadora X Layout!","Atencao!")
					//Conout("#TRETA019 TXT: U99->U99_POSINI+U99->U99_TAMANH = "+STR(U99->U99_POSINI+U99->U99_TAMANH) + " #### len(cLinha) = " + Str(len(cLinha)))
					//lRet := .F.
					lLinNotImp := .T.
					EXIT
				endif

				if U99->U99_UTILIZ == "C" //comparação pega da X3
					cCampo := alltrim(U99->U99_CAMPO)
				elseif U99->U99_UTILIZ == "V"
					cCampo := alltrim(U99->U99_CAMPO)+U99->U99_ITEM
				endif

				nPosField := aScan(::aHeaderExt,{|x| AllTrim(x[2])==cCampo})

				if U99->U99_VLRREC == "S" .AND. AjustaValor(substr(cLinha,U99->U99_POSINI,U99->U99_TAMANH), ::aHeaderExt[nPosField][8],,,.T.) == 0
					//Conout("Linha "+alltrim(str(nCount+1))+" do extrato não poderá ser importada por não estar de acordo com layout.")
					lLinNotImp := .T.
					EXIT
				endif

				//AjustaValor(cValor, cTipo, nPosIni, nTam, lParDecNum)
				aadd(aExtTmp, {::aHeaderExt[nPosField][2], AjustaValor(substr(cLinha,U99->U99_POSINI,U99->U99_TAMANH), ::aHeaderExt[nPosField][8],,,.T.), U99->U99_UTILIZ=="C", U99->U99_NVPESQ} )

				if empty(::cCpVlrEx) .AND. U99->U99_VLRREC == "S"
					::cCpVlrEx := cCampo
					if U99->U99_UTILIZ == "C"
						::cCpVlrDiv := alltrim(U99->U99_CAMPO)
					endif
				endif

		   		U99->(DbSkip())
			enddo
		endif

		if !lRet
			EXIT
		endif

		if !lLinNotImp
			//adicionando item no array
			aadd(aExtTmp, {"R_E_C_N_O_", len(::aExtrato)+1, .F. ,""} )
			aadd(::aExtrato, aExtTmp)
		endif

		nCount++

		FT_FSKIP() // Pula para próxima linha
	Enddo

	if len(::aExtrato) == 0
		MsgAlert("Não foi possível encontrar linhas no extrato configuradas conforme layout.","Atencao!")
		lRet := .F.
	endif

	if lRet .AND. empty(::cCpVlrEx)
		MsgAlert("Layout "+Alltrim(::cNmLayout)+" não tem uma coluna de valor a receber. Verifique cadastro Operadora X Layout.","Atencao!")
	    lRet := .F.
	endif

	// Fecha o arquivo
	FT_FUSE()

Return lRet

//---------------------------------------------------------------
// faz importação do extrato da operadora
// aFile = {_cArquivo, _dDtEmis1, _dDtEmis2, _lConsCab, _cBandeira, _cNmBand, _cTipCard}
//---------------------------------------------------------------
METHOD DoImpCSV(aFile) CLASS UT019ABA

	Local lRet := .T.
	Local nHdl := FT_FUse(aFile[1])
	Local nCount := 0
	Local cLinha := ""
	Local aLinha := {}
	Local nPosField := 0
	Local cCampo := ""
	Local aExtTmp := {}
	Local lLinNotImp := .F.

	//se houve erro na abertura do arquivo
	If nHdl == -1
	    MsgAlert("O arquivo de nome "+aFile[1]+" nao pode ser aberto!","Atencao!")
	    Return .F.
	Endif

	// Posiciona na primeira linha
	FT_FGoTop()

	if !aFile[4] .AND. !FT_FEOF()
		FT_FSKIP() // Se Pula cabeçalho
	endif

	While !FT_FEOF()
		cLinha  := FT_FReadLn() // lê a linha

		//verifica se a linha está em branco, se estiver pula
		If Empty(AllTrim(StrTran(cLinha,';','')))
			FT_FSkip()
			Loop
		EndIf

		aLinha 	:= StrTokArr2(cLinha, ";", .T.)
		aExtTmp := {}
		lLinNotImp := .F.

		//lendo estrutura do arquivo
		DbSelectArea("U99")
	 	U99->(DbSetOrder(1))
		if U99->(DbSeek(xFilial("U99")+::cOperad+::cCodLay))
			while U99->(!Eof()) .AND. U99->U99_FILIAL+U99->U99_OPERAD+U99->U99_CODIGO == xFilial("U99")+::cOperad+::cCodLay

				if (empty(U99->U99_COLUNA) .OR. val(U99->U99_COLUNA) <= 0 .OR. val(U99->U99_COLUNA) > len(aLinha) )
					//Conout("#TRETA019 CSV: Linha ignorada -> U99_COLUNA = "+U99->U99_COLUNA + " #### len(aLinha) = " + Str(len(aLinha)))
					lLinNotImp := .T.
					EXIT
				endif

				if U99->U99_UTILIZ == "C" //comparação pega da X3
					cCampo := alltrim(U99->U99_CAMPO)
				elseif U99->U99_UTILIZ == "V"
					cCampo := alltrim(U99->U99_CAMPO)+U99->U99_ITEM
				endif

				nPosField := aScan(::aHeaderExt,{|x| AllTrim(x[2])==cCampo})

				if U99->U99_VLRREC == "S" .AND. AjustaValor(aLinha[val(U99->U99_COLUNA)], ::aHeaderExt[nPosField][8]) == 0
					//Conout("Linha "+alltrim(str(nCount+1))+" do extrato não poderá ser importada por não estar de acordo com layout.")
					lLinNotImp := .T.
					EXIT
				endif

				//AjustaValor(cValor, cTipo, nPosIni, nTam)
				aadd(aExtTmp, {::aHeaderExt[nPosField][2], AjustaValor(aLinha[val(U99->U99_COLUNA)], ::aHeaderExt[nPosField][8], U99->U99_POSINI, U99->U99_TAMANH), U99->U99_UTILIZ=="C", U99->U99_NVPESQ } )

				if empty(::cCpVlrEx) .AND. U99->U99_VLRREC == "S"
					::cCpVlrEx := cCampo
					if U99->U99_UTILIZ == "C"
						::cCpVlrDiv := alltrim(U99->U99_CAMPO)
					endif
				endif

		   		U99->(DbSkip())
			enddo
		endif

		if !lRet
			EXIT
		endif

		if !lLinNotImp
			//adicionando item no array
			aadd(aExtTmp, {"R_E_C_N_O_", len(::aExtrato)+1, .F. ,""} )
			aadd(::aExtrato, aExtTmp)
		endif

		nCount++

		FT_FSKIP() // Pula para próxima linha
	Enddo

	if len(::aExtrato) == 0
		MsgAlert("Não foi possível encontrar linhas no extrato configuradas conforme layout.","Atencao!")
		lRet := .F.
	endif

	if lRet .AND. empty(::cCpVlrEx)
		MsgAlert("Layout "+Alltrim(::cNmLayout)+" não tem uma coluna de valor a receber. Verifique cadastro Operadora X Layout.","Atencao!")
	    lRet := .F.
	endif

	// Fecha o arquivo
	FT_FUSE()

Return lRet

//---------------------------------------------------------------
// faz importação do extrato da operadora
// aFile = {_cArquivo, _dDtEmis1, _dDtEmis2, _lConsCab, _cBandeira, _cNmBand, _cTipCard}
//---------------------------------------------------------------
METHOD DoImpXLS(aFile) CLASS UT019ABA

	Local lRet := .T.
	Local aDados := {}
	Local oXls2Csv
	Local nX, nY
	Local aExtTmp := {}
	Local cCampo := ""
	Local nCount := 0
	Local nPosField := 0
	Local nColXls := 0
	Local cColunas := "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
	Local nLoop
	Local lLinNotImp := .F.

	//cria objeto
	oXls2Csv := XLS2CSV():New( aFile[1] )

	For nLoop := 1 to 3 //faz tres tentativas para abrir arquivo
		if oXls2Csv:Import() //processa importação dos dados, gerando arquivo CSV
			aDados := oXls2Csv:GetArray(iif(!aFile[4]/*_lConsCab*/,1,0)) //transforma arquivo CSV em array

			if len(aDados) > 0

				For nX := 1 to len(aDados)
					aExtTmp := {}
					lLinNotImp := .F.

					//lendo estrutura do arquivo
					DbSelectArea("U99")
				 	U99->(DbSetOrder(1))
					if U99->(DbSeek(xFilial("U99")+::cOperad+::cCodLay))
						while U99->(!Eof()) .AND. U99->U99_FILIAL+U99->U99_OPERAD+U99->U99_CODIGO == xFilial("U99")+::cOperad+::cCodLay

							//descobirndo posição da coluna do excel no vetor
							nColXls := 0
							for nY := 1 to len(alltrim(U99->U99_COLUNA))
								nColXls += AT(substr(alltrim(U99->U99_COLUNA),nY,1), cColunas)
							next nY

							if nCount == 0 .AND. nColXls <= 0
								MsgAlert("O cadastro Operadora X Layout não está configurado corretamente. Erro nas parametrização das colunas do arquivo Excel.","Atencao!")
								lRet := .F.
								EXIT
							endif

							if nColXls > len(aDados[nX])
								//Conout("#TRETA019 XLS Ignorada: nColXls = "+STR(nColXls) + " #### len(aDados[nX]) = " + Str(len(aDados[nX])))
								lLinNotImp := .T.
								EXIT
							endif

							if U99->U99_UTILIZ == "C" //comparação pega da X3
								cCampo := alltrim(U99->U99_CAMPO)
							elseif U99->U99_UTILIZ == "V"
								cCampo := alltrim(U99->U99_CAMPO)+U99->U99_ITEM
							endif

							nPosField := aScan(::aHeaderExt,{|x| AllTrim(x[2])==cCampo})

							if U99->U99_VLRREC == "S" .AND. AjustaValor(aDados[nX][nColXls], ::aHeaderExt[nPosField][8]) == 0
								//Conout("Linha "+alltrim(str(nCount+1))+" do extrato não poderá ser importada por não estar de acordo com layout.")
								lLinNotImp := .T.
								EXIT
							endif

							//AjustaValor(cValor, cTipo, nPosIni, nTam)
							aadd(aExtTmp, {::aHeaderExt[nPosField][2], AjustaValor(aDados[nX][nColXls], ::aHeaderExt[nPosField][8], U99->U99_POSINI, U99->U99_TAMANH), U99->U99_UTILIZ=="C", U99->U99_NVPESQ } ) // GIANLUKA MORAES

							if empty(::cCpVlrEx) .AND. U99->U99_VLRREC == "S"
								::cCpVlrEx := cCampo
								if U99->U99_UTILIZ == "C"
									::cCpVlrDiv := alltrim(U99->U99_CAMPO)
								endif
							endif

					   		U99->(DbSkip())
						enddo
					endif

					if !lRet
						EXIT
					endif

					if !lLinNotImp
						//adicionando item no array
						aadd(aExtTmp, {"R_E_C_N_O_", len(::aExtrato)+1, .F. ,""} )
						aadd(::aExtrato, aExtTmp)
					endif

					nCount++

				next nX

				if len(::aExtrato) == 0
					MsgAlert("Não foi possível encontrar linhas no extrato configuradas conforme layout.","Atencao!")
					lRet := .F.
				endif

				if lRet .AND. empty(::cCpVlrEx)
					MsgAlert("Layout "+Alltrim(::cNmLayout)+" não tem uma coluna de valor a receber. Verifique cadastro Operadora X Layout.","Atencao!")
				    lRet := .F.
				endif

				EXIT
			else
				//Conout("#TRETA019 XLS *2: nLoop = "+STR(nLoop) )
				if nLoop == 3
					MsgAlert("Não foi possível abrir arquivo "+aFile[1]+".","Atencao!")
					lRet := .F.
				else
					Sleep(1000) //Aguarda 1 segundo e tenta novamente
				endif
			endif
		else
			EXIT
			lRet := .F.
		endif
	next nLoop

	oXls2Csv:Destroy() //limpla objeto e exclui arquivo CSV gerado na pasta temp

Return lRet

//---------------------------------------------------------------
// faz ajuste do valor lido do arquivo de acordo com o tipo e tamanho
//---------------------------------------------------------------
Static Function AjustaValor(cValor, cTipo, nPosIni, nTam, lParDecNum)

	Local xValue := Nil
	Local nMV_XDECIMP := SuperGetMv("MV_XDECIMP",,2) //define quantas casas decimais terá o campo valor
	Default nPosIni := 0
	Default nTam := 0
	Default lParDecNum := .F. //define se coloca decimais em numero 

	if nPosIni <= 0
		nPosIni := 1
	endif

	if nTam <= 0
		nTam := len(alltrim(cValor))
	endif

	if alltrim(cTipo) == "C" //se caractere
		xValue := substr(cValor,nPosIni,nTam)
    elseif alltrim(cTipo) == "N" //se numerico
    	if valtype(cValor) != "N"
			if lParDecNum
				cValor := SubStr(cValor,1,len(cValor)-nMV_XDECIMP)+","+Right(cValor,nMV_XDECIMP)
			endif
    		cValor := U_MyNoChar(cValor,"0123456789,")
    		cValor := StrTran(cValor,",",".")
			xValue := val(cValor)
		else
			xValue := cValor
		endif
    elseif alltrim(cTipo) == "D" //se data
    	if valtype(cValor) != "D"
	    	cValor := substr(cValor,nPosIni,nTam)
			//tenta formato DD/MM/AAAA
	    	xValue := CTOD(cValor)
			if empty(xValue) //se data vazia, tenta novamente, formato AAAAMMDD
	    		xValue := STOD(cValor)
	    	endif
			if empty(xValue) //se data vazia, tenta novamente, formato DDMMAAAA
	    		xValue := CTOD(SubStr(cValor,1,2) + "/" + SubStr(cValor,3,2) + "/" + SubStr(cValor,5,4) )
	    	endif
	    else
		    xValue := cValor
	    endif
    endif

Return xValue

//---------------------------------------------------------------
// faz comparação dados do extrato e titulos
//---------------------------------------------------------------
METHOD DoComparaArq() CLASS UT019ABA

	Local nX := 0, nY := 0
	Local aRecTitOk := {}
	Local aRecExtOk := {}
	Local cCompara 	:= ""
	Local nRecExt	:= 0
	Local lNvSecu   := .F.

	Private aCompara	:= {}

	DbSelectArea("SE1")

	//Comparando dados
	for nX := 1 to len(::aExtrato)

		// Gianluka Moraes | Valida se esta preenchido o nivel de pesquisa.
		lNvSecu := aScan(::aExtrato[nX], {|x| x[4] == "2" }) > 0

		cCompara := ""
		aCompara := {}
		nRecExt	:= ::aExtrato[nX][len(::aExtrato[nX])][2]

		//procurando titulo na SE1 compatível
		For nY := 1 to len(::aTitulos)
			
			//primeira busca considera todos campos comparação
			aCompara := {}
			cCompara := DoCriaMacro(,::aExtrato,nX,::nXMrgVal)

			SE1->(DbGoTo(::aTitulos[nY])) //posiciona a partir do recno

			If &(cCompara) //se comparação é válida,
				If aScan(aRecTitOk, SE1->(Recno())) == 0 //se nao encontrou

					aAdd(aRecTitOk, SE1->(Recno()))
					aAdd(aRecExtOk, nRecExt)

					::DoRelaciona(SE1->(Recno()), nRecExt)
					EXIT
				EndIf
			Elseif lNvSecu //se não encontrou, tenta só com campos nivel scundario
				aCompara := {}
				cCompara := DoCriaMacro("2",::aExtrato,nX,::nXMrgVal)
				If &(cCompara) //se comparação é válida,
					If aScan(aRecTitOk, SE1->(Recno())) == 0 //se nao encontrou

						aAdd(aRecTitOk, SE1->(Recno()))
						aAdd(aRecExtOk, nRecExt)

						::DoRelaciona(SE1->(Recno()), nRecExt)
						EXIT
					Endif
				EndIf
			EndIf

		Next nY

	Next nX

	//preenchendo titulos sem vinculo, no grid inconsitencias
	For nX := 1 to Len(::aTitulos)
		If aScan(aRecTitOk, ::aTitulos[nX]) == 0 //se nao encontrou
			::DoAddTitInc(::aTitulos[nX])
		EndIf
	Next nX

	//preenchendo itens do extrato sem vínculo, no grid inconsistencias
	For nX := 1 To Len(::aExtrato)
		If aScan(aRecExtOk, ::aExtrato[nX][Len(::aExtrato[nX])][2]) == 0 //se nao encontrou
			::DoAddExtInc(::aExtrato[nX][Len(::aExtrato[nX])][2])
		EndIf
	Next nX

	::oMSNewGeEx:oBrowse:Refresh()
	::DoAtuTotal()
Return

//---------------------------------------------------------------
// faz atualização dos totalizadores
//---------------------------------------------------------------
METHOD DoAtuTotal() CLASS UT019ABA

	Local nX
	Local nPosValT := 0
	Local nPosAcres := 0
	Local nPosDecres := 0
	Local nPosValE := 0
	Local nPosBand := 0
	Local nPosAdmF := 0

	::nVlrTotal := 0 //total fatura
	::nVlrBruto := 0 //total bruto fatura
	::nVlrTaxas := 0 //valor das taxas

	//zerando totalizadores gerais
	::nQtdGer	:= 0
	::nQtdInc	:= 0
	::nQtdArq	:= 0
	::nQtdSel	:= 0
	::nVlTotE1Ger := 0
	::nVlTotE1Inc := 0
	::nVlTotE1Sel := 0
	::nVlTotBE1Ger := 0
	::nVlTotBE1Inc := 0
	::nVlTotBE1Sel := 0
	::nVlTotExGer := 0
	::nVlTotExInc := 0
	::nVlTotExSel := 0

	For nX := 1 to len(::aBandeiras)
		//::aBandeiras {{cCodBand, oImagem, cImagem, oTipoOp, cTipoOp, oTotGeral, nTotGeral},...}
		::aBandeiras[nX][7] := 0
	next nX

	DbSelectArea("SAE")
	SAE->(DbSetOrder(1))

	//Executando totalizadores
	//somando variáveis da aba principal
	nPosValT := aScan(::aHeader,{|x| AllTrim(x[2]) == "E1_VALOR" })
	nPosValR := aScan(::aHeader,{|x| AllTrim(x[2]) == "E1_VLRREAL" })
	nPosAcres := aScan(::aHeader,{|x| AllTrim(x[2]) == "E1_ACRESC" })
	nPosDecres := aScan(::aHeader,{|x| AllTrim(x[2]) == "E1_DECRESC" })
	//TODO: trocar posicao pelo campo E1_ADM
	nPosAdmF := aScan(::aHeader,{|x| AllTrim(x[2]) == "E1_CLIENTE" })

	nPosValE := aScan(::aHeader,{|x| AllTrim(x[2]) == "E1_VALORE" })
	if empty(nPosValE)
		nPosValE := aScan(::aHeader,{|x| AllTrim(x[2]) == alltrim(::cCpVlrEx) })
	endif

    For nX := 1 to len(::aDados)
    	if ::aDados[nX][len(::aHeader)+1] > 0
	    	::nQtdGer++ //incrementa quantidade geral
			//if alltrim(::cCpVlrEx) == "E1_VALOR"
	    		::nVlTotE1Ger += ::aDados[nX][nPosValT] + ::aDados[nX][nPosAcres] - ::aDados[nX][nPosDecres]
			//else
				::nVlTotBE1Ger += ::aDados[nX][nPosValR] + ::aDados[nX][nPosAcres] - ::aDados[nX][nPosDecres]
			//endif
            If nPosValE>0
            	::nVlTotExGer += ::aDados[nX][nPosValE]
	    	Endif

	        //incrementa quantidade selecionada
	    	if ::aDados[nX][1] == "LBOK"
	    		::nQtdSel++
				//if alltrim(::cCpVlrEx) == "E1_VALOR"
	    			::nVlTotE1Sel += ::aDados[nX][nPosValT] + ::aDados[nX][nPosAcres] - ::aDados[nX][nPosDecres]
				//else
					::nVlTotBE1Sel += ::aDados[nX][nPosValR] + ::aDados[nX][nPosAcres] - ::aDados[nX][nPosDecres]
				//endif
	    		If nPosValE>0
	    			::nVlTotExSel += ::aDados[nX][nPosValE]
	    		Endif
	    		::nVlrBruto   += ::aDados[nX][nPosValR]
	    		::nVlrTaxas   += ::aDados[nX][nPosValR] - ::aDados[nX][nPosValT] + ::aDados[nX][nPosAcres] - ::aDados[nX][nPosDecres]
	    	endif

	    	if SAE->(DbSeek(xFilial("SAE")+Alltrim(::aDados[nX][nPosAdmF])))
	    		nPosBand := aScan(::aBandeiras,{|x| AllTrim(x[1]) == alltrim(SAE->AE_ADMCART) })
	    		if nPosBand > 0
					if alltrim(::cCpVlrEx) == "E1_VALOR"
						::aBandeiras[nPosBand][7] += ::aDados[nX][nPosValT] + ::aDados[nX][nPosAcres] - ::aDados[nX][nPosDecres]
					else
						::aBandeiras[nPosBand][7] += ::aDados[nX][nPosValR] + ::aDados[nX][nPosAcres] - ::aDados[nX][nPosDecres]
					endif
	    		endif
	    	endif
	    endif
    next nX

    //somando variaveis de inconsitencias
    nPosValT := aScan(::aHeaderSE1,{|x| AllTrim(x[2]) == alltrim("E1_VALOR") })
    nPosValR := aScan(::aHeaderSE1,{|x| AllTrim(x[2]) == alltrim("E1_VLRREAL") })
	nPosValE := aScan(::aHeaderExt,{|x| AllTrim(x[2]) == alltrim(::cCpVlrEx) })
    For nX := 1 to len(::aDadosSE1)
    	if ::aDadosSE1[nX][len(::aHeaderSE1)+1] > 0
	    	::nQtdInc++
	    	::nVlTotE1Inc += ::aDadosSE1[nX][nPosValT]
			::nVlTotBE1Inc += ::aDadosSE1[nX][nPosValR]
	    endif
    next nX
    For nX := 1 to len(::aDadosExt)
    	if ::aDadosExt[nX][len(::aHeaderExt)+1] > 0
			::nQtdArq++
	    	If nPosValE>0
	    	::nVlTotExInc += ::aDadosExt[nX][nPosValE]
	    	Endif
	    endif
    next nX

    //total da fatura a ser gerada
    ::nVlrTotal := ::nVlTotE1Sel + ::nVlrAcre - ::nVlrDesc - ::nVlrAlug - ::nVlrOutr //- ::nVlrTaxas

	//fazendo refresh dos campos
	for nX := 1 to len(::aObjTotaliz)
		::aObjTotaliz[nX]:Refresh()
	next nX
	For nX := 1 to len(::aBandeiras)
		//::aBandeiras {{cCodBand, oImagem, cImagem, oTipoOp, cTipoOp, oTotGeral, nTotGeral},...}
		::aBandeiras[nX][6]:Refresh()
	next nX

Return

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³ BaixaSE1 ºAutor ³Wellington Gonçalves º Data ³  15/12/2014 º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³ Função que faz a baixa da fatura                           º±±
±±º          ³                                                            º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ Marajó                                                     º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Static Function BaixaSE1(cNum)

Local aArea		:= GetArea()
Local aAreaSE1	:= SE1->(GetArea())
Local cBkpFunNam := FunName()

Private INCLUI := .F.
Private ALTERA := .F.

if cNum <> Nil .AND. !empty(cNum)

	SE1->(DbSetOrder(1)) // E1_FILIAL + E1_PREFIXO + E1_NUM + E1_PARCELA + E1_TIPO
	if SE1->(DbSeek(xFilial("SE1") + "FAT" + cNum))

		SetFunName("FINA070") //ADD Danilo, para ficar correto campo E5_ORIGEM (relatorios e rotinas conciliacao)					
		FINA070(,3,.T.)
		SetFunName(cBkpFunNam)

	endif

endif

RestArea(aArea)
RestArea(aAreaSE1)

Return()

//------------------------------------------------------------------------------
//Função para chamar alteração de sacado!
//------------------------------------------------------------------------------
Static function DoAltSacado(nAba, oAba)

	Local aRecsAlt := {}
	Local nX := 0
	Local lRefresh := .F.
	Local nTipo := 1 //1=Abas Operadora; 2=Aba Inconsistencia

	if nAba == len(aTFolder[1]) //se é a ultima aba, é
		nTipo := 2
	endif

	DbSelectArea("SE1")
	if nTipo == 1
		for nX := 1 to len(oAba:aDados)
			if oAba:aDados[nX][len(oAba:aHeader)+1] > 0 .AND. oAba:aDados[nX][1] == "LBOK"
				aadd(aRecsAlt, oAba:aDados[nX][len(oAba:aHeader)+1] )
			endif
		next nX
		if empty(aRecsAlt) //se nao tem titulo marcado, pega o posicionado
			if oAba:aDados[oAba:oGetDados:nAt][len(oAba:aHeader)+1] > 0
				SE1->(DbGoTo(oAba:aDados[oAba:oGetDados:nAt][len(oAba:aHeader)+1]))
				U_TRETA043(,,,,,SE1->(Recno()),,.T.)
				lRefresh := .T.
			else
				MsgInfo("Selecione um título para alteração.","Atençao")
				return
			endif
		else
			U_TRETA043(,,,,,,aRecsAlt,.T.)
			lRefresh := .T.
		endif
	else
		for nX := 1 to len(oAba:aDadosSE1)
			if oAba:aDadosSE1[nX][len(oAba:aHeaderSE1)+1] > 0
				aadd(aRecsAlt, oAba:aDadosSE1[nX][len(oAba:aHeaderSE1)+1] )
			endif
		next nX
		if empty(aRecsAlt)
			MsgInfo("Não há titulos para alterar sacado.","Atençao")
			return
		else
			U_TRETA043(,,,,,,aRecsAlt,.T.)
			lRefresh := .T.
		endif
	endif

	//fazendo refreshs
	if lRefresh
		if nTipo == 1
			for nX := 1 to len(oAba:aDados)
				oAba:DoAtuLinSE1(oAba:aDados[nX][len(oAba:aHeader)+1], oAba:aDados[nX][len(oAba:aHeader)+2], nX)
			next nX
			oAba:oGetDados:oBrowse:Refresh()
		else
			for nX := 1 to len(oAba:aDadosSE1)
				oAba:DoAtuLinSE1(oAba:aDadosSE1[nX][len(oAba:aHeaderSE1)+1], 0, nX)
			next nX
			oAba:oMSNewGeE1:oBrowse:Refresh()
		endif
		oAba:DoAtuTotal()
	endif

Return

Static Function DoCriaMacro(cNivel,aExtrato,nX,nXMrgVal)

	Local cCompara	:= ""
	Local nY

	Default cNivel	:= " "

	//montando string para macro substituição de comparação
	for nY := 1 to len(aExtrato[nX])
		if aExtrato[nX][nY][3] .AND. (aExtrato[nX][nY][4] == cNivel .OR. empty(cNivel)) //se é campo de comparação
			if !empty(cCompara)
				cCompara += " .AND. "
			endif

			cCompara += "(  "

			if valtype(aExtrato[nX][nY][2])=="C" //caractere
				aadd(aCompara, alltrim(aExtrato[nX][nY][2]))
				cCompara += "alltrim(SE1->"+aExtrato[nX][nY][1]+") == aCompara["+alltrim(Str(len(aCompara)))+"] "
			else //numerico ou data
				aadd(aCompara, aExtrato[nX][nY][2])
				If AllTrim(aExtrato[nX][nY][1]) $ "E1_VLRREAL/E1_VALOR" .and. nXMrgVal > 0
					cCompara += "SE1->"+aExtrato[nX][nY][1]+" >= " + cValToChar(aExtrato[nX][nY][2] - nXMrgVal) + " .AND. "
					cCompara += "SE1->"+aExtrato[nX][nY][1]+" <= " + cValToChar(aExtrato[nX][nY][2] + nXMrgVal) + "  "
				Else
					cCompara += "SE1->"+aExtrato[nX][nY][1]+" == aCompara["+alltrim(Str(len(aCompara)))+"] "
				EndIf
			endif

			cCompara += ")"

        endif
	next nY

Return cCompara

//---------------------------------------------------------------
// Chama tela de busca titulo, e relaciona ao item do extrato
//---------------------------------------------------------------
METHOD DoBuscaRapida() CLASS UT019ABA

	//Local nPosMarkEx := 0
	Local nX := 0
	Local nRecE1

	//Private oNewGetE1
	Private nOpcx := 0
	Private oDlgSE1
	Private oSayFilter
	Private oChkOper
	Private lChkOper := .T.
	Private oMrgDias
	Private cMrgDias := "0 "
	Private oMrgVal
	Private nMrgVal  := 0
	Private oNSU
	Private cNSU	 := Space(TAMSX3("E1_NSUTEF")[1])
	Private oCodAut
	Private cCodAut	 := Space(TAMSX3("E1_CARTAUT")[1])

	DEFINE MSDIALOG oDlgSE1 TITLE "Busca Titulos da Operadora" FROM 000, 000  TO 400, 700 COLORS 0, 16777215 PIXEL

	::DoMsGetSE1()
	::DoBuscaSE1()

    oSayFilter := TSay():New( 165, 06, {|| "Os titulos listados foram filtrados." }, oDlgSE1,,,,,,.T.,CLR_BLUE,,500,9 )

    TSay():New( 06, 250, {|| "Margem de Dias:" }	, oDlgSE1,,,,,,.T.,CLR_BLACK,,500,14 )
    TSay():New( 26, 250, {|| "Margem de Valor:" }	, oDlgSE1,,,,,,.T.,CLR_BLACK,,500,14 )
    TSay():New( 46, 250, {|| "Pesquisar NSU:" }		, oDlgSE1,,,,,,.T.,CLR_BLACK,,500,14 )
    TSay():New( 66, 250, {|| "Pesquisar Aut.:" }	, oDlgSE1,,,,,,.T.,CLR_BLACK,,500,14 )

	oMrgDias := TGet():New( 06, 295, {|u| iif( PCount()==0,cMrgDias,cMrgDias:= u) } ,oDlgSE1,50,9,"@!"                      ,/*bValid*/,,,,.F.,,.T.,,.F.,{|| .T.},.F.,.F.,/*bChange*/,.F.,.F.,,,,,,.F.,.F.)
   	oMrgVal  := TGet():New( 26, 295, {|u| iif( PCount()==0,nMrgVal,nMrgVal:= u) }   ,oDlgSE1,50,9,PesqPict("SE1","E1_VALOR"),/*bValid*/,,,,.F.,,.T.,,.F.,{|| .T.},.F.,.F.,/*bChange*/,.F.,.F.,,,,,,.F.,.F.)
    oNSU  	 := TGet():New( 46, 295, {|u| iif( PCount()==0,cNSU,cNSU:= u) }   		,oDlgSE1,50,9,"@!"						,/*bValid*/,,,,.F.,,.T.,,.F.,{|| .T.},.F.,.F.,/*bChange*/,.F.,.F.,,,,,,.F.,.F.)
    oCodAut	 := TGet():New( 66, 295, {|u| iif( PCount()==0,cCodAut,cCodAut:= u) }   ,oDlgSE1,50,9,"@!"						,/*bValid*/,,,,.F.,,.T.,,.F.,{|| .T.},.F.,.F.,/*bChange*/,.F.,.F.,,,,,,.F.,.F.)

    @ 181, 140 CHECKBOX oChkOper VAR lChkOper PROMPT "Mostrar apenas titulos da operadora." SIZE 100, 008 OF oDlgSE1 COLORS 0, 16777215 ON CHANGE (::DoBuscaSE1(.T.)) PIXEL

    @ 86,  250 BUTTON oButton1 PROMPT "Buscar" SIZE 037, 012 OF oDlgSE1 ACTION (::DoBuscaSE1(,,.T.),oSayFilter:Show()) PIXEL
    @ 86,  300 BUTTON oButton1 PROMPT "Limpar" SIZE 037, 012 OF oDlgSE1 ACTION (::DoBuscaSE1(.T.),oSayFilter:Hide(),ResetRapida()) PIXEL
    @ 180, 006 BUTTON oButton2 PROMPT "Confirmar" SIZE 037, 012 OF oDlgSE1 ACTION (nOpcx := 1,oDlgSE1:End()) PIXEL
    @ 180, 049 BUTTON oButton3 PROMPT "Cancelar" SIZE 037, 012 OF oDlgSE1 ACTION (nOpcx := 0,oDlgSE1:End()) PIXEL
    @ 180, 092 BUTTON oButton3 PROMPT "Filtrar" SIZE 037, 012 OF oDlgSE1 ACTION (::DoBuscaSE1(.T.,.T.,.T.)) PIXEL

	ACTIVATE MSDIALOG oDlgSE1 CENTERED ON INIT (oSayFilter:Hide())

	if nOpcx == 1

		For nX := 1 to len(::aBuscaSE1)
			nRecE1 := ::aBuscaSE1[nX][len(::aHeaderSE1)+1] //recno

			if nRecE1 > 0 .AND. ::aBuscaSE1[nX][1] == "LBOK" .AND. aScan(::aTitulos, nRecE1) == 0 //so se marcou e nao foi adiconado ainda
				aAdd(::aTitulos, nRecE1) //adiciono recno na lista de títulos
				//adiciono o titulo no grid inconsistências
			    ::DoAddTitInc(nRecE1)
			endif
		next nX
	endif

Return

/*--------------------------------------------------------------------------------------------------
Função: ResetRapida
Tipo: Função Estática
Descrição: Reinicializa os campos de pesquisa rápida.
Uso: Marajó
Parâmetros:
Retorno:
----------------------------------------------------------------------------------------------------
Atualizações:
- 29/03/2017 - Gianluka Moraes de Sousa - Construção Inicial do Fonte
--------------------------------------------------------------------------------------------------*/
Static Function ResetRapida

	cMrgDias := "0 "
	nMrgVal  := 0
	cNSU	 := Space(TAMSX3("E1_NSUTEF")[1])
	cCodAut	 := Space(TAMSX3("E1_CARTAUT")[1])

Return

//---------------------------------------------------------------
// Verifica possíveis troca de sacado do arquivo
//---------------------------------------------------------------
METHOD DoVerSacado(cArquivo, _cBandeira, lAddInc, _cTipCard) CLASS UT019ABA

	Local cQry		:= ""
	Local cAdmFin 	:= ""
	Local aChaves	:= {} //{campo,{valores}}
	Local aRecnos	:= {}
	Local nX, nY, nPosAux
	Default lAddInc := .F.

	// -> Pega o conteúdo dos campos definidos como Primário
	For nX := 1 to len(::aExtrato)
		For nY := 1 to len(::aExtrato[nX])
			If AllTrim(::aExtrato[nX][nY][1]) <> "R_E_C_N_O_"
				If !Empty(AllTrim(::aExtrato[nX][nY][4]))
					If AllTrim(::aExtrato[nX][nY][4]) == "1"
						If (nPosAux:=aScan(aChaves, {|x| x[1] == ::aExtrato[nX][nY][1] })) == 0 //campo
							aAdd(aChaves, {::aExtrato[nX][nY][1], {::aExtrato[nX][nY][2]} } )
						Else
							aadd(aChaves[nPosAux][2], ::aExtrato[nX][nY][2])
						EndIf
					EndIf
				EndIf
			EndIf
		Next nY
	Next nX

	if !empty(aChaves)
		if empty(_cBandeira) //se nao tem bandeira no filtro
			cAdmFin := "'"+::aAdmFin[1]+"'"
			for nX := 2 to len(::aAdmFin)
				cAdmFin += ",'"+::aAdmFin[nX]+"'"
			next nX
		else
			nPosBand := aScan(::aAdmBand, {|x| x[1] == _cBandeira }) //posição das adm fin da bandeira
			if nPosBand > 0
				cAdmFin := "'"+::aAdmBand[nPosBand][2][1]+"'"
				for nX := 2 to len(::aAdmBand[nPosBand][2])
					cAdmFin += ",'"+::aAdmBand[nPosBand][2][nX]+"'"
				next nX
			endif
		endif
	endif

	//vou montar uma query para cada campo primario
	for nY := 1 to len(aChaves)

		cChaves := "'"+alltrim(aChaves[nY][2][1])+"'"
		For nX := 2 To Len(aChaves[nY][2])
			If !Empty(AllTrim(aChaves[nY][2][nX]))
				cChaves += ",'"+AllTrim(aChaves[nY][2][nX])+"'"
			EndIf
		Next nX

		cQry := " SELECT SE1.R_E_C_N_O_ AS CHAVE"
		cQry += " FROM "+RetSqlName("SE1")+" SE1 "
		cQry += " WHERE SE1.D_E_L_E_T_ <> '*' "
		cQry += " 	AND SE1.E1_FILIAL = '"+xFilial("SE1")+"' "
		cQry += " 	AND SE1.E1_STATUS = 'A' "
		If UPPER(AllTrim(_cTipCard)) == "CC"
			cQry += " 	AND SE1.E1_TIPO IN ('CC ') " //add para trazer somente titulos de cartao de credito
		ElseIf UPPER(AllTrim(_cTipCard)) == "CD"
			cQry += " 	AND SE1.E1_TIPO IN ('CD ') " //add para trazer somente titulos de cartao de debito
		Else
			cQry += " 	AND SE1.E1_TIPO IN ('CC ','CD ') " //add para trazer somente titulos de cartao
		EndIf
		cQry += " 	AND SE1.E1_EMISSAO <= '"+DToS(ddatabase)+"' " //add para nao trazer titulos com emissao superior a data base
		cQry += "	AND SE1.E1_SALDO > 0 "
		cQry += "	AND RTRIM(SE1."+Alltrim(aChaves[nY][1])+") IN (" + cChaves + ")"
		//TODO: trocar busca pelo campo E1_ADM
		cQry += " 	AND LTRIM(RTRIM(E1_CLIENTE)) NOT IN ("+iif(empty(cAdmFin),"''",cAdmFin)+") "

		If Select("QTMP") > 0
			QTMP->( DbCloseArea() )
		EndIf

		cQry := ChangeQuery(cQry)
		TcQuery cQry New Alias "QTMP"

		QTMP->( DbGoTop() )
		While QTMP->( !EOF() )

			if lAddInc
				//verifico se realmente nao foi adicionado na rotina
				if aScan(::aTitulos, QTMP->CHAVE) == 0
					aadd(::aTitulos, QTMP->CHAVE)
					//adiciono o titulo no grid inconsistências
					::DoAddTitInc(QTMP->CHAVE)
				endif
			else
				if aScan(aRecnos, QTMP->CHAVE) == 0
					aAdd(aRecnos, QTMP->CHAVE )
				endif
			endif

			QTMP->( DbSkip() )
		EndDo

    	QTMP->( DbCloseArea() )
	next nY

	if !lAddInc .AND. !empty(aRecnos)
		If MsgYesNo("Foram encontrados registros com o mesmo NSU com SACADOS diferentes. Deseja alterar o sacado antes do processamento ?", "Arquivo: " + AllTrim(cArquivo))
			U_TRETA043(,,,,,,aRecnos,.T.)
		EndIf
	endif

Return

//---------------------------------------------------------------
// Ajusta os valores divergentes dos titulos ja vinculados
//---------------------------------------------------------------
METHOD AjuVlrDiv() CLASS UT019ABA

	If MsgYesNo("Confirma ajustar valores divegentes dos titulos vinculados, colocando acrescimos ou descontos?", "Atenção")
		MsAguarde({|| ::DoAjuVlrDiv() },"Aguarde...","Processando Ajustes...")
	Endif

Return 
//---------------------------------------------------------------
// Ajusta os valores divergentes dos titulos ja vinculados
//---------------------------------------------------------------
METHOD DoAjuVlrDiv() CLASS UT019ABA

	Local aFin040 := {}
	Local nX, nVlrAux
	Local nAcresc, nDecresc
	Local nPosDiverg := aScan(::aHeader,{|x| AllTrim(x[2]) == "E1_VALORD" })
	Local nPosVlrE := aScan(::aHeader,{|x| AllTrim(x[2]) == "E1_VALORE" })
	Local cBkpOrigem := ""

	for nX := 1 to len(::aDados)

		nAcresc := 0
		nDecresc := 0

		if ::aDados[nX][nPosDiverg] > 0 //se há divergência de valor

			SE1->(DbGoTo( ::aDados[nX][len(::aHeader)+1] )) //recno

			nAcresc := 0
			nDecresc := 0

			nVlrAux := IIF(nPosVlrE>0, ::aDados[nX][nPosVlrE], 0)
			nVlrAux := SE1->&(::cCpVlrDiv) - nVlrAux
			if nVlrAux < 0 //se titulo menor que extrato, acrescimo
				nAcresc := Abs(nVlrAux)
			else //senao eh desconto
				nDecresc := Abs(nVlrAux)
			endif

			//Montando array para execauto
			aFin040 := {}
			AADD(aFin040, {"E1_FILIAL"	,SE1->E1_FILIAL		,Nil } )
			AADD(aFin040, {"E1_PREFIXO"	,SE1->E1_PREFIXO	,Nil } )
			AADD(aFin040, {"E1_NUM"		,SE1->E1_NUM		,Nil } )
			AADD(aFin040, {"E1_PARCELA"	,SE1->E1_PARCELA  	,Nil } )
			AADD(aFin040, {"E1_TIPO"	,SE1->E1_TIPO	   	,Nil } )
			AADD(aFin040, {"E1_CLIENTE"	,SE1->E1_CLIENTE	,Nil } )
			AADD(aFin040, {"E1_LOJA"	,SE1->E1_LOJA		,Nil } )

			AADD(aFin040, {"E1_VALOR"   ,SE1->E1_VALOR	,Nil})

			AADD(aFin040, {"E1_ACRESC"	,nAcresc	,Nil } )
			AADD(aFin040, {"E1_SDACRES"	,nAcresc	,Nil } )
			AADD(aFin040, {"E1_DECRESC"	,nDecresc	,Nil } )
			AADD(aFin040, {"E1_SDDECRE"	,nDecresc	,Nil } )

			lMsErroAuto := .F. // variavel interna da rotina automatica
			lMsHelpAuto := .F.

			//apaga a origem para ser possível alteração/exclusão do titulo
			cBkpOrigem := SE1->E1_ORIGEM
			RecLock("SE1",.F.)
				SE1->E1_ORIGEM := ""
			SE1->(MsUnlock())

			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³ Chama a funcao de gravacao automatica do FINA040                        ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			MSExecAuto({|x,y| FINA040(x,y)},aFin040, 4)

			//volta a origem 
			RecLock("SE1",.F.)
				SE1->E1_ORIGEM := cBkpOrigem
			SE1->(MsUnlock())

			if lMsErroAuto
				MostraErro()
			else
				//fazendo refreshs
				::DoAtuLinSE1(::aDados[nX][len(::aHeader)+1], ::aDados[nX][len(::aHeader)+2], nX)
			endif

		endif

	next nX

	::oGetDados:oBrowse:Refresh()
	::DoAtuTotal()

Return

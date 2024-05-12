#INCLUDE 'PROTHEUS.CH'
#INCLUDE "hbutton.ch"
#INCLUDE "topconn.ch"
#INCLUDE "TbiConn.ch"
#INCLUDE 'poscss.ch'

/*/{Protheus.doc} TPDVE003
Consulta específica de produtos da tela do posto.

@author Totvs GO
@since 04/06/2014
@version 1.0
@return Nil
@type function
/*/

//**** CONFIGURAÇÃO DA SXB *****
//SB1PDV;1;01;RE;Consulta Produtos;Consulta Produtos;Consulta Produtos;SB1;
//SB1PDV;2;01;01;;;;U_TPDVE003();
//SB1PDV;5;01;;;;;&(ReadVar());
User Function TPDVE003()

	Local aArea := GetArea()
	Local oButton1
	Local oButton2
	Local oButton3
	Local oButton4
	Local oButton5
	Local oSay1
	Local oSay2
	Local oSay3
	Local oSay4

	Local oPnlPrinc
	Local cCor := SuperGetMv( "MV_LJCOLOR",,"07334C")// Cor da tela
	Local cCorBack := RGB(hextodec(SubStr(cCor,1,2)),hextodec(SubStr(cCor,3,2)),hextodec(SubStr(cCor,5,2)))

	Private _cGet1 		:= Space(TamSX3("B1_DESC")[1])
	Private _cGet2 		:= cGetProd//Space(TamSX3("B1_COD")[1])
	Private _cGet3 		:= Space(TamSX3("B1_CODBAR")[1])
	Private _oGet1
	Private _oGet2
	Private _oGet3
	Private oPanelProd
	Private oGridProd
	Private cBuscaOld := _cGet1+_cGet2+_cGet3
	Static oDlgProd

	DEFINE MSDIALOG oDlgProd TITLE "Consulta de Produtos" FROM 000, 000  TO 550, 600 COLORS 0, 16777215 PIXEL

	//pnl Principal
	@ 0,0 MSPANEL oPnlPrinc SIZE 500, 500 OF oDlgProd COLORS 0, cCorBack
	oPnlPrinc:Align := CONTROL_ALIGN_ALLCLIENT

	// crio o panel para mudar a cor da tela
	@ 004, 0 MSPANEL oPanelProd SIZE 300, 272 OF oPnlPrinc
	oPanelProd:SetCSS( POSCSS (GetClassName(oPanelProd), CSS_PANEL_CONTEXT ))

	@ 005, 010 SAY oSay4 PROMPT "Filtros - Consulta de Produtos" SIZE 393, 008 OF oPanelProd FONT COLORS 0, 16777215 PIXEL
	oSay4:SetCSS( POSCSS (GetClassName(oSay4), CSS_BREADCUMB ))

	@ 024, 010 SAY oSay1 PROMPT "Descrição" SIZE 50, 010 OF oPanelProd COLOR 0, 16777215 PIXEL
	oSay1:SetCSS( POSCSS (GetClassName(oSay1), CSS_LABEL_FOCAL ))
	@ 020, 045 MSGET _oGet1 VAR _cGet1 SIZE 200, 013 OF oPanelProd PICTURE PesqPict("SB1","B1_DESC") COLORS 0, 16777215 PIXEL VALID SearchSB1()
	_oGet1:SetCSS( POSCSS (GetClassName(_oGet1), CSS_GET_NORMAL ))

	@ 043, 010 SAY oSay2 PROMPT "Código" SIZE 50, 010 OF oPanelProd COLOR 0, 16777215 PIXEL
	oSay2:SetCSS( POSCSS (GetClassName(oSay2), CSS_LABEL_FOCAL ))
	@ 039, 045 MSGET _oGet2 VAR _cGet2 SIZE 075, 013 OF oPanelProd PICTURE PesqPict("SB1","B1_COD") COLORS 0, 16777215 PIXEL VALID SearchSB1()
	_oGet2:SetCSS( POSCSS (GetClassName(_oGet2), CSS_GET_NORMAL ))

	@ 043, 125 SAY oSay3 PROMPT "Cód. Barras" SIZE 60, 010 OF oPanelProd COLOR 0, 16777215 PIXEL
	oSay3:SetCSS( POSCSS (GetClassName(oSay3), CSS_LABEL_FOCAL ))
	@ 039, 170 MSGET _oGet3 VAR _cGet3 SIZE 075, 013 OF oPanelProd PICTURE PesqPict("SB1","B1_CODBAR") COLORS 0, 16777215 PIXEL  VALID SearchSB1()
	_oGet3:SetCSS( POSCSS (GetClassName(_oGet3), CSS_GET_NORMAL ))

	// BOTAO CONSULTAR
	oButton1 := TButton():New(039,;
							250,;
							"C&onsultar",;
							oPanelProd,;
							{|| LjMsgRun("Aguarde... Buscando Produtos",,{|| RefreshGrid(.T.) }) },;
							40,;
							15,;
							,,,.T.,;
							,,,{|| .T.})
	oButton1:SetCSS( POSCSS (GetClassName(oButton1), CSS_BTN_FOCAL ))

	// BOTAO LIMPAR
	oButton2 := TButton():New(020,;
							250,;
							"&Limpar",;
							oPanelProd,;
							{|| (LimpaFiltro(),SearchSB1(.T.))},;
							40,;
							15,;
							,,,.T.,;
							,,,{|| .T.})
	oButton2:SetCSS( POSCSS (GetClassName(oButton2), CSS_BTN_NORMAL ))

	// crio o grid de Produtos
	oGridProd := MsGridProd()
	//oGridProd:oBrowse:SetCSS( POSCSS("TGRID", CSS_BROWSE) ) //CSS do totvs pdv
	//oGridProd:oBrowse:nScrollType := 0 // mudo o tipo do scroll do grid para barra de rolagem

	// função chamada no duplo clique da linha do grid
	oGridProd:oBrowse:bLDblClick := {|| ConfirmaDados(),oDlgProd:End()}

	// preencho o grid de Produtos
	if !empty(cBuscaOld)
		LjMsgRun("Aguarde... Buscando Produtos",,{|| RefreshGrid() })
	endif

	// BOTAO CONFIRMAR
	oButton3 := TButton():New(240,;
							250,;
							"&Confirmar",;
							oPanelProd,;
							{|| (ConfirmaDados(),oDlgProd:End())},;
							45,;
							20,;
							,,,.T.,;
							,,,{|| .T.})
	oButton3:SetCSS( POSCSS (GetClassName(oButton3), CSS_BTN_FOCAL ))

	// BOTAO CANCELAR
	oButton4 := TButton():New(240,;
							200,;
							"C&ancelar",;
							oPanelProd,;
							{|| oDlgProd:End()},;
							45,;
							20,;
							,,,.T.,;
							,,,{|| .T.})
	oButton4:SetCSS( POSCSS (GetClassName(oButton4), CSS_BTN_NORMAL ))

	// BOTAO VISUALIZAR
	oButton5 := TButton():New(240,;
							150,;
							"Vis&ualizar",;
							oPanelProd,;
							{|| VisualProd() },;
							45,;
							20,;
							,,,.T.,;
							,,,{|| .T.})
	oButton5:SetCSS( POSCSS (GetClassName(oButton5), CSS_BTN_NORMAL ))

	ACTIVATE MSDIALOG oDlgProd CENTERED

	RestArea(aArea)

Return(.T.)

/*/{Protheus.doc} MsGridProd
Função que cria a MsNewGetDados dos Produtos.

@author pablo
@since 26/09/2018
@version 1.0
@return Nil

@type function
/*/
Static Function MsGridProd()

	Local nX
	Local aHeaderEx 	:= {}
	Local aColsEx 		:= {}
	Local aFieldFill 	:= {}
	Local aFields 		:= {"B1_COD","B1_DESC","DA1_PRCVEN","B1_UM"}
	Local aAlterFields 	:= {}

	// Define field properties
	For nX:=1 to Len(aFields)
		If !empty(GetSx3Cache(aFields[nX],"X3_CAMPO"))
			aadd(aHeaderEx, U_UAHEADER(aFields[nX]) )
		Endif
	Next nX
	For nX := 1 to Len(aHeaderEx)
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

	Aadd(aFieldFill, .F.)
	Aadd(aColsEx, aFieldFill)

Return(MsNewGetDados():New( 060, 005, 235, 297, , "AllwaysTrue", "AllwaysTrue", "+Field1+Field2", aAlterFields,, 999, "AllwaysTrue", "", "AllwaysTrue", oPanelProd, aHeaderEx, aColsEx))

/*/{Protheus.doc} LimpaFiltro
Função que limpa o filtro dos Produtos
@author thebr
@since 30/11/2018
@version 1.0
@return Nil
@type function
/*/
Static Function LimpaFiltro()

	// atualizo as variáveis dos MSGET's
	_cGet1 	:= SPACE(TamSX3("B1_DESC")[1])
	_cGet2 	:= SPACE(TamSX3("B1_COD")[1])
	_cGet3	:= SPACE(TamSX3("B1_CODBAR")[1])

	// faço um refresh nos MSGET's
	_oGet1:Refresh()
	_oGet2:Refresh()
	_oGet3:Refresh()

Return()

/*/{Protheus.doc} ConfirmaDados
Função que preenche os dados do Produtos
@author thebr
@since 30/11/2018
@version 1.0
@return Nil
@type function
/*/
Static Function ConfirmaDados()

	if !Empty(oGridProd:Acols) .AND. !Empty(oGridProd:Acols[oGridProd:nAt,aScan(oGridProd:aHeader,{|x| AllTrim(x[2])=="B1_COD"})])

		// atualizo as variáveis
		cGetProd	:= oGridProd:Acols[oGridProd:nAt,aScan(oGridProd:aHeader,{|x| AllTrim(x[2])=="B1_COD"})]

	endif

	// faço o refresh dos objetos
	oGetProd:Refresh()

Return()

/*/{Protheus.doc} SearchSB1
Busca produto
@author thebr
@since 30/11/2018
@version 1.0
@return Nil
@param lConsulta, logical, descricao
@type function
/*/
Static Function SearchSB1(lConsulta)

	Default lConsulta := .F.

	if cBuscaOld <> (_cGet1+_cGet2+_cGet3) .or. lConsulta

		cBuscaOld := _cGet1+_cGet2+_cGet3
		LjMsgRun("Aguarde... Buscando Produtos",,{|| RefreshGrid() })

	endif

Return(.T.)

/*/{Protheus.doc} RefreshGrid
Função que atualiza o Grid de Produtos
@author thebr
@since 30/11/2018
@version 1.0
@return Nil
@param lEmpty, logical, descricao
@type function
/*/
Static Function RefreshGrid(lEmpty)

	Local aFieldFill 	:= {}
	Local cCondicao		:= ""
	Local bCondicao
	Local cTpProd	 	:= SuperGetMv("MV_XTPPROD", Nil, "") //Lista de tipos de produtos que podem ser usados no PDV (Ex.: "ME/KT")
	Local aProdAux		:= {}
	Local nQtdMax		:= 100
	Local nX

	Default lEmpty	:= .F.

	oGridProd:Acols := {}

	#IFDEF TOP

	if empty(_cGet1+_cGet2+_cGet3) .AND. lEmpty

		SB1->(DbSetOrder(1)) //B1_FILIAL+B1_COD
		SB1->(DbGoTop())

		nCount := 0
		While SB1->(!Eof()) .and. (nCount <= nQtdMax)

			if U_TPDV003A(SB1->B1_COD)
				aFieldFill := {}

				aadd(aFieldFill, SB1->B1_COD)
				aadd(aFieldFill, SB1->B1_DESC)
				aadd(aFieldFill, U_URetPrec(SB1->B1_COD,,.F.))
				aadd(aFieldFill, SB1->B1_UM)
				aadd(aFieldFill, .F.)

				aadd(oGridProd:Acols,aFieldFill)

				nCount++
			endif
			SB1->(DbSkip())
		EndDo

	elseif !empty(_cGet1+_cGet2+_cGet3)

		cCondicao := " D_E_L_E_T_ <> '*'"
		cCondicao += " and SB1.B1_FILIAL = '" + xFilial("SB1") + "'"
		cCondicao += " and SB1.B1_MSBLQL <> '1'"
		if !Empty(cTpProd) //filtra os produtos pelo tipo
			cCondicao += " and '" + AllTrim(cTpProd) + "' like B1_TIPO"
		endif
		if !Empty(_cGet1)
			cCondicao += " and B1_DESC like '%" + AllTrim(_cGet1) + "%'"
		endif
		if !Empty(_cGet2)
			cCondicao += " and B1_COD like '%" + AllTrim(_cGet2) + "%'"
		endif
		if !Empty(_cGet3)
			cCondicao += " and B1_CODBAR like '%" + AllTrim(_cGet3) + "%'"
		endif

		aDados := STDQueryDB( {"B1_COD","B1_DESC","B1_UM"}, {"SB1"}, cCondicao, "B1_FILIAL, B1_COD", nQtdMax )

		For nX := 1 to len(aDados)

			if U_TPDV003A(aDados[nX][1])
				aFieldFill := {}

				aadd(aFieldFill, aDados[nX][1])
				aadd(aFieldFill, aDados[nX][2])
				aadd(aFieldFill, U_URetPrec(aDados[nX][1],,.F.))
				aadd(aFieldFill, aDados[nX][3])
				aadd(aFieldFill, .F.)

				aadd(oGridProd:Acols,aFieldFill)

			endif

		Next nX

	endif

	#ELSE

	if !empty(_cGet1+_cGet2+_cGet3) .OR. lEmpty

		cCondicao := "B1_FILIAL == '" + XFILIAL("SB1") + "'"
		cCondicao += " .AND. B1_MSBLQL <> '1'"

		if !Empty(cTpProd) //filtra os produtos pelo tipo
			cCondicao += " .AND. B1_TIPO $ '" + AllTrim(cTpProd) + "'"
		endif

		if !Empty(_cGet1)
			cCondicao += " .AND. '" + AllTrim(_cGet1) + "' $ B1_DESC"
		endif

		if !Empty(_cGet2)
			cCondicao += " .AND. '" + AllTrim(_cGet2) + "' $ B1_COD"
		endif

		if !Empty(_cGet3)
			cCondicao += " .AND. '" + AllTrim(_cGet3) + "' $ B1_CODBAR"
		endif

		// limpo os filtros da SB1
		SB1->(DbClearFilter())

		if !Empty(cCondicao)

			// faço um filtro na SB1
			bCondicao 	:= "{|| " + cCondicao + " }"
			SB1->(DbSetFilter(&bCondicao,cCondicao))

		endif

		SB1->(DbSetOrder(3)) //B1_FILIAL+B1_DESC

		// posiciono no primeiro item da SB1
		SB1->(DbGoTop())
		while SB1->(!Eof())

			aadd(aProdAux, {SB1->B1_COD, SB1->B1_DESC, SB1->B1_UM} )

			SB1->(DbSkip())
		enddo

		nCount := 0
		for nX := 1 to len(aProdAux)
			if U_TPDV003A(aProdAux[nX][1])
				aFieldFill := {}

				aadd(aFieldFill, aProdAux[nX][1])
				aadd(aFieldFill, aProdAux[nX][2])
				aadd(aFieldFill, U_URetPrec(aProdAux[nX][1],,.F.))
				aadd(aFieldFill, aProdAux[nX][3])
				aadd(aFieldFill, .F.)

				aadd(oGridProd:Acols,aFieldFill)

				nCount++
			endif

			if (nCount > 100)
				EXIT
			endif
		next nX

	endif

	#ENDIF

	if Empty(oGridProd:Acols)

		aFieldFill := {}

		// Define field values
		For nX := 1 to Len(oGridProd:aHeader)
			if oGridProd:aHeader[nX,8] == "N"
				Aadd(aFieldFill,0)
			elseif oGridProd:aHeader[nX,8] == "D"
				Aadd(aFieldFill,CTOD(""))
			elseif oGridProd:aHeader[nX,8] == "L"
				Aadd(aFieldFill,.F.)
			else
				Aadd(aFieldFill,"")
			endif
		Next nX

		aadd(aFieldFill, space(10)) //PROMO

		Aadd(aFieldFill, .F.)
		aadd(oGridProd:Acols,aFieldFill)

	endif

	// limpo os filtros da SB1
	SB1->(DbClearFilter())

	oGridProd:oBrowse:Refresh()

Return()

/*/{Protheus.doc} VisualProd
Função que visualiza o produto.

@author pablo
@since 26/09/2018
@version 1.0
@return Nil

@type function
/*/
Static Function VisualProd()

	Local cRecno 		:= 0
	Local _cCodProd 	:= oGridProd:Acols[oGridProd:nAt,aScan(oGridProd:aHeader,{|x| AllTrim(x[2])=="B1_COD"})]
	Private cCadastro	:= ""

	If !Empty(_cCodProd)

		SB1->(DbSetOrder(1))
		If SB1->(DbSeek(xFilial("SB1") + _cCodProd ))
			cCadastro	:= "Cadastro de Produtos"
			cRecno 		:= SB1->(Recno())

			// chamo rotina de visualização de produtos
			A010Visul("SB1",cRecno,2)
		EndIf

	EndIf

Return()

/*/{Protheus.doc} TPDV003A
Verifica se o produto possui preço de venda cadastrado.

@author Totvs GO
@since 27/04/2015
@version 1.0
@return lRet
@param _cCodProd, characters, codigo do produto
@type function
/*/
Function U_TPDV003A(_cCodProd,lConPad) //_cCodProd = B1_COD

	Local lTipoPreco	:= GetMv("MV_LJCNVDA")
	Local cTabPrc		:= GetMv("MV_TABPAD")
	Local lRet			:= .F.
	Local aAreaSB1
	Local aAreaDA1
	Local aArea

	Default lConPad := .F.

	if !lConPad
		aAreaSB1		:= SB1->(GetArea())
		aAreaDA1		:= DA1->(GetArea())
		aArea         	:= GetArea()
		SB1->(DbSetOrder(1))
		SB1->(DbSeek(xFilial("SB1")+_cCodProd))
	endif

	if SB1->B1_MSBLQL <> "1"
		if lTipoPreco
			if !empty(cTabPrc)
				DA1->(DbSetOrder(1)) // DA1_FILIAL + DA1_CODTAB + DA1_CODPRO + DA1_INDLOT + DA1_ITEM
				if DA1->(DbSeek(xFilial("DA1") + cTabPrc + _cCodProd))

					While DA1->(!Eof()) .AND. DA1->DA1_FILIAL == xFilial("DA1") .AND. DA1->DA1_CODTAB == cTabPrc .AND. AllTrim(DA1->DA1_CODPRO) == AllTrim(_cCodProd)

						// pego a maior data de vigencia
						if Empty(DA1->DA1_DATVIG) .OR. dDataBase >= DA1->DA1_DATVIG
							lRet 	:= .T.
							Exit
						endif

						DA1->(DbSkip())
					EndDo

				endif
			endif
		else
			SB0->(DbSetOrder(1))
			if SB0->(DbSeek(xFilial("SB0") + _cCodProd))
				lRet 	:= .T.
			endif
		endif

	endif

	if !lConPad
		RestArea(aAreaSB1)
		RestArea(aAreaDA1)
		RestArea(aArea)
	endif

return(lRet)

#INCLUDE "PROTHEUS.CH"
#INCLUDE 'FWMVCDEF.CH'

Static cRetProd := ""

/*/{Protheus.doc} User Function TRETE046

Construção da consulta especifica SB1DA1 (SXB) para produtos com preços 
@type  Function
@author danilo
@since 25/05/2023
@version 1
/*/
User Function TRETE046()

	Local lTipoPreco	:= GetMv("MV_LJCNVDA")
	Local cTabPrc		:= GetMv("MV_TABPAD")
	Local lRet        := .F.
	Local oBrowse     := Nil
	Local cAls        := GetNextAlias()
	Local nSuperior   := 0
	Local nEsquerda   := 0
	Local nInferior   := 0
	Local nDireita    := 0
	Local cQry        := ""
	Local aIndex      := {}
	Local aSeek       := {}
	Local oDlgEscTela := Nil

	if lTipoPreco
		cQry := " SELECT DISTINCT SB1.B1_COD, SB1.B1_DESC FROM " + RetSqlName("SB1") + " SB1 "
		cQry += " INNER JOIN "  + RetSqlName("DA1")  + " DA1 "
		cQry += "  ON DA1.DA1_CODTAB = '"+cTabPrc+"' "
		cQry += "  AND DA1.DA1_CODPRO = SB1.B1_COD "
		cQry += "  AND (DA1.DA1_DATVIG = ' ' OR  DA1.DA1_DATVIG <= '"+DTOS(dDataBase)+"') "
		cQry += "  AND DA1.D_E_L_E_T_ = ' '  "
		cQry += "  AND DA1.DA1_FILIAL = '"+xFilial("DA1")+"' "
		cQry += " WHERE SB1.B1_FILIAL = '"+xFilial("SB1")+"'"
		cQry += " AND SB1.D_E_L_E_T_ = ' '"
	else
		cQry := " SELECT DISTINCT SB1.B1_COD, SB1.B1_DESC  FROM " + RetSqlName("SB1") + " SB1 "
		cQry += " INNER JOIN "  + RetSqlName("SB0")  + " SB0 ON B0_FILIAL =  '" + xFilial("SB0") + "' AND SB0.B0_COD = SB1.B1_COD AND SB0.D_E_L_E_T_ = ' '"
		cQry += " WHERE SB1.B1_FILIAL = '"+xFilial("SB1")+"'"
		cQry += " AND SB1.D_E_L_E_T_ = ' '"
	Endif
	cQry := ChangeQuery(cQry)

	Aadd( aSeek, { GetSx3Cache("B1_COD","X3_TITULO"), {{"","C",TamSX3("B1_COD")[1],0,GetSx3Cache("B1_COD","X3_TITULO"),,}} } )
	Aadd( aIndex, "B1_COD" )
	Aadd( aSeek, { GetSx3Cache("B1_DESC","X3_TITULO"), {{"","C",TamSX3("B1_DESC")[1],0,GetSx3Cache("B1_DESC","X3_TITULO"),,}}})
	Aadd( aIndex, "B1_DESC")
	nSuperior := 0
	nEsquerda := 0
	nInferior := 460
	nDireita  := 800

	If !isBlind()

		DEFINE MSDIALOG oDlgEscTela TITLE "Produtos com preços" FROM nSuperior,nEsquerda TO nInferior,nDireita PIXEL

		oBrowse := FWFormBrowse():New()
		oBrowse:SetOwner(oDlgEscTela)
		oBrowse:SetDataQuery(.T.)
		oBrowse:SetAlias(cAls)
		oBrowse:SetQueryIndex(aIndex)
		oBrowse:SetQuery(cQry)
		oBrowse:SetSeek(,aSeek)
		oBrowse:SetDescription("Produtos com preços")
		oBrowse:SetMenuDef("")
		oBrowse:DisableDetails()

		oBrowse:SetDoubleClick({ || cRetProd := (oBrowse:Alias())->B1_COD, lRet := .T. ,oDlgEscTela:End()})
		oBrowse:AddButton( OemTOAnsi("Confirmar"), {|| cRetProd   := (oBrowse:Alias())->B1_COD, lRet := .T., oDlgEscTela:End() } ,, 2 )
		ADD COLUMN oColumn DATA { ||  B1_COD  } TITLE GetSx3Cache("B1_COD","X3_TITULO") SIZE TamSX3("B1_COD")[1] OF oBrowse
		ADD COLUMN oColumn DATA { ||  B1_DESC } TITLE GetSx3Cache("B1_DESC","X3_TITULO") SIZE TamSX3("B1_DESC")[1] OF oBrowse

		oBrowse:AddButton( OemTOAnsi("Cancelar"),  {||  cRetProd  := "", oDlgEscTela:End() } ,, 2 )
		oBrowse:AddButton( OemTOAnsi("Filtro"),  {|| FiltroQry(@cQry, @oBrowse) } ,, 2 )
		oBrowse:AddButton( OemTOAnsi("Limpar Filtro"),  {|| LimpaFiltro(@cQry, @oBrowse) } ,, 2 )
		oBrowse:DisableDetails()

		oBrowse:Activate()

		ACTIVATE MSDIALOG oDlgEscTela CENTERED

	EndIf

Return( lRet )

//funcao para retornar codigo
User Function TRET046A()
Return cRetProd

/*/{Protheus.doc} FiltroQry
Funcao para adicionar o filtro a tela 
@type function
@version 1.0
@author g.sampaio
@since 01/09/2023
@param cQry, character, query atual
@param oBrowse, object, objeto de browse da tela
/*/
Static Function FiltroQry(cQry, oBrowse)

	Local aArea         := GetArea()
	Local cFiltroSB1    := ""
	Local cTabPrc		:= GetMv("MV_TABPAD")
	Local lTipoPreco	:= GetMv("MV_LJCNVDA")


	Default cQry        := ""
	Default oBrowse 	:= Nil

	#IFDEF TOP
		cFiltroSB1  := BuildExpr("SB1",,cFiltroSB1,.T.)
	#ELSE
		cFiltroSB1  := BuildExpr("SB1",,cFiltroSB1,.F.)
	#ENDIF

	// verifico se o filtro e a query estao preenchidos
	If !Empty(cFiltroSB1)

		cQry += " AND " + cFiltroSB1

	Else

		if lTipoPreco
			cQry := " SELECT DISTINCT SB1.B1_COD, SB1.B1_DESC FROM " + RetSqlName("SB1") + " SB1 "
			cQry += " INNER JOIN "  + RetSqlName("DA1")  + " DA1 "
			cQry += "  ON DA1.DA1_CODTAB = '"+cTabPrc+"' "
			cQry += "  AND DA1.DA1_CODPRO = SB1.B1_COD "
			cQry += "  AND (DA1.DA1_DATVIG = ' ' OR  DA1.DA1_DATVIG <= '"+DTOS(dDataBase)+"') "
			cQry += "  AND DA1.D_E_L_E_T_ = ' '  "
			cQry += "  AND DA1.DA1_FILIAL = '"+xFilial("DA1")+"' "
			cQry += " WHERE SB1.B1_FILIAL = '"+xFilial("SB1")+"'"
			cQry += " AND SB1.D_E_L_E_T_ = ' '"
		else
			cQry := " SELECT DISTINCT SB1.B1_COD, SB1.B1_DESC  FROM " + RetSqlName("SB1") + " SB1 "
			cQry += " INNER JOIN "  + RetSqlName("SB0")  + " SB0 ON B0_FILIAL =  '" + xFilial("SB0") + "' AND SB0.B0_COD = SB1.B1_COD AND SB0.D_E_L_E_T_ = ' '"
			cQry += " WHERE SB1.B1_FILIAL = '"+xFilial("SB1")+"'"
			cQry += " AND SB1.D_E_L_E_T_ = ' '"
		Endif
		cQry := ChangeQuery(cQry)

	EndIf

	If !Empty(cQry)

		// atualizo a tela
		If oBrowse <> Nil
			Processa({|| oBrowse:SetQuery(cQry), oBrowse:Refresh() },"Aguarde...","Carregando registros...",.T.) //carrega dados
		EndIf

	EndIf

	RestArea(aArea)

Return(Nil)

/*/{Protheus.doc} LimpaFiltro
Funcao para Limpar Filtro
@type function
@version 1.0
@author g.sampaio
@since 01/09/2023
@param cQry, character, query atual
@param oBrowse, object, objeto de browse da tela
/*/
Static Function LimpaFiltro(cQry, oBrowse)

	Local aArea         := GetArea()
	Local cTabPrc		:= GetMv("MV_TABPAD")
	Local lTipoPreco	:= GetMv("MV_LJCNVDA")

	Default cQry        := ""
	Default oBrowse 	:= Nil
	Default lTipoPreco	:= .T.

	if lTipoPreco
		cQry := " SELECT DISTINCT SB1.B1_COD, SB1.B1_DESC FROM " + RetSqlName("SB1") + " SB1 "
		cQry += " INNER JOIN "  + RetSqlName("DA1")  + " DA1 "
		cQry += "  ON DA1.DA1_CODTAB = '"+cTabPrc+"' "
		cQry += "  AND DA1.DA1_CODPRO = SB1.B1_COD "
		cQry += "  AND (DA1.DA1_DATVIG = ' ' OR  DA1.DA1_DATVIG <= '"+DTOS(dDataBase)+"') "
		cQry += "  AND DA1.D_E_L_E_T_ = ' '  "
		cQry += "  AND DA1.DA1_FILIAL = '"+xFilial("DA1")+"' "
		cQry += " WHERE SB1.B1_FILIAL = '"+xFilial("SB1")+"'"
		cQry += " AND SB1.D_E_L_E_T_ = ' '"
	else
		cQry := " SELECT DISTINCT SB1.B1_COD, SB1.B1_DESC  FROM " + RetSqlName("SB1") + " SB1 "
		cQry += " INNER JOIN "  + RetSqlName("SB0")  + " SB0 ON B0_FILIAL =  '" + xFilial("SB0") + "' AND SB0.B0_COD = SB1.B1_COD AND SB0.D_E_L_E_T_ = ' '"
		cQry += " WHERE SB1.B1_FILIAL = '"+xFilial("SB1")+"'"
		cQry += " AND SB1.D_E_L_E_T_ = ' '"
	Endif
	cQry := ChangeQuery(cQry)

	If !Empty(cQry)

		// atualizo a tela
		If oBrowse <> Nil
			Processa({|| oBrowse:SetQuery(cQry), oBrowse:Refresh() },"Aguarde...","Carregando registros...",.T.) //carrega dados
		EndIf

	EndIf

	RestArea(aArea)

Return(Nil)

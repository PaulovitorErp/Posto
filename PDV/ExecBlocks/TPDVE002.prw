#INCLUDE 'PROTHEUS.CH'
#include "hbutton.ch"
#INCLUDE "topconn.ch"
#INCLUDE "TbiConn.ch"
#INCLUDE 'poscss.ch'

/*/{Protheus.doc} TPDVE002
Consulta específica de clientes da tela do posto.

@author Totvs GO
@since 26/09/2018
@version 1.0
@return Nil

@type function
/*/

/*/
	TODO - EM DESUSO
	Estava sendo usado pela rotina de cadastro de orçamentos: consulta F3, do TPDVA001
/*/
User Function TPDVE002()

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
	Local oSay5
	Local oSay6
	Local oSay7
	Local lSrvPDV 		:= SuperGetMV("MV_XSRVPDV",,.T.) //Servidor PDV
	Local cCor := SuperGetMv( "MV_LJCOLOR",,"07334C")// Cor da tela
	Local cCorBack := RGB(hextodec(SubStr(cCor,1,2)),hextodec(SubStr(cCor,3,2)),hextodec(SubStr(cCor,5,2)))
	Local cCampo := ReadVar()

	Private _cGet1 		:= PADR(iif(cCampo$"CGETCLI,CGETCGC,CGETCODCLI,CGETLOJA", cGetCli, ""),TamSX3("A1_NOME")[1])
	Private _cGet2 		:= PADR(iif(cCampo$"CGETCLI,CGETCGC,CGETCODCLI,CGETLOJA", cGetCGC, ""),TamSX3("A1_CGC")[1])
	Private _cGet3 		:= PADR(iif(cCampo$"CGETCLI,CGETCGC,CGETCODCLI,CGETLOJA", cGetCodCli, cFilCli),TamSX3("A1_COD")[1])
	Private _cGet4 		:= PADR(iif(cCampo$"CGETCLI,CGETCGC,CGETCODCLI,CGETLOJA", cGetLoja, cFilLoja),TamSX3("A1_LOJA")[1])
	Private _cGet5 		:= SPACE(TamSX3("ACY_DESCRI")[1])
	Private _cGet6 		:= PADR("",TamSX3("A1_MUN")[1])
	Private _cGet7 		:= PADR("",TamSX3("A1_EST")[1])
	Private _cGet8 		:= PADR("",TamSX3("A1_GRPVEN")[1])
	Private _oGet1
	Private _oGet2
	Private _oGet3
	Private _oGet4
	Private _oGet5
	Private _oGet6
	Private _oGet7
	Private oGridCli
	Private oDlgCli
	Private cBuscaOld := _cGet1+_cGet2+_cGet3+_cGet4+_cGet5+_cGet6+_cGet7+_cGet8
	Private oPanelCli

	DEFINE MSDIALOG oDlgCli TITLE "Consulta de Clientes" FROM 000, 000  TO 550, 600 COLORS 0, 16777215 PIXEL

	//pnl Principal
	@ 0,0 MSPANEL oPnlPrinc SIZE 500, 500 OF oDlgCli COLORS 0, cCorBack
	oPnlPrinc:Align := CONTROL_ALIGN_ALLCLIENT

	// crio o panel para mudar a cor da tela
	@ 05, 0 MSPANEL oPanelCli SIZE 300, 272 OF oPnlPrinc
	oPanelCli:SetCSS( POSCSS (GetClassName(oPanelCli), CSS_PANEL_CONTEXT ))

	@ 005, 010 SAY oSay4 PROMPT "Filtros - Consulta de Clientes" SIZE 393, 008 OF oPanelCli FONT COLORS 0, 16777215 PIXEL
	oSay4:SetCSS( POSCSS (GetClassName(oSay4), CSS_BREADCUMB ))

	@ 024, 010 SAY oSay1 PROMPT "Nome" SIZE 050, 007 OF oPanelCli  COLOR 0, 16777215 PIXEL
	oSay1:SetCSS( POSCSS (GetClassName(oSay1), CSS_LABEL_FOCAL ))
	@ 020, 045 MSGET _oGet1 VAR _cGet1 SIZE 200, 013 OF oPanelCli PICTURE PesqPict("SA1","A1_NOME")  COLORS 0, 16777215 PIXEL VALID SearchSA1()
	_oGet1:SetCSS( POSCSS (GetClassName(_oGet1), CSS_GET_NORMAL ))

	@ 042, 010 SAY oSay2 PROMPT "CPF/CNPJ" SIZE 050, 007 OF oPanelCli  COLOR 0, 16777215 PIXEL
	oSay2:SetCSS( POSCSS (GetClassName(oSay2), CSS_LABEL_FOCAL ))
	@ 038, 045 MSGET _oGet2 VAR _cGet2 SIZE 065, 013 OF oPanelCli PICTURE PesqPict("SA1","A1_CGC")  COLORS 0, 16777215 PIXEL VALID SearchSA1()
	_oGet2:SetCSS( POSCSS (GetClassName(_oGet2), CSS_GET_NORMAL ))

	@ 042, 115 SAY oSay3 PROMPT "Código" SIZE 050, 007 OF oPanelCli  COLOR 0, 16777215 PIXEL
	oSay3:SetCSS( POSCSS (GetClassName(oSay3), CSS_LABEL_FOCAL ))
	@ 038, 145 MSGET _oGet3 VAR _cGet3 SIZE 060, 013 OF oPanelCli PICTURE PesqPict("SA1","A1_COD")  COLORS 0, 16777215 PIXEL  VALID SearchSA1()
	_oGet3:SetCSS( POSCSS (GetClassName(_oGet3), CSS_GET_NORMAL ))

	@ 042, 210 SAY oSay4 PROMPT "Loja" SIZE 050, 007 OF oPanelCli  COLOR 0, 16777215 PIXEL
	oSay4:SetCSS( POSCSS (GetClassName(oSay4), CSS_LABEL_FOCAL ))
	@ 038, 225 MSGET _oGet4 VAR _cGet4 SIZE 020, 013 OF oPanelCli PICTURE PesqPict("SA1","A1_LOJA")  COLORS 0, 16777215 PIXEL VALID SearchSA1()
	_oGet4:SetCSS( POSCSS (GetClassName(_oGet4), CSS_GET_NORMAL ))

	@ 060, 010 SAY oSay5 PROMPT "Grupo" SIZE 050, 007 OF oPanelCli  COLOR 0, 16777215 PIXEL
	oSay5:SetCSS( POSCSS (GetClassName(oSay5), CSS_LABEL_FOCAL ))
	@ 056, 045 MSGET _oGet5 VAR _cGet5 SIZE 065, 013 OF oPanelCli PICTURE PesqPict("ACY","ACY_DESCRI")  COLORS 0, 16777215 PIXEL VALID SearchSA1()
	_oGet5:SetCSS( POSCSS (GetClassName(_oGet5), CSS_GET_NORMAL ))

	@ 060, 115 SAY oSay6 PROMPT "Cidade" SIZE 050, 007 OF oPanelCli  COLOR 0, 16777215 PIXEL
	oSay6:SetCSS( POSCSS (GetClassName(oSay6), CSS_LABEL_FOCAL ))
	@ 056, 145 MSGET _oGet6 VAR _cGet6 SIZE 060, 013 OF oPanelCli PICTURE PesqPict("SA1","A1_MUN")  COLORS 0, 16777215 PIXEL VALID SearchSA1()
	_oGet6:SetCSS( POSCSS (GetClassName(_oGet6), CSS_GET_NORMAL ))

	@ 060, 210 SAY oSay7 PROMPT "UF" SIZE 050, 007 OF oPanelCli  COLOR 0, 16777215 PIXEL
	oSay7:SetCSS( POSCSS (GetClassName(oSay7), CSS_LABEL_FOCAL ))
	@ 056, 225 MSGET _oGet7 VAR _cGet7 SIZE 020, 013 OF oPanelCli PICTURE PesqPict("SA1","A1_EST")  COLORS 0, 16777215 PIXEL  VALID SearchSA1()
	_oGet7:SetCSS( POSCSS (GetClassName(_oGet7), CSS_GET_NORMAL ))

	// BOTAO CONSULTAR
	oButton1 := TButton():New(056,;
							250,;
							"C&onsultar",;
							oPanelCli	,;
							{|| LjMsgRun("Aguarde... Buscando Clientes",,{|| RefreshGrid(.T.) })},;
							45,;
							15,;
							,,,.T.,;
							,,,{|| .T.})
	oButton1:SetCSS( POSCSS (GetClassName(oButton1), CSS_BTN_FOCAL ))

	// BOTAO LIMPAR
	oButton2 := TButton():New(038,;
							250,;
							"&Limpar",;
							oPanelCli	,;
							{|| (LimpaFiltro(),SearchSA1())},;
							45,;
							15,;
							,,,.T.,;
							,,,{|| .T.})
	oButton2:SetCSS( POSCSS (GetClassName(oButton2), CSS_BTN_NORMAL ))

	// crio o grid de clientes
	oGridCli := MsGridCli()
	//oGridCli:oBrowse:SetCSS( POSCSS("TGRID", CSS_BROWSE) ) //CSS do totvs pdv
	//oGridCli:oBrowse:nScrollType := 0 // mudo o tipo do scroll do grid para barra de rolagem

	// função chamada no duplo clique da linha do grid
	oGridCli:oBrowse:bLDblClick := {|| ConfirmaDados(cCampo),oDlgCli:End()}

	// preencho o grid de clientes
	If !empty(cBuscaOld)
		LjMsgRun("Aguarde... Buscando Clientes",,{|| RefreshGrid() })
	EndIf

	// BOTAO CONFIRMAR
	oButton3 := TButton():New(240,;
							250,;
							"&Confirmar",;
							oPanelCli	,;
							{|| (ConfirmaDados(cCampo),oDlgCli:End())},;
							45,;
							20,;
							,,,.T.,;
							,,,{|| .T.})
	oButton3:SetCSS( POSCSS (GetClassName(oButton3), CSS_BTN_FOCAL ))

	// BOTAO CANCELAR
	oButton4 := TButton():New(240,;
							200,;
							"C&ancelar",;
							oPanelCli	,;
							{|| oDlgCli:End()},;
							45,;
							20,;
							,,,.T.,;
							,,,{|| .T.})
	oButton4:SetCSS( POSCSS (GetClassName(oButton4), CSS_BTN_ATIVO ))

	// BOTAO INCLUIR
	If !lSrvPDV
		oButton5 := TButton():New(240,;
							150,;
							"&Incluir",;
							oPanelCli	,;
							{|| (IncluiSA1(),LjMsgRun("Aguarde... Buscando Clientes",,{|| RefreshGrid() }))},;
							45,;
							20,;
							,,,.T.,;
							,,,{|| .T.})
		oButton5:SetCSS( POSCSS (GetClassName(oButton5), CSS_BTN_NORMAL ))
	Else
		oButton5 := TButton():New(240,;
							150,;
							"Vis&ualizar",;
							oPanelCli	,;
							{|| VisualSA1()},;
							45,;
							20,;
							,,,.T.,;
							,,,{|| .T.})
		oButton5:SetCSS( POSCSS (GetClassName(oButton5), CSS_BTN_NORMAL ))
	EndIf

	ACTIVATE MSDIALOG oDlgCli CENTERED

	RestArea(aArea)

Return(.T.)


/*/{Protheus.doc} MsGridCli
Função que cria a MsNewGetDados dos clientes.

@author pablo
@since 26/09/2018
@version 1.0
@return Nil

@type function
/*/
Static Function MsGridCli()

	Local nX
	Local aHeaderEx 	:= {}
	Local aColsEx 		:= {}
	Local aFieldFill 	:= {}
	Local aFields 		:= {"A1_COD","A1_LOJA","A1_CGC","A1_NOME","A1_NREDUZ","A1_EST","A1_MUN"}
	Local aAlterFields 	:= {}

	// Define field properties
	For nX:=1 to Len(aFields)
		If !empty(GetSx3Cache(aFields[nX],"X3_CAMPO"))
			aadd(aHeaderEx, U_UAHEADER(aFields[nX]) )
		Endif
	Next nX

	// Define field values
	For nX := 1 to Len(aFields)
		If !empty(GetSx3Cache(aFields[nX],"X3_CAMPO"))
			if aFields[nX] $ "A1_COD/A1_CGC"
				Aadd(aFieldFill, Space(TamSx3(aFields[nX])[1]))
			else
				Aadd(aFieldFill, CriaVar(aFields[nX]))
			endif
		Endif
	Next nX

	Aadd(aFieldFill, .F.)
	Aadd(aColsEx, aFieldFill)

Return(MsNewGetDados():New( 075, 005, 235, 297, , "AllwaysTrue", "AllwaysTrue", "+Field1+Field2", aAlterFields,, 999, "AllwaysTrue", "", "AllwaysTrue", oPanelCli, aHeaderEx, aColsEx))

/*/{Protheus.doc} LimpaFiltro
Função que limpa o filtro dos clientes.

@author pablo
@since 26/09/2018
@version 1.0
@return Nil

@type function
/*/
Static Function LimpaFiltro()

	// atualizo as variáveis dos MSGET's
	_cGet1 		:= SPACE(TamSX3("A1_NOME")[1])
	_cGet2 		:= SPACE(TamSX3("A1_CGC")[1])
	_cGet3 		:= SPACE(TamSX3("A1_COD")[1])
	_cGet4 		:= SPACE(TamSX3("A1_LOJA")[1])
	_cGet5 		:= SPACE(TamSX3("ACY_DESCRI")[1])
	_cGet6 		:= SPACE(TamSX3("A1_MUN")[1])
	_cGet7 		:= SPACE(TamSX3("A1_EST")[1])
	_cGet8 		:= SPACE(TamSX3("A1_GRPVEN")[1])

	// faço um refresh nos MSGET's

	_oGet1:Refresh()
	_oGet2:Refresh()
	_oGet3:Refresh()
	_oGet4:Refresh()
	_oGet5:Refresh()
	_oGet6:Refresh()
	_oGet7:Refresh()

Return()


/*/{Protheus.doc} ConfirmaDados
Função que preenche os dados do cliente.

@author pablo
@since 26/09/2018
@version 1.0
@return Nil

@type function
/*/
Static Function ConfirmaDados(cGetRet)

	Local aAreaSA1 	:= SA1->(GetArea())
	Local aArea		:= GetArea()

	if !Empty(oGridCli:Acols) .AND. !Empty(oGridCli:Acols[oGridCli:nAt,aScan(oGridCli:aHeader,{|x| AllTrim(x[2])=="A1_COD"})])

		// atualizo as variáveis
		SA1->(DbSetOrder(1))
		if SA1->(DbSeek(xFilial("SA1") + oGridCli:Acols[oGridCli:nAt,aScan(oGridCli:aHeader,{|x| AllTrim(x[2])=="A1_COD"})] + oGridCli:Acols[oGridCli:nAt,aScan(oGridCli:aHeader,{|x| AllTrim(x[2])=="A1_LOJA"})]))

			if cGetRet $ "CGETCLI,CGETCGC,CGETCODCLI"

				cGetCli 	:= SA1->A1_NOME
				cGetCGC		:= SA1->A1_CGC
				cGetCodCli	:= SA1->A1_COD
				cGetLoja	:= SA1->A1_LOJA

				// faço o refresh dos objetos
				oGetCli:Refresh()
				oGetCGC:Refresh()
				oGetCodCli:Refresh()
				oGetLoja:Refresh()

			elseif cGetRet $ "CFILCLI,CFILLOJA"

				cFilCli	:= SA1->A1_COD
				cFilLoja := SA1->A1_LOJA

				oFilCli:Refresh()
				oFilLoja:Refresh()

			endif

		endif

	endif

	RestArea(aAreaSA1)
	RestArea(aArea)

Return()

/*/{Protheus.doc} SearchSA1
Busca cliente conforme parametros digitados.

@author pablo
@since 26/09/2018
@version 1.0
@return Nil

@type function
/*/
Static Function SearchSA1()

	if cBuscaOld <> (_cGet1+_cGet2+_cGet3+_cGet4+_cGet5+_cGet6+_cGet7+_cGet8)
		cBuscaOld := _cGet1+_cGet2+_cGet3+_cGet4+_cGet5+_cGet6+_cGet7+_cGet8
		LjMsgRun("Aguarde... Buscando Clientes",,{|| RefreshGrid() })
	endif

Return(.T.)


/*/{Protheus.doc} RefreshGrid
Função que atualiza o Grid de clientes.
@author pablo
@since 26/09/2018
@version 1.0
@return Nil
@param lEmpty, logical, descricao
@param lReta, logical, descricao
@type function
/*/
Static Function RefreshGrid(lEmpty, lReta)

	Local aDados
	Local aCampos := {}, aTable := {}
	Local aFieldFill := {}
	Local cCondicao	 := ""
	Local bCondicao
	Local nX		 := 0
	Local nQtdMax		:= 100

	Default lEmpty	:= .F.
	Default lReta   := .T.

	oGridCli:Acols := {}

	If !empty(_cGet1+_cGet2+_cGet3+_cGet4+_cGet5+_cGet6+_cGet7+_cGet8) .OR. lEmpty

		#IFDEF TOP

		if empty(_cGet1+_cGet2+_cGet3+_cGet4+_cGet5+_cGet6+_cGet7+_cGet8)

			SA1->(DbSetOrder(1)) //A1_FILIAL+A1_COD+A1_LOJA
			SA1->(DbGoTop())
			nCount := 0
			While SA1->(!Eof()) .and. (nCount <= nQtdMax)

				aFieldFill := {}

				aadd(aFieldFill, SA1->A1_COD)
				aadd(aFieldFill, SA1->A1_LOJA)
				aadd(aFieldFill, SA1->A1_CGC)
				aadd(aFieldFill, SA1->A1_NOME)
				aadd(aFieldFill, SA1->A1_NREDUZ)
				aadd(aFieldFill, SA1->A1_EST)
				aadd(aFieldFill, SA1->A1_MUN)
				aadd(aFieldFill, .F.)
				aadd(oGridCli:Acols,aFieldFill)

				nCount++
				SA1->(DbSkip())
			EndDo

		else

			aCampos := {"A1_COD","A1_LOJA","A1_CGC","A1_NOME","A1_NREDUZ","A1_EST","A1_MUN","A1_GRPVEN"}
			aTable := {"SA1"}

			cCondicao := " SA1.D_E_L_E_T_ <> '*' "
			cCondicao += "	and SA1.A1_FILIAL = '" + xFilial("SA1") + "'"
			cCondicao += "	and SA1.A1_MSBLQL <> '1'"
			If !Empty(_cGet1)
				cCondicao += "	and (SA1.A1_NOME like '%" + AllTrim(_cGet1) + "%' OR SA1.A1_NREDUZ like '%" + AllTrim(_cGet1) + "%')"
			EndIf
			If !Empty(_cGet2)
				cCondicao += "	and SA1.A1_CGC like '%" + AllTrim(_cGet2) + "%'"
			EndIf
			If !Empty(_cGet3)
				cCondicao += "	and SA1.A1_COD like '%" + AllTrim(_cGet3) + "%'"
			EndIf
			If !Empty(_cGet4)
				cCondicao += "	and SA1.A1_LOJA like '%" + AllTrim(_cGet4) + "%'"
			EndIf
			If !Empty(_cGet6)
				cCondicao += "	and SA1.A1_MUN like '%" + AllTrim(_cGet6) + "%'"
			EndIf
			If !Empty(_cGet7)
				cCondicao += "	and SA1.A1_EST like '%" + AllTrim(_cGet7) + "%'"
			EndIf
			If !Empty(_cGet8)
				cCondicao += "	and SA1.A1_GRPVEN like '%" + AllTrim(_cGet8) + "%'"
			EndIf

			If !Empty(_cGet5) .and. Empty(_cGet8)
				aadd(aTable, "ACY")
				cCondicao += " and ACY.D_E_L_E_T_ = ' ' "
				cCondicao += " and ACY.ACY_GRPVEN = SA1.A1_GRPVEN "
				cCondicao += " and ACY.ACY_FILIAL = SA1.A1_FILIAL "
				cCondicao += " and ACY.ACY_DESCRI like '%"+AllTrim(_cGet5)+"%'"
			endif

			aDados := STDQueryDB( aCampos, aTable, cCondicao, "SA1.A1_FILIAL, SA1.A1_COD, SA1.A1_LOJA", nQtdMax )

			for nX := 1 to len(aDados)

				aFieldFill := {}

				aadd(aFieldFill, aDados[nX][1])
				aadd(aFieldFill, aDados[nX][2])
				aadd(aFieldFill, aDados[nX][3])
				aadd(aFieldFill, aDados[nX][4])
				aadd(aFieldFill, aDados[nX][5])
				aadd(aFieldFill, aDados[nX][6])
				aadd(aFieldFill, aDados[nX][7])
				aadd(aFieldFill, .F.)
				aadd(oGridCli:Acols,aFieldFill)

			next nX

		endif

		#ELSE

		cCondicao := " SA1->A1_FILIAL = '" + xFilial("SA1") + "' "
		cCondicao += " .AND. SA1->A1_MSBLQL <> '1' "

		If !Empty(_cGet1)
			cCondicao += " .AND. ('" + AllTrim(_cGet1) + "' $ SA1->A1_NOME .OR. '" + AllTrim(_cGet1) + "' $ SA1->A1_NREDUZ ) "
		EndIf

		If !Empty(_cGet2)
			cCondicao += " .AND. '" + AllTrim(_cGet2) + "' $ SA1->A1_CGC "
		EndIf

		If !Empty(_cGet3)
			cCondicao += " .AND. '" + AllTrim(_cGet3) + "' $ SA1->A1_COD "
		EndIf

		If !Empty(_cGet4)
			cCondicao += " .AND. '" + AllTrim(_cGet4) + "' $ SA1->A1_LOJA "
		EndIf

		If !Empty(_cGet6)
			cCondicao += " .AND. '" + AllTrim(_cGet6)  + "' $ SA1->A1_MUN "
		EndIf

		If !Empty(_cGet7)
			cCondicao += " .AND. '" + AllTrim(_cGet7) + "' $ SA1->A1_EST "
		EndIf

		If !Empty(_cGet8)
			cCondicao += " .AND. '" + AllTrim(_cGet8) + "' $ SA1->A1_GRPVEN "
		EndIf

		SA1->(DbSetOrder(1))

		// limpo os filtros da SA1
		SA1->(DbClearFilter())

		If !Empty(cCondicao)
			// faço um filtro na SA1
			bCondicao 	:= "{|| " + cCondicao + " }"
			SA1->(DbSetFilter(&bCondicao,cCondicao))
		EndIf

		// posiciono no primeiro item da SA1
		SA1->(DbGoTop())

		While SA1->(!Eof())

			// se o campo grupo do cliente estiver preenchido
			If !Empty(_cGet5) .and. Empty(_cGet8)
				// verifico se existe o grupo na AC8 com a descrição informada
				ACY->(DbSetOrder(1))
				If !(ACY->(DbSeek(xFilial("ACY") + SA1->A1_GRPVEN)) .AND. AllTrim(_cGet5) $ ACY->ACY_DESCRI)
					SA1->(DbSkip())
					Loop
				EndIf
			EndIf

			aFieldFill := {}

			aadd(aFieldFill, SA1->A1_COD)
			aadd(aFieldFill, SA1->A1_LOJA)
			aadd(aFieldFill, SA1->A1_CGC)
			aadd(aFieldFill, SA1->A1_NOME)
			aadd(aFieldFill, SA1->A1_NREDUZ)
			aadd(aFieldFill, SA1->A1_EST)
			aadd(aFieldFill, SA1->A1_MUN)
			aadd(aFieldFill, .F.)
			aadd(oGridCli:Acols,aFieldFill)

			SA1->(DbSkip())
		EndDo

		#ENDIF

	EndIf

	// limpo os filtros da SA1
	SA1->(DbClearFilter())

	If !lReta .AND. Empty(oGridCli:Acols)

		aFieldFill := {}

		// Define field values
		For nX := 1 to Len(oGridCli:aHeader)

			If !empty(GetSx3Cache(oGridCli:aHeader[nX,2],"X3_CAMPO"))
				If Alltrim(oGridCli:aHeader[nX,2]) $ "A1_COD/A1_CGC"
					Aadd(aFieldFill, Space(TamSx3(oGridCli:aHeader[nX,2])[1]))
				Else
					Aadd(aFieldFill, CriaVar(oGridCli:aHeader[nX,2]))
				EndIf
			EndIf

		Next nX

		Aadd(aFieldFill, .F.)
		aadd(oGridCli:Acols,aFieldFill)
	EndIf

	If !Empty(oGridCli:Acols)
		oGridCli:oBrowse:Refresh()
	EndIf

Return(.T.)


/*/{Protheus.doc} IncluiSA1
Função que chama a rotina de inclusão de clientes.

@author pablo
@since 26/09/2018
@version 1.0
@return Nil

@type function
/*/
Static Function IncluiSA1()

	Private lAutoExec	:= .F.
	Private lInclui		:= .T.
	Private lAltera		:= .F.
	Private aRotina		:= {}
	Private aRotAuto	:= NIL
	Private cCadastro 	:= "Cadastro de Clientes"

	aadd(aRotina, {"Pesquisar" 		,"PesqBrw"    	, 0 , 1	, 0    	, .F.} )
	aadd(aRotina, {"Visualizar"		, "A030Visual" 	, 0 , 2	, 0   	, NIL} )
	aadd(aRotina, {"Incluir"		, "A030Inclui" 	, 0 , 3	, 81  	, NIL} )
	aadd(aRotina, {"Alterar"		, "A030Altera" 	, 0 , 4	, 143 	, NIL} )
	aadd(aRotina, {"Excluir"		, "A030Deleta" 	, 0 , 5	, 144 	, NIL} )

	A030Inclui("SA1",1,3)

Return()


/*/{Protheus.doc} VisualSA1
Função que chama a rotina de inclusão de clientes.
@author pablo
@since 26/09/2018
@version 1.0
@return Nil

@type function
/*/
Static Function VisualSA1()
	Local aArea    := GetArea()
	Local aAreaSA1 := SA1->(GetArea())

	Private lAutoExec	:= .F.
	Private lInclui		:= .T.
	Private lAltera		:= .F.
	Private aRotina		:= {}
	Private aRotAuto	:= NIL
	Private cCadastro 	:= "Cadastro de Clientes"

	aadd(aRotina, {"Pesquisar" 		,"PesqBrw"    	, 0 , 1	, 0    	, .F.} )
	aadd(aRotina, {"Visualizar"		, "A030Visual" 	, 0 , 2	, 0   	, NIL} )
	aadd(aRotina, {"Incluir"		, "A030Inclui" 	, 0 , 3	, 81  	, NIL} )
	aadd(aRotina, {"Alterar"		, "A030Altera" 	, 0 , 4	, 143 	, NIL} )
	aadd(aRotina, {"Excluir"		, "A030Deleta" 	, 0 , 5	, 144 	, NIL} )

	DbSelectArea("SA1")
	SA1->(DbSetOrder(1))
	If SA1->(DbSeek(xFilial("SA1")+oGridCli:Acols[oGridCli:nAt][aScan(oGridCli:aHeader,{|x| AllTrim(x[2])=="A1_COD"})]+oGridCli:Acols[oGridCli:nAt][aScan(oGridCli:aHeader,{|x| AllTrim(x[2])=="A1_LOJA"})]))
		A030Visual("SA1",1,2)
	EndIf

	RestArea(aAreaSA1)
	RestArea(aArea)

Return()

/*/{Protheus.doc} AtuCadRem
Funcao para atualizar o cadastro do cliente posicionado com a retaguarda.

@author pablo
@since 26/09/2018
@version 1.0
@return Nil

@type function
/*/
Static Function AtuCadRem()

	Local nPos := oGridCli:nAT
	Local nPCli  := aScan(oGridCli:aHeader,{|x| alltrim(x[2]) == "A1_COD" })
	Local nPLoja := aScan(oGridCli:aHeader,{|x| alltrim(x[2]) == "A1_LOJA" })

	if nPos == 0
		Return .T.
	endif

	//-- Preenchimento das Variaveis para a função
	cGetCodCli  := oGridCli:Acols[nPos][nPCli]
	cGetLoja 	:= oGridCli:Acols[nPos][nPLoja]

Return .T.


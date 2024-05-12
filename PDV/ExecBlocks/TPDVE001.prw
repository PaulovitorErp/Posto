#INCLUDE 'PROTHEUS.CH'
#INCLUDE 'hbutton.ch'
#INCLUDE 'topconn.ch'
#INCLUDE 'TbiConn.ch'
#INCLUDE 'poscss.ch'

/*/{Protheus.doc} TPDVE001
Consulta específica de motoristas da tela do posto.

@author Totvs GO
@since 26/09/2018
@version 1.0
@return Nil

@type function
/*/
User Function TPDVE001()

	Local aArea := GetArea()
	Local oButton1
	Local oButton2
	Local oButton3
	Local oButton4
	Local oButton5
	Local oButton6
	Local oSay1
	Local oSay2
	Local oSay3
	Local oSay4
	Local oPnlPrinc
	Local cCor := SuperGetMv( "MV_LJCOLOR",,"07334C")// Cor da tela
	Local cCorBack := RGB(hextodec(SubStr(cCor,1,2)),hextodec(SubStr(cCor,3,2)),hextodec(SubStr(cCor,5,2)))
	Local cCampo := ReadVar()

	Private _cGet1 		:= PADR(iif(cCampo $ "CGETCPF,CGETMOTOR", cGetMotor, ""),TamSX3("DA4_NOME")[1])
	Private _cGet2 		:= PADR(iif(cCampo $ "CGETCPF,CGETMOTOR", cGetCPF, cFilMot),TamSX3("DA4_CGC")[1])
	Private _cGet3 		:= SPACE(TamSX3("DA4_RG")[1])
	Private _oGet1
	Private _oGet2
	Private _oGet3
	Private oPanelMot
	Private oGridMot
	Private cBuscaOld := _cGet1+_cGet2+_cGet3

	Static oDlgMot

	DA4->(DbSetOrder(3)) //DA4_FILIAL+DA4_CGC
	If !empty(_cGet2) .AND. DA4->(!DbSeek(xFilial("DA4")+_cGet2))
		If MsgYesNo("Motorista nao cadastrado, deseja incluí-lo?","Atenção")
			nOpcRet := FWExecView('Inclusao de Motorista', 'OMSA040', 3,, {|| .T. /*fecha janela no ok*/ })
			If nOpcRet == 0 //e se confirmou cadastro de motorista
				ConfirmaDados(.T., cCampo)
				RestArea(aArea)
				Return(.T.)
			Endif
		EndIf
	EndIf


	DEFINE MSDIALOG oDlgMot TITLE "Consulta de Motoristas" FROM 000, 000  TO 550, 600 COLORS 0, 16777215 PIXEL

	//pnl Principal
	@ 0,0 MSPANEL oPnlPrinc SIZE 500, 500 OF oDlgMot COLORS 0, cCorBack
	oPnlPrinc:Align := CONTROL_ALIGN_ALLCLIENT

	// crio o panel para mudar a cor da tela
	@ 004, 0 MSPANEL oPanelMot SIZE 300, 272 OF oPnlPrinc //COLORS 0, RGB(40,79,102)
	oPanelMot:SetCSS( POSCSS (GetClassName(oPanelMot), CSS_PANEL_CONTEXT ))

	@ 005, 010 SAY oSay4 PROMPT "Filtros - Consulta de Motoristas" SIZE 393, 008 OF oPanelMot FONT COLORS 0, 16777215 PIXEL
	oSay4:SetCSS( POSCSS (GetClassName(oSay4), CSS_BREADCUMB ))

	@ 024, 010 SAY oSay1 PROMPT "Motorista" SIZE 040, 007 OF oPanelMot  COLOR 0, 16777215 PIXEL
	oSay1:SetCSS( POSCSS (GetClassName(oSay1), CSS_LABEL_FOCAL ))
	@ 020, 045 MSGET _oGet1 VAR _cGet1 SIZE 200, 013 OF oPanelMot PICTURE PesqPict("","DA4_NOME")  COLORS 0, 16777215 PIXEL VALID SearchDA4()
	_oGet1:SetCSS( POSCSS (GetClassName(_oGet1), CSS_GET_NORMAL ))

	@ 043, 010 SAY oSay2 PROMPT "CPF/CNPJ" SIZE 040, 007 OF oPanelMot  COLOR 0, 16777215 PIXEL
	oSay2:SetCSS( POSCSS (GetClassName(oSay2), CSS_LABEL_FOCAL ))
	@ 039, 045 MSGET _oGet2 VAR _cGet2 SIZE 080, 013 OF oPanelMot PICTURE PesqPict("DA4","DA4_CGC")  COLORS 0, 16777215 PIXEL VALID SearchDA4()
	_oGet2:SetCSS( POSCSS (GetClassName(_oGet2), CSS_GET_NORMAL ))

	@ 043, 150 SAY oSay3 PROMPT "RG" SIZE 029, 007 OF oPanelMot  COLOR 0, 16777215 PIXEL
	oSay3:SetCSS( POSCSS (GetClassName(oSay3), CSS_LABEL_FOCAL ))
	@ 039, 165 MSGET _oGet3 VAR _cGet3 SIZE 080, 013 OF oPanelMot PICTURE PesqPict("DA4","DA4_RG")  COLORS 0, 16777215 PIXEL  VALID SearchDA4()
	_oGet3:SetCSS( POSCSS (GetClassName(_oGet3), CSS_GET_NORMAL ))

	// BOTAO CONSULTAR
	oButton1 := TButton():New(039,;
							250,;
							"C&onsultar",;
							oPanelMot	,;
							{|| LjMsgRun("Aguarde... Buscando Motoristas",,{|| RefreshGrid(.T.) })},;
							45,;
							15,;
							,,,.T.,;
							,,,{|| .T.})
	oButton1:SetCSS( POSCSS (GetClassName(oButton1), CSS_BTN_FOCAL ))

	// BOTAO LIMPAR
	oButton2 := TButton():New(020,;
							250,;
							"&Limpar",;
							oPanelMot	,;
							{|| (LimpaFiltro(),SearchDA4())},;
							45,;
							15,;
							,,,.T.,;
							,,,{|| .T.})
	oButton2:SetCSS( POSCSS (GetClassName(oButton2), CSS_BTN_NORMAL ))

	// crio o grid de motoritas
	oGridMot := MsGridMot()
	//oGridMot:oBrowse:SetCSS( POSCSS("TGRID", CSS_BROWSE) ) //CSS do totvs pdv
	//oGridMot:oBrowse:nScrollType := 0 // mudo o tipo do scroll do grid para barra de rolagem

	// função chamada no duplo clique da linha do grid
	oGridMot:oBrowse:bLDblClick := {|| ConfirmaDados(,cCampo),oDlgMot:End()}

	// preencho o grid de motoristas
	if !empty(cBuscaOld)
		LjMsgRun("Aguarde... Buscando Clientes",,{|| RefreshGrid() })
	endif

	// BOTAO CONFIRMAR
	oButton3 := TButton():New(240,;
							250,;
							"&Confirmar",;
							oPanelMot	,;
							{|| (ConfirmaDados(,cCampo),oDlgMot:End())},;
							45,;
							20,;
							,,,.T.,;
							,,,{|| .T.})
	oButton3:SetCSS( POSCSS (GetClassName(oButton3), CSS_BTN_FOCAL ))

	// BOTAO CANCELAR
	oButton4 := TButton():New(240,;
							200,;
							"C&ancelar",;
							oPanelMot	,;
							{|| oDlgMot:End()},;
							45,;
							20,;
							,,,.T.,;
							,,,{|| .T.})
	oButton4:SetCSS( POSCSS (GetClassName(oButton4), CSS_BTN_ATIVO ))

	// BOTAO INCLUIR
	oButton5 := TButton():New(240,;
							150,;
							"&Incluir",;
							oPanelMot	,;
							{|| (IncMot())},;
							45,;
							20,;
							,,,.T.,;
							,,,{|| .T.})
	oButton5:SetCSS( POSCSS (GetClassName(oButton5), CSS_BTN_NORMAL ))

	// BOTAO ALTERA
	oButton6 := TButton():New(240,;
							100,;
							"Al&terar",;
							oPanelMot	,;
							{|| AlteraMot()},;
							45,;
							20,;
							,,,.T.,;
							,,,{|| .T.})
	oButton6:SetCSS( POSCSS (GetClassName(oButton6), CSS_BTN_NORMAL ))

	ACTIVATE MSDIALOG oDlgMot CENTERED

	RestArea(aArea)

Return(.T.)


/*/{Protheus.doc} MsGridMot
Função que cria a MsNewGetDados dos motoristas.

@author pablo
@since 26/09/2018
@version 1.0
@return Nil

@type function
/*/
Static Function MsGridMot()

	Local nX
	Local aHeaderEx 	:= {}
	Local aColsEx 		:= {}
	Local aFieldFill 	:= {}
	Local aFields 		:= {"DA4_CGC","DA4_RG","DA4_NOME"}
	Local aAlterFields 	:= {}

	// Define field properties
	For nX := 1 to Len(aFields)
		If !empty(GetSx3Cache(aFields[nX],"X3_CAMPO"))
			aadd(aHeaderEx, U_UAHEADER(aFields[nX]) )
		Endif
	Next nX

	// Define field values
	For nX := 1 to Len(aFields)
		If !empty(GetSx3Cache(aFields[nX],"X3_CAMPO"))
			Aadd(aFieldFill, CriaVar(aFields[nX]))
		Endif
	Next nX

	Aadd(aFieldFill, .F.)
	Aadd(aColsEx, aFieldFill)

Return(MsNewGetDados():New( 060, 005, 235, 297,, "AllwaysTrue", "AllwaysTrue", "+Field1+Field2", aAlterFields,, 999, "AllwaysTrue", "", "AllwaysTrue", oPanelMot, aHeaderEx, aColsEx))


/*/{Protheus.doc} LimpaFiltro
Função que limpa o filtro dos motoristas.

@author pablo
@since 26/09/2018
@version 1.0
@return Nil

@type function
/*/
Static Function LimpaFiltro()

	// atualizo as variáveis dos MSGET's
	_cGet1 		:= SPACE(TamSX3("DA4_NOME")[1])
	_cGet2 		:= SPACE(TamSX3("DA4_CGC")[1])
	_cGet3		:= SPACE(TamSX3("DA4_RG")[1])

	// faço um refresh nos MSGET's
	_oGet1:Refresh()
	_oGet2:Refresh()
	_oGet3:Refresh()

Return()


/*/{Protheus.doc} ConfirmaDados
Função que preenche os dados do motorista.

@author pablo
@since 26/09/2018
@version 1.0
@return Nil
@param lSemTela, logical, descricao
@type function
/*/
Static Function ConfirmaDados(lSemTela, cGetRet)

	Default lSemTela := .F.
	Default cGetRet := ""

	if cGetRet $ "CGETCPF,CGETMOTOR"

		if lSemTela

			// atualizo as variáveis
			cGetMotor	:= DA4->DA4_NOME
			cGetCPF		:= DA4->DA4_CGC

		elseif !Empty(oGridMot:Acols) .AND. !Empty(oGridMot:Acols[oGridMot:nAt,aScan(oGridMot:aHeader,{|x| AllTrim(x[2])=="DA4_CGC"})])

			// atualizo as variáveis
			cGetMotor	:= PADR(oGridMot:Acols[oGridMot:nAt,aScan(oGridMot:aHeader,{|x| AllTrim(x[2])=="DA4_NOME"})],TamSX3("DA4_NOME")[1])
			cGetCPF		:= PADR(oGridMot:Acols[oGridMot:nAt,aScan(oGridMot:aHeader,{|x| AllTrim(x[2])=="DA4_CGC"})],TamSX3("DA4_CGC")[1])

		endif

		oGetMotor:Refresh()
		oGetCPF:Refresh()

	elseif cGetRet $ "CFILMOT"

		if !Empty(oGridMot:Acols) .AND. !Empty(oGridMot:Acols[oGridMot:nAt,aScan(oGridMot:aHeader,{|x| AllTrim(x[2])=="DA4_CGC"})])
			cFilMot := PADR(oGridMot:Acols[oGridMot:nAt,aScan(oGridMot:aHeader,{|x| AllTrim(x[2])=="DA4_CGC"})],TamSX3("DA4_CGC")[1])
		endif

		oFilMot:Refresh()

	endif

Return()


/*/{Protheus.doc} SearchDA4
Busca dados de motoristas...

@author pablo
@since 26/09/2018
@version 1.0
@return Nil

@type function
/*/
Static Function SearchDA4()

	if cBuscaOld <> (_cGet1+_cGet2+_cGet3)

		cBuscaOld := _cGet1+_cGet2+_cGet3
		LjMsgRun("Aguarde... Buscando Motoristas",,{|| RefreshGrid() })

	endif

Return(.T.)


/*/{Protheus.doc} RefreshGrid
Função que atualiza o Grid de motoristas.

@author pablo
@since 26/09/2018
@version 1.0
@return Nil
@param lEmpty, logical, descricao
@type function
/*/
Static Function RefreshGrid(lEmpty)

	Local nX	 	:= ""
	Local aDados
	Local aFieldFill 	:= {}
	Local cCondicao		:= ""
	Local bCondicao
	Local nQtdMax		:= 100

	Default lEmpty	:= .F.

	oGridMot:Acols := {}

	if !empty(_cGet1+_cGet2+_cGet3) .OR. lEmpty

		#IFDEF TOP

		If empty(_cGet1+_cGet2+_cGet3) //busca todos

			DA4->(DbSetOrder(3)) //DA4_FILIAL+DA4_CGC
			DA4->(DbGoTop())
			nCount := 0
			While DA4->(!Eof()) .and. (nCount <= nQtdMax)

				aFieldFill := {}

				aadd(aFieldFill, DA4->DA4_CGC)
				aadd(aFieldFill, DA4->DA4_RG)
				aadd(aFieldFill, DA4->DA4_NOME)
				aadd(aFieldFill, .F.)
				aadd(oGridMot:Acols,aFieldFill)

				nCount++
				DA4->(DbSkip())
			EndDo

		Else

			cCondicao := " D_E_L_E_T_ <> '*'"
			cCondicao += " AND DA4_FILIAL = '" + xFilial("DA4") + "'"
			if !Empty(_cGet1)
				cCondicao += "	AND DA4_NOME LIKE '%" + AllTrim(_cGet1) + "%'"
			endif
			if !Empty(_cGet2)
				cCondicao += "	AND DA4_CGC LIKE '%" + AllTrim(_cGet2) + "%'"
			endif
			if !Empty(_cGet3)
				cCondicao += "	AND DA4_RG LIKE '%" + AllTrim(_cGet3) + "%'"
			endif

			aDados := STDQueryDB( {"DA4_CGC","DA4_RG","DA4_NOME"}, {"DA4"}, cCondicao, "DA4_FILIAL, DA4_CGC", nQtdMax )

			for nX := 1 to len(aDados)

				aFieldFill := {}

				aadd(aFieldFill, aDados[nX][1])
				aadd(aFieldFill, aDados[nX][2])
				aadd(aFieldFill, aDados[nX][3])
				aadd(aFieldFill, .F.)
				aadd(oGridMot:Acols,aFieldFill)

			next nX

		EndIf

		#ELSE

		cCondicao := " DA4_FILIAL = '" + XFILIAL("DA4") + "'"

		if !Empty(_cGet1)
			cCondicao += " .AND. '" + AllTrim(_cGet1) + "' $ DA4_NOME "
		endif

		if !Empty(_cGet2)
			cCondicao += " .AND. '" + AllTrim(_cGet2) + "' $ DA4_CGC "
		endif

		if !Empty(_cGet3)
			cCondicao += " .AND. '" + AllTrim(_cGet3) + "' $ DA4_RG "
		endif

		DA4->(DbSetOrder(3)) //DA4_FILIAL+DA4_CGC

		// limpo os filtros da DA4
		DA4->(DbClearFilter())

		if !Empty(cCondicao)

			// faço um filtro na DA4
			bCondicao 	:= "{|| " + cCondicao + " }"
			DA4->(DbSetFilter(&bCondicao,cCondicao))

		endif

		// posiciono no primeiro item da DA4
		DA4->(DbGoTop())

		While DA4->(!Eof())

			aFieldFill := {}

			aadd(aFieldFill, DA4->DA4_CGC)
			aadd(aFieldFill, DA4->DA4_RG)
			aadd(aFieldFill, DA4->DA4_NOME)
			aadd(aFieldFill, .F.)
			aadd(oGridMot:Acols,aFieldFill)

			DA4->(DbSkip())

		EndDo

		// limpo os filtros da DA4
		DA4->(DbClearFilter())

		#ENDIF

	endif

	if Empty(oGridMot:Acols)

		aFieldFill := {}

		// Define field values
		For nX := 1 to Len(oGridMot:aHeader)
			If !empty(GetSx3Cache(oGridMot:aHeader[nX,2],"X3_CAMPO"))
				Aadd(aFieldFill, CriaVar(oGridMot:aHeader[nX,2]))
			Endif
		Next nX

		Aadd(aFieldFill, .F.)
		aadd(oGridMot:Acols,aFieldFill)

	endif

	oGridMot:oBrowse:Refresh()

Return()


/*/{Protheus.doc} AlteraMot
Funcao para chamar MVC de alteracao do cadastro de motorista.

@author pablo
@since 26/09/2018
@version 1.0
@return Nil

@type function
/*/
Static Function AlteraMot()

	Local nPosCpf   := aScan(oGridMot:aHeader,{|x| AllTrim(x[2])=="DA4_CGC"})
	Local aAreaDA4  := DA4->( GetArea() )
	Local cCpf      := oGridMot:Acols[oGridMot:nAt, nPosCpf ]

	If !Empty(cCpf) .And. DA4->( DbSeek( xFilial('DA4') + cCpf ) )
		FWExecView('Alteracao de Motorista','OMSA040', 4,, {|| .T. /*fecha janela no ok*/ } )
	EndIf

	LjMsgRun("Aguarde... Buscando Motoristas",,{|| RefreshGrid(.T.) })

	RestArea(aAreaDA4)

Return()


/*/{Protheus.doc} IncMot
Funcao para chamar MVC de inclusão do cadastro de motorista.
@author pablo
@since 26/09/2018
@version 1.0
@return Nil

@type function
/*/
Static Function IncMot()

	Local cCPf     := ""
	Local nRetorno := 1 //  nValor Retorna 0 se for clicado em OK e 1 em Cancelar.

	nRetorno := FWExecView('Inclusao de Motorista','OMSA040', 3,, {|| .T. /*fecha janela no ok*/ })
	cCPf     := DA4->DA4_CGC

	If nRetorno == 0
		LimpaFiltro()

		_cGet2 := cCPf
		_oGet2:Refresh()
	EndIf

	LjMsgRun("Aguarde... Buscando Motoristas",,{|| RefreshGrid(.T.) })

Return()
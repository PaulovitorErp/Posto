#include 'protheus.ch'
#include 'poscss.ch'

/*/{Protheus.doc} TSearchF3
Consulta de registros via F3 de campos, para PDV

@author    Danilo Brito
@since     13/05/2019
@version   1.0
@example
oCgcCli := TGet():New( 015, 145,{|u| iif( PCount()==0,cCgcCli,cCgcCli:=u) },oPnlInc,85, 013,,{|| VldCliente() },,,,,,.T.,,,{|| .T. },,,,.F.,.F.,,"oCgcCli",,,,.T.,.F.)
TSearchF3():New(oCgcCli,400,250,"SA1","A1_COD",{{"A1_NOME",2},{"A1_CGC",3},{"A1_COD",1}},"SA1->A1_MSBLQL<>'1'",{{"A1_NOME","A1_EST","A1_MUN"},{"A1_CGC","A1_NOME","A1_EST","A1_MUN"},{"A1_COD","A1_LOJA","A1_NOME","A1_EST","A1_MUN"}},,,0)
@see (links_or_references)
/*/

class TSearchF3

	//para criacao do dlg
	DATA oGetPai
	DATA nRow
	DATA nCol
	DATA nWidth
	DATA nHeight
	DATA oMyDLG
	DATA oCboFld
	DATA cCboFld
	DATA aCboFld
	DATA oGetBusca
	DATA cGetBusca
	DATA oTList
	DATA aList
	DATA aRecnos
	DATA oSayErr
	DATA cSayErr
	DATA bSavKeyF3
	DATA lCssPdv
	DATA nPosition
	DATA nAjustPos
	DATA lBySeek
	DATA lUsaSQL
	DATA cAliasJoin
	DATA aChaveJoin

	//var configuracoes da busca/retorno
	DATA cAliasGet
	DATA cFldRet
	DATA aFldBusca
	DATA cFilter
	DATA aFldList
	DATA aFldRet

	method New(oGetPai,nWidth,nHeight,cAliasGet,cFldRet,aFldBusca,cFilter,aFldList,lCssPdv,nPosition,nAjustPos,lBySeek,aFldRet,lUsaSQL, cAliasJoin, aChaveJoin) constructor
	method CriaLista()
	method LimpaBusca()
	method Buscar()
	method Seleciona()

endclass

/*/{Protheus.doc} New
Metodo Construtor
@author Danilo Brito
@since 24/05/2019
@version 1.0
@return oObj
@param oGetPai, object, Objeto TGet onde será implementada funcionalidade
@param nWidth, numeric, Largura da janela a ser criada
@param nHeight, numeric, Algura da Janela a ser criada
@param cAliasGet, characters, Alias da tabela onde será feita a busca
@param cFldRet, characters, Campo a ser retornado pela seleção de um registro
@param aFldBusca, array, [1] Campo da tabela onde será feita a busca; [2] Indice a ser utilizdo para ordem dos registros listados
@param cFilter, characters, Filtros na tabela onde será feita a busca
@param aFldList, array, Campos a serem mostrados na lista (default fica o proprio aFldBusca)
@param lCssPdv, logical, Define se será aplicado o CSS do Totvs PDV
@param nPosition, numeric, Posição do dialog: //1=Abaixo do Get;2=Acima do Get
@param nAjustPos, numeric, Ajuste de posição top
@param lBySeek
@param aFldRet, array, [1] Objeto TGet do retorno; [2] Campo a ser retornado pela seleção de um registro;
@type function
/*/
method New(oGetPai,nWidth,nHeight,cAliasGet,cFldRet,aFldBusca,cFilter,aFldList,lCssPdv,nPosition,nAjustPos,lBySeek,aFldRet, lUsaSQL, cAliasJoin, aChaveJoin) class TSearchF3

	Local aRes := GetScreenRes()
	Local nX := 0

	DEFAULT aFldList := {}
	DEFAULT lCssPdv := .T.
	DEFAULT nPosition := 1 //1=Abaixo;2=Acima
	DEFAULT nAjustPos := 0
	DEFAULT lBySeek := .T.
	DEFAULT aFldRet := {}
	DEFAULT lUsaSQL	:= .F.
	DEFAULT cAliasJoin	:= ""
	DEFAULT aChaveJoin	:= {}

	::oGetPai := oGetPai
	::nWidth := nWidth
	::nHeight := nHeight
	::nPosition := nPosition
	::nRow := ::oGetPai:nTop
	::nCol := ::oGetPai:nLeft
	::nAjustPos := nAjustPos

	if ::nPosition == 1
		::nRow += ::oGetPai:nHeight
	else
		::nRow -= ::oGetPai:nHeight
	endif

	::nRow += ::nAjustPos

	//descobrindo a posição do get na tela
	oParent := ::oGetPai:oParent //painel onde está o campo
	nHWNDDlg := ::oGetPai:oWnd:hWnd //id do DLG ativo
	While .T.
		_nHWND := oParent:hWnd
		if _nHWND == nHWNDDlg //quando chegar no proprio dlg, sai
			EXIT
		endif
		::nRow += oParent:nTop
		::nCol += oParent:nLeft
		oParent := oParent:oParent //proximo painel
	enddo
	//considero que o DLG do get pai pode estar centralizado, portanto ajusto posição
	::nCol += ((aRes[1] - ::oGetPai:oWnd:nWidth)/2)
	::nRow += ((aRes[2] - ::oGetPai:oWnd:nHeight)/2)

	::oGetPai:cF3 := cAliasGet
	::oGetPai:bF3 := {|| ::CriaLista() }
	::oGetPai:bGotFocus := {|| ::bSavKeyF3 := SetKey(VK_F3), SetKey(VK_F3, {|| ::CriaLista() }) }
	::oGetPai:bLostFocus := {|| iif(Eval(::oGetPai:bValid),SetKey(VK_F3, ::bSavKeyF3),) }

	::cAliasGet := cAliasGet
	::cFldRet := cFldRet
	::aFldRet := aFldRet
	::aFldBusca := aFldBusca
	::cFilter := cFilter
	::aFldList := aFldList

	if valType(::aFldList) <> "A"
		::aFldList := {}
	endif

	if len(::aFldList) <= 0
		for nX:=1 to len(::aFldBusca)
			aadd(::aFldList, {::aFldBusca[nX][1]})
		next nX
	endif

	::aCboFld := {}
	for nX:=1 to len(::aFldBusca)
		aadd(::aCboFld, FWX3Titulo(::aFldBusca[nX][1]) )
	next nX

	::cCboFld := FWX3Titulo(::aFldBusca[1][1])

	::aRecnos := {}
	::lCssPdv := lCssPdv

	::lBySeek := lBySeek

	::lUsaSQL := lUsaSQL
	::cAliasJoin	:= cAliasJoin
	::aChaveJoin	:= aChaveJoin

Return

/*/{Protheus.doc} CriaLista
Criação da tela de busca (lista)
@author Danilo Brito
@since 24/05/2019
@version 1.0
@return Nil
@type function
/*/
method CriaLista() class TSearchF3

	Local oSay1, oPnlAux
	Local cCorBg := SuperGetMv( "MV_LJCOLOR",,"07334C")// Cor da tela
	Local oBySeek

	SetKey(VK_F3, {|| })

	if ::nPosition==1
		DEFINE MSDIALOG ::oMyDLG TITLE "Lista" FROM ::nRow, ::nCol TO (::nRow+::nHeight), (::nCol+::nWidth) COLORS 0, 16777215 PIXEL STYLE nOr(WS_VISIBLE,WS_POPUP)
	else
		DEFINE MSDIALOG ::oMyDLG TITLE "Lista" FROM (::nRow-::nHeight), ::nCol TO ::nRow, (::nCol+::nWidth) COLORS 0, 16777215 PIXEL STYLE nOr(WS_VISIBLE,WS_POPUP)
	endif

	@ 000, 000 MSPANEL oPnlAux SIZE 10, 10 OF ::oMyDLG
	oPnlAux:Align := CONTROL_ALIGN_ALLCLIENT
	oPnlAux:SetCSS( "TPanel{border: 1px solid #000000; background-color: #f4f4f4;}" )

	::oGetBusca := TGet():New( 013, 005,{|u| iif( PCount()==0,::cGetBusca,::cGetBusca:=u) },oPnlAux,(::nWidth/2)-5, 013,"@!",{|| .T. /*bValid*/},,,,,,.T.,,,{|| .T. },,,{|| ::Buscar() /*bChange*/},.F.,.F.,,::cGetBusca,,,,.T.,.F.)
	if ::lCssPdv
		::oGetBusca:SetCSS( POSCSS( GetClassName(::oGetBusca), CSS_GET_NORMAL ))
	endif

	::cGetBusca := Space(TamSX3(::aFldBusca[1][1])[1])
	@ 003, 004 SAY oSay1 PROMPT ("Buscar por: ") SIZE (::nWidth/2)-5, 010 OF oPnlAux COLORS 0, 16777215 PIXEL
	if ::lCssPdv
		oSay1:SetCSS( POSCSS( GetClassName(oSay1), CSS_LABEL_FOCAL ))
	endif

	::aList := {}
	::oTList := TListBox():Create(oPnlAux, 030, 005, Nil, ::aList, (::nWidth/2)-6,(::nHeight/2)-35,,,,,.T.,,{|| ::Seleciona() })
	if ::lCssPdv
		::oTList:SetCSS(POSCSS(GetClassName(::oTList), CSS_LISTBOX))
	endif
	//::oTList:bLDBLClick := {|| ::Seleciona() }

	::oCboFld := TComboBox():New(002, 042, {|u| If(PCount()>0,::cCboFld:=u,::cCboFld)}, ::aCboFld, 100, 010, oPnlAux, Nil , {|| ::LimpaBusca()}/* bChange */, /* bValid*/, /* nClrBack*/, /* nClrText*/, .T./* lPixel*/,  , Nil, Nil, /* bWhen*/, Nil, Nil, Nil, Nil, ::cCboFld, /* cLabelText*/ ,/* nLabelPos*/,  , /*nLabelColor*/  )
	if ::lCssPdv
		::oCboFld:SetCSS( POSCSS(CSS_GET_FOCAL) )
	endif

	@ 003, (::nWidth/2)-57 CHECKBOX oBySeek VAR ::lBySeek PROMPT 'que começa com' SIZE 055,010 OF oPnlAux COLORS 0, 16777215 ON CHANGE (::Buscar()) PIXEL

	::cSayErr := ""
	@ (::nHeight/2), 006 SAY ::oSayErr PROMPT ::cSayErr SIZE (::nWidth/2)-5, 010 OF oPnlAux COLORS 0, 16777215 PIXEL
	::oSayErr:SetCSS( "TSay{ color: #"+cCorBg+"; }" )

	ACTIVATE MSDIALOG ::oMyDLG //CENTERED

	SetKey(VK_F3, {|| ::CriaLista() })
return

/*/{Protheus.doc} Limpar busca quando mudar campo de busca
Função limpa a busca, quando mudar o campo de busca
@author Totvs GO
@since 02/09/2019
@version 1.0
@return Nil
@type function
/*/
method LimpaBusca() class TSearchF3

	::cGetBusca := Space(TamSX3(::aFldBusca[::oCboFld:nAt][1])[1])
	::aList := {}
	::aRecnos := {}
	::cSayErr := ""
	::oTList:SetItems(::aList)
	::oTList:Refresh()
	::oTList:GoTop()

Return .T.

/*/{Protheus.doc} Buscar
Função para busca dos registros a serem listados
@author thebr
@since 24/05/2019
@version 1.0
@return Nil
@type function
/*/
method Buscar() class TSearchF3

	Local cQuery := ""
	Local nCount := 0
	Local nJoin  := 0
	Local nLimit := 50
	Local lRet := .T.
	Local cCondicao, bCondicao, nX, cLinha
	Local cPfxCp := iif(SubStr(::cAliasGet,1,1)=="S",SubStr(::cAliasGet,2,2),::cAliasGet)
	Local cChvIndex := (::cAliasGet)->( IndexKey( ::aFldBusca[::oCboFld:nAt][2] ) )
	Local nTamBusca := len(AllTrim(::cGetBusca))

	::aList := {}
	::aRecnos := {}

	::cSayErr := "Buscando registros... Aguarde..."
	::oSayErr:Refresh()

	CursorArrow()
	CursorWait()

	if nTamBusca >= 3

		(::cAliasGet)->(DbSetOrder(::aFldBusca[::oCboFld:nAt][2]))

		If ::lUsaSQL // determino se faco a query SQL

			cQuery := " SELECT " + ::cAliasGet + ".R_E_C_N_O_ REG FROM " + RetSQLName(::cAliasGet) + " " + ::cAliasGet + " "

			If !Empty(AllTrim(::cAliasJoin))
				cQuery += " INNER JOIN " + RetSQLName(::cAliasJoin) + " " + ::cAliasJoin + " "
				cQuery += " ON " + ::cAliasJoin + ".D_E_L_E_T_ = ' ' "

				If Len(::aChaveJoin) > 0
					For nJoin := 1 To Len(::aChaveJoin)
						If "FILIAL" $ ::aChaveJoin[nJoin, 1]
							cQuery += " AND " + ::cAliasJoin + "." + ::aChaveJoin[nJoin, 1] + " = '" + xFilial(::cAliasJoin) + "' "
						Else
							cQuery += " AND " + ::cAliasJoin + "." + ::aChaveJoin[nJoin, 1] + " = " + ::cAliasGet + "." + ::aChaveJoin[nJoin, 2] + " "
						EndIf
					Next nJoin
				EndIf

			EndIf

			cQuery += " WHERE " + ::cAliasGet + ".D_E_L_E_T_ = ' ' "
			cQuery += " AND " + ::cAliasGet + "." + cPfxCp + "_FILIAL = '" + xFilial(::cAliasGet) + "' "
			cQuery += " AND " + ::cAliasGet + "." + ::aFldBusca[::oCboFld:nAt][1]+" LIKE '%" + AllTrim(::cGetBusca) + "%'"
			cQuery += " AND " + ::cAliasGet + "." + SubStr( ::cFilter, 6 )

			cQuery := ChangeQuery(cQuery)

			// executo a query e crio o alias temporario
			MPSysOpenQuery( cQuery, 'TRBFIL' )

			If TRBFIL->(!Eof())
				While TRBFIL->(!Eof())
					(::cAliasGet)->(DbGoTo(TRBFIL->REG))
					cLinha := ""
					for nX := 1 to len(::aFldList[::oCboFld:nAt])
						if !empty(cLinha)
							cLinha += " | "
						endif
						cLinha += AllTrim((::cAliasGet)->&(::aFldList[::oCboFld:nAt][nX]))
					next nX
					aadd(::aList, cLinha)
					aadd(::aRecnos, (::cAliasGet)->(Recno()) )

					nCount++
					If nCount == nLimit
						Exit
					EndIf

					TRBFIL->(DbSkip())
				EndDo
			EndIf

		Elseif ::lBySeek //que começas com: faz o seek

			//fazendo filtro
			cCondicao := ::cAliasGet+"->"+cPfxCp+"_FILIAL = '" + xFilial(::cAliasGet) + "' "
			if !empty(::cFilter)
				cCondicao += " .AND. ("+::cFilter+")"
			endif
			cCondicao += " .AND. '" + AllTrim(::cGetBusca) + "' $ "+::cAliasGet+"->"+::aFldBusca[::oCboFld:nAt][1]+" "

			if (::cAliasGet)->(DbSeek(xFilial(::cAliasGet)+AllTrim(::cGetBusca) ))
				While (::cAliasGet)->(!Eof()) ;
						.AND. SubStr((::cAliasGet)->&(cChvIndex),1,len(cFilAnt)+nTamBusca) == xFilial(::cAliasGet)+AllTrim(::cGetBusca) ;
						.AND. nCount < nLimit

					if &(AllTrim(cCondicao))
						cLinha := ""
						for nX := 1 to len(::aFldList[::oCboFld:nAt])
							if !empty(cLinha)
								cLinha += " | "
							endif
							cLinha += AllTrim((::cAliasGet)->&(::aFldList[::oCboFld:nAt][nX]))
						next nX
						aadd(::aList, cLinha)
						aadd(::aRecnos, (::cAliasGet)->(Recno()) )
						nCount++
					endif

					(::cAliasGet)->(DbSkip())
				enddo
			endif

		else //faz filtro via DbSetFilter

			//fazendo filtro
			cCondicao := ::cAliasGet+"->"+cPfxCp+"_FILIAL = '" + xFilial(::cAliasGet) + "' "
			if !empty(::cFilter)
				cCondicao += " .AND. ("+::cFilter+")"
			endif
			cCondicao += " .AND. '" + AllTrim(::cGetBusca) + "' $ "+::cAliasGet+"->"+::aFldBusca[::oCboFld:nAt][1]+" "

			(::cAliasGet)->(DbSetOrder())
			(::cAliasGet)->(DbClearFilter())
			(::cAliasGet)->(DbGoTop())

			//If (::cAliasGet)->(!EOF())
			//	(::cAliasGet)->(DbGoTo((::cAliasGet)->(LastRec())+1))
			//EndIf

			bCondicao := "{|| " + cCondicao + " }"
			(::cAliasGet)->(DbSetFilter(&bCondicao, cCondicao))
			//(::cAliasGet)->(DbSetFilter({ || &cCondicao }, cCondicao))
			//(::cAliasGet)->(DbSkip(-1))
			(::cAliasGet)->(DbGoTop())

			While (::cAliasGet)->(!EOF())

				cLinha := ""
				For nX := 1 to Len(::aFldList[::oCboFld:nAt])
					If !empty(cLinha)
						cLinha += " | "
					EndIf
					cLinha += AllTrim((::cAliasGet)->&(::aFldList[::oCboFld:nAt][nX]))
				Next nX
				aadd(::aList, cLinha)
				aadd(::aRecnos, (::cAliasGet)->(Recno()) )

				nCount++
				If nCount == nLimit
					EXIT
				EndIf

				(::cAliasGet)->(DbSkip())
			EndDo
			(::cAliasGet)->(DbClearFilter())


			//cCondicao := ""
			//if !empty(::cFilter)
			//	cCondicao += " ("+::cFilter+")"
			//endif
			//if !empty(cCondicao)
			//	cCondicao += " .AND. "
			//endif
			//cCondicao += "'" + AllTrim(::cGetBusca) + "' $ "+::cAliasGet+"->"+::aFldBusca[::oCboFld:nAt][1]+" "

			//(::cAliasGet)->(DbGoTop())
			//if (::cAliasGet)->(DbSeek(xFilial(::cAliasGet) ))
			//	While (::cAliasGet)->(!Eof())

			//		if (::cAliasGet)->(&cCondicao)
			//
			//			cLinha := ""
			//			for nX := 1 to len(::aFldList[::oCboFld:nAt])
			//				if !empty(cLinha)
			//					cLinha += " | "
			//				endif
			//				cLinha += AllTrim((::cAliasGet)->&(::aFldList[::oCboFld:nAt][nX]))
			//			next nX
			//			aadd(::aList, cLinha)
			//			aadd(::aRecnos, (::cAliasGet)->(Recno()) )
			//
			//			nCount++
			//			if nCount == nLimit
			//				EXIT
			//			endif
			//		endif

			//		(::cAliasGet)->(DbSkip())
			//	EndDo
			//endif


			/*	
			//fazendo filtro
			cCondicao := ::cAliasGet+"->"+cPfxCp+"_FILIAL = '" + xFilial(::cAliasGet) + "' "
			if !empty(::cFilter)
				cCondicao += " .AND. ("+::cFilter+")"
			endif
			cCondicao += " .AND. '" + AllTrim(::cGetBusca) + "' $ "+::cAliasGet+"->"+::aFldBusca[::oCboFld:nAt][1]+" "

			(::cAliasGet)->(DbClearFilter())
			bCondicao 	:= "{|| " + cCondicao + " }"
			(::cAliasGet)->(DbSetFilter(&bCondicao,cCondicao))

			// posiciono no primeiro item da tabela
			(::cAliasGet)->(DbGoTop())
			While (::cAliasGet)->(!Eof()) .AND. nCount < nLimit
				cLinha := ""
				for nX := 1 to len(::aFldList[::oCboFld:nAt])
					if !empty(cLinha)
						cLinha += " | "
					endif
					cLinha += AllTrim((::cAliasGet)->&(::aFldList[::oCboFld:nAt][nX]))
				next nX
				aadd(::aList, cLinha)
				aadd(::aRecnos, (::cAliasGet)->(Recno()) )

				nCount++
				(::cAliasGet)->(DbSkip())
			EndDo

			(::cAliasGet)->(DbClearFilter())*/

		endif
		
		if nCount == nLimit
			::cSayErr := "Resultado foi limitado a "+cValToChar(nLimit)+" registros. Refine sua busca se for necessário."
		else
			::cSayErr := cValToChar(nCount)+" registros encontrados!"
		endif
	else
		::cSayErr := "É necessário digitar pelo menos 3 caracteres."
	endif

	if empty(::aRecnos) //se nao encontrou resultados, mantem foco no get
		lRet := .F.
	endif

	CursorArrow()

	::oSayErr:Refresh()
	::oTList:SetItems(::aList)
	::oTList:Refresh()
	::oTList:GoTop()

Return lRet

/*/{Protheus.doc} Seleciona
Função que faz o retorno retorno da seleção para o get e fecha a busca
@author Danilo Brito
@since 24/05/2019
@version 1.0
@return Nil
@type function
/*/
method Seleciona() class TSearchF3
	Local cRet := ""
	Local nX := 0

	if empty(::aRecnos)
		Return
	endif

	if valtype(::oGetPai) != "O"
		Return
	endif
	
	if ::aRecnos[::oTList:GetPos()] > 0
		(::cAliasGet)->(DbGoTo( ::aRecnos[::oTList:GetPos()] ))
		cRet := (::cAliasGet)->&(::cFldRet)
	endif

	::oGetPai:cText := PadR(cRet,Len(::oGetPai:cText))
	::oGetPai:Refresh()

	for nX:=1 to len(::aFldRet)
		::aFldRet[nX][1]:cText := PadR((::cAliasGet)->&(::aFldRet[nX][2]),Len(::aFldRet[nX][1]:cText))
		::aFldRet[nX][1]:Refresh()
	next nX

	::oMyDLG:end()

Return

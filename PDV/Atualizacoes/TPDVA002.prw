#include 'protheus.ch'
#include 'parmtype.ch'
#include 'hbutton.ch'
#include 'topconn.ch'
#include 'tbiconn.ch'
#include 'poscss.ch'
#include 'rwmake.ch'

Static aIDEnt := {}
Static oPnlGeral
Static oPnlBrow
Static oMsGetAB
Static oQtdAbAB
Static cQtdAbAB := "0"
Static aFieldAB	:= {"L2_NUM","L1_SERIE","L1_DOC","L1_PDV","L1_PLACA","MID_CODBIC","MHZ_DESPRO","MID_LITABA","MID_PREPLI","MID_TOTAPA","L1_EMISNF","L1_HORA","L1_SITUA","MID_ENCFIN","A3_NOME","MID_RFID","MID_NUMORC","MHZ_CODPRO","MID_DATACO","MID_HORACO","MID_CODTAN","MID_CODABA","MID_SEQUE","MID_NLOGIC","MIC_XCONCE"}
Static oFDataAB
Static dFDataAB	:= Date() //filtro abastecimentos por data
Static dCDataAB	:= Date() //filtro abastecimentos por data
Static oFPlacaAB
Static cFPlacaAB := Space(TamSX3("L1_PLACA")[1])
Static cCPlacaAB := Space(TamSX3("L1_PLACA")[1])
Static oFVendAB
Static cFVendAB	:= Space(TamSX3("A3_COD")[1]) //filtro abastecimentos por vendedor
Static cCVendAB	:= Space(TamSX3("A3_COD")[1]) //filtro abastecimentos por vendedor
Static oFBicoAB
Static cFBicoAB	:= Space(TamSx3("MID_CODBIC")[1]) //filtro abastecimentos por numero de bico
Static cCBicoAB	:= Space(TamSx3("MID_CODBIC")[1]) //filtro abastecimentos por numero de bico
Static nColOrder := 0
Static __XVEZ := "0"
Static _nMarca := 1

/*/{Protheus.doc} TPDVA002
Tela que lista abastecimentos baixados no PDV.

@author Pablo Cavalcante
@since 11/07/2017
@version 1.0

@return Nil

@type function
/*/
User Function TPDVA002(oPnlPrinc)

	Local nWidth, nHeight
	Local oPnlGrid, oPnlAux
	Local cCorBg := SuperGetMv("MV_LJCOLOR",,"07334C")// Cor da tela
	Local aStation := STBInfoEst( 1, .T. ) // [1]-CAIXA [2]-ESTACAO [3]-SERIE [4]-PDV [5]-LG_SERNFIS
	Local lNfce := iif( SLG->( FieldPos("LG_NFCE") ) > 0, SLG->LG_NFCE, .F. ) //Sinaliza se utiliza NFC-e
	
	nWidth := oPnlPrinc:nWidth/2
	nHeight := oPnlPrinc:nHeight/2

	//painel geral da tela (mesmo tamanho da principal)
	oPnlGeral := TPanel():New(000,000,"",oPnlPrinc,NIL,.T.,.F.,,,nWidth,nHeight,.T.,.F.)

	@ 002, 002 SAY oSay1 PROMPT "ABASTECIMENTOS BAIXADOS - PDV: "+aStation[4]/*cPDV*/ SIZE nWidth-004, 015 OF oPnlGeral COLORS 0, 16777215 PIXEL CENTER
	oSay1:SetCSS( POSCSS (GetClassName(oSay1), CSS_BTN_FOCAL ))

	//Painel de Browse das compensações
	oPnlBrow := TPanel():New(020,000,"",oPnlGeral,NIL,.T.,.F.,,,nWidth,nHeight-020,,.T.,.F.)

	@ 005, 005 SAY oSay3 PROMPT "Dt Abast.:" SIZE 035, 008 OF oPnlBrow /*FONT oFntLblCab*/ COLORS 0, 16777215 PIXEL
	oSay3:SetCSS( POSCSS (GetClassName(oSay3), CSS_LABEL_FOCAL ))
	@ 015, 005 MSGET oFDataAB VAR dFDataAB SIZE 060, 013 OF oPnlBrow VALID (RefreshAB(.T.)) PICTURE "@!" COLORS 0, 16777215 /*FONT oFntGetCab*/ HASBUTTON PIXEL
	oFDataAB:SetCSS( POSCSS (GetClassName(oFDataAB), CSS_GET_NORMAL ))

	@ 005, 070 SAY oSay5 PROMPT "Placa:" SIZE 035, 008 OF oPnlBrow COLORS 0, 16777215 PIXEL
	oSay5:SetCSS( POSCSS (GetClassName(oSay5), CSS_LABEL_FOCAL ))
	oFPlacaAB := TGet():New( 015, 070,{|u| iif( PCount()==0,cFPlacaAB,cFPlacaAB:=u) },oPnlBrow,045, 013,"@!R NNN-9N99",{|| RefreshAB(.T.) },,,,,,.T.,,,{|| .T. },,,,.F.,.F.,,"cFPlacaAB",,,,.T.,.F.)
	oFPlacaAB:SetCSS( POSCSS (GetClassName(oFPlacaAB), CSS_GET_NORMAL ))

	@ 005, 130 SAY oSay1 PROMPT "Vendedor:" SIZE 035, 008 OF oPnlBrow /*FONT oFntLblCab*/ COLORS 0, 16777215 PIXEL
	oSay1:SetCSS( POSCSS (GetClassName(oSay1), CSS_LABEL_FOCAL ))
	@ 015, 130 MSGET oFVendAB VAR cFVendAB SIZE 060, 013 OF oPnlBrow VALID (RefreshAB(.T.)) PICTURE "@!" COLORS 0, 16777215 /*FONT oFntGetCab*/ HASBUTTON PIXEL
	oFVendAB:SetCSS( POSCSS (GetClassName(oFVendAB), CSS_GET_NORMAL ))
	TSearchF3():New(oFVendAB,400,180,"SA3","A3_COD",{{"A3_NOME",2}},"",,,,0)

	@ 005, 190 SAY oSay2 PROMPT "Bico:" SIZE 025, 008 OF oPnlBrow /*FONT oFntLblCab*/ COLORS 0, 16777215 PIXEL
	oSay2:SetCSS( POSCSS (GetClassName(oSay2), CSS_LABEL_FOCAL ))
	@ 015, 190 MSGET oFBicoAB VAR cFBicoAB SIZE 040, 013 OF oPnlBrow VALID (RefreshAB(.T.)) PICTURE "@!" COLORS 0, 16777215 /*FONT oFntGetCab*/ HASBUTTON PIXEL
	oFBicoAB:SetCSS( POSCSS (GetClassName(oFBicoAB), CSS_GET_NORMAL ))
	TSearchF3():New(oFBicoAB,400,250,"MIC","MIC_CODBIC",{{"MIC_CODBIC",1}},"",{{"MIC_CODBIC","MIC_NLOGIC","MIC_LADO"}},,,0,.F.)

	oBtn1 := TButton():New( 015, 325, "Limpar Filtros", oPnlBrow, {|| LimpaFilAbast() },060,015,,,,.T.,,,,{|| .T.})
	oBtn1:SetCSS( POSCSS (GetClassName(oBtn1), CSS_BTN_FOCAL ))

	//GRID
	@ 035, 003 MSPANEL oPnlGrid SIZE nWidth-4, nHeight-80 OF oPnlBrow

	@ 000,000 BITMAP oTop RESOURCE "x.png" NOBORDER SIZE 000,005 OF oPnlGrid ADJUST PIXEL
	oTop:Align := CONTROL_ALIGN_TOP
	//oTop:SetCSS( POSCSS (GetClassName(oTop), CSS_PANEL_HEADER ))
	oTop:SetCSS("TBitmap{ margin: 0px 9px 0px 5px; border: 1px solid #"+cCorBg+"; background-color: #"+cCorBg+"; border-top-right-radius: 8px; border-top-left-radius: 8px; }")
	oTop:ReadClientCoors(.T.,.T.)

	@ 000,000 BITMAP oBottom RESOURCE "x.png" NOBORDER SIZE 000,025 OF oPnlGrid ADJUST PIXEL
	oBottom:Align := CONTROL_ALIGN_BOTTOM
	oBottom:SetCSS( POSCSS (GetClassName(oBottom), CSS_PANEL_FOOTER ) )
	oBottom:ReadClientCoors(.T.,.T.)

	@ 000,000 BITMAP oContent RESOURCE "x.png" NOBORDER SIZE 000,000 OF oPnlGrid ADJUST PIXEL
	oContent:Align := CONTROL_ALIGN_ALLCLIENT
	oContent:ReadClientCoors(.T.,.T.)
	oPnlAux := POSBrwContainer(oContent)
	
	// Grid de abastecimentos
	oMsGetAB := bMsGetAB(093, 005, (aRes[2]/2)-043, (aRes[1]/2)-6, oPnlAux)
	oMsGetAB:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT
	oMsGetAB:oBrowse:SetCSS( StrTran(POSCSS("TGRID", CSS_BROWSE),"gridline-color: white;","") ) //CSS do totvs pdv
	//oMsGetAB:oBrowse:lCanGotFocus := .F.
	oMsGetAB:oBrowse:nScrollType := 0
	oMsGetAB:oBrowse:lHScroll := .F.

	// função chamada no duplo clique do grid de abastecimentos
	oMsGetAB:oBrowse:bLDblClick := {|| IIF(oMsGetAB:oBrowse:nColPos == aScan(oMsGetAB:aHeader,{|x| AllTrim(x[2])=="MARK"}),DbClique(oMsGetAB),DbClique(oMsGetAB)) }
	oMsGetAB:oBrowse:bHeaderClick := {|oBrw1,nCol| IIF(oMsGetAB:oBrowse:nColPos <> 111 .and. nCol == 1, ( MarcaTodos(oMsGetAB), oBrw1:SetFocus() ), ( OrderGrid(oMsGetAB,nCol), nColOrder := nCol ))}

	@ (oPnlGrid:nHeight/2)-22, 010 SAY oQtdAbAB PROMPT (cQtdAbAB+" abastecimentos encontrados") SIZE 150, 010 OF oPnlGrid COLORS 0, 16777215 PIXEL
	oQtdAbAB:SetCSS( POSCSS (GetClassName(oQtdAbAB), CSS_LABEL_NORMAL))

	oBtn2 := TButton():New( nHeight-45,005,"Reimprimir NFCe/NFe",oPnlBrow,{|| ReImprAB() },080,020,,,,.T.,,,,{|| lNfce })
	oBtn2:SetCSS( POSCSS (GetClassName(oBtn2), CSS_BTN_FOCAL ))

	oBtn3 := TButton():New( nHeight-45,095,"Rel. Movimen. Placa",oPnlBrow,{|| U_TRETR023() },080,020,,,,.T.,,,,{|| .T. })
	oBtn3:SetCSS( POSCSS (GetClassName(oBtn3), CSS_BTN_FOCAL ))

	RefreshAB()

Return

//
// Função para limpar filtro de abastecimentos
//
Static Function LimpaFilAbast()

	dFDataAB := Date()
	oFDataAB:Refresh()
	cFPlacaAB := Space(TamSx3("L1_PLACA")[1])
	oFPlacaAB:Refresh()
	cFVendAB := Space(TamSX3("A3_COD")[1])
	oFVendAB:Refresh()
	cFBicoAB := Space(TamSx3("MID_CODBIC")[1])
	oFBicoAB:Refresh()
	cQtdAbAB := "0"
	oQtdAbAB:Refresh()

	RefreshAB()

Return

//
// Função que faz o Refresh das vendas baixadas
//
Static Function RefreshAB(lConsult)
	Default lConsult := .F. //quando de origem da validação dos campos Vendedor e Bico
	LjMsgRun("Consultando abastecimentos baixados...",,{|| RRefreshAB(lConsult)})
Return(.T.)

Static Function RRefreshAB(lConsult)

	Local aArea	:= GetArea()
	Local aAreaMID	:= MID->(GetArea())
	Local aAreaSL1	:= SL1->(GetArea())
	Local aAreaSL2	:= SL2->(GetArea())

	Local _nX 			:= 1
	Local _aFieldFill	:= {}
	Local _lRet			:= .T.
	Local _aAux			:= aClone(oMsGetAB:aCols)
	Local _nExiste		:= 0
	Local nPosAbst		:= aScan(oMsGetAB:aHeader,{|x| AllTrim(x[2]) == "MID_CODABA"})
	Local nRegPos		:= oMsGetAB:oBrowse:nAt
	Local aAuxAcols		:= {} // variavel auxiliar para simular o acols do newgetdados
	Local nCountAbast	:= 0

	Local aFields, aTables, cWhere, cOrderBy, aParam, aResult
	Local nCodRet := 0
	Local lHasConnect := .F.
	Local lHostError := .F.
	Local nPResult := 0

	//ajsute tamanho de campo bico colocando zeros a esquerda
	MIC->(DbSetOrder(3)) //MIC_FILIAL+MIC_CODBIC+MIC_CODTAN
	If !Empty(cFBicoAB)
		If !MIC->(DbSeek(xFilial("MIC")+cFBicoAB))
			If MIC->(DbSeek(xFilial("MIC")+padl(AllTrim(cFBicoAB),tamsx3("MIC_CODBIC")[1],"0")))
				cFBicoAB := padl(AllTrim(cFBicoAB),tamsx3("MIC_CODBIC")[1],"0")
				oFBicoAB:Refresh()
			EndIf
		EndIf
	EndIf

	If lConsult .and. (cCVendAB == cFVendAB) .and. (cCBicoAB == cFBicoAB) .and. (dFDataAB == dCDataAB) .and. (cFPlacaAB == cCPlacaAB)
		Return (.T.)
	EndIf

	//Monta os campos da query
	aFields := {"MID_CODBIC","MHZ_DESPRO","MID_LITABA","MID_PREPLI","MID_TOTAPA","MID_ENCFIN","MID_RFID","MID_NUMORC","MHZ_CODPRO","MID_DATACO","MID_HORACO","MID_CODTAN","MID_CODABA","MID_SEQUE","MID_NLOGIC","MIC_XCONCE"}

	//Tabela da Query
	aTables := {"MID","MIC","MHZ"}

	cWhere := " MID.D_E_L_E_T_ = ' ' AND MIC.D_E_L_E_T_ = ' ' AND MHZ.D_E_L_E_T_ = ' '"
	cWhere += " AND MIC_FILIAL = '"+ xFilial("MIC") + "' "
	cWhere += " AND MHZ_FILIAL = '"+ xFilial("MHZ") + "' "
	cWhere += " AND MHZ_CODTAN = MIC_CODTAN "
	cWhere += " AND MID_FILIAL = '"+ xFilial("MID") + "' "
	cWhere += " AND MIC_CODBIC = MID_CODBIC "
	cWhere += " AND MID_NUMORC NOT IN ('"+Padr("P",TAMSX3("MID_NUMORC")[1])+"','"+Padr("PP",TAMSX3("MID_NUMORC")[1])+"','"+Padr("O",TAMSX3("MID_NUMORC")[1])+"') " //abast em aberto
	cWhere += " AND MID_AFERIR <> 'S' "//retiro afericao
	cWhere += " AND MID_DATACO = '"+ DtoS(dFDataAB) + "' "
	If !Empty(cFBicoAB)
		cWhere += " AND MID_CODBIC = '"+ cFBicoAB + "' "
	EndIf

	//Monta a Cláusula Order By da query
	cOrderBy := " MID_FILIAL, MID_DATACO, MID_CODBIC, MID_CODTAN "

	//parametros para busca
	aParam := {aFields, aTables, cWhere, cOrderBy, 0}
	aParam := {"STDQUERYDB",aParam}

	If FWHostPing() .AND. STBRemoteExecute("_EXEC_CEN", aParam,,,@aResult,/*cType*/,/*cKeyOri*/, @nCodRet )
		// Se retornar esses codigos siginifica que a central esta off
		lHasConnect := !(nCodRet == -105 .OR. nCodRet == -107 .OR. nCodRet == -104)
		// Verifica erro de execucao por parte do host
		//-103 : erro na execução ,-106 : 'erro deserializar os parametros (JSON)
		lHostError := (nCodRet == -103 .OR. nCodRet == -106)

		If lHostError
			U_SetMsgRod("Erro de conexão central PDV: " + cValtoChar(nCodRet))
			//Conout("TPDVA002 - Erro de conexão central PDV: " + cValtoChar(nCodRet))
			_lRet := .F.
		EndIf

	ElseIf nCodRet == -101 .OR. nCodRet == -108
		U_SetMsgRod( "Servidor PDV nao Preparado. Funcionalidade nao existe ou host responsavel não associado. Cadastre a funcionalidade e vincule ao Host da Central PDV: " + cValtoChar(nCodRet))
		//Conout( "TPDVA002 - Servidor PDV nao Preparado. Funcionalidade nao existe ou host responsavel não associado. Cadastre a funcionalidade e vincule ao Host da Central PDV: " + cValtoChar(nCodRet))
		_lRet := .F.
	Else
		U_SetMsgRod( "Erro de conexão central PDV: " + cValtoChar(nCodRet))
		//Conout("TPDVA002 - Erro de conexão central PDV: " + cValtoChar(nCodRet))
		_lRet := .F.
	EndIf

	If _lRet .AND. lHasConnect .AND. ValType(aResult)=="A" .AND. len(aResult)>0

		SL1->(DbSetOrder(1)) //L1_FILIAL+L1_NUM
		SL2->(DbOrderNickName("SL2MIDCOD")) //L2_FILIAL+L2_MIDCOD

		For nPResult := 1 to Len(aResult)

			//valida se o abastecimento foi baixado pelo PDV
			If !SL2->(DbSeek(xFilial("SL2")+aResult[nPResult][aScan(aFields,"MID_CODABA")])) /*.or. Empty(SL1->L1_DOC)*/	//-- verifica se existe venda
				LOOP
			EndIf

			If !SL1->(DbSeek(SL2->L2_FILIAL+SL2->L2_NUM))
				LOOP
			EndIf

			//valida pelo filtro do vendedor
			If !Empty(cFVendAB) .and. (cFVendAB <> SL2->L2_VEND) //!(Alltrim(cFVendAB) $ AllTrim(POSICIONE("SA3",1,XFILIAL("SA3")+POSICIONE("U68",3,XFILIAL("U68")+aResult[nPResult][aScan(aFields,"MID_RFID")],"U68_VEND"),"A3_NOME")))) .or. ;	//-- filtra por vendedor
				LOOP
			EndIf

			//valida pelo filtro de placa
			If !Empty(cFPlacaAB) .and. (cFPlacaAB <> SL1->L1_PLACA)
				LOOP
			EndIf

			_aFieldFill := {}

			For _nX := 1 To Len(oMsGetAB:aHeader)

				//-- para o campo do tipo mark browser
				If oMsGetAB:aHeader[_nX,2] == "MARK"
					_nExiste := aScan(_aAux,{|x| AllTrim(x[aScan(oMsGetAB:aHeader,{|x| AllTrim(x[2])=="MID_CODABA"})]) == SL2->L2_MIDCOD })
					If _nExiste == 0
						aadd(_aFieldFill,"UNCHECKED")
					Else
						aadd(_aFieldFill,_aAux[_nExiste,1])
					EndIf

				ElseIf AllTrim(oMsGetAB:aHeader[_nX,2]) == "L2_NUM"
					aadd(_aFieldFill, SL2->L2_NUM)

				ElseIf AllTrim(oMsGetAB:aHeader[_nX,2]) == "L1_SERIE"
					aadd(_aFieldFill, Iif(!Empty(SL1->L1_SERIE),Iif(SL1->L1_SITUA=='07'.or.SL1->L1_STORC=='A',"CAN",SL1->L1_SERIE),"EM "))

				ElseIf AllTrim(oMsGetAB:aHeader[_nX,2]) == "L1_DOC"
					aadd(_aFieldFill, Iif(!Empty(SL1->L1_DOC),Iif(SL1->L1_SITUA=='07'.or.SL1->L1_STORC=='A',"CANCELADO",SL1->L1_DOC),"ORCAMENTO"))

				ElseIf AllTrim(oMsGetAB:aHeader[_nX,2]) == "L1_EMISNF"
					aadd(_aFieldFill, SL1->L1_EMISNF)

				ElseIf AllTrim(oMsGetAB:aHeader[_nX,2]) == "L1_HORA"
					aadd(_aFieldFill, SL1->L1_HORA)

				ElseIf AllTrim(oMsGetAB:aHeader[_nX,2]) == "L1_SITUA"
					aadd(_aFieldFill, SL1->L1_SITUA)

				ElseIf AllTrim(oMsGetAB:aHeader[_nX,2]) == "L1_PDV"
					aadd(_aFieldFill, SL1->L1_PDV)

				ElseIf AllTrim(oMsGetAB:aHeader[_nX,2]) == "L1_PLACA"
					aadd(_aFieldFill, SL1->L1_PLACA)

				ElseIf AllTrim(oMsGetAB:aHeader[_nX,2]) == "A3_NOME"
					//aadd(_aFieldFill, POSICIONE("SA3",1,XFILIAL("SA3")+POSICIONE("U68",3,XFILIAL("U68")+aResult[nPResult][aScan(aFields,"MID_RFID")],"U68_VEND"),"A3_NOME") )
					aadd(_aFieldFill, POSICIONE("SA3",1,XFILIAL("SA3")+SL2->L2_VEND,"A3_NOME") )

				Else

					If oMsGetAB:aHeader[_nX,10] == "V" // se for virtual executo o inicializador padrao do campo
						aadd(_aFieldFill, &(oMsGetAB:aHeader[_nX,12]))
					Else
						If aScan(aFields,AllTrim(oMsGetAB:aHeader[_nX,2])) > 0
							aadd(_aFieldFill, aResult[nPResult][aScan(aFields,AllTrim(oMsGetAB:aHeader[_nX,2]))])
						Else
							If oMsGetAB:aHeader[_nX,8] == "N"
								Aadd(_aFieldFill,0)
							ElseIf oMsGetAB:aHeader[_nX,8] == "D"
								Aadd(_aFieldFill,CTOD(""))
							ElseIf oMsGetAB:aHeader[_nX,8] == "L"
								Aadd(_aFieldFill,.F.)
							Else
								Aadd(_aFieldFill,"")
							EndIf
						EndIf
					EndIf

				EndIf

			Next _nX

			aadd(_aFieldFill,.F.)

			aadd(aAuxAcols,_aFieldFill)
			nCountAbast++

		Next nPResult

	EndIf

	If Empty(aAuxAcols)

		_aFieldFill := {}

		For _nX := 1 to Len(oMsGetAB:aHeader)
			If oMsGetAB:aHeader[_nX,8] == "N"
				Aadd(_aFieldFill,0)
			ElseIf oMsGetAB:aHeader[_nX,8] == "D"
				Aadd(_aFieldFill,CTOD(""))
			ElseIf oMsGetAB:aHeader[_nX,8] == "L"
				Aadd(_aFieldFill,.F.)
			Else
				Aadd(_aFieldFill,"")
			EndIf
		Next _nX

		aadd(_aFieldFill,.F.)
		aadd(aAuxAcols,_aFieldFill)

	EndIf

	If nColOrder > 0

		// reordeno o array do grid de acordo com a coluna do aHeader que foi selecionada
		If nPosAbst > 0

			If oMsGetAB:aHeader[nColOrder,8] == "N"
				ASORT(aAuxAcols,,,{|x, y| ( StrZero(INT(x[nColOrder]),10) + cValToChar((x[nColOrder] - INT(x[nColOrder])) * 1000) + x[nPosAbst] ) > ( StrZero(INT(y[nColOrder]),10) + cValToChar((y[nColOrder] - INT(y[nColOrder])) * 1000) + y[nPosAbst] )})
			ElseIf oMsGetAB:aHeader[nColOrder,8] == "C"
				ASORT(aAuxAcols,,,{|x, y| x[nColOrder] + x[nPosAbst] > y[nColOrder] + y[nPosAbst] })
			ElseIf oMsGetAB:aHeader[nColOrder,8] == "D"
				ASORT(aAuxAcols,,,{|x, y| DTOS(x[nColOrder]) + x[nPosAbst] > DTOS(y[nColOrder]) + y[nPosAbst] })
			ElseIf oMsGetAB:aHeader[nColOrder,8] == "L"
				ASORT(aAuxAcols,,,{|x, y| iif(x[nColOrder],"S","F") + x[nPosAbst] > iif(y[nColOrder],"S","F") + y[nPosAbst] })
			EndIf

		Else
			ASORT(aAuxAcols,,,{|x, y| x[nColOrder] > y[nColOrder] })
		EndIf

	EndIf

	oMsGetAB:aCols := aClone(aAuxAcols)

	If nRegPos <= Len(oMsGetAB:aCols)
		oMsGetAB:oBrowse:nAt := nRegPos
	Else
		oMsGetAB:oBrowse:nAt := Len(oMsGetAB:aCols)
	EndIf

	oMsGetAB:oBrowse:Refresh()
	oMsGetAB:oBrowse:SetFocus()

	cQtdAbAB := Alltrim(Str(nCountAbast))
	oQtdAbAB:Refresh()

	cCVendAB  := cFVendAB
	cCBicoAB  := cFBicoAB
	dCDataAB  := dFDataAB
	cCPlacaAB := cFPlacaAB

	RestArea(aAreaMID)
	RestArea(aAreaSL1)
	RestArea(aAreaSL2)
	RestArea(aArea)

Return(.T.)

//
// Função para criar o MsNewGetDados dos abastecimentos pendentes
//
Static Function bMsGetAB(nTop,nLeft,nBottom,nRight,oPnl)

	Local oObj
	Local nX
	Local aHeaderEx 	:= {}
	Local aColsEx 		:= {}
	Local aFieldFill 	:= {}
	Local aAlterFields 	:= {}

	// a primeira coluna do grid é um checkbox
	Aadd(aHeaderEx,{Space(10),'MARK','@BMP',2,0,'','€€€€€€€€€€€€€€','C','','','',''})

	For nX:=1 to Len(aFieldAB)
		aadd(aHeaderEx, U_UAHEADER(aFieldAB[nX]) )
	Next nX

	For nX := 1 to Len(aHeaderEx)
		If Alltrim(aHeaderEx[nX][2]) $ "MARK"
			Aadd(aFieldFill, "UNCHECKED")
		ElseIf aHeaderEx[nX][2] == "MID_CODABA"
			Aadd(aFieldFill, space(TamSX3("MID_CODABA")[1]))
		else
			if aHeaderEx[nX][8] == "N"
				Aadd(aFieldFill, 0)
			elseif aHeaderEx[nX][8] == "D"
				Aadd(aFieldFill, stod(""))
			ElseIf aHeaderEx[nX][8] == "L"
				Aadd(aFieldFill,.F.)
			else
				Aadd(aFieldFill, "")
			endif
		endif
	Next nX

	Aadd(aFieldFill, .F.)
	Aadd(aColsEx, aFieldFill)

	oObj := MsNewGetDados():New( nTop, nLeft, nBottom, nRight,, "AllwaysTrue", "AllwaysTrue", "+Field1+Field2", aAlterFields,, 999, "AllwaysTrue", "", "AllwaysTrue", oPnl, aHeaderEx, aColsEx)

Return(oObj)

//
//	Função chamada pelo duplo clique no grid de abastecimentos
//
Static Function DbClique(_obj)

	If _obj:aCols[_obj:nAt][1] == "CHECKED"
		_obj:aCols[_obj:nAt][1] := "UNCHECKED"
	Else
		_obj:aCols[_obj:nAt][1] := "CHECKED"
	EndIf
	_obj:oBrowse:Refresh()

Return()

//
//	Função chamada pela ação de clicar no cabeçalho dos grids para selecionar todos os checkbox
//
Static Function MarcaTodos(_obj)

	Local nX := 1

	If __XVEZ == "0"
		__XVEZ := "1"
	Else
		If __XVEZ == "1"
			__XVEZ := "2"
		EndIf
	EndIf

	If __XVEZ == "2"
		If _nMarca == 0
			For nX := 1 TO Len(_obj:aCols)
				_obj:aCols[nX][1] := "CHECKED"
			Next
			_nMarca := 1
		Else
			For nX := 1 TO Len(_obj:aCols)
				_obj:aCols[nX][1] := "UNCHECKED"
			Next
			_nMarca := 0
		Endif
		__XVEZ:="0"
		_obj:oBrowse:Refresh()
	EndIf

Return()

//
//	Função que faz a ordenação do grid de acordo com o objeto e coluna passados como parâmetro
//
Static Function OrderGrid(oObj,nColum)

	Local nPosAbst	:= aScan(oObj:aHeader,{|x| AllTrim(x[2]) == "MID_CODABA"})

	If __XVEZ == "0"
		__XVEZ := "1"
	Else
		If __XVEZ == "1"
			__XVEZ := "2"
		EndIf
	EndIf

	If __XVEZ == "2"

		// reordeno o array do grid
		If nPosAbst > 0

			If oObj:aHeader[nColum,8] == "N"
				ASORT(oObj:aCols,,,{|x, y| ( StrZero(INT(x[nColum]),10) + cValToChar((x[nColum] - INT(x[nColum])) * 1000) + x[nPosAbst] ) > ( StrZero(INT(y[nColum]),10) + cValToChar((y[nColum] - INT(y[nColum])) * 1000) + y[nPosAbst] )})
			ElseIf oObj:aHeader[nColum,8] == "C"
				ASORT(oObj:aCols,,,{|x, y| x[nColum] + x[nPosAbst] > y[nColum] + y[nPosAbst] })
			ElseIf oObj:aHeader[nColum,8] == "D"
				ASORT(oObj:aCols,,,{|x, y| DTOS(x[nColum]) + x[nPosAbst] > DTOS(y[nColum]) + y[nPosAbst] })
			ElseIf oObj:aHeader[nColum,8] == "L"
				ASORT(oObj:aCols,,,{|x, y| iif(x[nColum],"S","F") + x[nPosAbst] > iif(y[nColum],"S","F") + y[nPosAbst] })
			EndIf

		Else
			ASORT(oObj:aCols,,,{|x, y| x[nColum] > y[nColum] })
		EndIf

		// faço um refresh no grid
		oObj:oBrowse:Refresh()

	EndIf

Return()

//
// Função para colorir as linhas do MsNewGetDados do grid de abastecimentos do PDV
//
/*
User Function CorAbasAB(oObj)

Local aArea := GetArea()

Local nCor1 := RGB(152, 152, 152) // cinza escuro
Local nCor2 := RGB(240, 240, 240) // cinza claro

Local nCor3 := RGB(144, 238, 144) // verde claro
Local nCor4 := RGB(050, 205, 050) // verde lima

Local nCor5 := RGB(250, 235, 215) // branco antigo
Local nCor6 := RGB(255, 222, 173) // branco navajo

Local nPAbast := 0

Local cDoc		:= "" //codigo do documento
Local lVerde 	:= .F.
Local lBranco	:= .F.

nPDoc := aScan(oObj:aHeader,{|x| AllTrim(x[2])=="L1_DOC"})
If oObj:nAt > 0 .AND. oObj:nAt <= Len(oObj:aCols) .AND. nPDoc > 0 .AND. nPDoc <= Len(oObj:aCols[oObj:nAt])
cDoc := oObj:aCols[oObj:nAt][nPDoc]
If (AllTrim(cDoc) == "ORCAMENTO") .or. (AllTrim(cDoc) == "CANCELADO") .or. Empty(cDoc)
lVerde := .T.
EndIf
EndIf

nPSitua := aScan(oObj:aHeader,{|x| AllTrim(x[2])=="L1_SITUA"})
If oObj:nAt > 0 .AND. oObj:nAt <= Len(oObj:aCols) .AND. nPSitua > 0 .AND. nPSitua <= Len(oObj:aCols[oObj:nAt])
cSitua := oObj:aCols[oObj:nAt][nPSitua]
If cSitua <> "TX"
lBranco := .T.
EndIf
EndIf

If lVerde // se estiver pendente de cupom
If oObj:nAt%2 == 0 // se a linha for par
nRet := nCor3
Else // se a linha for impar
nRet := nCor4
EndIf
ElseIf lBranco // se estiver com pendendia sefaz
If oObj:nAt%2 == 0 // se a linha for par
nRet := nCor5
Else // se a linha for impar
nRet := nCor6
EndIf
ElseIf oObj:nAt%2 == 0 // se a linha for par
nRet := nCor1
Else // se a linha for impar
nRet := nCor2
EndIf

RestArea(aArea)

Return(nRet)
*/

//
// Reimpressão da NFe/NFCe
//
Static Function ReImprAB()

	Local aArea := GetArea()
	Local aAreaSL1 := SL1->(GetArea())

	Local nX := 0
	Local nQtdReimp := 0
	Local cL1_SERIE := "", cL1_DOC := "", cL1_SITUA := ""
	Local nPDoc := aScan(oMsGetAB:aHeader,{|x| AllTrim(x[2])=="L1_DOC"})
	Local nPSerie := aScan(oMsGetAB:aHeader,{|x| AllTrim(x[2])=="L1_SERIE"})
	Local nPSitua := aScan(oMsGetAB:aHeader,{|x| AllTrim(x[2])=="L1_SITUA"})

	For nX:=1 to Len(oMsGetAB:aCols)
		If oMsGetAB:aCols[nX][1] == "CHECKED"
			nQtdReimp ++
			cL1_SERIE := oMsGetAB:aCols[nX][nPSerie]
			cL1_DOC   := oMsGetAB:aCols[nX][nPDoc]
			cL1_SITUA := oMsGetAB:aCols[nX][nPSitua]
			If nQtdReimp > 1 //selecionou mais de 1 documento
				Exit
			EndIf
		EndIf
	Next nX

	If nQtdReimp<1
		Alert("Selecione um documento NFCe/NFe para reimpressão...")
	ElseIf nQtdReimp>1
		Alert("Não é permitido selecionar mais de um documento NFCe/NFe para reimpressão. Faça a reimpressão de um único documento por vez.")
	Else //se selecionou apenas 1 documento
		If AllTrim(cL1_DOC) <> "ORCAMENTO" .and. AllTrim(cL1_DOC) <> "CANCELADO" .and. !Empty(cL1_DOC) //.and. cL1_SITUA == "TX"

			CursorWait()
			SL1->( DbSetOrder(2) ) //L1_FILIAL+L1_SERIE+L1_DOC+L1_PDV
			If SL1->( DbSeek( xFilial("SL1") + cL1_SERIE + cL1_DOC ) )

				//-- NFC-e
				If SL1->L1_SERIE == SLG->LG_SERIE
					LJMsgRun("Imprimindo NFC-e ...",,{|| ImpDanfe(1) })

				Else //-- NF-e

					//-- Danfe Simplificado
					If GetNewPar("MV_LJTXNFE", 0) == 3
						LJMsgRun("Reimprimindo NF-e Simplificada...",,{|| ImpDanfe(3) } )

					ElseIf GetNewPar("MV_LJTXNFE", 0) == 2
						SF2->( DbSetOrder(1), DbSeek( xFilial("SF2") + SL1->L1_DOC + SL1->L1_SERIE ) )
						LJMsgRun("Reimprimindo NF-e (A4)...",,{|| ImpDanfe(2) })

					EndIf

				EndIf

				U_TPDVR001() //Chama a impressão do comprovante venda a prazo
				
				//-------------------------------------------------------------//
				// Faz impressão do comprovante de Vale Haver
				//-------------------------------------------------------------//
				If SL1->L1_XTROCVL > 0
					U_TPDVR006(SL1->L1_XTROCVL, .F./*lCmp*/, AllTrim(SL1->L1_SERIE))
				EndIf

				//--------------------------------------------------------------//
				// Faço a impressão customizada da carta frete
				//--------------------------------------------------------------//
				If ExistBlock("UTPDVRCF")
					U_UTPDVRCF()
				EndIf

			EndIf
			CursorArrow()

		Else
			If cL1_SITUA <> "TX" .and. !Empty(cL1_DOC) .and. cL1_DOC <> "ORCAMENTO" .and. AllTrim(cL1_DOC) <> "CANCELADO"
				Alert("Não é possível realizar a impressão deste documento. Verifique o status da nota N. "+cL1_DOC+"/"+cL1_SERIE+" no Monitor NF-e/NFC-e.")
			ElseIf Empty(cL1_DOC) .or. cL1_DOC == "ORCAMENTO"
				Alert("Abastecimento se encontra em um orçamento não finalizado. Favor finalizar a venda.")
			ElseIf Empty(cL1_DOC) .or. cL1_DOC == "CANCELADO"
				Alert("Abastecimento se encontra em um orçamento cancelado. Favor verificar se foi baixado em outra venda.")
			EndIf

		EndIf

	EndIf

	RestArea(aAreaSL1)
	RestArea(aArea)

Return (.T.)

/*/{Protheus.doc} ImpDanfe
Funcao para verificar se impressao pode ser feita.

@author pablo
@since 16/10/2018
@version 1.0
@return Nil
@param nTP, numeric, descricao
@type function
/*/
Static Function ImpDanfe(nTP)

	Local aSF2 := SF2->( GetArea() )
	Local aRetSFZ := {}

	//-- Posiciono para saber se e NFe ou NFC-e
	SF2->( DbSetOrder(1), DbSeek( xFilial("SF2") + SL1->L1_DOC + SL1->L1_SERIE ) )

	//-- Pesquisa codigo de retorno
	/*
	aRet[01] := AllTrim(cVersao)
	aRet[02] := AllTrim(cAmbiente)
	aRet[03] := AllTrim(cCodRet)
	aRet[04] := AllTrim(cMsgNFe)
	aRet[05] := AllTrim(cProtocolo)
	aRet[06] := dData
	aRet[07] := cHora
	aRet[08] := cRecibo
	*/
	lNfe := !(nTP == 1)
	aRetSFZ := RetAutoriz(SL1->L1_SERIE+SL1->L1_DOC,lNfe)

	cRetSfz := aRetSFZ[05]+"|"+aRetSFZ[03]+"|"+aRetSFZ[04]
	if !Empty(cRetSfz) .and. (Empty(SL1->L1_RETSFZ) .or. AllTrim(cRetSfz) <> AllTrim(SL1->L1_RETSFZ))
		RecLock( "SL1", .F. )
		SL1->L1_RETSFZ := cRetSfz
		SL1->( MsUnlock() )
	endif

	if (aRetSFZ[03] <> "100" .and. ( Empty(SL1->L1_RETSFZ) .or. !("100" $ SL1->L1_RETSFZ) )) .and. ;
		(aRetSFZ[03] <> "150" .and. ( Empty(SL1->L1_RETSFZ) .or. !("150" $ SL1->L1_RETSFZ) ))

		U_XHELP("ATENÇÃO",;
		"FAVOR RETER TODOS OS DOCUMENTOS!!! NOTA FISCAL COM USO DENEGADO/NÃO AUTORIZADA JUNTO A SEFAZ. Código Sefaz: " + aRetSFZ[03] + " Motivo: " + AllTrim(aRetSFZ[04]),;
		"VERIFIQUE NO MONITOR DA SEFAZ A MENSSAGEM E CORRIJA.")
		Return .F.

	endif

	if nTP == 1 //AllTrim(SF2->F2_ESPECIE) == "NFCE" //-- Impressão de NFC-e

		LjNfceImp(SL1->L1_FILIAL,SL1->L1_NUM)

	elseif AllTrim(SF2->F2_ESPECIE) == "SPED" //-- Impressão de NF-e

		if nTP == 3
			//StaticCall(LOJNFCE,LjRDNFeImp,SL1->L1_FILIAL,SL1->L1_NUM)
			LjNFCeImp( SL1->L1_FILIAL, SL1->L1_NUM )
		elseif nTP == 2
			//StaticCall(LOJNFCE,LjDANFENFe)
			&("StaticCall(LOJNFCE,LjDANFENFe)")
		endif

	endif

	RestArea(aSF2)

Return .T.

/*/{Protheus.doc} RetAutoriz
Consulta Autorização pelo Nr Documento.

@author pablo
@since 16/10/2018
@version 1.0
@return Nil
@param cDocum, characters, descricao
@param lNfe, logical, descricao
@type function
/*/
Static Function RetAutoriz(cDocum,lNfe)
	Local cIdEnt := "", cProtocolo := "", cCodRet := "", cRecibo := ""
	Local cVersao := "", cAmbiente := "", cMsgNFe := "",cHora := ""
	Local cURL := PadR(GetNewPar("MV_SPEDURL","http://"),250)
	Local aRet := {"","","","","", stod(""),"", ""}, oWS := {}, aRetorno := {}
	Local aSFT := SFT->( GetArea() )
	Local ix1 := 0, QtdNo1 := 0, QtdNo2 := 0
	Local dData := date()
	Default lNfe := .T.

	//-- Verifica se as informações de URL do TSS estão corretas (teste de conexão)
	if !CTIsReady(cURL,3,.T.)

		aRet[03] := "998"
		aRet[04] := "ULJ7VEND: Não há conexão com o servidor TSS. Verifique as configurações."

		return aRet

	endif

	//-- Posiciona na SFT
	SFT->( DbSetOrder(1) )
	SFT->( DbSeek( xFilial("SFT") + "S" + cDocum ) )

	//-- Busca ID da NF-e
	if (SFT->( Found() ) .and. AllTrim(SFT->FT_ESPECIE) == "SPED") .or. lNfe
		// Obtem o codigo da entidade
		If FindFunction("LjTSSIDEnt")
			cIdEnt := LjTSSIDEnt("55",.F.)
		Else
			//cIdEnt := StaticCall(LOJNFCE, LjTSSIDEnt, "55", .F.)
			cIdEnt := &("StaticCall(LOJNFCE, LjTSSIDEnt, '55', .F.)")
		EndIf
		cURL   := PadR(GetNewPar("MV_SPEDURL","http://"),250)

	elseif (SFT->( Found() ) .and. AllTrim(SFT->FT_ESPECIE) == "NFCE") .or. !lNfe
		// Obtem o codigo da entidade
		If FindFunction("LjTSSIDEnt")
			cIdEnt := LjTSSIDEnt("65",.F.)
		Else
			//cIdEnt := StaticCall(LOJNFCE, LjTSSIDEnt, "65", .F.)
			cIdEnt := &("StaticCall(LOJNFCE, LjTSSIDEnt, '65', .F.)")
		EndIf
		cURL := PadR(GetNewPar("MV_NFCEURL","http://"),250)

	endif

	//-- Valida se Encontrou o Registro
	if Empty(cIdEnt) .or. Empty(cURL) .or. (lNfe .and. !SFT->( Found() ))

		aRet[03] := "999"
		aRet[04] := "Nao Existe na SF2"
		aRet[04] := "ULJ7VEND: Falha em buscar na ID/Url ou ausencia dos dados Fiscais!"

		RestArea(aSFT)
		return aRet

	endif

	//-- Verifica se a SEFAZ esta no Ar!
	aRetorno := SEFAZReady(cIdEnt,cURL)
	nPosAux := 01
	if lNfe
		nPosAux := aScan(aRetorno,{|x| x[1]=='55' })
	else //nfce
		nPosAux := aScan(aRetorno,{|x| x[1]=='65' })
	endif
	if nPosAux == 0
		nPosAux := 1
	endif
	if Empty(aRetorno) .or. aRetorno[nPosAux][02] <> "107"

		aRet[03] := "997"
		aRet[04] := "ULJ7VEND: SEFAZ fora do AR. Verifique possibilidade de entrar em Contingência NF-e!"

		return aRet

	endif

	//-- Chamada para Pesquisa no WebService
	oWs:= WsNFeSBra():New()
	oWs:cUserToken   := "TOTVS"
	oWs:cID_ENT      := cIdEnt
	oWs:_URL         := AllTrim(cURL)+"/NFeSBRA.apw"
	oWs:cIDInicial   := cDocum //SFT->FT_SERIE+SFT->FT_NFISCAL
	oWs:cIDFinal     := cDocum //SFT->FT_SERIE+SFT->FT_NFISCAL

	if !oWs:MonitorFaixa()

		//Conout( "LOJA140-Consulta TSS: Execute o módulo de configuração do serviço, antes de utilizar esta opção!!!" )

		aRet[03] := "999"
		aRet[04] := "Sem Retorno na SEFAZ"

		RestArea(aSFT)
		Return aRet

	endif

	QtdNo1 := len(oWs:oWsMonitorFaixaResult:oWsMonitorNFE)
	for ix1:=1 to QtdNo1

		cProtocolo := oWs:oWsMonitorFaixaResult:oWsMonitorNFE[ix1]:cProtocolo
		cAmbiente  := oWs:oWsMonitorFaixaResult:oWsMonitorNFE[ix1]:nAmbiente
		cVersao    := ""

		QtdNo2 := len(oWs:oWsMonitorFaixaResult:oWsMonitorNFE[ix1]:oWSErro:oWsLoteNFE)
		if QtdNo2 == 0
			Loop
		endif

		//-- Ordenar para carregar a ultima acao
		cCodRet := oWs:oWsMonitorFaixaResult:oWsMonitorNFE[ix1]:oWSErro:oWsLoteNFE[QtdNo2]:cCodRetNFE
		cMsgNFe := oWs:oWsMonitorFaixaResult:oWsMonitorNFE[ix1]:oWSErro:oWsLoteNFE[QtdNo2]:cMsgRetNFE
		dData	:= oWs:oWsMonitorFaixaResult:oWsMonitorNFE[ix1]:oWSErro:oWsLoteNFE[QtdNo2]:dDataLote
		cHora	:= oWs:oWsMonitorFaixaResult:oWsMonitorNFE[ix1]:oWSErro:oWsLoteNFE[QtdNo2]:cHoraLote
		cRecibo := oWs:oWsMonitorFaixaResult:oWsMonitorNFE[ix1]:oWSErro:oWsLoteNFE[QtdNo2]:nReciboSefaz
		Exit

	next ix1

	aRet[01] := AllTrim(cVersao)
	aRet[02] := AllTrim(cAmbiente)
	aRet[03] := AllTrim(cCodRet)
	aRet[04] := AllTrim(cMsgNFe)
	aRet[05] := AllTrim(cProtocolo)
	aRet[06] := dData
	aRet[07] := cHora
	aRet[08] := cRecibo

	RestArea(aSFT)
Return aClone(aRet)

//-- Funcao que Verifica Status SEFAZ
Static Function SEFAZReady(cIdEnt,cURL)
	Local oWs := {}, aSize := {}, aXML := {}, aStatus := {}
	Local nX := 0
	Local cStatus := "", cAuditoria := ""

	oWS:= WSNFeSBRA():New()
	oWS:cUSERTOKEN := "TOTVS"
	oWS:cID_ENT    := cIdEnt
	oWS:_URL       := AllTrim(cURL)+"/NFeSBRA.apw"

	if !oWS:MONITORSEFAZMODELO()
		Return {}
	endif

	aSize := MsAdvSize()
	aXML := oWS:oWsMonitorSefazModeloResult:OWSMONITORSTATUSSEFAZMODELO
	for nX := 1 To Len(aXML)

		cStatus := ""

		Do Case
		Case aXML[nX]:cModelo == "55"
			cStatus += "- NFe"+CRLF

		Case aXML[nX]:cModelo == "57"
			cStatus += "- CTe"+CRLF

		Case aXML[nX]:cModelo == "58"
			cStatus += "- MDFe"+CRLF

		Case aXML[nX]:cModelo == "65"
			cStatus += "- NFCe"+CRLF

		EndCase

		cStatus += Space(6)+"Versão da mensagem: " + aXML[nX]:cVersaoMensagem+CRLF
		cStatus += Space(6)+"Código do Status: "   + aXML[nX]:cStatusCodigo+"-"+aXML[nX]:cStatusMensagem+CRLF
		cStatus += Space(6)+"UF Origem: " + aXML[nX]:cUFOrigem+CRLF

		if !Empty( aXML[nX]:cUFResposta )
			cStatus += Space(6)+"UF Resposta: " + aXML[nX]:cUFResposta+CRLF
		endif

		if aXML[nX]:nTempoMedioSEF <> Nil
			cStatus += Space(6)+"Tempo de espera: " + Str(aXML[nX]:nTempoMedioSEF,6)+CRLF+CRLF
		endif

		if !Empty(aXML[nX]:cMotivo)
			cStatus += Space(6)+"Motivo: " + aXML[nX]:cMotivo+CRLF+CRLF
		endif

		if !Empty(aXML[nX]:cObservacao)
			cStatus += Space(6)+"Observação: " + aXML[nX]:cObservacao+CRLF+CRLF
		endif

		if !Empty(aXML[nX]:cSugestao)
			cStatus += Space(6)+"Sugestão: " + aXML[nX]:cSugestao+CRLF+CRLF
		endif

		if !Empty(aXML[nX]:cLogAuditoria)
			cAuditoria += aXML[nX]:cLogAuditoria
		endif

		//-- Preencher vetor com o resultado
		aadd(aStatus,{	aXML[nX]:cModelo,;			//-- Modelo Nota
						aXML[nX]:cStatusCodigo,;	//-- Codigo Retorno Status
						cStatus,;					//-- Status
						cAuditoria} )				//-- Mensagem de Sugestão

	next nX

	//-- Ordena por Modelo Nota
	aSort(aStatus,,,{|x,y| x[1] < y[1]})
Return aClone(aStatus)

//Funçao para compatiblidade para painel posto inteligente
User Function TPDVA2CL

	LimpaFilAbast()

Return

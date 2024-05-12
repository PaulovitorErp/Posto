#include 'protheus.ch'
#include 'parmtype.ch'
#include 'poscss.ch'
#include "topconn.ch"
#include "TOTVS.CH"

Static cUsrBxt := ""
Static oPnlGeral
Static oPnlAbast
Static oCodBico
Static cCodBico := ""
Static oDescBico
Static cDescBico := ""
Static oBtnTpDiv, oBtnTpAgl
Static cTipoOper := "D" //D-DIVIDIR;A-AGLUTINAR
Static lOnlyView := .F.
Static oMsGetAbast
Static oQtdReg
Static nQtdReg := 0

/*/{Protheus.doc} TPDVA009
Baixa Trocada no PDV.

@author pablo
@since 22/07/2019
@version 1.0
@return ${return}, ${return_description}
@param oPnlPrinc, object, descricao
@type function
/*/
User Function TPDVA009(oPnlPrinc)

Local nWidth, nHeight
Local oPnlGrid, oPnlAux
Local cCorBg := SuperGetMv("MV_LJCOLOR",,"07334C")// Cor da tela

	nWidth  := oPnlPrinc:nWidth/2
	nHeight := oPnlPrinc:nHeight/2

	cCodBico  := Space(TamSx3("MID_CODBIC")[1])
	cDescBico := Space(TamSx3("MHZ_DESPRO")[1])

	//verifica se o usuário tem permissão para acesso a rotina
	U_TRETA37B("BXTROC", "BAIXA TROCADA NO PDV")
	cUsrBxt := U_VLACESS1("BXTROC", RetCodUsr())
	If cUsrBxt == Nil .OR. Empty(cUsrBxt)
		@ 020, 020 SAY oSay1 PROMPT "<h1>Ops!</h1><br>Seu usuário não tem permissão de acesso a rotina de Baixa Trocada. Entre em contato com o administrador do sistema." SIZE nWidth-40, 100 OF oPnlPrinc COLORS 0, 16777215 PIXEL HTML
		oSay1:SetCSS( POSCSS (GetClassName(oSay1), CSS_LABEL_FOCAL ))
		Return cUsrBxt
	EndIf

	cAmbiente := GetMV("MV_LJAMBIE")
	If Empty(cAmbiente)
		@ 020, 020 SAY oSay1 PROMPT "<h1>Ops!</h1><br>Configuração do Ambiente (MV_LJAMBIE) no Host Superior não realizada. Entre em contato com o administrador do sistema." SIZE nWidth-40, 100 OF oPnlPrinc COLORS 0, 16777215 PIXEL HTML
		oSay1:SetCSS(POSCSS(GetClassName(oSay1), CSS_LABEL_FOCAL))
		Return ""
	EndIf

	// Painel geral da tela de Baixa Trocada (mesmo tamanho da principal)
	oPnlGeral := TPanel():New(000,000,"",oPnlPrinc,NIL,.T.,.F.,,,nWidth,nHeight,.T.,.F.)

	@ 002, 002 SAY oSay1 PROMPT ("BAIXA TROCADA DE ABASTECIMENTOS") SIZE nWidth-004, 015 OF oPnlGeral COLORS 0, 16777215 PIXEL CENTER
	oSay1:SetCSS(POSCSS(GetClassName(oSay1), CSS_BTN_FOCAL))

	//Painel de Inclusão de Baixa Trocada
	oPnlAbast := TPanel():New(020,000,"",oPnlGeral,NIL,.T.,.F.,,,nWidth,nHeight-020,,.T.,.F.)

	@ 005, 005 SAY oSay1 PROMPT "Cód. Bico" SIZE 100, 010 OF oPnlAbast COLORS 0, 16777215 PIXEL
	oSay1:SetCSS(POSCSS (GetClassName(oSay1), CSS_LABEL_FOCAL))
	oCodBico := TGet():New(015, 005,{|u| iif(PCount()==0,cCodBico,cCodBico:=u) },oPnlAbast,050,013,"@!",{|| VldBico() },,,,,,.T.,,,{|| .T. },,,,.F.,.F.,,"oCodBico",,,,.T.,.F.)
	oCodBico:SetCSS(POSCSS(GetClassName(oCodBico), CSS_GET_NORMAL))
	TSearchF3():New(oCodBico,400,250,"MIC","MIC_CODBIC",{{"MIC_CODBIC",1}},"",{{"MIC_CODBIC","MIC_NLOGIC","MIC_LADO"}},,,0,.F.)

	@ 005, 070 SAY oSay2 PROMPT "Descrição" SIZE 100, 010 OF oPnlAbast COLORS 0, 16777215 PIXEL
	oSay2:SetCSS(POSCSS(GetClassName(oSay2), CSS_LABEL_FOCAL))
	oDescBico := TGet():New(015, 070,{|u| iif(PCount()==0,cDescBico,cDescBico:=u)},oPnlAbast,160,013,"@!",{|| .T./*bValid*/ },,,,,,.T.,,,{|| .T. },,,,.F.,.F.,,"oDescBico",,,,.T.,.F.)
	oDescBico:SetCSS(POSCSS(GetClassName(oDescBico), CSS_GET_NORMAL))
	oDescBico:lCanGotFocus := .F.

	@ 035, 005 SAY oSay3 PROMPT "Tipo de Operação" SIZE 100, 010 OF oPnlAbast COLORS 0, 16777215 PIXEL
	oSay3:SetCSS(POSCSS(GetClassName(oSay3), CSS_LABEL_FOCAL))
	oBtnTpAgl := TButton():New(045,005,"DIVIDIR", oPnlAbast,{|| cTipoOper:="D", SetTipoSel(cTipoOper) },050,015,,,,.T.,,,,{|| !lOnlyView })
	oBtnTpDiv := TButton():New(045,055,"AGLUTINAR", oPnlAbast,{|| cTipoOper:="A", SetTipoSel(cTipoOper) },050,015,,,,.T.,,,,{|| !lOnlyView })

	@ 065, 005 SAY oSay4 PROMPT "Abastecimentos do Bico" SIZE 400, 011 OF oPnlAbast COLORS 0, 16777215 PIXEL
	oSay4:SetCSS( POSCSS (GetClassName(oSay4), CSS_BREADCUMB ))
	@ 069, 005 SAY Replicate("_",nWidth) SIZE nWidth-10, 008 OF oPnlAbast FONT COLORS CLR_HGRAY, 16777215 PIXEL

	//GRID
	@ 080, 003 MSPANEL oPnlGrid SIZE nWidth-4, nHeight-120 OF oPnlAbast

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

	oMsGetAbast := MsNewGetAbast(oPnlAux, 001, 005, 150, nWidth-5)
	oMsGetAbast:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT
	oMsGetAbast:oBrowse:SetCSS( StrTran(POSCSS("TGRID", CSS_BROWSE),"gridline-color: white;","") ) //CSS do totvs pdv
	//oMsGetAbast:oBrowse:lCanGotFocus := .F.
	oMsGetAbast:oBrowse:nScrollType := 0
	oMsGetAbast:oBrowse:lHScroll := .F.
	oMsGetAbast:oBrowse:bLDblClick := {|| DbClique(oMsGetAbast,cTipoOper)}

	@ (oPnlGrid:nHeight/2)-22, 010 SAY oQtdReg PROMPT (cValToChar(nQtdReg)+" registros encontrados.") SIZE 150, 010 OF oPnlGrid COLORS 0, 16777215 PIXEL
	oQtdReg:SetCSS( POSCSS (GetClassName(oQtdReg), CSS_LABEL_NORMAL))
	//@ (oPnlGrid:nHeight/2)-21, nWidth-090 BITMAP oLeg ResName "BR_VERDE" OF oPnlGrid Size 10, 10 NoBorder When .F. PIXEL
	//@ (oPnlGrid:nHeight/2)-22, nWidth-080 SAY oSay14 PROMPT "Ativo" OF oPnlGrid Color CLR_BLACK PIXEL
	//oSay14:SetCSS( POSCSS (GetClassName(oSay14), CSS_LABEL_NORMAL))
	//@ (oPnlGrid:nHeight/2)-21, nWidth-055 BITMAP oLeg ResName "BR_PRETO" OF oPnlGrid Size 10, 10 NoBorder When .F. PIXEL
	//@ (oPnlGrid:nHeight/2)-22, nWidth-045 SAY oSay14 PROMPT "Estornado" OF oPnlGrid Color CLR_BLACK PIXEL
	//oSay14:SetCSS( POSCSS (GetClassName(oSay14), CSS_LABEL_NORMAL))

	oBtn2 := TButton():New( nHeight-45,nWidth-75,"Confirmar",oPnlAbast,{|| Confirmar() },070,020,,,,.T.,,,,{|| .T.})
	oBtn2:SetCSS(POSCSS(GetClassName(oBtn2), CSS_BTN_FOCAL))
	
	oBtn3 := TButton():New( nHeight-45,nWidth-150,"Limpar Tela",oPnlAbast,{|| U_TPDVA9CL() },070,020,,,,.T.,,,,{|| .T.})
	oBtn3:SetCSS(POSCSS(GetClassName(oBtn3), CSS_BTN_NORMAL))

	SetTipoSel(cTipoOper)
	oCodBico:SetFocus()
	
Return cUsrBxt

/*/{Protheus.doc} TPDVA9CL
Função para limpar e resetar tela.

@author Totvs GO
@since 22/07/2019
@version 1.0
@return Nil
@type function
/*/
User Function TPDVA9CL()
Local aFieldFill 	:= {}
Local nX

cCodBico  := Space(TamSx3("MID_CODBIC")[1])
cDescBico := Space(TamSx3("MHZ_DESPRO")[1])
nQtdReg := 0

If oMsGetAbast <> Nil

	oMsGetAbast:Acols := {}
	For nX := 1 to Len(oMsGetAbast:aHeader)
		If oMsGetAbast:aHeader[nX,2] == "MARK"
			Aadd(aFieldFill,"LBNO")
		ElseIf oMsGetAbast:aHeader[nX,8] == "N"
			Aadd(aFieldFill,0)
		ElseIf oMsGetAbast:aHeader[nX,8] == "D"
			Aadd(aFieldFill,CTOD(""))
		ElseIf oMsGetAbast:aHeader[nX,8] == "L"
			Aadd(aFieldFill,.F.)
		Else
			Aadd(aFieldFill,"")
		EndIf
	Next nX

	Aadd(aFieldFill, .F.)
	aadd(oMsGetAbast:Acols,aFieldFill)
EndIf

U_SetMsgRod("")

If oCodBico <> Nil
	oCodBico:SetFocus()
EndIf

Return

//--------------------------------------------------------------
// Aplica CSS no botão tipo Radio (D-DIVIDIR;A-AGLUTINAR)
//--------------------------------------------------------------
Static Function SetTipoSel(cOpcSel)

	Local cCssBtn

	If cOpcSel == "A" //AGLUTINAR

		//deixo botão DIVIDIR azul
		cCssBtn := POSCSS(GetClassName(oBtnTpDiv), CSS_BTN_FOCAL )
		cCssBtn:= StrTran(cCssBtn, "border-radius: 6px;", "border-radius: 3px;")
		oBtnTpDiv:SetCss(cCssBtn)

		//deixo botão AGLUTINAR branco
		cCssBtn := POSCSS(GetClassName(oBtnTpAgl), CSS_BTN_NORMAL )
		cCssBtn:= StrTran(cCssBtn, "border-radius: 6px;", "border-radius: 3px;")
		cCssBtn:= StrTran(cCssBtn, "font: bold large;", "")
		oBtnTpAgl:SetCss(cCssBtn)

	Else //AGLUTINAR

		//deixo botão DIVIDIR branco
		cCssBtn := POSCSS(GetClassName(oBtnTpDiv), CSS_BTN_NORMAL )
		cCssBtn:= StrTran(cCssBtn, "border-radius: 6px;", "border-radius: 3px;")
		cCssBtn:= StrTran(cCssBtn, "font: bold large;", "")
		oBtnTpDiv:SetCss(cCssBtn)

		//deixo botão AGLUTINAR azul
		cCssBtn := POSCSS(GetClassName(oBtnTpAgl), CSS_BTN_FOCAL )
		cCssBtn:= StrTran(cCssBtn, "border-radius: 6px;", "border-radius: 3px;")
		oBtnTpAgl:SetCss(cCssBtn)

	EndIf

	ValidaCombo(oMsGetAbast)

	oBtnTpDiv:Refresh()
	oBtnTpAgl:Refresh()

Return

//--------------------------------------------------------
// Função chamada na validação do combobox.
// Está sendo utilizada para desmarcar todos os check's
//--------------------------------------------------------
Static Function ValidaCombo(_obj)

Local lRet 	:= .T.
Local nX	:= 1

If _obj <> NIL
	
	For nX := 1 To Len(_obj:aCols)
		_obj:aCols[nX][aScan(_obj:aHeader,{|x| AllTrim(x[2]) == "MARK"})] := "LBNO"
	Next nX

	_obj:oBrowse:Refresh()

EndIf

Return(lRet)

//--------------------------------------------------------
// Validação e gatilho do bico
//--------------------------------------------------------
Static Function VldBico()

	Local cMsgErr := ""
	Local lRet := .T.
	Local cTanque := ""

	If Empty(cCodBico)
		cDescBico := Space(TamSx3("MHZ_DESPRO")[1])
	Else
		cTanque := Posicione("MIC",3,xFilial("MIC")+cCodBico,"MIC_CODTAN") //MIC_FILIAL+MIC_CODBIC+MIC_CODTAN
		cDescBico := Posicione("MHZ",1,xFilial("MHZ")+cTanque,"MHZ_DESPRO") //MHZ_FILIAL+MHZ_CODTAN
		If Empty(cDescBico)
			lRet := .F.
			cMsgErr := "Bico não encontrado!"
		EndIf
	EndIf

	If lRet
		oDescBico:Refresh()
		RefreshAbs() //Consultando abastecimentos pendêntes...
	EndIf

	U_SetMsgRod(cMsgErr)

Return lRet

//-----------------------------------------------------------------------------------------
// Monta grid NewGetDados de Estorno
//-----------------------------------------------------------------------------------------
Static Function MsNewGetAbast(oPnl, nTop, nLeft, nBottom, nRight)

	Local aHeaderEx 	:= {}
	Local aColsEx 		:= {}
	Local aAlterFields 	:= {}
	Local aFields 		:= { "MID_CODABA", "MID_XCONCE", "MID_LADBOM", "MID_NLOGIC", "MID_CODBIC", "MID_ENCFIN", "MID_LITABA", "MID_PREPLI", "MID_TOTAPA", "MID_DATACO", "MID_HORACO" }
	Local aFieldFill 	:= {}
	Local nX

	// a primeira coluna do grid é MARK
	Aadd(aHeaderEx,{Space(10),'MARK','@BMP',2,0,'','€€€€€€€€€€€€€€','C','','','',''})
	Aadd(aFieldFill,"LBNO")

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

	Aadd(aFieldFill, .F.)
	Aadd(aColsEx, aFieldFill)

Return MsNewGetDados():New( nTop, nLeft, nBottom, nRight, , "AllwaysTrue", "AllwaysTrue", "+Field1+Field2", aAlterFields,, 999, "AllwaysTrue", "", "AllwaysTrue", oPnl, aHeaderEx, aColsEx)

//-------------------------------------------
// Função chamada pelo duplo clique no grid
//-------------------------------------------
Static Function DbClique(_obj,cCombo)

Local nX := 1

if _obj:aCols[_obj:oBrowse:nAt][1] == "LBOK"
	_obj:aCols[_obj:oBrowse:nAt][1] := "LBNO"
else

	// pode selecionar apenas um abastecimentos
	if cCombo == "D"

		For nX := 1 To Len(_obj:aCols)

			if _obj:aCols[nX][aScan(_obj:aHeader,{|x| AllTrim(x[2]) == "MARK"})] == "LBOK"
				_obj:aCols[nX][aScan(_obj:aHeader,{|x| AllTrim(x[2]) == "MARK"})] := "LBNO"
			endif

		Next nX

		// Marco apenas o abastecimento posicionado
		_obj:aCols[_obj:oBrowse:nAt][1] := "LBOK"

	else // se a opção for aglutinar, pode selecionar vários abastecimentos

		_obj:aCols[_obj:oBrowse:nAt][1] := "LBOK"

	endif

endif

_obj:oBrowse:Refresh()

Return()

//------------------------------------------------------
// Função que atualiza o Grid dos abastecimentos
// Consulta abastecimentos pendêntes
//------------------------------------------------------
Static Function RefreshAbs()

Local aFieldFill 	:= {}
Local nX := 0, nY := 0

Local aRet := {}, aCampos := {}, aParam := {}

If !Empty(cCodBico)

	U_SetMsgRod("Consultando abastecimentos pendêntes. Aguarde...")

	CursorArrow()
	CursorWait()

	oMsGetAbast:Acols := {}
	aRet := Nil

	For nX := 1 to Len(oMsGetAbast:aHeader)
		If oMsGetAbast:aHeader[nX,2] <> "MARK"
			Aadd(aCampos,oMsGetAbast:aHeader[nX,2])
		EndIf
	Next nx

	aParam := {cCodBico,aCampos}
	aParam := {"U_TPDVA09A",aParam}
	If !FWHostPing() .OR. !STBRemoteExecute("_EXEC_CEN",aParam,,,@aRet)
		// Tratamento do erro de conexao
		U_SetMsgRod("Falha de comunicação com a central...")

	ElseIf aRet = Nil .or. Empty(aRet) .or. Len(aRet) == 0
		// Tratamento para retorno vazio
		U_SetMsgRod("Ocorreu falha na consulta de abastecimentos ou não existem abastecimentos pendêntes...")

	ElseIf Len(aRet) > 0 //-- consulta realizada com sucesso
		U_SetMsgRod("Foram encontrados"+" "+AllTrim(Str(Len(aRet)))+" "+"abastecimentos pendêntes...")
		nQtdReg := Len(aRet)
		oQtdReg:Refresh()

		For nX:=1 to Len(aRet)
			aFieldFill := {}

			aadd(aFieldFill, "LBNO")
			For nY:=1 to Len(aRet[nX])
				aadd(aFieldFill, aRet[nX][nY])
			Next nY
			Aadd(aFieldFill, .F.)
			aadd(oMsGetAbast:Acols,aFieldFill)

		Next nX

	EndIf

	CursorArrow()

Else
	oMsGetAbast:Acols := {}

EndIf

//-- se array vazio, limpa acols
If Empty(oMsGetAbast:Acols)

	For nX := 1 to Len(oMsGetAbast:aHeader)
		If oMsGetAbast:aHeader[nX,2] == "MARK"
			Aadd(aFieldFill,"LBNO")
		ElseIf oMsGetAbast:aHeader[nX,8] == "N"
			Aadd(aFieldFill,0)
		ElseIf oMsGetAbast:aHeader[nX,8] == "D"
			Aadd(aFieldFill,CTOD(""))
		ElseIf oMsGetAbast:aHeader[nX,8] == "L"
			Aadd(aFieldFill,.F.)
		Else
			Aadd(aFieldFill,"")
		EndIf
	Next nX

	Aadd(aFieldFill, .F.)
	aadd(oMsGetAbast:Acols,aFieldFill)

EndIf

oMsGetAbast:oBrowse:Refresh()

Return()

//---------------------------------------------------------------------
// Retorna Abastecimentos Pendentes para PDV (CENTRAL PDV)
//---------------------------------------------------------------------
User Function TPDVA09A(cBico,aCampos,cFiltro)

Local aAbasPend := {} //Array de Retorno
Local aTemp 	 := {}
Local nx := 0
Local cQry		 := ""	 //	Query
Local cAlias	 := ""	 //	Alias
Local cSGBD		 := ""	 //	guarda Gerenciador de banco de dados
Local nLimitRegs := 1000 // Limita registros
Local cFields 	 := ""
Local cWhere 	 := ""
Local cEndQuery	 := ""

DEFAULT cBico 	:= ""
DEFAULT aCampos := { "MID_CODABA", "MID_XCONCE", "MID_LADBOM", "MID_NLOGIC", "MID_CODBIC", "MID_ENCFIN", "MID_LITABA", "MID_PREPLI", "MID_TOTAPA", "MID_DATACO", "MID_HORACO" }
DEFAULT cFiltro := ""

#IFDEF TOP

	cAlias := GetNextAlias()
	
	//Tratamento para trazer uma quantidade limitada de registros
	cSGBD := Upper(AllTrim(TcGetDB()))
	If nLimitRegs > 0
		
		If "MSSQL" $ cSGBD //Microsoft SQL Server
			cFields := " TOP " + AllTrim(Str(nLimitRegs)) + " " + cFields			
		ElseIf "ORACLE" $ cSGBD //Oracle 
			cWhere += " AND ROWNUM <= " + AllTrim(Str(nLimitRegs))
		ElseIf "DB2" $ cSGBD //DB2
			cEndQuery := " FETCH FIRST " + AllTrim(Str(nLimitRegs)) + " ROWS ONLY"
		ElseIf "INFORMIX" $ cSGBD //Informix
			cFields := " FIRST " + AllTrim(Str(nLimitRegs)) + " " + cFields
		ElseIf "SYBASE" $ cSGBD //Sybase
			cFields := " TOP " + AllTrim(Str(nLimitRegs)) + " " + cFields
		ElseIf "POSTGRES" $ cSGBD //PostgreSQL
			cEndQuery := " LIMIT " + AllTrim(Str(nLimitRegs))
		ElseIf "MYSQL" $ cSGBD //MySQL
			cEndQuery := " LIMIT " + AllTrim(Str(nLimitRegs))
		EndIf
		
	EndIf
	
	cQry := "SELECT " + Iif(!Empty(cFields),cFields+", ","") + " MID.* "
	cQry += " FROM " + RetSQLName("MID") + " MID "
	cQry += " WHERE MID_FILIAL = '" + xFilial("MID") + "'"
	cQry += " AND D_E_L_E_T_ = ' '"
	cQry += cWhere
	
	If !Empty(cBico)
		cQry += " AND MID_CODBIC = '" + cBico + "'"
	EndIf

	if !empty(cFiltro)
		cQry += " AND " + cFiltro
	endif
	
	//-- Vamos carregar 2 situações:
	//-- 	P => Abastecimentos pendentes que vieram da bomba
	//-- 	O => Abastecimentos selecionados para finalizacao da venda
	//cQry += " AND (MID_NUMORC = 'P' OR MID_NUMORC = 'O')"
	cQry += " AND MID_NUMORC = 'P'"
	
	cQry += " ORDER BY MID_FILIAL, MID_XCONCE, MID_LADBOM, MID_NLOGIC, MID_CODBIC, MID_ENCFIN, MID_DATACO, MID_HORACO "
	cQry += cEndQuery
	cQry := ChangeQuery(cQry)
	
	// Importante: Por utilizar funcao build in de SGBD, nao aplicar o PARSER.	
	//DbUseArea(.T.,__cRDD,TcGenQry(,,cQry),cAlias,.T.,.F.)
	TcQuery cQry New ALIAS &(cAlias)
	DbSelectArea(cAlias)
	(cAlias)->(dbGoTop())
	While !(cAlias)->(Eof())
	
		aTemp := {}
		For nx := 1 to Len(aCampos) 
			If TamSx3(aCampos[nx])[3] == "D" .and. VALTYPE((cAlias)->( FieldGet( FieldPos( aCampos[nx] ) ) )) <> "D"
				AADD(aTemp, StoD((cAlias)->( FieldGet( FieldPos( aCampos[nx] ) ) )))
			Else
				AADD(aTemp, (cAlias)->( FieldGet( FieldPos( aCampos[nx] ) ) ))
			EndIf
		Next nx
		AADD(aAbasPend, aTemp)
	
		(cAlias)->(dbSkip())
	EndDo
	
	FechaArqT(cAlias)

	//DANILO: Adicionado tratamento olhando situa, pois tem vez que acontece de o registro MID estar no meio da integração.
	//O problema é que se excluir a MID e gerar SLI, e após o job de subida de abastecimentos gravar o SITUA = TX, 
	//a deleção da SLI não sobe.
	cQry := "SELECT R_E_C_N_O_ RECNO "
	cQry += "FROM " + RetSQLName("MID") + " "
	cQry += "WHERE D_E_L_E_T_ = '*' " //somente deletados
	cQry += "AND MID_CHECKS = 'EX' "
	cQry += "AND MID_SITUA = 'TX' "

	If Select("QXEXC") > 0
		QXEXC->(DbCloseArea())
	Endif
	cQry := ChangeQuery(cQry)
	TcQuery cQry New ALIAS "QXEXC"

	QXEXC->(dbGoTop())
	if !QXEXC->(Eof())
		SET DELETED OFF //Desabilita filtro do campo D_E_L_E_T_
		While !QXEXC->(Eof())
			
			MID->(DbGoTo( QXEXC->RECNO  ))
			LjGrvLog("TPDVA009","Voltando abastecimento marcado com X_EXCLUI para Situa 00. Cod Abast: ", MID->MID_CODABA )
			Reclock("MID", .F.)
				MID->MID_SITUA := "00"
				MID->MID_CHECKS := ""
			MID->(MsUnLock())

			// Gero SLI para tentar novamente
			U_UReplica("MID",1,xFilial("MID")+MID->MID_CODABA,"E")

			QXEXC->(dbSkip())
		EndDo
		SET DELETED ON //Habilita filtro do campo D_E_L_E_T_
	endif
	QXEXC->(DbCloseArea())

#ENDIF

Return aAbasPend

//---------------------------------------------------------------------
// Função que executa a confirmação da rotina
//---------------------------------------------------------------------
Static Function Confirmar()
Local nX 		:= 1
Local cCodAbast	:= ""
Local nPosAbast := 0
Local aAbast	:= {}

If cTipoOper == "D" // dividir abastecimentos

	For nX := 1 To Len(oMsGetAbast:aCols)

		If AllTrim(oMsGetAbast:aCols[nX][aScan(oMsGetAbast:aHeader,{|x| AllTrim(x[2])=="MARK"})]) == "LBOK"
			cCodAbast := oMsGetAbast:aCols[nX][aScan(oMsGetAbast:aHeader,{|x| AllTrim(x[2])=="MID_CODABA"})]
			nPosAbast := nX
			Exit
		EndIf

	Next nX

	If Empty(cCodAbast)
		U_SetMsgRod("Selecione o abastecimento a ser dividido!")
	Else

		If MsgYesNo("Deseja dividir o abastecimento?")
			DivideAbast(nPosAbast, cCodAbast)
		EndIf

	EndIf

Else // aglutinar abastecimentos

	For nX := 1 To Len(oMsGetAbast:aCols)

		If AllTrim(oMsGetAbast:aCols[nX][aScan(oMsGetAbast:aHeader,{|x| AllTrim(x[2])=="MARK"})]) == "LBOK"
			aadd(aAbast,oMsGetAbast:aCols[nX][aScan(oMsGetAbast:aHeader,{|x| AllTrim(x[2])=="MID_CODABA"})])
		EndIf

	Next nX

	If Len(aAbast) < 2
		U_SetMsgRod("Selecione 2 ou mais abastecimentos sequenciais a serem aglutinados!")
	Else

		If MsgYesNo("Deseja aglutinar os abastecimentos?")
			AglutAbast(aAbast)
		EndIf

	EndIf

EndIf

Return()

//---------------------------------------------------------------------
// Função que faz a divisão de um abastecimento
//---------------------------------------------------------------------
Static Function DivideAbast(nPosAbast, cCodAbast)

Local oFntGroup		:= TFont():New("Arial",,018,,.T.,,,,,.F.,.F.)
Local oLitros1
Local oLitros2
Local oEnc1
Local oEnc2
Local oGroup1
Local oGroup2
Local oPanelDv
Local cPictLt		:= PesqPict("MID","MID_LITABA")
Local cPictEnc		:= PesqPict("MID","MID_ENCFIN")
Local nLitros1		:= 0
Local nLitros2		:= 0
Local nEnc1			:= 0
Local nEnc2			:= 0
Local nLitros		:= 0
Local nEncerrante	:= 0

Local nWidth, nHeight

Private oDlgDv

nLitros		:= oMsGetAbast:aCols[nPosAbast][aScan(oMsGetAbast:aHeader,{|x| AllTrim(x[2])=="MID_LITABA"})]
nEncerrante	:= oMsGetAbast:aCols[nPosAbast][aScan(oMsGetAbast:aHeader,{|x| AllTrim(x[2])=="MID_ENCFIN"})]
nLitros1	:= Round(nLitros / 2, TamSx3("MID_LITABA")[2])
nLitros2	:= Round(nLitros - nLitros1, TamSx3("MID_LITABA")[2])
nEnc1		:= Round(nEncerrante - nLitros2, TamSx3("MID_ENCFIN")[2])
nEnc2		:= Round(nEncerrante, TamSx3("MID_ENCFIN")[2])

//limpa as tecla atalho
U_UKeyCtr() 

DEFINE MSDIALOG oDlgDv TITLE "" FROM 000,000 TO 250,420 PIXEL STYLE nOr(WS_VISIBLE, WS_POPUP)

	nWidth := (oDlgDv:nWidth/2)
	nHeight := (oDlgDv:nHeight/2)

	@ 000, 000 MSPANEL oPanelDv SIZE nWidth, nHeight OF oDlgDv
	oPanelDv:SetCSS( "TPanel{border: 2px solid #999999; background-color: #f4f4f4;}" )

	// crio o grupo do primeiro abastecimento
	@ 010, 005 GROUP oGroup1 TO 052, 205 PROMPT " Abastecimento 1 " OF oPanelDv COLOR CLR_GRAY, 16777215 PIXEL
	oGroup1:oFont := oFntGroup

	@ 020, 010 SAY oSay1 PROMPT "Litros:" SIZE 060, 008 OF oPanelDv COLORS 0, 16777215 PIXEL
	oSay1:SetCSS( POSCSS (GetClassName(oSay1), CSS_LABEL_FOCAL ))
	oLitros1 := TGet():New( 030, 010, {|u| iif( PCount()==0,nLitros1,nLitros1:=u)},oPanelDv, 080, 013, cPictLt, {|| ValidLitros(nLitros,nEncerrante,nLitros1,@nLitros2,@nEnc1,@nEnc2) },,,,,,.T.,,,{|| .T. },,,,.F.,.F.,,"nLitros1",,,,.F.,.T.)
	oLitros1:SetCSS( POSCSS (GetClassName(oLitros1), CSS_GET_NORMAL ))

	@ 020, 120 SAY oSay2 PROMPT "Encerrante:" SIZE 060, 008 OF oPanelDv COLORS 0, 16777215 PIXEL
	oSay2:SetCSS( POSCSS (GetClassName(oSay2), CSS_LABEL_FOCAL ))
	oEnc1 := TGet():New( 030, 120, {|u| iif( PCount()==0,nEnc1,nEnc1:=u)},oPanelDv, 080, 013, cPictEnc, {|| .T. },,,,,,.T.,,,{|| .T. },,,,.T.,.F.,,"nEnc1",,,,.F.,.T.)
	oEnc1:SetCSS( POSCSS (GetClassName(oEnc1), CSS_GET_NORMAL ))

	// crio o grupo do segundo abastecimento
	@ 060, 005 GROUP oGroup2 TO 102, 205 PROMPT " Abastecimento 2 " OF oPanelDv COLOR CLR_GRAY, 16777215 PIXEL
	oGroup2:oFont := oFntGroup

	@ 070, 010 SAY oSay3 PROMPT "Litros:" SIZE 060, 008 OF oPanelDv COLORS 0, 16777215 PIXEL
	oSay3:SetCSS( POSCSS (GetClassName(oSay3), CSS_LABEL_FOCAL ))
	oLitros2 := TGet():New( 080, 010, {|u| iif( PCount()==0,nLitros2,nLitros2:=u)},oPanelDv, 080, 013, cPictLt, {|| .T. },,,,,,.T.,,,{|| .T. },,,,.T.,.F.,,"nLitros2",,,,.F.,.T.)
	oLitros2:SetCSS( POSCSS (GetClassName(oLitros2), CSS_GET_NORMAL ))

	@ 070, 120 SAY oSay4 PROMPT "Encerrante:" SIZE 060, 008 OF oPanelDv COLORS 0, 16777215 PIXEL
	oSay4:SetCSS( POSCSS (GetClassName(oSay4), CSS_LABEL_FOCAL ))
	oEnc2 := TGet():New( 080, 120, {|u| iif( PCount()==0,nEnc2,nEnc2:=u)},oPanelDv, 080, 013, cPictEnc, {|| .T. },,,,,,.T.,,,{|| .T. },,,,.T.,.F.,,"nEnc2",,,,.F.,.T.)
	oEnc2:SetCSS( POSCSS (GetClassName(oEnc2), CSS_GET_NORMAL ))

	// BOTAO CONFIRMAR
	oButton1 := TButton():New( nHeight-20,nWidth-60,"Confirmar",oPanelDv,{|| iif(GravaDv(cCodAbast,nLitros1,nLitros2,nEnc1,nEnc2,nLitros),oDlgDv:End(),) },050,014,,,,.T.,,,,{|| .T.})
	oButton1:SetCSS( POSCSS (GetClassName(oButton1), CSS_BTN_FOCAL ))

	// BOTAO CANCELAR
	oButton2 := TButton():New( nHeight-20,nWidth-115,"Cancelar",oPanelDv,{|| oDlgDv:End()},050,014,,,,.T.,,,,{|| .T.})
	oButton2:SetCSS( POSCSS (GetClassName(oButton2), CSS_BTN_ATIVO ))

ACTIVATE MSDIALOG oDlgDv CENTERED

//restaura as teclas atalho
U_UKeyCtr(.T.)

Return

//---------------------------------------------------------------------
// Função que valida a quantidade de litros informada
//---------------------------------------------------------------------
Static Function ValidLitros(nLitros,nEncerrante,nLitros1,nLitros2,nEnc1,nEnc2)

Local lRet := .T.

// quantidade de litros deve ser maior que zero
If nLitros1 <= 0

	U_SetMsgRod("A quantidade de litros deve ser maior que zero!")
	lRet := .F.

ElseIf nLitros1 >= nLitros // quantidade de litros deve ser inferior a quantidade total, senão não justifica dividir

	U_SetMsgRod("A quantidade de litros deve ser menor que o valor original!")
	lRet := .F.

Else

	nLitros2	:= Round(nLitros - nLitros1 , TamSx3("MID_LITABA")[2])
	nEnc1		:= Round(nEncerrante - nLitros2 , TamSx3("MID_ENCFIN")[2])
	nEnc2		:= Round(nEncerrante , TamSx3("MID_ENCFIN")[2])

EndIf

Return(lRet)

//---------------------------------------------------------------------
// Função que faz a gravação da divisão do abastecimento
//---------------------------------------------------------------------
Static Function GravaDv(cCodAbast,nLitros1,nLitros2,nEnc1,nEnc2,nLitros)

Local aRet		:= {}
Local lRet		:= .T.

// faço a validação da quantidade informada
// quantidade de litros deve ser maior que zero
If nLitros1 <= 0

	U_SetMsgRod("A quantidade de litros deve ser maior que zero!")
	lRet := .F.

ElseIf nLitros1 >= nLitros // quantidade de litros deve ser inferior a quantidade total, senão não justifica dividir

	U_SetMsgRod("A quantidade de litros deve ser menor que o valor original!")
	lRet := .F.

Else

	U_SetMsgRod("Realizando a gravação da divisão de abastecimento. Aguarde...")

	CursorArrow()
	CursorWait()

	aRet := Nil

	aParam := {cCodAbast,nLitros1,nLitros2,nEnc1,nEnc2}
	aParam := {"U_TPDVA09B",aParam}
	If !FWHostPing() .OR. !STBRemoteExecute("_EXEC_CEN",aParam,,,@aRet)
		// Tratamento do erro de conexao
		U_SetMsgRod("Falha de comunicação com a central...")
		lRet := .F.

	ElseIf aRet = Nil .or. Empty(aRet) .or. Len(aRet) == 0
		// Tratamento para retorno vazio
		U_SetMsgRod("Ocorreu falha na gravação da divisão de abastecimento...")
		lRet := .F.

	ElseIf Len(aRet) >= 2 //-- consulta realizada com sucesso
		lRet := aRet[1]
		U_SetMsgRod(aRet[2])

		If lRet
			// atualizo a tela com os abastecimentos do bico
			RefreshAbs() //Consultando abastecimentos pendêntes...
		EndIf

	EndIf

	CursorArrow()

EndIf

Return(lRet)

//---------------------------------------------------------------------
// Função que faz a gravação da divisão do abastecimento (CENTRAL PDV)
//---------------------------------------------------------------------
User Function TPDVA09B(cCodAbast,nLitros1,nLitros2,nEnc1,nEnc2)

	Local lRet := .F.
	Local cMsg := ""
	Local cCampo	:= ""
	Local aCampos 	:= {}
	Local aArea		:= GetArea()
	Local nRecnoMID	:= 0 //recno do abastecimento atual
	Local aSX3MID, nX

	MID->(DbSetOrder(1)) //MID_FILIAL+MID_CODABA
	If MID->(DbSeek(xFilial("MID") + cCodAbast)) .and. MID->MID_NUMORC = Padr("P",TamSx3("MID_NUMORC")[1])

		nPrcVen := MID->MID_PREPLI

		If Reclock("MID",.F.)
			MID->MID_NUMORC := Padr("O",TamSx3("MID_NUMORC")[1])
			MID->(MsUnLock())
		EndIf

		// faço a cópia de todos os campos do abastecimento original
		aSX3MID := FWSX3Util():GetAllFields( "MID" , .F./*lVirtual*/ )
		If !empty(aSX3MID)

			For nX := 1 to len(aSX3MID)
				if Alltrim(aSX3MID[nX]) <> "MID_CODABA"
					cCampo := AllTrim(aSX3MID[nX])
					aadd(aCampos, { cCampo , MID->( FieldGet( FieldPos(cCampo) ) ) })
				endif
			next nX

			// inicio o controle de transação para inclusão do orçamento
			BeginTran()

			nRecnoMID := MID->(RecNo())

			// altera o encerrante do primeiro abastecimento
			aCampos[aScan(aCampos,{|x| AllTrim(x[1])=="MID_PREPLI"}),2] 	:= nPrcVen
			aCampos[aScan(aCampos,{|x| AllTrim(x[1])=="MID_LITABA"}),2] 	:= nLitros1
			aCampos[aScan(aCampos,{|x| AllTrim(x[1])=="MID_TOTAPA"}),2]		:= Round(nPrcVen * nLitros1,2)
			aCampos[aScan(aCampos,{|x| AllTrim(x[1])=="MID_ENCFIN"}),2] 	:= nEnc1
			aCampos[aScan(aCampos,{|x| AllTrim(x[1])=="MID_NUMORC"}),2]		:= Padr("P",TamSx3("MID_NUMORC")[1])
			aCampos[aScan(aCampos,{|x| AllTrim(x[1])=="MID_ENCINI"}),2] 	:= (nEnc1-nLitros1)
			
			// grava o primeiro abastecimento
			//conout(">> U_GrvAbMID: " + CRLF + U_XtoStrin(aCampos))
			lRet := U_GrvAbMID(aCampos)
			If lRet
				// altera o encerrante do segundo abastecimento
				aCampos[aScan(aCampos,{|x| AllTrim(x[1])=="MID_LITABA"}),2] 	:= nLitros2
				aCampos[aScan(aCampos,{|x| AllTrim(x[1])=="MID_TOTAPA"}),2]		:= nPrcVen * nLitros2
				aCampos[aScan(aCampos,{|x| AllTrim(x[1])=="MID_ENCFIN"}),2] 	:= nEnc2
				aCampos[aScan(aCampos,{|x| AllTrim(x[1])=="MID_NUMORC"}),2]		:= Padr("P",TamSx3("MID_NUMORC")[1])
				aCampos[aScan(aCampos,{|x| AllTrim(x[1])=="MID_ENCINI"}),2] 	:= (nEnc2-nLitros2)

				// grava o segundo abastecimento
				//conout(">> U_GrvAbMID: " + CRLF + U_XtoStrin(aCampos))
				lRet := U_GrvAbMID(aCampos)

			EndIf

			// -- 27/03/2018 - foi alterado o local do cancelamento do abastecimento original para o final da rotina (apos incluir os dois novos)
			// -- pois a concentradora FUSION envia o mesmo abastecimento, e as vezes acontecia de incluir o mesmo abastecimento novamente
			If lRet
				MID->(DbGoTo(nRecnoMID))

				//DANILO: Adicionado tratamento olhando situa, pois tem vez que acontece de o registro MID estar no meio da integração.
				//O problema é que se excluir a MID e gerar SLI, e após o job de subida de abastecimentos gravar o SITUA = TX, 
				//a deleção da SLI não sobe. 
				if MID->MID_SITUA == "00"
					LjGrvLog("TPDVA009","Abastecimento com situa 00. Marcado X_EXCLUI. Cod Abast: ", MID->MID_CODABA )
					Reclock("MID", .F.)
						MID->MID_CHECKS := "EX"
					MID->(MsUnLock())
				endif

				// função que exclui o abastecimento
				If MID->(Eof()) .or. !U_ExcAbMID(MID->MID_CODABA)
					lRet := .F.
				EndIf
			EndIf

			If !lRet
				// cancelo a transação
				DisarmTransaction()
				cMsg := "Não foi possível realizar a operação!"

				// gravo o flag do orçamento para não usado
				MID->(DbSetOrder(1))
				If MID->(DbSeek(xFilial("MID") + cCodAbast))
					If Reclock(MID,.F.)
						MID->MID_NUMORC := Padr("P",TamSx3("MID_NUMORC")[1])
						MID->(MsUnLock())
					EndIf
				EndIf

			Else	
				cMsg := "Operação realizada com sucesso!"
				
			EndIf

			// finalizo o controle de transação
			EndTran()

		EndIf
	
	Else
		If MID->(Eof())
			cMsg := "Abastecimento não localizado!"
		ElseIf MID->MID_NUMORC <> Padr("P",TamSx3("MID_NUMORC")[1])
			cMsg := "Abastecimento não esta mais pendente..."	
		EndIf
	EndIf

	RestArea(aArea)

Return({lRet,cMsg})

//---------------------------------------------------------------------
// Função que faz a aglutinação de abastecimentos
//---------------------------------------------------------------------
Static Function AglutAbast(aAbast)
Local lRet := .F.

U_SetMsgRod("Realizando a aglutinação dos abastecimentos. Aguarde...")

CursorArrow()
CursorWait()

aRet := Nil

aParam := {aAbast}
aParam := {"U_TPDVA09C",aParam}
If !FWHostPing() .OR. !STBRemoteExecute("_EXEC_CEN",aParam,,,@aRet)
	// Tratamento do erro de conexao
	U_SetMsgRod("Falha de comunicação com a central...")
	lRet := .F.

ElseIf aRet = Nil .or. Empty(aRet) .or. Len(aRet) == 0
	// Tratamento para retorno vazio
	U_SetMsgRod("Ocorreu falha na aglutinação dos abastecimentos...")
	lRet := .F.

ElseIf Len(aRet) >= 2 //-- consulta realizada com sucesso
	lRet := aRet[1]
	U_SetMsgRod(aRet[2])

	If lRet
		// atualizo a tela com os abastecimentos do bico
		RefreshAbs() //Consultando abastecimentos pendêntes...
	EndIf

EndIf

CursorArrow()

Return lRet

//---------------------------------------------------------------------
// Função que faz a aglutinação de abastecimentos (CENTRAL PDV)
//---------------------------------------------------------------------
User Function TPDVA09C(aAbast)

Local aArea			:= GetArea()
Local lRet	   		:= .T.
Local cMsg			:= ""
Local nX 	   		:= 1
Local nQtd			:= 0
Local nEncerrante	:= 0
Local nQuantidade   := 0
Local nEncMaior		:= 0
Local cCampo		:= ""
Local aCampos		:= {}
Local cUltRFID		:= ""
Local cUltimoAbast	:= ""
Local lDiferente	:= .F.
Local _nToler       := 0
Local nDiferenca	:= 0
Local nDivergencia	:= 0
Local aSX3MID

// inicio o controle de transação para inclusão do orçamento
BeginTran()

//Quintais 29/07/2015
_nToler := SuperGetMv("ESP_XAGLUT",.F.,0.5)
For nX := 1 To Len(aAbast)

	MID->(DbSetOrder(1)) //MID_FILIAL+MID_CODABA
	If MID->(DbSeek(xFilial("MID") + aAbast[nX])) .and. MID->MID_NUMORC = Padr("P",TamSx3("MID_NUMORC")[1])

		//If Reclock("MID",.F.)

			//MID->MID_NUMORC := Padr("O",TamSx3("MID_NUMORC")[1])
			//MID->(MsUnLock())
				
			If nEncerrante < MID->MID_ENCFIN // se o encerrante do primeiro abastecimento for menor que o do segundo abastecimento

				nDiferenca := MID->MID_ENCFIN - MID->MID_LITABA

				If nEncerrante > 0 .and. (nEncerrante <> nDiferenca)
					nDivergencia := nEncerrante - nDiferenca
					If nDivergencia < 0
						nDivergencia := nDivergencia * (-1)
					EndIf
					lDiferente := nDivergencia > _nToler // VALIDA A DIFERENÇA AQUI COM O PARAMETRO CRIADO
				EndIf

			Else

				nDiferenca := nEncerrante - nQuantidade

				If (MID->MID_ENCFIN <> nDiferenca)
					nDivergencia := nEncerrante - nDiferenca
					If nDivergencia < 0
						nDivergencia := nDivergencia * (-1)
					EndIf
					lDiferente := nDivergencia > _nToler // VALIDA A DIFERENÇA AQUI COM O PARAMETRO CRIADO
				EndIf

			EndIf

			If lDiferente
				cMsg := "Para aglutinar abastecimentos é necessário que os mesmos sejam consecutivos!"
				lRet := .F.
				Exit //sai do For
			EndIf

			if !empty(cUltRFID) .AND. cUltRFID <> MID->MID_RFID
				cMsg := "Para aglutinar abastecimentos é necessário que os mesmos sejam do mesmo frentista (identifid)!"
				lRet := .F.
				Exit //sai do For
			endif

			nEncerrante := MID->MID_ENCFIN
			nQuantidade	:= MID->MID_LITABA
			cUltimoAbast := MID->MID_CODABA
			nQtd   		+= nQuantidade
			cUltRFID	:= MID->MID_RFID

			If nEncMaior < MID->MID_ENCFIN
				nEncMaior := MID->MID_ENCFIN
			EndIf

		//Else
		//	cMsg := "O abastecimento " + AllTrim(MID->MID_CODABA) + " está sendo utilizado por outro usuário!"
		//	lRet := .F.		
		//	Exit //sai do For
		//EndIf

	Else
		cMsg := "O abastecimento " + AllTrim(MID->MID_CODABA) + " já está finalizado ou em orçamento!"
		lRet := .F.
		Exit //sai do For

	EndIf

Next nX

If lRet

	// posiciono no último abastecimento
	MID->(DbSetOrder(1))
	If MID->(DbSeek(xFilial("MID") + cUltimoAbast))

		nPrcVen := MID->MID_PREPLI

		// faço a cópia de todos os campos do último abastecimento
		aSX3MID := FWSX3Util():GetAllFields( "MID" , .F./*lVirtual*/ )
		If !empty(aSX3MID)

			For nX := 1 to len(aSX3MID)
				if Alltrim(aSX3MID[nX]) <> "MID_CODABA"
					cCampo := AllTrim(aSX3MID[nX])
					aadd(aCampos, { cCampo , MID->( FieldGet( FieldPos(cCampo) ) ) })
				endif
			next nX

			// excluo os abastecimentos originais
			For nX := 1 To Len(aAbast)
				MID->(DbSetOrder(1))
				If MID->(DbSeek(xFilial("MID") + aAbast[nX]))

					//DANILO: Adicionado tratamento olhando situa, pois tem vez que acontece de o registro MID estar no meio da integração.
					//O problema é que se excluir a MID e gerar SLI, e após o job de subida de abastecimentos gravar o SITUA = TX, 
					//a deleção da SLI não sobe. 
					if MID->MID_SITUA == "00"
						LjGrvLog("TPDVA009","Abastecimento com situa 00. Marcado X_EXCLUI. Cod Abast: ", MID->MID_CODABA )
						Reclock("MID", .F.)
							MID->MID_CHECKS := "EX"
						MID->(MsUnLock())
					endif
					
					// função que exclui o abastecimento
					If !U_ExcAbMID(MID->MID_CODABA)
						lRet := .F.
						Exit //sai do For
					EndIf

				EndIf
			Next nX

			If lRet

				// altera o encerrante do primeiro abastecimento
				aCampos[aScan(aCampos,{|x| AllTrim(x[1])=="MID_LITABA"}),2] 	:= nQtd
				aCampos[aScan(aCampos,{|x| AllTrim(x[1])=="MID_TOTAPA"}),2]		:= Round(nPrcVen * nQtd,2)
				aCampos[aScan(aCampos,{|x| AllTrim(x[1])=="MID_ENCFIN"}),2] 	:= nEncMaior //nEncerrante
				aCampos[aScan(aCampos,{|x| AllTrim(x[1])=="MID_NUMORC"}),2] 	:= Padr("P",TamSx3("MID_NUMORC")[1])
				aCampos[aScan(aCampos,{|x| AllTrim(x[1])=="MID_ENCINI"}),2] 	:= (nEncMaior-nQtd)

				// crio o novo abastecimento
				//conout(">> U_GrvAbMID: " + CRLF + U_XtoStrin(aCampos))
				If !U_GrvAbMID(aCampos)
					lRet := .F.
				EndIf

			EndIf

		Else
			lRet := .F.
		EndIf

		If !lRet
			cMsg := "Não foi possível realizar a operação!"
		Else
			cMsg := "Operação realizada com sucesso!"
		EndIf
		
	EndIf

EndIf

If !lRet
	// cancelo a transação
	DisarmTransaction()
EndIf

// finalizo o controle de transação
EndTran()

RestArea(aArea)

Return({lRet,cMsg})


//
// Converte em valor da STRING em NUMERICO
// Ex.: 1) RetValr("0230011",3) -> 230.011
//      2) RetValr("565654550",2) -> 5,656,545.50
//
Static Function RetValr(cStr,nDec)
	cStr := SubStr(cStr,1,(Len(cStr)-nDec)) + "." + SubStr(cStr,(Len(cStr)-nDec)+1,Len(cStr)-(Len(cStr)-nDec))
Return Val(cStr)

// 
// Transforma um valor em STRING
//
Static Function TransStr(nNum, nTam, nDec)
Local cRet := ""

	cRet := Transform( nNum, "@E " + Replicate( "9", nTam ) + "." + Replicate( "9", nDec ) )
	cRet := StrTran( cRet, ".", "" )
	cRet := StrTran( cRet, ",", "" )
	cRet := PadL( AllTrim(cRet), nTam, "0")

Return cRet

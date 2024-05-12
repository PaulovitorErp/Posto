#INCLUDE "PROTHEUS.CH"
#INCLUDE "topconn.ch"
#INCLUDE "TbiConn.ch"


/*/{Protheus.doc} TRETE002
Função que atualiza o preço do produto no bico da concentradora.

@author pablo
@since 27/09/2018
@version 1.0
@return ${return}, ${return_description}

@type function
/*/
User Function TRETE002(lTabPreco)

Local aButtons		:= {}
Local aObjects 		:= {}
Local aSizeAut		:= MsAdvSize()
Local bSvblDb
Local nPosVal := 0
Local bMarcaTodos := {|x| iif(x[1]=="LBNO", x[1]:="LBOK", x[1]:="LBNO")  }
Local cBkpFil := cFilAnt
Local cUsrPRC
Private cPerg 		:= "TRETE002"
Private lPerguntaOK	:= .F.
Private	cConcDe		:= ""
Private	cConcAte	:= ""
Private	cBicoDe		:= ""
Private	cBicoAte	:= ""
Private cTanquDe	:= ""
Private cTanquAte	:= ""
Private	cBombaDe	:= ""
Private	cBombaAte	:= ""
Private cProdDe		:= ""
Private lPrcNv1		:= .F. //"0"-Dinheiro
Private lPrcNv2		:= .F. //"1"-Débito
Private lPrcNv3		:= .F. //"2"-Crédito
Private oGridBicos
Private oDlgBicos
Private lMARKALL := .F.

// mostra a tela de perguntas
CriaPerguntas(lTabPreco)

// se o usuário não tiver cancelado a operação
if lPerguntaOK

	//Largura, Altura, Modifica largura, Modifica altura
	aAdd( aObjects, { 100,	100, .T., .T. } ) //Browse

	aInfo 	:= { aSizeAut[ 1 ], aSizeAut[ 2 ], aSizeAut[ 3 ], aSizeAut[ 4 ], 2, 2 }
	aPosObj := MsObjSize( aInfo, aObjects, .T. )

	DEFINE MSDIALOG oDlgBicos TITLE "Atualização de preço dos bicos" From aSizeAut[7],0 TO aSizeAut[6],aSizeAut[5] COLORS 0, 16777215 PIXEL

	EnchoiceBar(oDlgBicos, {|| Confirmar()},{|| oDlgBicos:End()},,aButtons)

	// crio o grid de bicos
	oGridBicos := MsGridBicos(@nPosVal)
	bSvblDb  := oGridBicos:oBrowse:bLDblClick
	oGridBicos:oBrowse:bLDblClick := {|| iif(oGridBicos:oBrowse:nColPos==nPosVal, U_UGdRstDb(oGridBicos, bSvblDb), ( oGridBicos:aCols[oGridBicos:nAt][1] := iif(oGridBicos:aCols[oGridBicos:nAt][1]=="LBNO", iif(!empty(oGridBicos:aCols[oGridBicos:nAt][2]),"LBOK","LBNO"), "LBNO") , oGridBicos:oBrowse:Refresh() )) }
	oGridBicos:oBrowse:bHeaderClick := {|oBrw,nCol| iif(lMARKALL .AND. !empty(oGridBicos:aCols[1][2]), (aEval(oGridBicos:aCols, bMarcaTodos),oBrw:Refresh(),oBrw:SetFocus(),lMARKALL:=!lMARKALL), lMARKALL:=!lMARKALL) }

	// caso não tenha encontrato bicos
	if !RefreshGrid()

		Alert("Não foram encontrados dados para este filtro!")
		oDlgBicos:End()

	endif

	ACTIVATE MSDIALOG oDlgBicos CENTERED

endif

cFilAnt := cBkpFil 

Return()


/*/{Protheus.doc} MsGridBicos
Função que cria a MsNewGetDados dos clientes.

@author pablo
@since 27/09/2018
@version 1.0
@return ${return}, ${return_description}

@type function
/*/
Static Function MsGridBicos(nPosVal)

Local nX
Local aHeaderEx 	:= {}
Local aColsEx 		:= {}
Local aFieldFill 	:= {}
Local aFields 		:= {"MARK","MIC_CODTAN","MIC_CODBOM","MIC_CODBIC","MIC_NLOGIC","MIC_LADO","MHZ_CODPRO","MHZ_DESPRO","PRECO","STATUS"}
Local aAlterFields 	:= {}
Local lNivCbc := SuperGetMv("MV_XNIVCBC",,.F.) .and. U68->( FieldPos("U68_TIPPRC") ) > 0

If SuperGetMv("MV_XPDFTAB",,.F.)
	aadd(aAlterFields,"PRECO")
EndIf

If lNivCbc
	aFields := {"MIC_CODTAN","MIC_CODBOM","MIC_CODBIC","MIC_NLOGIC","MIC_LADO","MHZ_CODPRO","MHZ_DESPRO","PRECO","U68_TIPPRC","STATUS"}
EndIf

// Define field properties
For nX := 1 to Len(aFields)

	If aFields[nX] == "STATUS"
		Aadd(aHeaderEx, {"Status","STATUS","@!",40,0,"","€€€€€€€€€€€€€€","C","","","",""})
	ElseIf AllTrim(aFields[nX]) == "MARK"
			Aadd(aHeaderEx,{Space(10),'MARK','@BMP',2,0,'','€€€€€€€€€€€€€€','C','','','',''})
	ElseIf aFields[nX] == "PRECO"
		nPosVal := nX
		Aadd(aHeaderEx, {"Preco","PRECO",PesqPict("SL2","L2_VRUNIT"),TamSX3("L2_VRUNIT")[1],TamSX3("L2_VRUNIT")[2],"","€€€€€€€€€€€€€€","C","","","",""})
	ElseIf !empty(GetSx3Cache(aFields[nX],"X3_CAMPO"))
		aadd(aHeaderEx, U_UAHEADER(aFields[nX]) )
	EndIf

Next nX

// Define field values
For nX := 1 to Len(aFields)

	If aFields[nX] == "STATUS"
		Aadd(aFieldFill, "")
	ElseIf aFields[nX] == "MARK"
		Aadd(aFieldFill, "LBNO")
	ElseIf aFields[nX] == "PRECO"
		Aadd(aFieldFill, 0)
	ElseIf !empty(GetSx3Cache(aFields[nX],"X3_CAMPO"))
		Aadd(aFieldFill, CriaVar(aFields[nX]))
	EndIf

Next nX

Aadd(aFieldFill, .F.)
Aadd(aColsEx, aFieldFill)

Return(MsNewGetDados():New( aPosObj[1,1], aPosObj[1,2], aPosObj[1,3], aPosObj[1,4], GD_UPDATE, "AllwaysTrue", "AllwaysTrue", "+Field1+Field2", aAlterFields,, 999, "AllwaysTrue", "", "AllwaysTrue", oDlgBicos, aHeaderEx, aColsEx))


/*/{Protheus.doc} RefreshGrid
Função que atualiza o Grid dos bicos.

@author pablo
@since 27/09/2018
@version 1.0
@return ${return}, ${return_description}

@type function
/*/
Static Function RefreshGrid()

Local aArea			:= GetArea()
Local cQuery	 	:= ""
Local cPulaLinha 	:= chr(13)+chr(10)
Local aFieldFill 	:= {}
Local nX			:= 1
Local cIP 			:= ""
Local nPorta		:= 0
Local cSerial		:= ""
Local cAutomacao	:= ""
Local cTipoConexao	:= ""
Local lTipoPreco	:= GetMv("MV_LJCNVDA") //Habilita tabela de preço: MV_TABPAD = número da tabela de preço referente ao produto da venda (001)
Local cTabPrc		:= GetMv("MV_TABPAD")
Local nPrcInt		:= 0
Local nPrcFloat		:= 0
Local nPreco		:= 0
Local nQuantItens	:= 0
Local nContador		:= 0
Local lRet			:= .T.
Local cMsgErro		:= ""
Local cRetorno		:= ""
Local cCondicao		:= ""
Local bCondicao
Local lNivCBC		:= SuperGETMV('MV_XNIVCBC',,.F.) .and. U68->( FieldPos("U68_TIPPRC") ) > 0

oGridBicos:Acols := {}

MIC->(DbSetOrder(3)) //MIC_FILIAL+MIC_CODBIC+MIC_CODTAN

cCondicao := " MIC_FILIAL = '" + xFilial("MIC") + "'"
//cCondicao += " .AND. MIC_STATUS <> '2' "
cCondicao += " .AND. ((MIC->MIC_STATUS = '1' .AND. DTOS(MIC->MIC_XDTATI) <= '"+DTOS(dDataBase)+"') .OR. (MIC->MIC_STATUS = '2' .AND. DTOS(MIC->MIC_XDTDES) >= '"+DTOS(dDataBase)+"')) "
cCondicao += " .AND. ( MIC_CODBIC >= '" + cBicoDe + "' .AND. MIC_CODBIC <= '" + cBicoAte + "' ) "
cCondicao += " .AND. ( MIC_XCONCE >= '" + cConcDe + "' .AND. MIC_XCONCE <= '" + cConcAte + "' ) "
cCondicao += " .AND. ( MIC_CODBOM >= '" + cBombaDe + "' .AND. MIC_CODBOM <= '" + cBombaAte + "' ) "
cCondicao += " .AND. ( MIC_CODTAN >= '" + cTanquDe + "' .AND. MIC_CODTAN <= '" + cTanquAte + "' ) "

// limpo os filtros da MIC
MIC->(DbClearFilter())

// executo o filtro na MIC
bCondicao 	:= "{|| " + cCondicao + " }"
MIC->(DbSetFilter(&bCondicao,cCondicao))

// vou para a primeira linha
MIC->(DbGoTop())

// verifico quantos itens foram filtrados
MIC->(DbEval({|| nQuantItens++}))

If lNivCBC
	nQtdNv := 0
	If lPrcNv1
		nQtdNv += 1
	EndIf
	If lPrcNv2
		nQtdNv += 1
	EndIf
	If lPrcNv3
		nQtdNv += 1
	EndIf
	nQuantItens := nQtdNv * nQuantItens
EndIf

// vou para a primeira linha
MIC->(DbGoTop())

if nQuantItens > 0

	ProcRegua(nQuantItens)
	MHZ->(DbSetOrder(1)) //MHZ_FILIAL+MHZ_CODTAN

	While MIC->(!Eof())

		IncProc("Concentradora - " + AllTrim(MIC->MIC_XCONCE) + " / Bico - " + AllTrim(MIC->MIC_CODBIC) )

		MHZ->(DbSeek(xFilial("MHZ") + MIC->MIC_CODTAN ))

		// se tiver preenchido o produto, filtra apenas ele
		if Empty(cProdDe) .OR. cProdDe == MHZ->MHZ_CODPRO

			SB1->(DbSetOrder(1))
			if SB1->(DbSeek( xFilial("SB1") + MHZ->MHZ_CODPRO ))

				// função que retorna o preço do produto
				nPreco := U_URetPrec(MHZ->MHZ_CODPRO,@cMsgErro)

				If lNivCBC

					If lPrcNv1 //"0"-Dinheiro
						nPreco := U_URetPrec(MHZ->MHZ_CODPRO,@cMsgErro,,"0")
						aFieldFill := {}

						aadd(aFieldFill, "LBOK")
						aadd(aFieldFill, MIC->MIC_CODTAN)
						aadd(aFieldFill, MIC->MIC_CODBOM)
						aadd(aFieldFill, MIC->MIC_CODBIC)
						aadd(aFieldFill, MIC->MIC_NLOGIC)
						aadd(aFieldFill, MIC->MIC_LADO)
						aadd(aFieldFill, MHZ->MHZ_CODPRO)
						aadd(aFieldFill, MHZ->MHZ_DESPRO)
						aadd(aFieldFill, nPreco)
						aadd(aFieldFill, "0") //"0"-Dinheiro
						aadd(aFieldFill, cMsgErro)
						Aadd(aFieldFill, .F.)
						aadd(oGridBicos:Acols,aFieldFill)
					EndIf

					If lPrcNv2 //"1"-Débito
						nPreco := U_URetPrec(MHZ->MHZ_CODPRO,@cMsgErro,,"1")
						aFieldFill := {}

						aadd(aFieldFill, "LBOK")
						aadd(aFieldFill, MIC->MIC_CODTAN)
						aadd(aFieldFill, MIC->MIC_CODBOM)
						aadd(aFieldFill, MIC->MIC_CODBIC)
						aadd(aFieldFill, MIC->MIC_NLOGIC)
						aadd(aFieldFill, MIC->MIC_LADO)
						aadd(aFieldFill, MHZ->MHZ_CODPRO)
						aadd(aFieldFill, MHZ->MHZ_DESPRO)
						aadd(aFieldFill, nPreco)
						aadd(aFieldFill, "1") //"1"-Débito
						aadd(aFieldFill, cMsgErro)
						Aadd(aFieldFill, .F.)
						aadd(oGridBicos:Acols,aFieldFill)
					EndIf

					If lPrcNv3 //"2"-Crédito
						nPreco := U_URetPrec(MHZ->MHZ_CODPRO,@cMsgErro,,"2")
						aFieldFill := {}

						aadd(aFieldFill, "LBOK")
						aadd(aFieldFill, MIC->MIC_CODTAN)
						aadd(aFieldFill, MIC->MIC_CODBOM)
						aadd(aFieldFill, MIC->MIC_CODBIC)
						aadd(aFieldFill, MIC->MIC_NLOGIC)
						aadd(aFieldFill, MIC->MIC_LADO)
						aadd(aFieldFill, MHZ->MHZ_CODPRO)
						aadd(aFieldFill, MHZ->MHZ_DESPRO)
						aadd(aFieldFill, nPreco)
						aadd(aFieldFill, "2") //"2"-Crédito
						aadd(aFieldFill, cMsgErro)
						Aadd(aFieldFill, .F.)
						aadd(oGridBicos:Acols,aFieldFill)
					EndIf

				Else

					aFieldFill := {}

					aadd(aFieldFill, "LBOK")
					aadd(aFieldFill, MIC->MIC_CODTAN)
					aadd(aFieldFill, MIC->MIC_CODBOM)
					aadd(aFieldFill, MIC->MIC_CODBIC)
					aadd(aFieldFill, MIC->MIC_NLOGIC)
					aadd(aFieldFill, MIC->MIC_LADO)
					aadd(aFieldFill, MHZ->MHZ_CODPRO)
					aadd(aFieldFill, MHZ->MHZ_DESPRO)
					aadd(aFieldFill, nPreco)
					aadd(aFieldFill, cMsgErro)
					Aadd(aFieldFill, .F.)
					aadd(oGridBicos:Acols,aFieldFill)

				EndIf
				nContador ++

			endif

		endif


		MIC->(DbSkip())

	EndDo

	// limpo os filtros da MIC
	MIC->(DbClearFilter())

	RestArea(aArea)
	oGridBicos:oBrowse:Refresh()

endif

if nQuantItens <= 0 .OR. nContador <= 0
	lRet := .F.
endif

Return(lRet)


/*/{Protheus.doc} CriaPerguntas
Função que mostra tela de perguntas.

@author pablo
@since 27/09/2018
@version 1.0
@return ${return}, ${return_description}

@type function
/*/
Static Function CriaPerguntas(lTabPreco)

Local aMvPar
Local nMv := 0
Local aParamBox := {}
Local lNivCbc := SuperGetMv("MV_XNIVCBC",,.F.) .and. U68->( FieldPos("U68_TIPPRC") ) > 0

if lTabPreco .AND. len(Alltrim(xFilial("DA0"))) <> len(cFilAnt)

	aAdd(aParamBox,{1,"Informe a Filial",Space(len(cFilAnt)),"","FWFilExist(,MV_PAR01)","XM0","",0,.T.}) // Tipo caractere

	If ParamBox(aParamBox,"Atualização de preço dos bicos",@aMvPar,,,,,,,cPerg)
		cFilAnt := aMvPar[1]
	else
		lPerguntaOK := .F.
		Return .F.
	EndIf
	aMvPar := Nil
	aParamBox := {}

	//verifica se o usuário tem permissão para acesso a rotina
	if lTabPreco
		U_TRETA37B("PRCBIC", "ENVIA PREÇO PARA BICO ")
		cUsrPRC := U_VLACESS1("PRCBIC", RetCodUsr())
		If cUsrPRC == Nil .OR. Empty(cUsrPRC)
			MsgInfo("Usuário não tem permissão de acesso a rotina de Envio de Preços para Bico.")
			lPerguntaOK := .F.
			Return .F.
		EndIf
	endif

endif

// Tipo 1 -> MsGet()
//           [2]-Descricao
//           [3]-String contendo o inicializador do campo
//           [4]-String contendo a Picture do campo
//           [5]-String contendo a validacao
//           [6]-Consulta F3
//           [7]-String contendo a validacao When
//           [8]-Tamanho do MsGet
//           [9]-Flag .T./.F. Parametro Obrigatorio ?
aAdd(aParamBox,{1,"Concentradora De",Space(TamSX3("MIC_XCONCE")[1]),"","","MHX","",0,.F.}) // Tipo caractere
aAdd(aParamBox,{1,"Concentradora Ate",Replicate("Z",TamSX3("MIC_XCONCE")[1]),"","","MHX","",0,.F.}) // Tipo caractere
aAdd(aParamBox,{1,"Tanque De",Space(TamSX3("MIC_CODTAN")[1]),"","","MHZ","",0,.F.}) // Tipo caractere
aAdd(aParamBox,{1,"Tanque Ate",Replicate("Z",TamSX3("MIC_CODTAN")[1]),"","","MHZ","",0,.F.}) // Tipo caractere
aAdd(aParamBox,{1,"Bomba De",Space(TamSX3("MIC_CODBOM")[1]),"","","MHY","",0,.F.}) // Tipo caractere
aAdd(aParamBox,{1,"Bomba Ate",Replicate("Z",TamSX3("MIC_CODBOM")[1]),"","","MHY","",0,.F.}) // Tipo caractere
aAdd(aParamBox,{1,"Bico De",Space(TamSX3("MIC_CODBIC")[1]),"","","MIC01","",0,.F.}) // Tipo caractere
aAdd(aParamBox,{1,"Bico Ate",Replicate("Z",TamSX3("MIC_CODBIC")[1]),"","","MIC01","",0,.F.}) // Tipo caractere
aAdd(aParamBox,{1,"Produto",Space(TamSX3("B1_COD")[1]),"","","SB1","",0,.F.}) // Tipo caractere

If lNivCbc
		// Tipo 5 -> Somente CheckBox
	//           [2]-Descricao
	//           [3]-Indicador Logico contendo o inicial do Check
	//           [4]-Tamanho do Radio
	//           [5]-Validacao
	//           [6]-Flag .T./.F. Parametro Obrigatorio ?
	aAdd(aParamBox,{5,"Nível Dinheiro ?",.T.,50,"",.F.})
	aAdd(aParamBox,{5,"Nível Débito ?",.T.,50,"",.F.})
	aAdd(aParamBox,{5,"Nível Credito ?",.T.,50,"",.F.})
EndIf

// Parametros da função Parambox()
// -------------------------------
// 1 - < aParametros > - Vetor com as configurações
// 2 - < cTitle >      - Título da janela
// 3 - < aRet >        - Vetor passador por referencia que contém o retorno dos parâmetros
// 4 - < bOk >         - Code block para validar o botão Ok
// 5 - < aButtons >    - Vetor com mais botões além dos botões de Ok e Cancel
// 6 - < lCentered >   - Centralizar a janela
// 7 - < nPosX >       - Se não centralizar janela coordenada X para início
// 8 - < nPosY >       - Se não centralizar janela coordenada Y para início
// 9 - < oDlgWizard >  - Utiliza o objeto da janela ativa
//10 - < cLoad >       - Nome do perfil se caso for carregar
//11 - < lCanSave >    - Salvar os dados informados nos parâmetros por perfil
//12 - < lUserSave >   - Configuração por usuário

// Caso alguns parâmetros para a função não seja passada será considerado DEFAULT as seguintes abaixo:
// DEFAULT bOk   := {|| (.T.)}
// DEFAULT aButtons := {}
// DEFAULT lCentered := .T.
// DEFAULT nPosX  := 0
// DEFAULT nPosY  := 0
// DEFAULT cLoad     := ProcName(1)
// DEFAULT lCanSave := .T.
// DEFAULT lUserSave := .F.
If lPerguntaOK := ParamBox(aParamBox,"Atualização de preço dos bicos",@aMvPar,,,,,,,cPerg)
	For nMv := 1 To Len( aMvPar )
		&( "MV_PAR" + StrZero( nMv, 2, 0 ) ) := aMvPar[ nMv ]
	Next nMv
EndIf

// valida se foi preenchido pelo menos um nível (quanto ativado preço por nível)
If lNivCbc .and. !MV_PAR10 .and. !MV_PAR11 .and. !MV_PAR12
	Alert("Obrigatório selecionar pelo menos um nível: 0-Dinheiro / 1-Débito / 2-Crédito")
	lPerguntaOK := .F.
EndIf

If lPerguntaOK
	
	cConcDe		:= MV_PAR01
	cConcAte	:= MV_PAR02
	cTanquDe	:= MV_PAR03
	cTanquAte	:= MV_PAR04
	cBombaDe	:= MV_PAR05
	cBombaAte	:= MV_PAR06
	cBicoDe		:= MV_PAR07
	cBicoAte	:= MV_PAR08 
	cProdDe		:= MV_PAR09
	If lNivCbc
		lPrcNv1	:= MV_PAR10
		lPrcNv2	:= MV_PAR11
		lPrcNv3	:= MV_PAR12
	EndIf
	
EndIf

Return lPerguntaOK

/*/{Protheus.doc} Confirmar
Funcao chamada na confirmação da rotina.
Faz o envio do preço à concentradora.

@author pablo
@since 27/09/2018
@version 1.0
@return ${return}, ${return_description}

@type function
/*/
Static Function Confirmar()

	//barra de processamento
	Processa({|| RunProc()},"Aguarde...","Comunicando com a concentradora...",.T.)

Return()


/*/{Protheus.doc} RunProc
Função que faz o processamento.

@author pablo
@since 27/09/2018
@version 1.0
@return ${return}, ${return_description}

@type function
/*/
Static Function RunProc()

Local nX 			:= 1
Local nPosCodBic	:= aScan(oGridBicos:aHeader,{|x| AllTrim(x[2]) == "MIC_CODBIC"})
Local nPosTanque	:= aScan(oGridBicos:aHeader,{|x| AllTrim(x[2]) == "MIC_CODTAN"})
Local nPosPrc		:= aScan(oGridBicos:aHeader,{|x| AllTrim(x[2]) == "PRECO"})
Local nPosStatus	:= aScan(oGridBicos:aHeader,{|x| AllTrim(x[2]) == "STATUS"})
Local nPreco		:= 0
Local cNLogic		:= ""
Local cLado			:= ""
Local lRet			:= .F.
Local cRetorno		:= ""
Local cTipoPrc		:= "0" //"0" dinheiro, "1" debito e "2" crédito
Local lNivCbc 		:= SuperGetMv("MV_XNIVCBC",,.F.) .and. U68->( FieldPos("U68_TIPPRC") ) > 0
Local cAmbCent		:= SuperGetMv("TP_AMBCPPR",,"") //Define o codigo ambiente da MD4 da central pdv da filial corrente, para atualização remota
Private oRpcSrv

If lNivCbc
	nPosTipPrc := aScan(oGridBicos:aHeader,{|x| AllTrim(x[2]) == "U68_TIPPRC"})
EndIf

// mostro a quantidade de bicos a serem processados
ProcRegua(Len(oGridBicos:aCols))

// percorro todos os bicos do grid
For nX := 1 To Len(oGridBicos:aCols)

	if oGridBicos:aCols[nX,1] == "LBOK"

		lRet	:= .F.
		nPreco 	:= oGridBicos:aCols[nX,nPosPrc]
		If lNivCbc .and. nPosTipPrc > 0
			cTipoPrc := oGridBicos:aCols[nX,nPosTipPrc]
		EndIf

		// se o preço do produto estiver preenchido
		if nPreco > 0

			// posiciono na tabela de bicos
			MIC->(DbSetOrder(3)) //MIC_FILIAL+MIC_CODBIC+MIC_CODTAN
			if MIC->(DbSeek( xFilial("MIC") + oGridBicos:aCols[nX,nPosCodBic] + oGridBicos:aCols[nX,nPosTanque] ))

				//logica pra encontrar o bico ativo
				while MIC->(!Eof()) .AND. MIC->MIC_FILIAL+MIC->MIC_CODBIC+MIC->MIC_CODTAN == xFilial("MIC") + oGridBicos:aCols[nX,nPosCodBic] + oGridBicos:aCols[nX,nPosTanque]
					if ((MIC->MIC_STATUS = '1' .AND. MIC->MIC_XDTATI <= dDataBase) .OR. (MIC->MIC_STATUS = '2' .AND. MIC->MIC_XDTDES >= dDataBase))
						EXIT
					endif
					MIC->(DbSkip())
				enddo

				IncProc("Concentradora - " + AllTrim(MIC->MIC_XCONCE) + " / Bico - " + AllTrim(MIC->MIC_CODBIC) )

				// posiciono na tabela de concentradoras
				MHX->(DbSetOrder(1)) //MHX_FILIAL+MHX_CODCON
				if MHX->(DbSeek(xFilial("MHX") + MIC->MIC_XCONCE))

					cNLogic	:= AllTrim(MIC->MIC_NLOGIC)
					cLado	:= MIC->MIC_LADO

					// envio o comando para a concentradora
					if !empty(cAmbCent) //via RPC
						lRet := DoRPC_Pdv(cAmbCent, "U_TRETE001", MHX->MHX_CODCON, "3"/*AtuPreco*/, {cNLogic,cLado,nPreco,cTipoPrc})
					else //na propria base
						lRet := U_TRETE001(MHX->MHX_CODCON,"3"/*AtuPreco*/,{cNLogic,cLado,nPreco,cTipoPrc})
					endif

					if lRet
						cRetorno := "Preço enviado com sucesso!"
						oGridBicos:aCols[nX,1] := "LBNO" //caso de sucesso, desmarco pra nao enviar novamente
					else
						cRetorno := "Não foi possível enviar o preço!"
					endif

				else
					cRetorno := "Concentradora não cadastrada!"
				endif

			else
				cRetorno := "Bico não cadastrado!"
			endif

			oGridBicos:aCols[nX,nPosStatus] := cRetorno

		endif

	endif

Next nX

if !empty(cAmbCent)
	DoRpcClose()
endif

oGridBicos:oBrowse:Refresh()

Return()


//--------------------------------------------------------------------------------------
// Função que faz conexão RPC na retaguarda, para buscar registros
//--------------------------------------------------------------------------------------
Static Function DoRPC_Pdv(cAmbLocal, cFunction, xParam1, xParam2, xParam3, xParam4, xParam5, xParam6, xParam7, xParam8, xParam9, xParam10, xParam11, xParam12, xParam13, xParam14, xParam15)

	Local lRet 		:= .F.
	Local xRet      := .F.
	Local cRpcEnv   := ""
	Local cRpcSrv   := ""
	Local nRpcPort  := 0
	Local cRpcEmp   := ""
	Local cRpcFil   := ""
	Local aAliasRpc := {"MHX","MIC"}
	Local cMsgError := ""

	if type("oRpcSrv")=="O"
		if oRpcSrv:CallProc( 'FindFunction', cFunction )
			// Executa função através do CallProc
			xRet := oRpcSrv:CallProc( cFunction, xParam1, xParam2, xParam3, xParam4, xParam5, xParam6, xParam7, xParam8, xParam9, xParam10, xParam11, xParam12, xParam13, xParam14, xParam15)
			cMsgError := ""
		else
			cMsgError := "RPC: Função "+cFunction+" nao compilada no ambiente destino."
		endif
	else
		DbSelectArea("MD4")
		MD4->( DbSetOrder(1) ) //MD4_FILIAL+MD4_CODIGO
		DbSelectArea("MD3")
		MD3->( DbSetOrder(1) ) //MD3_FILIAL+MD3_CODAMB+MD3_TIPO

		If !Empty( cAmbLocal )
			If MD4->(DbSeek( xFilial("MD4") + cAmbLocal ))
				DbSelectArea("MD3")
				MD3->( DbSetOrder(1) ) //MD3_FILIAL+MD3_CODAMB+MD3_TIPO
				If MD3->(DbSeek( xFilial("MD3") + cAmbLocal + "R")) //"R" -> Tipo de Comunicacao RPC
					// Prepara ambiente para conexão em outro Servidor
					cRpcEnv := AllTrim( MD3->MD3_NOMAMB )
					cRpcEmp := AllTrim( MD3->MD3_EMP )
					cRpcFil := cFilAnt //AllTrim( MD3->MD3_FIL )
					oRpcSrv := TRpc():New( cRpcEnv ) //TRpc():New(GetEnvServer())

					// Conecta no ambiente
					cRpcSrv  := AllTrim( MD3->MD3_IP )
					nRpcPort := Val( MD3->MD3_PORTA )

					If ( oRpcSrv:Connect( cRpcSrv, nRpcPort ) )
						oRpcSrv:CallProc( 'RPCSetType', 3 )
						oRpcSrv:CallProc( 'RPCSetEnv', cRpcEmp, cRpcFil,,,,, aAliasRpc )

						if oRpcSrv:CallProc( 'FindFunction', cFunction )
							// Executa função através do CallProc
							xRet:= oRpcSrv:CallProc( cFunction, xParam1, xParam2, xParam3, xParam4, xParam5, xParam6, xParam7, xParam8, xParam9, xParam10, xParam11, xParam12, xParam13, xParam14, xParam15)
							cMsgError := ""
						else
							cMsgError := "RPC: Função "+cFunction+" nao compilada no ambiente destino."
						endif

					Else
						cMsgError := 'RPC: Conexão com o Servidor PDV Falhou!'
						FreeObj(oRpcSrv)
					Endif
				EndIf
			EndIf
		EndIf
	Endif

	if !empty(cMsgError)
		MsgAlert(cMsgError, "Aviso!")
	endif

	if ValType(xRet) == "L"
		lRet := xRet
	else
		cMsgError := "Falha na execução da funcionalidade no host Central PDV."
	endif

Return lRet

//--------------------------------------------------------------------------------------
// Função que fecha conexão RPC
//--------------------------------------------------------------------------------------
Static Function DoRpcClose()
	if oRpcSrv != Nil
		oRpcSrv:CallProc( 'RpcClearEnv' )
		oRpcSrv:CallProc( 'DbCloseAll' )
		oRpcSrv:Disconnect()
		FreeObj(oRpcSrv)
	endif
Return

#INCLUDE 'PROTHEUS.CH'
#INCLUDE "topconn.ch"
#INCLUDE "TbiConn.ch"

/*/{Protheus.doc} TRETE006
Função que faz a leitura dos encerrantes dos bicos na concentradora.

@author Totvs GO
@since 11/10/2018
@version 1.0
@return ${return}, ${return_description}

@type function
/*/
User Function TRETE006()

Private cPerg 		:= "TRETE006"
Private lPerguntaOK	:= .F.
Private	cConcDe		:= ""
Private	cConcAte	:= ""
Private	cBicoDe		:= ""
Private	cBicoAte	:= ""

// mostra a tela de perguntas
CriaPerguntas()

// se o usuário não tiver cancelado a operação
If lPerguntaOK

	//barra de processamento
	Processa({|| RunProc()},"Aguarde...","Comunicando com a concentradora...",.T.)

EndIf

Return()

/*/{Protheus.doc} RunProc
Função que faz o processamento.

@author pablo
@since 11/10/2018
@version 1.0
@return ${return}, ${return_description}

@type function
/*/
Static Function RunProc()

Local aButtons	:= {}
Local aObjects 	:= {}
Local aSizeAut	:= MsAdvSize()
Private oGridBicos
Private oDlgBicos

//Largura, Altura, Modifica largura, Modifica altura
aAdd( aObjects, { 100,	100, .T., .T. } ) //Browse

aInfo 	:= { aSizeAut[ 1 ], aSizeAut[ 2 ], aSizeAut[ 3 ], aSizeAut[ 4 ], 2, 2 }
aPosObj := MsObjSize( aInfo, aObjects, .T. )

DEFINE MSDIALOG oDlgBicos TITLE "Leitura de Encerrantes" From aSizeAut[7],0 TO aSizeAut[6],aSizeAut[5] COLORS 0, 16777215 PIXEL

EnchoiceBar(oDlgBicos, {|| oDlgBicos:End()},{|| oDlgBicos:End()},,aButtons)

// crio o grid de bicos
oGridBicos := MsGridBicos()

// caso não tenha encontrato bicos
If !RefreshGrid()

	Alert("Não foram encontrados dados para este filtro!")
	oDlgBicos:End()

EndIf

ACTIVATE MSDIALOG oDlgBicos CENTERED

Return()

/*/{Protheus.doc} MsGridBicos
Função que cria a MsNewGetDados dos bicos.

@author pablo
@since 11/10/2018
@version 1.0
@return ${return}, ${return_description}

@type function
/*/
Static Function MsGridBicos()

Local nX
Local aHeaderEx 	:= {}
Local aColsEx 		:= {}
Local aFieldFill 	:= {}
Local aFields 		:= {"MIC_CODBIC","MIC_NLOGIC","MIC_LADO","MHZ_CODPRO","MHZ_DESPRO","ENCVL","ENCLT"}
Local aAlterFields 	:= {}

// Define field properties
For nX := 1 to Len(aFields)

	if aFields[nX] == "ENCVL"
		Aadd(aHeaderEx, {"Valor","ENCVL","@E 999,999,999.99",11,2,"","€€€€€€€€€€€€€€","C","","","",""})
	elseif aFields[nX] == "ENCLT"
		Aadd(aHeaderEx, {"Litros","ENCLT","@E 999,999,999.99",11,2,"","€€€€€€€€€€€€€€","C","","","",""})
	elseIf !empty(GetSx3Cache(aFields[nX],"X3_CAMPO"))
		aadd(aHeaderEx, U_UAHEADER(aFields[nX]) )
	endif

Next nX

// Define field values
For nX := 1 to Len(aFields)

	if aFields[nX] == "ENCVL"
		Aadd(aFieldFill, 0)
	elseif aFields[nX] == "ENCLT"
		Aadd(aFieldFill, 0)
	elseIf !empty(GetSx3Cache(aFields[nX],"X3_CAMPO"))
		Aadd(aFieldFill, CriaVar(aFields[nX]))
	endif

Next nX

Aadd(aFieldFill, .F.)
Aadd(aColsEx, aFieldFill)

Return(MsNewGetDados():New( aPosObj[1,1], aPosObj[1,2], aPosObj[1,3], aPosObj[1,4], GD_UPDATE, "AllwaysTrue", "AllwaysTrue", "+Field1+Field2", aAlterFields,, 999, "AllwaysTrue", "", "AllwaysTrue", oDlgBicos, aHeaderEx, aColsEx))


/*/{Protheus.doc} RefreshGrid
Função que atualiza o Grid dos bicos.

@author pablo
@since 11/10/2018
@version 1.0
@return ${return}, ${return_description}

@type function
/*/
Static Function RefreshGrid()

Local aFieldFill 	:= {}
Local nQuantItens	:= 0
Local lRet			:= .T.
Local aArea			:= GetArea()
Local cIdEncerrante	:= "7"
Local cCondicao		:= ""
Local nENCVL		:= 0
Local nENCLT		:= 0
Local bCondicao

oGridBicos:Acols := {}

cCondicao := " MIC->MIC_FILIAL = '" + xFilial("MIC") + "'"
//cCondicao += " .AND. MIC->MIC_STATUS <> '2' "
cCondicao += " .AND. ((MIC->MIC_STATUS = '1' .AND. MIC->MIC_XDTATI <= dDataBase) .OR. (MIC->MIC_STATUS = '2' .AND. MIC->MIC_XDTDES >= dDataBase)) "
cCondicao += " .AND. ( MIC->MIC_CODBIC >= '" + cBicoDe + "' .AND. MIC->MIC_CODBIC <= '" + cBicoAte + "' ) "
cCondicao += " .AND. ( MIC->MIC_XCONCE >= '" + cConcDe + "' .AND. MIC->MIC_XCONCE <= '" + cConcAte + "' ) "

// limpo os filtros da MIC
MIC->(DbClearFilter())

// executo o filtro na MIC
bCondicao 	:= "{|| " + cCondicao + " }"
MIC->(DbSetFilter(&bCondicao,cCondicao))

// vou para a primeira linha
MIC->(DbGoTop())

// verifico quantos itens foram filtrados
MIC->(DbEval({|| nQuantItens++}))

If nQuantItens > 0

	ProcRegua(nQuantItens)

	MHZ->(DbSetOrder(1)) //MHZ_FILIAL+MHZ_CODTAN

	MIC->(DbSetOrder(3)) //MIC_FILIAL+MIC_CODBIC+MIC_CODTAN
	MIC->(DbGoTop())
	While MIC->(!Eof())

		IncProc("Concentradora - " + AllTrim(MIC->MIC_XCONCE) + " / Bico - " + AllTrim(MIC->MIC_CODBIC) )

		// posiciono na tabela de concentradoras
		MHX->(DbSetOrder(1)) //MHX_FILIAL+MHX_CODCON
		if MHX->(DbSeek(xFilial("MHX") + MIC->MIC_XCONCE))

			cNLogic	:= MIC->MIC_NLOGIC
			cLado	:= MIC->MIC_LADO

			// envio o comando para integração com a concentradora
			nENCVL 	:= U_TRETE001(MHX->MHX_CODCON,cIdEncerrante,{cNLogic,cLado,"$"})
			nENCLT 	:= U_TRETE001(MHX->MHX_CODCON,cIdEncerrante,{cNLogic,cLado,"L"})

			aFieldFill := {}
			
			MHZ->(DbSeek(xFilial("MHZ") + MIC->MIC_CODTAN ))

			aadd(aFieldFill, MIC->MIC_CODBIC)
			aadd(aFieldFill, MIC->MIC_NLOGIC)
			aadd(aFieldFill, MIC->MIC_LADO)
			aadd(aFieldFill, MHZ->MHZ_CODPRO)
			aadd(aFieldFill, MHZ->MHZ_DESPRO)
			aadd(aFieldFill, nENCVL)
			aadd(aFieldFill, nENCLT)
			Aadd(aFieldFill, .F.)
			aadd(oGridBicos:Acols,aFieldFill)

		EndIf

		MIC->(DbSkip())
	EndDo

	// limpo os filtros da MIC
	MIC->(DbClearFilter())

	RestArea(aArea)
	oGridBicos:oBrowse:Refresh()

Else
	lRet := .F.
EndIf

Return(lRet)


/*/{Protheus.doc} CriaPerguntas
Função que mostra tela de perguntas.

@author pablo
@since 11/10/2018
@version 1.0
@return ${return}, ${return_description}

@type function
/*/
Static Function CriaPerguntas()

	// cria as perguntas na SX1
	AjustaSx1()

	If Pergunte(cPerg,.T.) //Chama a tela de parametros

		lPerguntaOK := .T.
		cConcDe		:= MV_PAR01
		cConcAte	:= MV_PAR02
		cBicoDe		:= MV_PAR03
		cBicoAte	:= MV_PAR04

	Else
		lPerguntaOK 	:= .F.
	EndIf

Return()

/*/{Protheus.doc} AjustaSX1
Funcao que cria as perguntas na SX1.

@author pablo
@since 11/10/2018
@version 1.0
@return ${return}, ${return_description}

@type function
/*/
Static Function AjustaSX1()  // cria a tela de perguntas do relatório

Local aHelpPor	:= {}
Local aHelpEng	:= {}
Local aHelpSpa	:= {}

	///////////// Concentradora ////////////////

	U_uAjusSx1( cPerg, "01","Concentradora De?","Concentradora De?","Concentradora De?","cConcDe","C",3,0,0,"G","","MHX","","",;
	"MV_PAR01","","","","","","","","","","","","","","","","",aHelpPor,aHelpEng,aHelpSpa)

	U_uAjusSx1( cPerg, "02","Concentradora Ate?","Concentradora Ate?","Concentradora Ate?","cConcAte","C",3,0,0,"G","","MHX","","",;
	"MV_PAR02","","","","","","","","","","","","","","","","",aHelpPor,aHelpEng,aHelpSpa)

	///////////// Bico ////////////////

	U_uAjusSx1( cPerg, "03","Bico De?","Bico De?","Bico De?","cBicoDe","C",3,0,0,"G","","MIC","","",;
	"MV_PAR03","","","","","","","","","","","","","","","","",aHelpPor,aHelpEng,aHelpSpa)

	U_uAjusSx1( cPerg, "04","Bico Ate?","Bico Ate?","Bico Ate?","cBicoAte","C",3,0,0,"G","","MIC","","",;
	"MV_PAR04","","","","","","","","","","","","","","","","",aHelpPor,aHelpEng,aHelpSpa)

Return

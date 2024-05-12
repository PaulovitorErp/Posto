#include 'totvs.ch'

STATIC cU56_FILAUT := Space(TAMSX3("U56_FILAUT")[1])

/*/{Protheus.doc} TRETE021
Consulta Específica de Filial (para requisição)
SXB: U56FIL

@author thebr
@since 02/05/2019
@version 1.0
@return Nil
@type function
/*/
User Function TRETE021()

	Local nI
	Local aAreaSM0 		:= SM0->(GetArea())
	Local aInf			:= {}
	Local aDados		:= {}
	Local aCampos		:= {{"OK","C",002,0},{"COL1","C",12,0},{"COL2","C",15,0}}
	Local aCampos2		:= {{"OK","","",""},{"COL1","","Código",""},{"COL2","","Descrição",""}}
	Local nPosIt		:= 0
	Local cDBExt 		:= ".dbf"

	Private cArqTrab	:= CriaTrab(aCampos) // Criando arquivo temporario
	Private oTempTable as object
	Private oDlg
	Private oMark
	Private cMarca	 	:= "mk"
	Private lImpFechar	:= .F.
	Private oSay1, oSay2, oSay3, oSay4
	Private oTexto
	Private cTexto		:= Space(40)
	Private nCont		:= 0
	Private cInf 		:= ""
	Private cReadVar := ReadVar()

	If "U56_FILAUT" $ cReadVar // Alltrim(ReadVar()) == cReadVar

		aInf := IIF(!Empty(&(cReadVar)),StrTokArr(AllTrim(&(cReadVar)),"/"),{})
		cInf := &(cReadVar)

		dbSelectArea("SM0")
		SM0->(dbGoTop())

		While SM0->(!EOF())
			If AllTrim(SM0->M0_CODIGO) == AllTrim(cEmpAnt)
				aAdd(aDados,{SM0->M0_CODFIL,SM0->M0_FILIAL})
			Endif

			SM0->(dbSkip())
		EndDo

		RestArea(aAreaSM0)

		//Retorna a extensão em uso para as tabelas acessadas através do driver ou RDD "DBFCDX"
		cDBExt := GetSrvProfString( "LocalDBExtension", ".dbf" ) //GetDBExtension()
		cDBExt := Lower( cDBExt )

		If cDBExt = '.dbf' .or. cDBExt = '.dtc' //dicionário não é DBF ou CTREE
			//cria a tabela temporaria: arquivo
			DBUseArea(.T.,,cArqTrab,"TRBAUX",If(.F. .OR. .F., !.F., NIL), .F.)  // Criando Alias para o arquivo temporario
		Else
			//cria a tabela temporaria: no banco de dados relacional da base do sistema
			oTempTable := FWTemporaryTable():New("TRBAUX")
			oTempTable:SetFields(aCampos)
			oTempTable:Create()
		EndIf

		DbSelectArea("TRBAUX")

		If Len(aDados) > 0
			For nI := 1 to Len(aDados)
				TRBAUX->(RecLock("TRBAUX",.T.))
				If Len(aInf) > 0
					nPosIt := aScan(aInf,{|x| AllTrim(x) == AllTrim(aDados[nI][1])})
					If nPosIt > 0
						TRBAUX->OK := "mk"
						nCont++
					Else
						TRBAUX->OK := "  "
					Endif
				Else
					TRBAUX->OK := "  "
				Endif
				TRBAUX->COL1 := aDados[nI][1]
				TRBAUX->COL2 := aDados[nI][2]
				TRBAUX->(MsUnlock())
			Next
		Else
			TRBAUX->(RecLock("TRBAUX",.T.))
			TRBAUX->OK		:= "  "
			TRBAUX->COL1	:= Space(6)
			TRBAUX->COL2 	:= Space(40)
			TRBAUX->(MsUnlock())
		Endif

		TRBAUX->(DbGoTop())

		DEFINE MSDIALOG oDlg TITLE "Seleção de Dados - Filiais" From 000,000 TO 450,700 COLORS 0, 16777215 PIXEL

		@ 005, 005 SAY oSay1 PROMPT "Descrição:" SIZE 060, 007 OF oDlg COLORS 0, 16777215 PIXEL
		@ 004, 050 MSGET oTexto VAR cTexto SIZE 200, 010 OF oDlg COLORS 0, 16777215 PIXEL Picture "@!"
		@ 005, 272 BUTTON oButton1 PROMPT "Localizar" SIZE 040, 010 OF oDlg ACTION Localiza(cTexto) PIXEL

		//Browse
		oMark := MsSelect():New("TRBAUX","OK","",aCampos2,,@cMarca,{020,005,190,348})
		oMark:bMark 				:= {|| xMarcaIt()}
		oMark:oBrowse:LCANALLMARK 	:= .T.
		oMark:oBrowse:LHASMARK    	:= .T.
		oMark:oBrowse:bAllMark 		:= {|| xMarcaT()}

		@ 193, 005 SAY oSay2 PROMPT "Total de registros selecionados:" SIZE 200, 007 OF oDlg COLORS 0, 16777215 PIXEL
		@ 193, 090 SAY oSay3 PROMPT cValToChar(nCont) SIZE 040, 007 OF oDlg COLORS 0, 16777215 PIXEL

		//Linha horizontal
		@ 203, 005 SAY oSay4 PROMPT Repl("_",342) SIZE 342, 007 OF oDlg COLORS CLR_GRAY, 16777215 PIXEL

		@ 213, 272 BUTTON oButton2 PROMPT "Confirmar" SIZE 040, 010 OF oDlg ACTION CXFilAut() PIXEL
		@ 213, 317 BUTTON oButton3 PROMPT "Fechar" SIZE 030, 010 OF oDlg ACTION FXFilAut() PIXEL

		ACTIVATE MSDIALOG oDlg CENTERED VALID lImpFechar //impede o usuario fechar a janela atraves do [X]

	Endif

Return .T.

//-------------------------------------------------------------------
/*/{Protheus.doc} CXFilAut
Acao do botao Confirmar da funcao XFilAut
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
Static Function CXFilAut()

	Local lAux 	:= .F.
	Local nAux	:= 0

	TRBAUX->(dbGoTop())

	While TRBAUX->(!EOF())
		If TRBAUX->OK == "mk"
			If !lAux
				&(cReadVar) := AllTrim(TRBAUX->COL1)
				lAux := .T.
			Else
				&(cReadVar) += "/" + AllTrim(TRBAUX->COL1)
			Endif
			nAux += Len(TRBAUX->COL1)
		EndIf

		TRBAUX->(dbSkip())
	EndDo

	FXFilAut()

	cU56_FILAUT := &(cReadVar)

Return

//-------------------------------------------------------------------
/*/{Protheus.doc} FXFilAut
Acao do botao Fechar da funcao XFilAut
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
Static Function FXFilAut()

	lImpFechar := .T.

	If Select("TRBAUX") > 0
		TRBAUX->(DbCloseArea())
	Endif

	//Retorna a extensão em uso para as tabelas acessadas através do driver ou RDD "DBFCDX"
	cDBExt := GetSrvProfString( "LocalDBExtension", ".dbf" ) //GetDBExtension()
	cDBExt := Lower( cDBExt )

	If cDBExt = '.dbf' .or. cDBExt = '.dtc' //dicionário não é DBF ou CTREE
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Apagando arquivo temporario                                         ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		FErase(cArqTrab + GetDBExtension())
		FErase(cArqTrab + OrdBagExt())
	Else
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Apagando arquivo temporario no banco de dados                       ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		oTempTable:Delete()
	EndIf

	oDlg:End()

Return

//-------------------------------------------------------------------
/*/{Protheus.doc} xMarcaIt
Acao ao selecionar item
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
Static Function xMarcaIt()

	If TRBAUX->OK == "mk"
		nCont++
	Else
		--nCont
	Endif

	oSay3:Refresh()

Return

//-------------------------------------------------------------------
/*/{Protheus.doc} xMarcaT
Acao ao selecionar tudo
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
Static Function xMarcaT()

	Local lMarca 	:= .F.
	Local lNMARCA 	:= .F.

	nCont := 0

	TRBAUX->(dbGoTop())

	While TRBAUX->(!EOF())
		If TRBAUX->OK == "mk" .And. !lMarca
			RecLock("TRBAUX",.F.)
			TRBAUX->OK := "  "
			TRBAUX->(MsUnlock())
			lNMarca := .T.
		Else
			If !lNMarca
				RecLock("TRBAUX",.F.)
				TRBAUX->OK := "mk"
				TRBAUX->(MsUnlock())
				nCont++
				lMarca := .T.
			Endif
		Endif

		TRBAUX->(dbSkip())
	EndDo

	TRBAUX->(dbGoTop())

	oSay3:Refresh()

Return

//-------------------------------------------------------------------
/*/{Protheus.doc} Localiza
Acao ao selecionar Localizar
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
Static Function Localiza(_cTexto)

	If !Empty(_cTexto)
		TRBAUX->(dbSkip())

		While TRBAUX->(!EOF())
			If AllTrim(_cTexto) $ TRBAUX->COL2
				Exit
			Endif

			TRBAUX->(dbSkip())
		EndDo
	Else
		TRBAUX->(dbGoTop())
	Endif

Return

/*/{Protheus.doc} TRETE21A
Retorno da consulta padrão

@author thebr
@since 02/05/2019
@version 1.0
@return Nil
@type function
/*/
User Function TRETE21A()
Return cU56_FILAUT

/*/{Protheus.doc} TRETE21B
Validação do campo U56_FILAUT

@author thebr
@since 02/05/2019
@version 1.0
@return lRet
@type function
/*/
User Function TRETE21B()

	Local lRet := .T.
	Local aFilAut
	Local nX

	If Alltrim(ReadVar()) == "M->U56_FILAUT"
		aFilAut  := IIF(!Empty(M->U56_FILAUT),StrTokArr(AllTrim(M->U56_FILAUT),"/"),{})

		aAreaSM0 := SM0->(GetArea())
		dbSelectArea("SM0")
		For nX:=1 to len(aFilAut)
			If !SM0->(DbSeek(cEmpAnt+aFilAut[nX]))
				MsgStop("Digite os valores de filiais autorizadas com dados válidos! Ex.: 0101/0102/0201","Atenção")
				lRet := .F.
				Exit
			EndIf
		Next nX
		RestArea(aAreaSM0)

	EndIf

Return lRet

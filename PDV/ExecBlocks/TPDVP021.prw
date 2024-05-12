#include 'totvs.ch'

/*/{Protheus.doc} TPDVP021
(StwFsQuery) Manipular a seleção do abastecimento de acordo com uma regra especifica do cliente

@author Totvs GO
@since 05/09/2019
@version 1.0
@return xRet - nova query
@type function
/*/
User Function TPDVP021()

	Local cNewQuery
	//Local cId := ParamIxb[01] //Se usuario solicitou visualizar todos abastecimentos via * (filtro na pesquisa)
	//Local cNrPDV := ParamIxb[02] //Codigo do PDV solicitado como filtro na pesquisa
	//Local cBico := ParamIxb[03] //Codigo do Bico solicitado como filtro na pesquisa
	Local aQuery := ParamIxb[04] //array contendo montagem da query  {cFields,cFrom,cWhere,cOrderBy}
	Local cCodPDV := ParamIxb[05] //Codigo do PDV solicitante (LG_CODIGO)
	//Local lSQLite := AllTrim(Upper(GetSrvProfString("RpoDb",""))) == "SQLITE" //PDVM/Fat Client

	Local nPos := 0

	Local lMvPosto := SuperGetMv("MV_XPOSTO",.F.,.F.) //Habilita Posto de Combustível (Posto Inteligente).
	//Caso o Posto Inteligente não esteja habilitado não faz nada...
	If !lMvPosto
		Return aQuery
	EndIf
	
	//conout("")
	//conout(">> StwFsQuery - Codigo do PDV solicitante (LG_CODIGO) - cCodPDV: " + cCodPDV)
	//conout("cQry - ")
	//conout(cQry)
	//conout("")

	LjGrvLog( "PE StwFsQuery", "Query de consulta de abastecimentos (ANTES)[4]: ", ParamIxb)  //Gera LOG

	If !Empty(cCodPDV) //filtra somente os bicos liberados para a estação

		cNewQuery := " AND EXISTS ( "
		cNewQuery += " SELECT 1 "
		cNewQuery += " FROM " + RetSQLName("MIC") + " MIC "
		cNewQuery += " WHERE MIC.D_E_L_E_T_ = ' ' ""
		cNewQuery += " AND MIC.MIC_FILIAL = '"+xFilial("MIC")+"'"
		cNewQuery += " AND (MIC.MIC_XHOST = '"+space(TamSX3("MIC_XHOST")[1])+"' OR MIC.MIC_XHOST LIKE '%"+cCodPDV+"%')"
		cNewQuery += " AND MIC.MIC_CODBIC = MID_CODBIC "
		cNewQuery += " ) "

		nPos := rat("%",aQuery[3])
		aQuery[3] := substr(aQuery[3],1,nPos-1) + cNewQuery + "%"

		LjGrvLog( "PE StwFsQuery", "Query de consulta de abastecimentos (DEPOIS): ", aQuery)  //Gera LOG

	EndIf

Return aQuery

//-------------------------------------------------------------------
/*/{Protheus.doc} TPDVP21A
Valida os códigos das estações, inseridos no campo MIC_XHOST - "PDVs Liber."
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
User Function TPDVP21A(cString)

	Local lRet		 := .T.
	Local nTamCodSLG := TamSX3("LG_CODIGO")[1] //retorna o tamanho do campo codigo estação (LG_CODIGO)

	While !Empty(cString)

		If Len(AllTrim(cString)) > nTamCodSLG .And. SubStr(cString,nTamCodSLG+1,1)  <> '/'
			Alert("Os códigos das estações devem ser separados pelo caracter '/'...")
			lRet := .F.
		ElseIf !ExistCpo("SLG",SubStr(cString,1,nTamCodSLG))
			Alert("O código '"+SubStr(cString,1,nTamCodSLG)+"' não corresponde a uma estação válida.")
			lRet := .F.
		Else
			lRet := .T.
		EndIf

		cString := SubStr(cString,nTamCodSLG+2,Len(cString))

	EndDo

Return (lRet)

/*/{Protheus.doc} TPDVP21B
Tela de seleção de estações que o registro será bloqueado.

@author Totvs GO
@since 05/09/2019
@version 1.0

@return ${return}, ${return_description}

@type function
@obs Programa chamado pelo click no campo
/*/
User Function TPDVP21B()

	Local aInf			:= {}
	Local aDados		:= {}

	Local aCampos		:= {{"OK","C",002,0},{"COL1","C",012,0},{"COL2","C",015,0},{"COL3","C",012,0},{"COL4","C",012,0}}
	Local aCampos2		:= {{"OK","","",""},{"COL1","","Estação",""},{"COL2","","Nome",""},{"COL3","","Nr. PDV",""},{"COL4","","Série",""}}

	Local nPosIt		:= 0
	Local nI

	Private cRet		:= ""
	Private oTempTable as object

	Private oMark
	Private cMarca	 	:= "mk"
	Private lImpFechar	:= .F.

	Private oSay1, oSay2, oSay3, oSay4
	Private oTexto
	Private cTexto		:= Space(TamSX3("LG_NOME")[1])
	Private nContSel	:= 0

	Private cBkpInf 	:= ""

	Private oDlgEstacao

	Private aBlqFil		:= {}

	If Alltrim(ReadVar()) == "M->MIC_XHOST"

		aInf := IIF(!Empty(M->MIC_XHOST),StrTokArr(AllTrim(M->MIC_XHOST),"/"),{})
		cBkpInf := M->MIC_XHOST

		dbSelectArea("SLG")
		SLG->(dbSetOrder(1)) //LG_FILIAL+LG_CODIGO
		SLG->(dbGoTop())
		SLG->(dbSeek(xFilial("SLG")))

		While SLG->(!EOF()) .and. SLG->LG_FILIAL = xFilial("SLG")
			aAdd(aDados,{LG_CODIGO,LG_NOME,LG_PDV,LG_SERIE})
			SLG->(dbSkip())
		EndDo

		//cria a tabela temporaria
		oTempTable := FWTemporaryTable():New("TRBAUX")
		oTempTable:SetFields(aCampos)
		oTempTable:Create()

		DbSelectArea("TRBAUX")

		If Len(aDados) > 0
			For nI := 1 to Len(aDados)
				TRBAUX->(RecLock("TRBAUX",.T.))
				If Len(aInf) > 0
					nPosIt := aScan(aInf,{|x| AllTrim(x) == AllTrim(aDados[nI][1])})
					If nPosIt > 0
						TRBAUX->OK := "mk"
						nContSel++
					Else
						TRBAUX->OK := "  "
					Endif
				Else
					TRBAUX->OK := "  "
				Endif
				TRBAUX->COL1 := aDados[nI][1]
				TRBAUX->COL2 := aDados[nI][2]
				TRBAUX->COL3 := aDados[nI][3]
				TRBAUX->COL4 := aDados[nI][4]
				TRBAUX->(MsUnlock())
			Next
		Else
			TRBAUX->(RecLock("TRBAUX",.T.))
			TRBAUX->OK		:= "  "
			TRBAUX->COL1	:= Space(TamSX3("LG_CODIGO")[1])
			TRBAUX->COL2 	:= Space(TamSX3("LG_NOME")[1])
			TRBAUX->COL3 	:= Space(TamSX3("LG_PDV")[1])
			TRBAUX->COL4 	:= Space(TamSX3("LG_SERIE")[1])
			TRBAUX->(MsUnlock())
		Endif

		TRBAUX->(DbGoTop())

		DEFINE MSDIALOG oDlgEstacao TITLE "Seleção de Dados - Estações" From 000,000 TO 450,700 COLORS 0, 16777215 PIXEL

		@ 005, 005 SAY oSay1 PROMPT "Descrição:" SIZE 060, 007 OF oDlgEstacao COLORS 0, 16777215 PIXEL
		@ 004, 050 MSGET oTexto VAR cTexto SIZE 200, 010 OF oDlgEstacao COLORS 0, 16777215 PIXEL Picture "@!"
		@ 005, 272 BUTTON oButton1 PROMPT "Localizar" SIZE 040, 010 OF oDlgEstacao ACTION FindText(cTexto) PIXEL

		//Browse
		oMark := MsSelect():New("TRBAUX","OK","",aCampos2,,@cMarca,{020,005,190,348})
		oMark:bMark 				:= {|| MarcaIt("TRBAUX",@nContSel,@oSay3)}
		oMark:oBrowse:LCANALLMARK 	:= .T.
		oMark:oBrowse:LHASMARK    	:= .T.
		oMark:oBrowse:bAllMark 		:= {|| MarcaT("TRBAUX",@nContSel,@oSay3)}

		@ 193, 005 SAY oSay2 PROMPT "Total de registros selecionados:" SIZE 200, 007 OF oDlgEstacao COLORS 0, 16777215 PIXEL
		@ 193, 090 SAY oSay3 PROMPT cValToChar(nContSel) SIZE 040, 007 OF oDlgEstacao COLORS 0, 16777215 PIXEL

		//Linha horizontal
		@ 203, 005 SAY oSay4 PROMPT Repl("_",342) SIZE 342, 007 OF oDlgEstacao COLORS CLR_GRAY, 16777215 PIXEL

		@ 213, 272 BUTTON oButton2 PROMPT "Confirmar" SIZE 040, 010 OF oDlgEstacao ACTION Conf002() PIXEL
		@ 213, 317 BUTTON oButton3 PROMPT "Fechar" SIZE 030, 010 OF oDlgEstacao ACTION Fech002() PIXEL

		ACTIVATE MSDIALOG oDlgEstacao CENTERED VALID lImpFechar //impede o usuario fechar a janela atraves do [X]

	Endif

Return .T.

//-------------------------------------------------------------------
/*/{Protheus.doc} FindText
Localiza estação...
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
Static Function FindText(_cTexto)

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

//-------------------------------------------------------------------
/*/{Protheus.doc} Conf002
Confirma a seleção
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
Static Function Conf002()

	Local lAux 	:= .F.
	Local nAux	:= 0

	TRBAUX->(dbGoTop())

	If Empty(ReadVar())
		__READVAR := "M->MIC_XHOST"
	EndIf

	M->MIC_XHOST := PadR("",TamSx3("MIC_XHOST")[1])

	While TRBAUX->(!EOF())
		If TRBAUX->OK == "mk"
			If !lAux
				M->MIC_XHOST := AllTrim(TRBAUX->COL1)
				lAux := .T.
			Else
				M->MIC_XHOST += "/" + AllTrim(TRBAUX->COL1)
			Endif
			nAux += Len(TRBAUX->COL1)
		Endif

		TRBAUX->(dbSkip())
	EndDo

	M->MIC_XHOST := PadR(M->MIC_XHOST,TamSx3("MIC_XHOST")[1])

	Fech002()

Return

//-------------------------------------------------------------------
/*/{Protheus.doc} Fech002
Fecha a tela de seleção
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
Static Function Fech002()

	lImpFechar := .T.

	If Select("TRBAUX") > 0
		TRBAUX->(DbCloseArea())
	Endif

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Apagando arquivo temporario                                         ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	oTempTable:Delete()

	oDlgEstacao:End()

Return

//-------------------------------------------------------------------
/*/{Protheus.doc} MarcaIt
SubFunção da U_TPDVP21B - MarcaIt
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
Static Function MarcaIt(cTabAux,nContSel,oSay3)

	If (cTabAux)->OK == "mk"
		nContSel++
	Else
		--nContSel
	Endif

	oSay3:Refresh()

Return

//-------------------------------------------------------------------
/*/{Protheus.doc} MarcaT
SubFunção da U_TPDVP21B - MarcaT
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
Static Function MarcaT(cTabAux,nContSel,oSay3)

	Local lMarca 	:= .F.
	Local lNMARCA 	:= .F.

	nContSel := 0

	(cTabAux)->(dbGoTop())

	While (cTabAux)->(!EOF())

		If (cTabAux)->OK == "mk" .And. !lMarca
			RecLock(cTabAux,.F.)
			(cTabAux)->OK := "  "
			(cTabAux)->(MsUnlock())
			lNMarca := .T.
		Else
			If !lNMarca
				RecLock(cTabAux,.F.)
				(cTabAux)->OK := "mk"
				(cTabAux)->(MsUnlock())
				nContSel++
				lMarca := .T.
			Endif
		Endif
		(cTabAux)->(dbSkip())
	EndDo

	(cTabAux)->(dbGoTop())

	oSay3:Refresh()

Return

//Função para validar se os abastecimentos do bico podem aparecer no PDV
User Function TPDVP21C(cBico, cCodPDV)

	Local lRet := .F.
	Local cHost := Posicione("MIC",1,xFilial("MIC")+cBico, "MIC_XHOST") //MIC_FILIAL+MIC_CODBIC+MIC_CODBOM

	if empty(cHost) .OR. cCodPDV $ cHost
		lRet := .T.
	endif

Return lRet

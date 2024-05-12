#include "protheus.ch"
#include "topconn.ch"
#include "fwmvcdef.ch"

/*/{Protheus.doc} TRETA006
Cadastro Estoque Exposição
@author TOTVS TBC
@since 02/05/2014
@version 1.0
@param Nao recebe parametros
@return nulo
/*/
User Function TRETA006()

	Local oBrowse

	Private aRotina 	:= {}

	Public __cLocOri	:= ""

	oBrowse := FWmBrowse():New()
	oBrowse:SetAlias("U59")
	oBrowse:SetDescription("Estoque de Exposição")
	oBrowse:Activate()

Return Nil

//-------------------------------------------------------------------
/*/{Protheus.doc} MenuDef
description
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
Static Function MenuDef()

	aRotina 	:= {}

	ADD OPTION aRotina Title 'Visualizar' 			Action "VIEWDEF.TRETA006"	OPERATION 2 ACCESS 0
	ADD OPTION aRotina Title "Incluir"    			Action "VIEWDEF.TRETA006"	OPERATION 3 ACCESS 0
	ADD OPTION aRotina Title "Alterar"    			Action "VIEWDEF.TRETA006"	OPERATION 4 ACCESS 0
	ADD OPTION aRotina Title "Excluir"    			Action "VIEWDEF.TRETA006"	OPERATION 5 ACCESS 0
	ADD OPTION aRotina Title "Otimizar Prateleira"  Action "U_OTIPRAT()"		OPERATION 4 ACCESS 0
	ADD OPTION aRotina Title "Armazem Estacoes"  	Action "U_ESTEXPES()"		OPERATION 4 ACCESS 0

Return aRotina

//-------------------------------------------------------------------
/*/{Protheus.doc} ModelDef
description
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
Static Function ModelDef()

// Cria a estrutura a ser usada no Modelo de Dados
	Local oStruU59 := FWFormStruct(1,"U59",/*bAvalCampo*/,/*lViewUsado*/ )

	Local oModel

// Cria o objeto do Modelo de Dados
	oModel := MPFormModel():New("TRETM006",/*bPreValidacao*/,/*bPosValidacao*/,/*bCommit*/,/*bCancel*/ )

// Adiciona ao modelo uma estrutura de formulário de edição por campo
	oModel:AddFields("U59MASTER",/*cOwner*/,oStruU59)

// Adiciona a chave primaria da tabela principal
	oModel:SetPrimaryKey({"U59_FILIAL","U59_CODIGO"})

// Adiciona função modo edição para o campo
//oStruU59:SetProperty("U59_LOCORI",MODEL_FIELD_WHEN,{|| U_U59LOC()})

// Adiciona a descricao do Componente do Modelo de Dados
	oModel:GetModel("U59MASTER"):SetDescription("Estoque de Exposição")

Return oModel

//-------------------------------------------------------------------
/*/{Protheus.doc} ViewDef
description
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
Static Function ViewDef()

// Cria a estrutura a ser usada na View
	Local oStruU59 := FWFormStruct(2,"U59")

// Cria um objeto de Modelo de Dados baseado no ModelDef do fonte informado
	Local oModel   := FWLoadModel("TRETA006")
	Local oView

// Cria o objeto de View
	oView := FWFormView():New()

// Define qual o Modelo de dados será utilizado
	oView:SetModel(oModel)

//Adiciona no nosso View um controle do tipo FormFields(antiga enchoice)
	oView:AddField("VIEW_U59",oStruU59,"U59MASTER")

// Criar "box" horizontal para receber algum elemento da view
	oView:CreateHorizontalBox("PAINEL_CABEC", 100)

// Relaciona o ID da View com o "box" para exibicao
	oView:SetOwnerView("VIEW_U59","PAINEL_CABEC")

// Liga a identificacao do componente
	oView:EnableTitleView("VIEW_U59","Estoque de Exposição")

// Define fechamento da tela ao confirmar a operação
	oView:SetCloseOnOk( {||.T.} )

Return oView

//-------------------------------------------------------------------
/*/{Protheus.doc} VldEstExp
description
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
User Function VldEstExp(cLocal,cProd)

	Local lRet 	:= .T.
	Local cQry	:= ""

	If !Empty(cLocal) .And. !Empty(cProd)

		If Select("QRYESTEXP") > 0
			QRYESTEXP->(DbCloseArea())
		Endif

		cQry := "SELECT U59_LOCAL"
		cQry += " FROM "+RetSqlName("U59")+""
		cQry += " WHERE D_E_L_E_T_	<> '*'"
		cQry += " AND U59_FILIAL	= '"+xFilial("U59")+"'"
		cQry += " AND U59_LOCAL 	= '"+cLocal+"'"
		cQry += " AND U59_PRODUT 	= '"+cProd+"'"

		cQry := ChangeQuery(cQry)
		TcQuery cQry NEW Alias "QRYESTEXP"

		If QRYESTEXP->(!EOF())
			Help(,,'Help',,"Há registro cadastrado para o Local "+AllTrim(cLocal)+" e Produto "+AllTrim(cProd)+", favor selecionar outros dados.",1,0)
			lRet := .F.
		Endif

		If Select("QRYESTEXP") > 0
			QRYESTEXP->(DbCloseArea())
		Endif
	Endif

Return lRet

//-------------------------------------------------------------------
/*/{Protheus.doc} VldLocOri
description
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
User Function VldLocOri(cLocaisOri)

	Local lRet 			:= .T.
	Local aArea			:= GetArea()

	Local aInf			:= {}
	Local nI

	Local oModel		:= FWModelActive()
	Local oView			:= FWViewActive()
	Local oModelU59 	:= oModel:GetModel("U59MASTER")
	Local cLocal 		:= oModelU59:GetValue("U59_LOCAL")

	If !Empty(cLocaisOri)

		DbSelectArea("NNR")
		NNR->(DbSetOrder(1)) //NNR_FILIAL+NNR_CODIGO

		If Len(AlLTrim(cLocaisOri)) < 2

			Help(,,'Help',,"A informação deve ter o seguinte formato 01/02/03, ou seja, o código dos locais de origem separados por uma '/'.",1,0)
			lRet :=  .F.

		ElseIf Len(AlLTrim(cLocaisOri)) == 2

			If !NNR->(DbSeek(xFilial("NNR")+cLocaisOri))
				Help(,,'Help',,"O local de origem "+cLocaisOri+" digitado é inválido.",1,0)
				lRet :=  .F.
			ElseIf cLocaisOri == cLocal
				Help(,,'Help',,"O local de origem "+cLocal+" selecionado é inválido, pois este não pode ser igual ao local de exposição.",1,0)
				lRet := .F.
			Endif

		ElseIf Len(AlLTrim(cLocaisOri)) > 2

			aInf := StrTokArr(AllTrim(cLocaisOri),"/")

			For nI := 1 To Len(aInf)

				If !NNR->(DbSeek(xFilial("NNR")+aInf[nI]))
					Help(,,'Help',,"O local de origem "+aInf[nI]+" digitado é inválido.",1,0)
					lRet :=  .F.
					Exit
				ElseIf aInf[nI] == cLocal
					Help(,,'Help',,"O local de origem "+aInf[nI]+" selecionado é inválido, pois este não pode ser igual ao local de exposição.",1,0)
					lRet := .F.
					Exit
				ElseIf Len(aInf[nI]) <> 2
					Help(,,'Help',,"A informação deve ter o seguinte formato 01/02/03, ou seja, o código dos locais de origem separados por uma '/'.",1,0)
					lRet :=  .F.
					Exit
				Endif
			Next nI
		Endif
	Endif

	RestArea(aArea)

Return lRet

//-------------------------------------------------------------------
/*/{Protheus.doc} U59LOC
description
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
User Function U59LOC()

	Local cQry			:= ""
	Local aColunas 		:= StrTokArr("NNR_CODIGO,NNR_DESCRI",",")
	Local aInf			:= {}
	Local aDados		:= {}

	Local aCampos		:= {{"OK","C",002,0},{"COL1","C",TamSX3(aColunas[1])[1],0},{"COL2","C",TamSX3(aColunas[2])[1],0}}
	Local aCampos2		:= {{"OK","","",""},{"COL1","","Código",""},{"COL2","","Descrição",""}}

	Local nPosIt		:= 0
	Local nI
	Local _cAlias		:= "NNR"
	Local _cColOrd		:= "NNR_CODIGO

	Local oModel		:= FWModelActive()
	Local oView			:= FWViewActive()
	Local oModelU59 	:= oModel:GetModel("U59MASTER")
	Local aCpoFoco		:= {}

	Private cRet		:= ""
	Private oTempTable as object

	Private oDlg
	Private oMark
	Private cMarca	 	:= "mk"
	Private lImpFechar	:= .F.

	Private oSay1, oSay2, oSay3, oSay4
	Private oTexto
	Private cTexto		:= Space(40)
	Private nCont		:= 0

	Private oDlg

	__cLocOri := oModelU59:GetValue("U59_LOCORI")
	aInf := IIF(!Empty(__cLocOri),StrTokArr(AllTrim(__cLocOri),"/"),{})

	If Select("QRYAUX") > 0
		QRYAUX->(DbCloseArea())
	Endif

	cQry := "SELECT NNR_CODIGO,NNR_DESCRI"
	cQry += " FROM "+RetSqlName(_cAlias)+""
	cQry += " WHERE D_E_L_E_T_ <> '*'"
	cQry += " AND "+IIF(SubStr(_cAlias,1,1) == "S",SubStr(_cAlias,2,2),_cAlias)+"_FILIAL = '"+xFilial(_cAlias)+"'"
	cQry += " ORDER BY "+_cColOrd+""

	cQry := ChangeQuery(cQry)
	TcQuery cQry NEW Alias "QRYAUX"

	While QRYAUX->(!EOF())

		AAdd(aDados,{&("QRYAUX->"+aColunas[1]),&("QRYAUX->"+aColunas[2])})

		QRYAUX->(dbSkip())
	EndDo

	If Select("QRYAUX") > 0
		QRYAUX->(DbCloseArea())
	Endif

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

	DEFINE MSDIALOG oDlg TITLE "Seleção de Dados - Locais de Origem" From 000,000 TO 450,700 COLORS 0, 16777215 PIXEL

	@ 005, 005 SAY oSay1 PROMPT "Descrição:" SIZE 060, 007 OF oDlg COLORS 0, 16777215 PIXEL
	@ 004, 050 MSGET oTexto VAR cTexto SIZE 200, 010 OF oDlg COLORS 0, 16777215 PIXEL Picture "@!"
	@ 005, 272 BUTTON oButton1 PROMPT "Localizar" SIZE 040, 010 OF oDlg ACTION Localiza(cTexto) PIXEL

//Browse
	oMark := MsSelect():New("TRBAUX","OK","",aCampos2,,@cMarca,{020,005,190,348})
	oMark:bMark 				:= {||MarcaIt()}
	oMark:oBrowse:LCANALLMARK 	:= .T.
	oMark:oBrowse:LHASMARK    	:= .T.
	oMark:oBrowse:bAllMark 		:= {||MarcaT()}

	@ 193, 005 SAY oSay2 PROMPT "Total de registros selecionados:" SIZE 200, 007 OF oDlg COLORS 0, 16777215 PIXEL
	@ 193, 090 SAY oSay3 PROMPT cValToChar(nCont) SIZE 040, 007 OF oDlg COLORS 0, 16777215 PIXEL

//Linha horizontal
	@ 203, 005 SAY oSay4 PROMPT Repl("_",342) SIZE 342, 007 OF oDlg COLORS CLR_GRAY, 16777215 PIXEL

	@ 213, 272 BUTTON oButton2 PROMPT "Confirmar" SIZE 040, 010 OF oDlg ACTION Conf001() PIXEL
	@ 213, 317 BUTTON oButton3 PROMPT "Fechar" SIZE 030, 010 OF oDlg ACTION Fech001() PIXEL

	ACTIVATE MSDIALOG oDlg CENTERED VALID lImpFechar //impede o usuario fechar a janela atraves do [X]

Return .T.

//-------------------------------------------------------------------
/*/{Protheus.doc} Conf001
description
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
Static Function Conf001()

	Local nAux	:= 0
	Local cAux	:= ""

	Local oModel		:= FWModelActive()
	Local oView			:= FWViewActive()
	Local oModelU59 	:= oModel:GetModel("U59MASTER")

	TRBAUX->(dbGoTop())

	While TRBAUX->(!EOF())

		If TRBAUX->OK == "mk"

			If AllTrim(M->U59_LOCAL) == AllTrim(TRBAUX->COL1)
				Help(,,'Help',,"O Local de origem "+AllTrim(TRBAUX->COL1)+" selecionado é inválido, pois este não pode ser igual ao local de exposição.",1,0)
				Return
			Endif

			nAux++
		Endif

		TRBAUX->(dbSkip())
	EndDo

	If nAux > 0

		__cLocOri := ""

		TRBAUX->(dbGoTop())

		While TRBAUX->(!EOF())

			If TRBAUX->OK == "mk"

				If Empty(__cLocOri)
					__cLocOri := AllTrim(TRBAUX->COL1)
				Else
					__cLocOri += "/" + AllTrim(TRBAUX->COL1)
				Endif
			Endif

			TRBAUX->(dbSkip())
		EndDo

		Fech001()
	Else
		Help(,,'Help',,"Nenhum registro selecionado.",1,0)
		TRBAUX->(dbGoTop())
	Endif

Return

//-------------------------------------------------------------------
/*/{Protheus.doc} Fech001
description
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
Static Function Fech001()

	lImpFechar := .T.

	If Select("TRBAUX") > 0
		TRBAUX->(DbCloseArea())
	Endif

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Apagando arquivo temporario                                         ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	oTempTable:Delete()

	oDlg:End()

Return

//-------------------------------------------------------------------
/*/{Protheus.doc} MarcaIt
description
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
Static Function MarcaIt()

	If TRBAUX->OK == "mk"
		nCont++
	Else
		--nCont
	Endif

	oSay3:Refresh()

Return

//-------------------------------------------------------------------
/*/{Protheus.doc} MarcaT
description
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
Static Function MarcaT()

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
description
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

//-------------------------------------------------------------------
/*/{Protheus.doc} OTIPRAT
description
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
User Function OTIPRAT()

	Local cTitulo 	:= "Sugestão para Estoque de Exposição"
	Local aButtons 	:= {}

	Private oSay1, oSay2, oSay3

	Private oGet1
	Private nCont 	:= 0

	Private nAux	:= 0

	Private oDlgSug

	If !ValidPerg()
		Return
	Endif

	cMV_PAR01 := MV_PAR01
	cMV_PAR02 := MV_PAR02
	cMV_PAR03 := MV_PAR03
	cMV_PAR04 := MV_PAR04
	cMV_PAR05 := MV_PAR05
	cMV_PAR06 := MV_PAR06
	dMV_PAR07 := MV_PAR07
	dMV_PAR08 := MV_PAR08
	nMV_PAR09 := MV_PAR09

	aObjects := {}
	aSizeAut := MsAdvSize()

//Largura, Altura, Modifica largura, Modifica altura
	aAdd( aObjects, { 100,	90, .T., .T. } ) //Browse
	aAdd( aObjects, { 100,	10,	 .T., .T. } ) //Rodapé

	aInfo 	:= { aSizeAut[ 1 ], aSizeAut[ 2 ], aSizeAut[ 3 ], aSizeAut[ 4 ], 2, 2 }
	aPosObj := MsObjSize( aInfo, aObjects, .T. )

	DEFINE MSDIALOG oDlgSug TITLE cTitulo From aSizeAut[7],0 TO aSizeAut[6],aSizeAut[5] OF oMainWnd PIXEL

//Browse
	oGet1 := GetDados1()
	oGet1:oBrowse:bHeaderClick := {|oBrw,nCol| IIF(nCol == 1,(CliqueT(),oBrw:SetFocus()),)}
	bSvblDblClick := oGet1:oBrowse:bLDblClick
	oGet1:oBrowse:bLDblClick := {|| IIF(oGet1:oBrowse:nColPos <> 1,GdRstDblClick(@oGet1,@bSvblDblClick),Clique())}

//Contador
	@ aPosObj[2,1], aPosObj[2,2] SAY oSay1 PROMPT "Registros selecionados:" SIZE 80, 007 OF oDlgSug COLORS 0, 16777215 PIXEL
	@ aPosObj[2,1], aPosObj[2,2]+80 SAY oSay2 PROMPT cValToChar(nCont) SIZE 40, 007 OF oDlgSug COLORS 0, 16777215 PIXEL

//Linha horizontal
	@ aPosObj[2,1] + 10, aPosObj[2,2] SAY oSay3 PROMPT Repl("_",aPosObj[1,4]) SIZE aPosObj[1,4], 007 OF oDlgSug COLORS CLR_GRAY, 16777215 PIXEL

	aAdd(aButtons,{"Sugestão",{||U_ParamOti()},"Parâmetros","Parâmetros"})

	MsgRun("Selecionando registros...","Aguarde",{|| BuscaDados()})

	ACTIVATE MSDIALOG oDlgSug ON INIT EnchoiceBar(oDlgSug, {|| Processa({|| ConfAlt()},"Atualizando Estoque de Exposição...")}, {||oDlgSug:End()},,aButtons)

Return

//-------------------------------------------------------------------
/*/{Protheus.doc} GetDados1
description
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
Static Function GetDados1()

	Local nX, nPosAux
	Local aHeaderEx 	:= {}
	Local aColsEx 		:= {}
	Local aFieldFill 	:= {}

	Local aFields 		:= {"OK","B1_COD","B1_DESC","B1_UM","U59_LOCAL","U59_LOCDES","B2_QATU","SLD_FILIAL","GIRO","U59_QUANT","QTD_SUG","ORIGEM"}
	Local aAlterFields 	:= {"U59_LOCAL","QTD_SUG"}

	//Define field properties
	For nX := 1 to Len(aFields)
		If aFields[nX] == "OK" //Checkbox
			Aadd(aHeaderEx, {"","OK","@BMP",2,0,"","€€€€€€€€€€€€€€","C","","","",""})
		ElseIf aFields[nX] == "SLD_FILIAL" //Saldo filial
			Aadd(aHeaderEx, {"Saldo Filial","SLD_FILIAL","@E 99,999,999,999.99",14,2,"","€€€€€€€€€€€€€€","N","","","",""})
		ElseIf aFields[nX] == "GIRO" //Qtd. sugestão
			Aadd(aHeaderEx, {"Média diária de venda","GIRO","@E 99,999,999,999.99",14,2,"","€€€€€€€€€€€€€€","N","","","",""})
		ElseIf aFields[nX] == "QTD_SUG" //Qtd. sugestão
			Aadd(aHeaderEx, {"Qtd. Sugestão","QTD_SUG","@E 99,999,999,999.99",14,2,"","€€€€€€€€€€€€€€","N","","","",""})
		ElseIf aFields[nX] == "ORIGEM" //Origem
			Aadd(aHeaderEx, {"Origem","ORIGEM","@!",40,0,"","€€€€€€€€€€€€€€","C","","","",""})
		ElseIf !empty(GetSx3Cache( aFields[nX]  ,"X3_CAMPO"))
			If aFields[nX] == "B1_COD"
				aadd(aHeaderEx, U_UAHEADER(aFields[nX]) )
				nPosAux := len(aHeaderEx)
				aHeaderEx[nPosAux][1] := "Produto"
			ElseIf aFields[nX] == "B2_QATU"
				aadd(aHeaderEx, U_UAHEADER(aFields[nX]) )
				nPosAux := len(aHeaderEx)
				aHeaderEx[nPosAux][1] := "Saldo Armazém"
			ElseIf aFields[nX] == "U59_QUANT"
				aadd(aHeaderEx, U_UAHEADER(aFields[nX]) )
				nPosAux := len(aHeaderEx)
				aHeaderEx[nPosAux][1] := "Qtd. cadastrada p/ exposição"
			Else
				aadd(aHeaderEx, U_UAHEADER(aFields[nX]) )
			Endif
		Endif
	Next

	For nX := 1 To Len(aFields)
		If !empty(GetSx3Cache( aFields[nX]  ,"X3_CAMPO"))
			aAdd(aFieldFill, CriaVar(aFields[nX]))
		Else
			Do Case
			Case aFields[nX] == "OK"
				Aadd(aFieldFill, "LBNO")

			Case aFields[nX] == "QTD_SUG"
				Aadd(aFieldFill, 0)

			Case aFields[nX] == "ORIGEM"
				Aadd(aFieldFill, Space(40))
			EndCase
		Endif
	Next

	aAdd(aFieldFill, .F.)
	aAdd(aColsEx, aFieldFill)

Return MsNewGetDados():New(aPosObj[1,1],aPosObj[1,2],aPosObj[1,3],aPosObj[1,4],GD_UPDATE,"AllwaysTrue","AllwaysTrue",,aAlterFields,,999,;
		"AllwaysTrue","","AllwaysTrue",oDlgSug,aHeaderEx,aColsEx)

//-------------------------------------------------------------------
/*/{Protheus.doc} BuscaDados
description
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
Static Function BuscaDados()

	Local cQry := ""

//Zera o contador
	nCont := 0

//Limpa o aCols
	aSize(oGet1:aCols,0)

	If Select("QRYEST") > 0
		QRYEST->(DbCloseArea())
	Endif

	cQry := "SELECT ISNULL(SB2.B2_LOCAL, '  ') AS B2_LOCAL, ISNULL(SB2.B2_QATU, 0) AS B2_QATU, SB1.B1_COD, SB1.B1_DESC, SB1.B1_UM, 0 AS U59_QUANT, 0 AS QTD_SUG, 'SEM ESTOQUE DE EXPOSIÇÃO' AS ORIGEM,"
	cQry += " NNR.NNR_DESCRI,"
	cQry += " (SELECT SUM(SB2.B2_QATU)"
	cQry += " 	FROM "+RetSqlName("SB2")+" SB2"
	cQry += " 	WHERE SB2.D_E_L_E_T_ = ' '"
	cQry += " 	AND SB2.B2_FILIAL 	= '"+xFilial("SB2")+"'"
	cQry += " 	AND SB2.B2_COD		= SB1.B1_COD) AS SLD_FILIAL"
	cQry += " FROM "+RetSqlName("SB1")+" SB1"
	cQry += " LEFT JOIN "+RetSqlName("SB2")+" SB2 ON ("
	cQry += " 	SB2.D_E_L_E_T_ 	= ' ' "
	cQry += " 	AND SB2.B2_FILIAL 	= '"+xFilial("SB2")+"'"
	cQry += " 	AND SB2.B2_COD		= SB1.B1_COD "
	cQry += " 	AND SB2.B2_LOCAL	BETWEEN '"+cMV_PAR01+"' AND '"+cMV_PAR02+"'"
	cQry += " 	AND SB2.B2_QATU		> 0"
	cQry += " )"
	cQry += " LEFT JOIN "+RetSqlName("NNR")+" NNR ON ("
	cQry += " 	NNR.D_E_L_E_T_ 	= ' ' "
	cQry += " 	AND NNR.NNR_FILIAL 	= '"+xFilial("NNR")+"'"
	cQry += " 	AND NNR.NNR_CODIGO 	= SB2.B2_LOCAL "
	cQry += " )"

	cQry += " WHERE SB1.D_E_L_E_T_ 	= ' '"
	cQry += " AND SB1.B1_FILIAL 	= '"+xFilial("SB1")+"'"
	cQry += " AND SB1.B1_XTIPO		= 'V'" //Venda c/ exposição
	cQry += " AND NOT EXISTS (SELECT 1 FROM "+RetSqlName("U59")+" WHERE D_E_L_E_T_ = ' ' AND U59_PRODUT = SB1.B1_COD)"
	cQry += " AND (SB2.B2_LOCAL IS NOT NULL OR SB1.B1_LOCPAD	BETWEEN '"+MV_PAR01+"' AND '"+MV_PAR02+"')"
	cQry += " AND SB1.B1_GRUPO		BETWEEN '"+cMV_PAR03+"' AND '"+cMV_PAR04+"'"
	cQry += " AND SB1.B1_COD		BETWEEN '"+cMV_PAR05+"' AND '"+cMV_PAR06+"'"

	cQry += " UNION ALL"

	cQry += " SELECT U59.U59_LOCAL AS B2_LOCAL, ISNULL(SB2.B2_QATU, 0) AS B2_QATU, SB1.B1_COD, SB1.B1_DESC, SB1.B1_UM, U59.U59_QUANT, AVG(ISNULL(SD2.D2_QUANT, 0)) AS QTD_SUG, 'GIRO (VENDA)' AS ORIGEM,"
	cQry += " NNR.NNR_DESCRI,"
	cQry += " (SELECT SUM(SB2.B2_QATU)"
	cQry += " 	FROM "+RetSqlName("SB2")+" SB2"
	cQry += " 	WHERE SB2.D_E_L_E_T_ <> '*'"
	cQry += " 	AND SB2.B2_FILIAL 	= '"+xFilial("SB2")+"'"
	cQry += " 	AND SB2.B2_COD		= SB1.B1_COD) AS SLD_FILIAL"

	cQry += " FROM "+RetSqlName("U59")+" U59 "
	cQry += " INNER JOIN "+RetSqlName("SB1")+" SB1 ON ("
	cQry += " 	SB1.D_E_L_E_T_ 	= ' ' "
	cQry += " 	AND SB1.B1_FILIAL 	= '"+xFilial("SB1")+"'"
	cQry += " 	AND SB1.B1_COD 		= U59.U59_PRODUT "
	cQry += " 	AND SB1.B1_GRUPO	BETWEEN '"+cMV_PAR03+"' AND '"+cMV_PAR04+"'"
	cQry += " )"
	cQry += " INNER JOIN "+RetSqlName("NNR")+" NNR ON ("
	cQry += " 	NNR.D_E_L_E_T_ 	= ' ' "
	cQry += " 	AND NNR.NNR_FILIAL 	= '"+xFilial("NNR")+"'"
	cQry += " 	AND NNR.NNR_CODIGO 	= U59.U59_LOCAL "
	cQry += " )"
	cQry += " LEFT JOIN "+RetSqlName("SB2")+" SB2 ON ("
	cQry += " 	SB2.D_E_L_E_T_ 	= ' ' "
	cQry += " 	AND SB2.B2_FILIAL 	= '"+xFilial("SB2")+"'"
	cQry += " 	AND SB2.B2_COD		= U59.U59_PRODUT"
	cQry += " 	AND SB2.B2_LOCAL	= U59.U59_LOCAL"
	//cQry += " 	AND SB2.B2_QATU		> 0"
	cQry += " )"
	cQry += " LEFT JOIN "+RetSqlName("SD2")+" SD2 ON ("
	cQry += " 	SD2.D_E_L_E_T_ 	= ' '"
	cQry += " 	AND SD2.D2_FILIAL 	= '"+xFilial("SD2")+"'"
	cQry += " 	AND SD2.D2_COD		= U59.U59_PRODUT "
	cQry += " 	AND SD2.D2_LOCAL	= U59.U59_LOCAL"
	cQry += " 	AND SD2.D2_EMISSAO	BETWEEN '"+DToS(dMV_PAR07)+"' AND '"+DToS(dMV_PAR08)+"'"
	cQry += " )"

	cQry += " WHERE U59.D_E_L_E_T_ 	= ' '"
	cQry += " AND U59.U59_FILIAL 	= '"+xFilial("U59")+"'"
	cQry += " AND U59.U59_LOCAL		BETWEEN '"+cMV_PAR01+"' AND '"+cMV_PAR02+"'"
	cQry += " AND U59.U59_PRODUT	BETWEEN '"+cMV_PAR05+"' AND '"+cMV_PAR06+"'"

	cQry += " GROUP BY U59.U59_LOCAL, NNR.NNR_DESCRI, SB2.B2_QATU, SB1.B1_COD, SB1.B1_DESC, SB1.B1_UM, U59.U59_QUANT"
	cQry += " ORDER BY 3,1"

	cQry := ChangeQuery(cQry)
//MemoWrite("c:\temp\RESTA001.txt",cQry)
	TcQuery cQry NEW Alias "QRYEST"

	If QRYEST->(!EOF())
		While QRYEST->(!EOF())

			aAdd(oGet1:aCols,{iif(!empty(QRYEST->B2_LOCAL),"LBOK","LBNO"),QRYEST->B1_COD,QRYEST->B1_DESC,QRYEST->B1_UM,QRYEST->B2_LOCAL,QRYEST->NNR_DESCRI,QRYEST->B2_QATU,;
				QRYEST->SLD_FILIAL,Round(QRYEST->QTD_SUG,2),QRYEST->U59_QUANT,Round(QRYEST->QTD_SUG,2) * nMV_PAR09,QRYEST->ORIGEM,.F.})
			nCont++

			QRYEST->(dbSkip())
		EndDo
	Else
		MsgInfo("Nenhum registro selecionado !!","Atenção")
		aAdd(oGet1:aCols,{"LBNO",Space(TamSX3("B1_COD")[1]),Space(TamSX3("B1_DESC")[1]),Space(TamSX3("B1_UM")[1]),Space(TamSX3("B2_LOCAL")[1]),;
			Space(TamSX3("NNR_DESCRI")[1]),Space(TamSX3("B2_QATU")[1]),Space(TamSX3("B2_QATU")[1]),0,0,0,Space(40),.F.})
	Endif

	If Select("QRYEST") > 0
		QRYEST->(DbCloseArea())
	Endif

	oGet1:Refresh()
	oSay2:Refresh()

Return

//-------------------------------------------------------------------
/*/{Protheus.doc} ParamOti
description
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
User Function ParamOti()

	If !ValidPerg()
		Return
	Endif

	cMV_PAR01 := MV_PAR01
	cMV_PAR02 := MV_PAR02
	cMV_PAR03 := MV_PAR03
	cMV_PAR04 := MV_PAR04
	cMV_PAR05 := MV_PAR05
	cMV_PAR06 := MV_PAR06
	dMV_PAR07 := MV_PAR07
	dMV_PAR08 := MV_PAR08
	nMV_PAR09 := MV_PAR09

	BuscaDados()

Return

//-------------------------------------------------------------------
/*/{Protheus.doc} Clique
description
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
Static Function Clique()

	If oGet1:aCols[oGet1:nAt][1] == "LBOK"
		oGet1:aCols[oGet1:nAt][1] := "LBNO"
		nCont--
	Else
		oGet1:aCols[oGet1:nAt][1] := "LBOK"
		nCont++
	Endif

	oGet1:oBrowse:Refresh()
	oSay2:Refresh()

Return

//-------------------------------------------------------------------
/*/{Protheus.doc} CliqueT
description
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
Static Function CliqueT()

	Local nI

	If nAux == 1
		nAux := 0
	Else
		nCont := 0

		If oGet1:aCols[1][1] == "LBOK"
			For nI := 1 To Len(oGet1:aCols)
				oGet1:aCols[nI][1] := "LBNO"
			Next
			nCont := 0
		Else
			For nI := 1 To Len(oGet1:aCols)
				oGet1:aCols[nI][1] := "LBOK"
				nCont++
			Next
		Endif

		nAux := 1
	Endif

	oGet1:oBrowse:Refresh()
	oSay2:Refresh()

Return

//-------------------------------------------------------------------
/*/{Protheus.doc} ConfAlt
description
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
Static Function ConfAlt()

	Local nPosOk		:= aScan(oGet1:aHeader,{|x| AllTrim(x[2])=="OK"})
	Local nPosLocal		:= aScan(oGet1:aHeader,{|x| AllTrim(x[2])=="U59_LOCAL"})
	Local nPosProd		:= aScan(oGet1:aHeader,{|x| AllTrim(x[2])=="B1_COD"})
	Local nPosDProd		:= aScan(oGet1:aHeader,{|x| AllTrim(x[2])=="B1_DESC"})
	Local nPosQtdSug    := aScan(oGet1:aHeader,{|x| AllTrim(x[2])=="QTD_SUG"})
	Local nI
	Local nAux			:= 0

	if aScan(oGet1:aCols, {|x| x[nPosOk]=="LBOK" .AND. empty(x[nPosLocal]) }) > 0
		MsgInfo("Há registros marcados, sem preencher o local de esotque! Esses serão ignorados", "Atenção")
	endif

	dbSelectArea("U59")
	U59->(dbSetOrder(1))

	If MsgYesNo("A quantidade de reposição será atualizada para os registros selecionados, deseja continuar ?")

		ProcRegua(Len(oGet1:aCols))

		For nI := 1 To Len(oGet1:aCols)
			If oGet1:aCols[nI][nPosOk] == "LBOK" .AND. !empty(oGet1:aCols[nI][nPosLocal])

				IncProc()
				nAux++

				If U59->(dbSeek(xFilial("U59")+oGet1:aCols[nI][nPosLocal]+oGet1:aCols[nI][nPosProd]))
					RecLock("U59",.F.)
					U59->U59_QUANT := oGet1:aCols[nI][nPosQtdSug]
					U59->(MsUnlock())
				Else
					RecLock("U59",.T.)
					U59->U59_FILIAL := xFilial("U59")
					U59->U59_LOCAL 	:= oGet1:aCols[nI][nPosLocal]
					U59->U59_LOCDES := Posicione("NNR",1,xFilial("NNR")+oGet1:aCols[nI][nPosLocal],"NNR_DESCRI")
					U59->U59_PRODUT := oGet1:aCols[nI][nPosProd]
					U59->U59_PRODDE := oGet1:aCols[nI][nPosDProd]
					U59->U59_QUANT	:= oGet1:aCols[nI][nPosQtdSug]
					U59->U59_LOCORI	:= Space(20)
					U59->(MsUnlock())
				Endif
			Endif
		Next

		If nAux > 0
			MsgInfo("As sugestões foram incluídas com sucesso!!","Atenção")
		Else
			MsgInfo("Nenhum registro selecionado.","Atenção")
		Endif

		BuscaDados()
	Endif

Return

//-------------------------------------------------------------------
/*/{Protheus.doc} ValidPerg
description
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
Static Function ValidPerg()

	Local lRet := .T.
	Local aMvPar
	Local nMv := 0
	Local cPerg := "TRETA006"
	Local aParamBox := {}

// Tipo 1 -> MsGet()
//           [2]-Descricao
//           [3]-String contendo o inicializador do campo
//           [4]-String contendo a Picture do campo
//           [5]-String contendo a validacao
//           [6]-Consulta F3
//           [7]-String contendo a validacao When
//           [8]-Tamanho do MsGet
//           [9]-Flag .T./.F. Parametro Obrigatorio ?
	aAdd(aParamBox,{1,"Do Armazem Exposição",space(TamSX3("NNR_CODIGO")[1]),"",""/*"Vazio() .or. ExistCpo('NNR',mv_par01)"*/,"NNR","",0,.F.}) // Tipo caractere
	aAdd(aParamBox,{1,"Ate o Armazem Exposição",space(TamSX3("NNR_CODIGO")[1]),"","","NNR","",0,.F.}) // Tipo caractere
	aAdd(aParamBox,{1,"Do Grupo",space(TamSX3("BM_GRUPO")[1]),"","","SBM","",0,.F.}) // Tipo caractere
	aAdd(aParamBox,{1,"Ate o Grupo",space(TamSX3("BM_GRUPO")[1]),"","","SBM","",0,.F.}) // Tipo caractere
	aAdd(aParamBox,{1,"Produto de",space(TamSX3("B1_COD")[1]),"","","SB1","",0,.F.}) // Tipo caractere
	aAdd(aParamBox,{1,"Produto ate",space(TamSX3("B1_COD")[1]),"","","SB1","",0,.F.}) // Tipo caractere
	aAdd(aParamBox,{1,"Vendas de",ctod(Space(8)),"","","","",50,.F.}) // Tipo data
	aAdd(aParamBox,{1,"Vendas ate",ctod(Space(8)),"","","","",50,.F.}) // Tipo data
	aAdd(aParamBox,{1,"Dias exposição prateleira",001,"@E 999","","","",20,.F.}) // Tipo numérico

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
	If lRet := ParamBox(aParamBox,"Sugestão para Estoque de Exposição",@aMvPar,,,,,,,cPerg)
		For nMv := 1 To Len( aMvPar )
			&( "MV_PAR" + StrZero( nMv, 2, 0 ) ) := aMvPar[ nMv ]
		Next nMv
	Endif

Return lRet

/*/{Protheus.doc} ESTEXPES
Cadastro de Estoque de Exposição por Estação
@author Pablo Cavalcante
@since 17/12/2017
@version 1.0

@return ${return}, ${return_description}

@type function
/*/
User Function ESTEXPES()
	Local oButton1
	Local oGet1
	Local oGet2
	Local oGet3
	Local oGet4
	Local oGet5
	Local oSay1
	Local oSay2
	Local oSay3
	Local oSay4
	Local oSay5

	Private cGet1 := Space(TamSX3('LG_CODIGO')[1])
	Private cGet2 := Space(TamSX3('LG_NOME')[1])
	Private cGet3 := Space(TamSX3('LG_IMPFISC')[1])
	Private cGet4 := Space(TamSX3('LG_PORTIF ')[1])
	Private cGet5 := Space(TamSX3('B1_LOCPAD')[1])

	Static oDlgArmSLG

	If SLG->(FieldPos("LG_XLOCAL"))>0

		DEFINE MSDIALOG oDlgArmSLG TITLE "Configuração Estoque Exposição das Estações" FROM 000, 000  TO 180, 300 COLORS 0, 16777215 PIXEL

		@ 007, 005 SAY oSay1 PROMPT "Estação:" SIZE 025, 007 OF oDlgArmSLG COLORS 0, 16777215 PIXEL
		@ 020, 005 SAY oSay2 PROMPT "Nome:" SIZE 025, 007 OF oDlgArmSLG COLORS 0, 16777215 PIXEL
		@ 032, 005 SAY oSay3 PROMPT "Impressora:" SIZE 031, 007 OF oDlgArmSLG COLORS 0, 16777215 PIXEL
		@ 045, 005 SAY oSay4 PROMPT "Porta:" SIZE 025, 007 OF oDlgArmSLG COLORS 0, 16777215 PIXEL
		@ 057, 004 SAY oSay5 PROMPT "Armazem:" SIZE 025, 007 OF oDlgArmSLG COLORS 0, 16777215 PIXEL
		@ 005, 037 MSGET oGet1 VAR cGet1 SIZE 022, 010 OF oDlgArmSLG COLORS 0, 16777215 F3 "SLG" PIXEL VALID Gatilha()
		@ 017, 037 MSGET oGet2 VAR cGet2 SIZE 105, 010 OF oDlgArmSLG COLORS 0, 16777215 READONLY PIXEL
		@ 030, 037 MSGET oGet3 VAR cGet3 SIZE 105, 010 OF oDlgArmSLG COLORS 0, 16777215 READONLY PIXEL
		@ 042, 037 MSGET oGet4 VAR cGet4 SIZE 027, 010 OF oDlgArmSLG COLORS 0, 16777215 READONLY PIXEL
		@ 055, 037 MSGET oGet5 VAR cGet5 SIZE 015, 010 OF oDlgArmSLG COLORS 0, 16777215 F3 "NNR" PIXEL
		@ 072, 107 BUTTON oButton1 PROMPT "Fechar" SIZE 037, 012 OF oDlgArmSLG PIXEL ACTION oDlgArmSLG:End()
		@ 072, 067 BUTTON oButton2 PROMPT "Atualizar" SIZE 037, 012 OF oDlgArmSLG PIXEL ACTION Grava()

		ACTIVATE MSDIALOG oDlgArmSLG CENTERED

	EndIf

Return

//-------------------------------------------------------------------
/*/{Protheus.doc} Gatilha
Gatilha informações da SLG
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
Static Function Gatilha()

	SLG->(DbSetOrder(1)) //LG_FILIAL+LG_CODIGO
	If !Empty(cGet1) .and. SLG->(DbSeek(xFilial("SLG")+cGet1))
		cGet2 := SLG->LG_NOME
		cGet3 := SLG->LG_IMPFISC
		cGet4 := SLG->LG_PORTIF
		cGet5 := SLG->LG_XLOCAL
	Else
		cGet2 := Space(TamSX3('LG_NOME')[1])
		cGet3 := Space(TamSX3('LG_IMPFISC')[1])
		cGet4 := Space(TamSX3('LG_PORTIF ')[1])
		cGet5 := Space(TamSX3('B1_LOCPAD')[1])
	EndIf

Return .T.

//-------------------------------------------------------------------
/*/{Protheus.doc} Grava
Grava o armazem informado na estação (SLG)
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
Static Function Grava()

	SLG->(DbSetOrder(1)) //LG_FILIAL+LG_CODIGO

	If !Empty(cGet1) .and. !Empty(cGet5) .and. SLG->(DbSeek(xFilial("SLG")+cGet1))

		RecLock("SLG",.F.)
		SLG->LG_XLOCAL := cGet5
		SLG->(MsUnlock())

		U_UReplica("SLG",1,SLG->(LG_FILIAL+LG_CODIGO),"A")

		//Aviso("Atenção!","Estoque de exposição da estação "+SLG->LG_CODIGO+" - "+AllTrim(SLG->LG_NOME)+" gravado com sucesso!",{"Ok"})
		Help(,,'Help',,"Estoque de exposição da estação "+SLG->LG_CODIGO+" - "+AllTrim(SLG->LG_NOME)+" gravado com sucesso!",1,0)
	EndIf

Return .T.

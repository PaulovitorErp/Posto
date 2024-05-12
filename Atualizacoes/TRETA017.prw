#include "totvs.ch"
#include "topconn.ch"
#include "tbiconn.ch"

/*/{Protheus.doc} TRETA017
Cadastro Configurar Faturamento

@author TOTVS
@since 21/07/2014
@version P11
@param Nao recebe parametros
@return nulo
/*/
User Function TRETA017()

	Private cCadastro := "Configurar Faturamento"
	Private aRotina := {{"Pesquisar","AxPesqui",0,1} ,;
		{"Visualizar","AxVisual",0,2} ,;
		{"Incluir","U_TRETA17B",0,3} ,;
		{"Alterar","AxAltera",0,4} ,;
		{"Excluir","AxDeleta",0,5} ,;
		{"Replicar","U_TRETA17A()",0,6}}   //Função criada por Gianluka Moraes de Sousa
	Private cDelFunc := ".T." // Validacao para a exclusao. Pode-se utilizar ExecBlock
	Private cString := "U88"

	dbSelectArea("U88")
	dbSetOrder(1)

	dbSelectArea(cString)
	mBrowse(6,1,22,75,cString)

Return

//-------------------------------------------------------------------
/*/{Protheus.doc} TRETA17D
description
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
User Function TRETA17D(cAlias,nReg,nOpcx,cOri)

	Local aArea 		:= GetArea()

	Private cCadastro 	:= "Configurar Faturamento"

	Private aRotina 	:= {{"Pesquisar","AxPesqui",0,1} ,;
		{"Visualizar","AxVisual",0,2} ,;
		{"Incluir","U_TRETA17B",0,3} ,;
		{"Alterar","AxAltera",0,4} ,;
		{"Excluir","AxDeleta",0,5}}

	Private _nRecnoSA1	:= SA1->(Recno())

	Public __cOri		:= cOri

	// preparo o ambiente para empresa e filial 
	//RpcSetType(3)
	//RpcSetEnv( cEmpAnt, cFilAnt )

	//-- Preparar ambiente local na retagauarda
	RpcSetType(3)
	PREPARE ENVIRONMENT EMPRESA cEmpAnt FILIAL cFilAnt MODULO "FRT"

	DbSelectArea("SA1")
	SA1->(DbGoTo(_nRecnoSA1))

	DbSelectArea("U88")
	U88->(DbSetOrder(1)) //U88_FILIAL+U88_FORMAP+U88_CLIENT+U88_LOJA

	U_TRETA17B(cAlias,nReg,nOpcx)

	RestArea(aArea)

Return

// -> FilAut -> TRETA17E
//-------------------------------------------------------------------
/*/{Protheus.doc} TRETA17E
Modo de edição do campo U88_FILAUT
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
User Function TRETA17E()

	Local aInf			:= {}
	Local aDados		:= {}

	Local aCampos		:= {{"OK","C",002,0},{"COL1","C",12,0},{"COL2","C",15,0}}
	Local aCampos2		:= {{"OK","","",""},{"COL1","","Código",""},{"COL2","","Descrição",""}}

	Local nPosIt		:= 0
	Local nI

	Private cRet		:= ""
	Private oTempTable1 as object

	Private oMark
	Private cMarca	 	:= "mk"
	Private lImpFechar	:= .F.

	Private oSay1, oSay2, oSay3, oSay4
	Private oTexto
	Private cTexto		:= Space(40)
	Private nContSel	:= 0

	Private cInf 		:= ""

	Static oDlg

	if xFilial("U88") == cFilAnt //se tabela está exclusivo, desabilito o campo
		Return .F.
	endif

	If Alltrim(ReadVar()) == "M->U88_FILAUT"

		aInf := IIF(!Empty(M->U88_FILAUT),StrTokArr(AllTrim(M->U88_FILAUT),"/"),{})
		cInf := M->U88_FILAUT

		dbSelectArea("SM0")
		SM0->(dbGoTop())

		While SM0->(!EOF())
			If AllTrim(SM0->M0_CODIGO) == AllTrim(cEmpAnt)
				aAdd(aDados,{SM0->M0_CODFIL,SM0->M0_FILIAL})
			Endif

			SM0->(dbSkip())
		EndDo

		//cria a tabela temporaria
		oTempTable1 := FWTemporaryTable():New("TRBAUX")
		oTempTable1:SetFields(aCampos)
		oTempTable1:Create()

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
		oMark:bMark 				:= {||MarcaIt()}
		oMark:oBrowse:LCANALLMARK 	:= .T.
		oMark:oBrowse:LHASMARK    	:= .T.
		oMark:oBrowse:bAllMark 		:= {||MarcaT()}

		@ 193, 005 SAY oSay2 PROMPT "Total de registros selecionados:" SIZE 200, 007 OF oDlg COLORS 0, 16777215 PIXEL
		@ 193, 090 SAY oSay3 PROMPT cValToChar(nContSel) SIZE 040, 007 OF oDlg COLORS 0, 16777215 PIXEL

		//Linha horizontal
		@ 203, 005 SAY oSay4 PROMPT Repl("_",342) SIZE 342, 007 OF oDlg COLORS CLR_GRAY, 16777215 PIXEL

		@ 213, 272 BUTTON oButton2 PROMPT "Confirmar" SIZE 040, 010 OF oDlg ACTION Conf001(oDlg) PIXEL
		@ 213, 317 BUTTON oButton3 PROMPT "Fechar" SIZE 030, 010 OF oDlg ACTION Fech001(oDlg) PIXEL

		ACTIVATE MSDIALOG oDlg CENTERED VALID lImpFechar //impede o usuario fechar a janela atraves do [X]
	Endif

Return .T.

//-------------------------------------------------------------------
/*/{Protheus.doc} Conf001
description
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
Static Function Conf001(oDlg)

	Local lAux 	:= .F.
	Local nAux	:= 0

	TRBAUX->(dbGoTop())

	While TRBAUX->(!EOF())
		If TRBAUX->OK == "mk"
			If !lAux
				M->U88_FILAUT := AllTrim(TRBAUX->COL1)
				lAux := .T.
			Else
				M->U88_FILAUT += "/" + AllTrim(TRBAUX->COL1)
			Endif
			nAux += Len(TRBAUX->COL1)
		Endif

		TRBAUX->(dbSkip())
	EndDo

	Fech001(oDlg)

Return

//-------------------------------------------------------------------
/*/{Protheus.doc} Fech001
description
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
Static Function Fech001(oDlg)

	lImpFechar := .T.

	If Select("TRBAUX") > 0
		TRBAUX->(DbCloseArea())
	Endif

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Apagando arquivo temporario                                         ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	oTempTable1:Delete()

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
		nContSel++
	Else
		--nContSel
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

	nContSel := 0

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
				nContSel++
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
/*/{Protheus.doc} TRETA17A
Função: TelaSelFil
Tipo: Função Estática
Descrição: Monta a tela com as filiais escolhidas para alterar o preço de venda para cada uma delas.
Uso:  ExpA1 = Array com as filiais selecionadas
	ExpA2 = Array com os campos utilizados na inclusão do registro
----------------------------------------------------------------------------------------------------
Atualizações:
- 13/07/2016 - Gianluka Moraes de Sousa - Construção Inicial do Fonte
--------------------------------------------------------------------------------------------------
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
User Function TRETA17A(cPonto,cCliente,cLoja)

	Local aArea		:= GetArea()
	Local cQry 		:= ""
	Local oButton1
	Local oButton2
	Local oFont1 := TFont():New("MS Sans Serif",,022,,.T.,,,,,.F.,.F.)
	Local oGet1
	Local cGet1 := Space( TAMSX3("A1_COD")[1] )
	Local oGet2
	Local cGet2 := Space( TAMSX3("A1_LOJA")[1] )
	Local oGet3
	Local cGet3 := Space( TAMSX3("A1_NOME")[1] )
	Local oSay1
	Local oSay2
	Local oSay3
	Local oSay4
	Local nX
	Static oDlg2

	Private _MSG	 	:= {| cStr | oSay:cCaption := (cStr) , ProcessMessages() } // Gianluka Moraes | 13/07/16 : Exibir mensagens no processamento
	Private _nRecnoU88 	:= 0
	Private cLog      	:= ""
	Private cUsuFar		:= ""

	DEFAULT cPonto := ""
	DEFAULT cCliente := ""
	DEFAULT cLoja := ""

	If !Len(AllTrim(cPonto)) > 0 // Nao foi chamado via P.E
		_nRecnoU88	:= U88->(Recno())
		DbSelectArea("U88")
		U88->(DbGoTo(_nRecnoU88))

		cGet1	:= U88->U88_CLIENT
		cGet2	:= U88->U88_LOJA
		cGet3	:= U88->U88_NOME


		DEFINE MSDIALOG oDlg2 TITLE "Reaplicar Cadastro" FROM 000, 000  TO 300, 500 COLORS 0, 16777215 PIXEL

		@ 008, 073 SAY oSay1 PROMPT "Reaplicar Cadastro" SIZE 095, 013 OF oDlg2 FONT oFont1 COLORS 0, 16777215 PIXEL
		@ 047, 009 SAY oSay2 PROMPT "Cód. do Cliente:" SIZE 042, 007 OF oDlg2 COLORS 0, 16777215 PIXEL
		@ 045, 052 MSGET oGet1 VAR cGet1 SIZE 081, 013 OF oDlg2 COLORS 0, 16777215 /*F3 "SA1X"*/ PIXEL WHEN .F.
		@ 047, 141 SAY oSay3 PROMPT "Loja:" SIZE 017, 007 OF oDlg2 COLORS 0, 16777215 PIXEL
		@ 045, 158 MSGET oGet2 VAR cGet2 SIZE 060, 013 OF oDlg2 COLORS 0, 16777215 PIXEL WHEN .F.
		@ 064, 009 SAY oSay4 PROMPT "Nome Cliente:" SIZE 037, 007 OF oDlg2 COLORS 0, 16777215 PIXEL
		@ 064, 052 MSGET oGet3 VAR cGet3 SIZE 166, 012 OF oDlg2 COLORS 0, 16777215 PIXEL WHEN .F.
		@ 084, 041 BUTTON oButton1 PROMPT "Confirmar" SIZE 075, 029 OF oDlg2 ACTION xPrepara(cGet1, cGet2)PIXEL
		@ 084, 141 BUTTON oButton2 PROMPT "Sair" SIZE 075, 029 OF oDlg2 ACTION oDlg2:End() PIXEL

		ACTIVATE MSDIALOG oDlg2 CENTERED

	ElseIf cPonto $ "M030INC/MALTCLI" // Inclusão automática após inclusão do cliente

		cQry := "SELECT U88.* FROM " + RetSqlName("U88") + " U88 WHERE U88.D_E_L_E_T_ = ' ' "
		cQry += "AND U88.U88_CLIENT = '" + AllTrim(cCliente) + "' AND U88.U88_LOJA = '" + AllTrim(cLoja) + "' "

		If Select("QU88") > 0
			QU88->( DbCloseArea() )
		EndIf
		cQry := ChangeQuery(cQry)
		TcQuery cQry New Alias "QU88"

		If Contar("QU88", "!EOF()") > 0
			MsgStop("Já existe cadastro para este cliente no Configurar Faturamento, nenhuma inclusão será realizada!"+CRLF+;
				"Caso necessário utilize a rotina Reaplicar!", "Atencao")
		Else
			cUsuFat := SelUsuFat()

			If cUsuFat == ".F."
				MsgStop("Operação cancelada pelo usuário.", "Atencao")
				QU88->( DbCloseArea() )
				Return
			EndIf

			aFiliais := fFilial()

			For nX:=1 To Len(aFiliais)
				If aFiliais[nX][1]
					FWMsgRun(, {|oSay| 	IncluiU88( @oSay, aFiliais[nX][2], cCliente, cLoja , cLog) }, "Configurar Faturamento", "Incluindo... | Filial: " + AllTrim(aFiliais[nX][2]) + " - " + AllTrim(aFiliais[nX][3]) ) // Chama rotina para incluir em todas as filiais selecionadas.
				EndIf
			Next nX

			If Len(AllTrim(cLog)) > 0
				Aviso("Log de Inclusões - Configura Faturamento",cLog,{"OK"}, 3) // Exibe o log de inclusões.
			EndIf

		EndIf

		QU88->( DbCloseArea() )

	EndIf

	RestArea(aArea)

Return

//-------------------------------------------------------------------
/*/{Protheus.doc} xPrepara
description
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
Static Function xPrepara(cCliente,cLoja)

	Local aAreaU88		:= U88->( GetArea() )
	Local aFiliais		:= {}
	Local aFilSel		:= {}
	Local nTam			:= 0
	Local cQry 			:= ""
	Local nRegistros	:= 0
	Local xFilAnt		:= cFilAnt
	Local x, nX
	Private lCancMultiFil := .F.
	Private aCampos		:= {}
	Private oNwGetDad

//Valida se já existe cadastro deste cliente em alguma filial. (Tabela U88)

	cQry := " SELECT * FROM " + CRLF
	cQry += RetSqlName("U88") + " AS U88 " + CRLF
	cQry += " WHERE U88.D_E_L_E_T_ = ' ' AND U88.U88_CLIENT = '" + U88->U88_CLIENT + "' AND U88.U88_LOJA = '" + U88->U88_LOJA + "' " + CRLF
	cQry += " AND U88.U88_FILIAL = '" + U88->U88_FILIAL + "' "

	If Select("TMP") > 0
		TMP->( DbCloseArea() )
	EndIf
	cQry := ChangeQuery(cQry)
	TcQuery cQry New Alias "TMP"

	nRegistros := Contar("TMP", "!EOF()")

	If nRegistros > 1
		MsgStop("Existe mais de um registro cadastrado para este cliente nesta filial!", "Atencao - Inconsistencia")
		Return
	EndIf

	If nRegistros > 0

		TMP->( DbGoTop() )

		nTam := TMP->(FCOUNT())

		For x:=1 To nTam
			Aadd( aCampos, { FIELD(x), TMP->&(FIELD(x)) } )
		Next x

		aFiliais := fFilial()

		For nX:=1 To Len(aFiliais)
			If aFiliais[nX][1]
				Aadd( aFilSel, { aFiliais[nX][2] })
			EndIf
		Next nX

		If Len(aFilSel) > 0
			TelaSelFil( aFiliais )
		EndIf

		// -> Volto o cFilAnt, pois sofre alterações pelo bChange do MsNewGetDados
		cFilAnt := xFilAnt

		If !lCancMultifil
			FWMsgRun(, {|oSay| 	InsMultFil( @oSay, aFiliais ) }, "Aguarde", "Carregando registros" ) // Chama rotina para incluir em todas as filiais selecionadas.
		Else
			MsgStop("Operacao Cancelada","Atencao")
			Return
		EndIf

	Else
		MsgStop("Ainda não existe nenhum cadastro realizado para Reaplicar. Primeiramente, faça uma inclusão para em seguida Reaplicar!", "Atencao")
	EndIf



	TMP->( DbCloseArea() )
	RestArea( aAreaU88 )

Return

//-------------------------------------------------------------------
/*/{Protheus.doc} TelaSelFil
Função: TelaSelFil
Tipo: Função Estática
Descrição: Monta a tela com as filiais escolhidas para alterar o preço de venda para cada uma delas.
Uso:  ExpA1 = Array com as filiais selecionadas
	  ExpA2 = Array com os campos utilizados na inclusão do registro
Parâmetros: 
Retorno:
----------------------------------------------------------------------------------------------------
Atualizações:
- 13/07/2016 - Gianluka Moraes de Sousa - Construção Inicial do Fonte
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
Static Function TelaSelFil( aFiliais )

	Local oButton1
	Local oButton2
	Local oGroup1 
	Local oSay1
	Local lFechaX := .F.
	Static oDlg1  
	

	DEFINE MSDIALOG oDlg1 TITLE "Configura Faturamento" FROM 000, 000 TO 500, 1000 COLORS 0, 16777215 PIXEL

		fMSNewGe1( aFiliais )
		@ 009, 002 GROUP oGroup1 TO 062, 235 PROMPT "Reaplicar Informações" OF oDlg1 COLOR 0, 16777215 PIXEL
		@ 028, 007 SAY oSay1 PROMPT "Digite as informações de banco para cada filial." SIZE 109, 007 OF oDlg1 COLORS 0, 16777215 PIXEL
		@ 193, 135 BUTTON oButton1 PROMPT "Confirmar" SIZE 084, 031 OF oDlg1 PIXEL ACTION ( lFechaX:=.T., oDlg1:End() )
		@ 193, 245 BUTTON oButton2 PROMPT "Cancelar" SIZE 084, 031 OF oDlg1 PIXEL ACTION ( lFechaX:=lCancMultiFil:=.T., oDlg1:End() )

	ACTIVATE MSDIALOG oDlg1 CENTERED VALID lFechaX // Impede o usuário de fechar a janela pelo "X"
Return

//-------------------------------------------------------------------
/*/{Protheus.doc} fMSNewGe1
description
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
Static Function fMSNewGe1( aFiliais )
	Local aAltCpo 		:= {}
	Local aHeaderEx 	:= {}
	Local aHeadGrid 	:= {}
	Local aCmpGrid 		:= {} 
	Local x,nX
	Local bGetParFil	:= {|cPar, cFil| SUPERGETMV(cPar,,"",cFil) }
	Local nPosFil 		:= aScan(aCampos, {|x| AllTrim(x[1])=="U88_FILIAL"	})
	Local nPosForPg		:= aScan(aCampos, {|x| AllTrim(x[1])=="U88_FORMAP"	})
	Local nPosCodCli 	:= aScan(aCampos, {|x| AllTrim(x[1])=="U88_CLIENT"	})
	Local nPosLojaCli	:= aScan(aCampos, {|x| AllTrim(x[1])=="U88_LOJA"	})
	Local nPosDesCli 	:= aScan(aCampos, {|x| AllTrim(x[1])=="U88_NOME"	})
	//Local nPosBanco 	:= aScan(aCampos, {|x| AllTrim(x[1])=="U88_BANCOC"	})
	//Local nPosAgencia 	:= aScan(aCampos, {|x| AllTrim(x[1])=="U88_AGC"		})
	//Local nPosConta		:= aScan(aCampos, {|x| AllTrim(x[1])=="U88_CONTAC"	})
	
	Private lMarajo		:= SuperGetMv("MV_XMARAJO",.F.,.F.)
	                                                                             
	// Somente Header dos campos que quero jogar na Grid.
	Aadd( aHeadGrid, { "U88_FILIAL"	}) // Código da Filial
	Aadd( aHeadGrid, { "A1_NOME" 	}) // Trazer o nome da filial
	Aadd( aHeadGrid, { "U88_BANCOC" })
	Aadd( aHeadGrid, { "U88_AGC" 	})
	Aadd( aHeadGrid, { "U88_CONTAC" })	
	Aadd( aHeadGrid, { "U88_FORMAP"	}) // Trazer o nome da filial	
	Aadd( aHeadGrid, { "U88_CLIENT" })	
	Aadd( aHeadGrid, { "U88_LOJA" 	})
	Aadd( aHeadGrid, { "U88_NOME" 	}) // Trazer o nome do cliente	
	
	// Somente contéudo dos campos que quero jogar na Grid, criando um aCols para cada filial que o usuario selecionou.
	For x:=1 To Len(aFiliais)
		If aFiliais[x,1]
			If lMarajo
				Aadd( aCmpGrid, {aFiliais[x,2],aFiliais[x,3],;
				Eval(bGetParFil, "MV_BCOFAT", aFiliais[x,2]),; // Busca do parametro um banco padrão para a filial corrente.
				Eval(bGetParFil, "MV_AGCFAT", aFiliais[x,2]) ,; // Busca do parametro uma agencia padrão para a filial corrente.
				Eval(bGetParFil, "MV_CNTFAT", aFiliais[x,2]) ,; // Busca do parametro uma conta padrão para a filial corrente.
				aCampos[nPosForPg,2],aCampos[nPosCodCli,2],aCampos[nPosLojaCli,2],aCampos[nPosDesCli,2],.F.}) 
			Else
				Aadd( aCmpGrid, {aFiliais[x,2],aFiliais[x,3],;
				U88->U88_BANCOC,;
				U88->U88_AGC,;
				U88->U88_CONTAC,;
				aCampos[nPosForPg,2],aCampos[nPosCodCli,2],aCampos[nPosLojaCli,2],aCampos[nPosDesCli,2],.F.})
			Endif
		EndIf
	Next x

	// Campos que o usuário poderá alterar.
	aAltCpo := {"U88_BANCOC"}
	
	//Define as propriedades dos campos
	For nX:=1 To Len( aHeadGrid )
		Aadd( aHeaderEx, U_UAHEADER(aHeadGrid[nX][1]))
	Next nX
	
	oNwGetDad := msNewGetDados():New( 071, 001, 167, 500, GD_UPDATE, "AlwaysTrue", "AlwaysTrue",, aAltCpo,,, "AlwaysTrue", "", "AlwaysTrue", , aHeaderEx, aCmpGrid, {||cFilAnt:=aCols[n,nPosFil]} )

Return        

//-------------------------------------------------------------------
/*/{Protheus.doc} InsMultFil
Função: InsMultFil
Tipo: Função Estática
Descrição: Realiza as inclusões dos registros nas filiais selecionadas.
Uso:  ExpA1 = Array com as filiais selecionadas
      ExpA2 = Array com os campos utilizados na inclusão dos registros
Parâmetros: 
Retorno:
----------------------------------------------------------------------
Atualizações:
- 13/07/2016 - Gianluka Moraes de Sousa - Construção Inicial do Fonte
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
Static Function InsMultFil( oSay, aFiliais )

	Local aHeader	:= oNwGetDad:aHeader   
	Local aCols 	:= oNwGetDad:aCols 
	Local aFilSel	:= {} // Irá guardar somente as filiais que foram selecionadas.  
	Local x, nX

	Local nPosFil 	:= aScan( aHeader, {|x| AllTrim(x[2])=="U88_FILIAL"	})
	Local nPosForPg := aScan( aHeader, {|x| AllTrim(x[2])=="U88_FORMAP"	})
	Local nPosCli	:= aScan( aHeader, {|x| AllTrim(x[2])=="U88_CLIENT"	})
	Local nPosLoja	:= aScan( aHeader, {|x| AllTrim(x[2])=="U88_LOJA"	})
	Local nPosBanco	:= aScan( aHeader, {|x| AllTrim(x[2])=="U88_BANCOC"	})
	Local nPosAgenc	:= aScan( aHeader, {|x| AllTrim(x[2])=="U88_AGC"	})	
	Local nPosConta	:= aScan( aHeader, {|x| AllTrim(x[2])=="U88_CONTAC"	})

	For nX:=1 To Len(aFiliais)
		If aFiliais[nX][1]
    		Aadd( aFilSel, { aFiliais[nX][2] })
		EndIf
	Next nX

	// Valido se já existe cadastro em uma das filiais selecionadas.
	DbSelectArea("U88")
	U88->( DbSetOrder(1) )
	For x:=1 To Len(aCols)
		Eval(_MSG,"Inserindo Informações... | Registro " + cValToChar(x) + " de " + cValToChar(Len(aCols)) )

		If !U88->(dbSeek(aCols[x, nPosFil] + aCols[x, nPosForPg] + aCols[x, nPosCli] + aCols[x, nPosLoja]))     // Busca exata, se verdadeiro, entra
				RecLock("U88", .T.)  //F-> altera.  T-> inclui				              
				
				U88->U88_FILIAL := aCols[x, nPosFil] // Informações diferentes pra cada filial, pego do aCols
				U88->U88_FORMAP := aCampos[aScan(aCampos,{|x|AllTrim(x[1])=="U88_FORMAP"}),2] 
				U88->U88_DESCRI := aCampos[aScan(aCampos,{|x|AllTrim(x[1])=="U88_DESCRI"}),2] 
	
				U88->U88_CLIENT := aCampos[aScan(aCampos,{|x|AllTrim(x[1])=="U88_CLIENT"}),2] 
				U88->U88_LOJA 	:= aCampos[aScan(aCampos,{|x|AllTrim(x[1])=="U88_LOJA"}),2] 
				U88->U88_NOME 	:= aCampos[aScan(aCampos,{|x|AllTrim(x[1])=="U88_NOME"}),2] 
	
				U88->U88_USUFAT := aCampos[aScan(aCampos,{|x|AllTrim(x[1])=="U88_USUFAT"}),2] 
				U88->U88_FATAUT := aCampos[aScan(aCampos,{|x|AllTrim(x[1])=="U88_FATAUT"}),2] 
				U88->U88_FILAUT := aCampos[aScan(aCampos,{|x|AllTrim(x[1])=="U88_FILAUT"}),2] 
				U88->U88_MAILFA := aCampos[aScan(aCampos,{|x|AllTrim(x[1])=="U88_MAILFA"}),2] 
				U88->U88_FATSMS := aCampos[aScan(aCampos,{|x|AllTrim(x[1])=="U88_FATSMS"}),2] 
				U88->U88_FATCOR := aCampos[aScan(aCampos,{|x|AllTrim(x[1])=="U88_FATCOR"}),2] 
				U88->U88_GERANF := aCampos[aScan(aCampos,{|x|AllTrim(x[1])=="U88_GERANF"}),2] 
				U88->U88_END 	:= aCampos[aScan(aCampos,{|x|AllTrim(x[1])=="U88_END"}),2] 
				U88->U88_COMPLE := aCampos[aScan(aCampos,{|x|AllTrim(x[1])=="U88_COMPLE"}),2] 
				U88->U88_BAIRRO := aCampos[aScan(aCampos,{|x|AllTrim(x[1])=="U88_BAIRRO"}),2] 
				U88->U88_EST 	:= aCampos[aScan(aCampos,{|x|AllTrim(x[1])=="U88_EST"}),2] 
				U88->U88_MUN 	:= aCampos[aScan(aCampos,{|x|AllTrim(x[1])=="U88_MUN"}),2] 
				U88->U88_CEP 	:= aCampos[aScan(aCampos,{|x|AllTrim(x[1])=="U88_CEP"}),2] 
				U88->U88_INSCR 	:= aCampos[aScan(aCampos,{|x|AllTrim(x[1])=="U88_INSCR"}),2] 
				U88->U88_CGC 	:= aCampos[aScan(aCampos,{|x|AllTrim(x[1])=="U88_CGC"}),2] 
				U88->U88_TEL 	:= aCampos[aScan(aCampos,{|x|AllTrim(x[1])=="U88_TEL"}),2] 
				U88->U88_CLICOB := aCampos[aScan(aCampos,{|x|AllTrim(x[1])=="U88_CLICOB"}),2] 
				U88->U88_LOJCOB := aCampos[aScan(aCampos,{|x|AllTrim(x[1])=="U88_LOJCOB"}),2] 
				U88->U88_NOMCOB := aCampos[aScan(aCampos,{|x|AllTrim(x[1])=="U88_NOMCOB"}),2] 
				U88->U88_TPCOBR := aCampos[aScan(aCampos,{|x|AllTrim(x[1])=="U88_TPCOBR"}),2] 
				U88->U88_BANCOC := aCols[x, nPosBanco] // Informações diferentes pra cada filial, pego do aCols
				U88->U88_AGC	:= aCols[x, nPosAgenc] // Informações diferentes pra cada filial, pego do aCols
				U88->U88_CONTAC	:= aCols[x, nPosConta] // Informações diferentes pra cada filial, pego do aCols
				U88->U88_MSEXP	:= aCampos[aScan(aCampos,{|x|AllTrim(x[1])=="U88_MSEXP"}),2] 
				U88->U88_HREXP	:= aCampos[aScan(aCampos,{|x|AllTrim(x[1])=="U88_HREXP"}),2] 				
				U88->U88_BOLCOR := aCampos[aScan(aCampos,{|x|AllTrim(x[1])=="U88_BOLCOR"}),2] 
				
				U88->(MSUNLOCK())     // Destrava o registro  
				
		        cLog += "Inclusão na filial "+aCols[x, nPosFil]+" - "+AllTrim(RetField('SM0',1,cEmpAnt+aCols[x,nPosFil],'M0_FILIAL'))+" realizada com sucesso." + CRLF
				
		Else //se não foi localizado o registro, então gera erro
	        cLog += "Cadastro já existente na filial "+aCols[x,nPosFil]+" - "+AllTrim(RetField('SM0',1,cEmpAnt+aCols[x,nPosFil],'M0_FILIAL'))+", não foi possível alterar." + CRLF
		Endif

	Next x
	
	Aviso("Log de Inclusões",cLog,{"OK"}, 3) // Exibe o log de inclusões.
          
Return

//-------------------------------------------------------------------
/*/{Protheus.doc} IncluiU88
description
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
Static Function IncluiU88( oSay, _cFilial, _cCliente, _cLoja , _cLog)
    
	DbSelectArea("SA1")
	SA1->( DbSetOrder(1) )            	
	If !SA1->( DbSeek(xFilial("SA1")+_cCliente+_cLoja) )
		MsgAlert("Falha ao posicionar no cliente para incluir os dados no Configura Faturamento.","Atencao")
		Return
	EndIf

	// Valido se já existe cadastro em uma das filiais selecionadas.
	DbSelectArea("U88")
	U88->( DbSetOrder(1) )	                                         

	If !U88->(dbSeek(_cFilial + "FT" + _cCliente + _cLoja))     // Busca exata, se verdadeiro, entra
		RecLock("U88", .T.)  //F-> altera.  T-> inclui				              
		// O conteudo padrão dos campos foi passado pela usuária Margarete				
		U88->U88_FILIAL := _cFilial 
		U88->U88_FORMAP := "FT"
		U88->U88_DESCRI := "FATURA"

		U88->U88_CLIENT := SA1->A1_COD
		U88->U88_LOJA 	:= SA1->A1_LOJA
		U88->U88_NOME 	:= SA1->A1_NOME

		U88->U88_USUFAT := cUsuFat
		U88->U88_FATAUT := "S"
		U88->U88_FILAUT := LeSM0() // GMdS | 05-04-2017 : Solicitado pelo Jonatas.
		U88->U88_MAILFA := "S"
		U88->U88_FATSMS := "N"
		U88->U88_FATCOR := "N"
		U88->U88_GERANF := "S"            
		U88->U88_END 	:= SA1->A1_END
		U88->U88_COMPLE := SA1->A1_COMPLEM
		U88->U88_BAIRRO := SA1->A1_BAIRRO
		U88->U88_EST 	:= SA1->A1_EST
		U88->U88_MUN 	:= SA1->A1_MUN
		U88->U88_CEP 	:= SA1->A1_CEP
		U88->U88_INSCR 	:= SA1->A1_INSCR
		U88->U88_CGC 	:= SA1->A1_CGC
		U88->U88_TEL 	:= SA1->A1_TEL
		U88->U88_CLICOB := SA1->A1_COD
		U88->U88_LOJCOB := SA1->A1_LOJA
		U88->U88_NOMCOB := SA1->A1_NOME
		U88->U88_TPCOBR := "B"
		U88->U88_BANCOC := SUPERGETMV("MV_BCOFAT",,"",_cFilial) 
		U88->U88_AGC	:= SUPERGETMV("MV_AGCFAT",,"",_cFilial) 
		U88->U88_CONTAC	:= SUPERGETMV("MV_CNTFAT",,"",_cFilial) 
		U88->U88_BOLCOR := "N"
		
		U88->(MSUNLOCK())     // Destrava o registro  
		
		cLog += "Inclusão na filial "+_cFilial+" - "+AllTrim(RetField('SM0',1,cEmpAnt+_cFilial,'M0_FILIAL'))+" realizada com sucesso." + CRLF
				
	Else //se não foi localizado o registro, então gera erro
	    cLog += "Cadastro já existente na filial "+_cFilial+" - "+AllTrim(RetField('SM0',1,cEmpAnt+_cFilial,'M0_FILIAL'))+", não foi possível alterar." + CRLF
	Endif

SA1->( DbCloseArea() )
U88->( DbcloseArea() )

Return   

//-------------------------------------------------------------------
/*/{Protheus.doc} SelUsuFat
description
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
Static Function SelUsuFat()
Local oButton1
Local oButton2
Local oGet1
Local cGet1 := Space(6)
Local oGet2
Local cGet2 := Space(100)
Local oSay1
Local oSay2
Local oSay3
Static oDlg

  DEFINE MSDIALOG oDlg TITLE "Usuário Responsável" FROM 000, 000  TO 250, 500 COLORS 0, 16777215 PIXEL

    @ 014, 064 SAY oSay1 PROMPT "Selecione o Usuário Responsável pelo Cliente" SIZE 131, 007 OF oDlg COLORS 0, 16777215 PIXEL
    @ 045, 018 SAY oSay2 PROMPT "Cod. Usuario:" SIZE 039, 007 OF oDlg COLORS 0, 16777215 PIXEL
    @ 045, 061 MSGET oGet1 VAR cGet1 SIZE 060, 010 OF oDlg COLORS 0, 16777215 F3 "US2" PIXEL
    @ 064, 018 SAY oSay3 PROMPT "Nome Usuário:" SIZE 053, 007 OF oDlg COLORS 0, 16777215 PIXEL
    @ 064, 061 MSGET oGet2 VAR cGet2 SIZE 150, 010 OF oDlg COLORS 0, 16777215 PIXEL WHEN .F.
    @ 093, 104 BUTTON oButton1 PROMPT "Confirmar" SIZE 057, 018 OF oDlg PIXEL ACTION oDlg:End()
    @ 093, 169 BUTTON oButton2 PROMPT "Cancelar" SIZE 057, 018 OF oDlg PIXEL ACTION (cGet1:=".F.",oDlg:End())

  ACTIVATE MSDIALOG oDlg CENTERED

Return cGet1                        


//TpTitCor -> TRETA17F
//-------------------------------------------------------------------
/*/{Protheus.doc} TRETA17F
description
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
User Function TRETA17F()

	Local aInf			:= {}
	Local aDados		:= {}

	Local aCampos		:= {{"OK","C",002,0},{"COL1","C",12,0},{"COL2","C",15,0}}
	Local aCampos2		:= {{"OK","","",""},{"COL1","","Código",""},{"COL2","","Descrição",""}}

	Local cTpFat		:= SuperGetMv("MV_XFPGFAT",.F.,"NP/BOL/RP/CF/FT/CC/CCP/CD/CDP/DP/CT/CTF/NF/VLS/RE/REN/CN")
	Local nPosIt		:= 0

	Local aContent 		:= {} // Vetor com os dados do SX5com: [1] FILIAL [2] TABELA [3] CHAVE [4] DESCRICAO
	Local nX := 1
	Local nI

	Private cRet		:= ""
	Private oTempTable2 as object

	Private oMark
	Private cMarca	 	:= "mk"
	Private lImpFechar	:= .F.

	Private oSay1, oSay2, oSay3, oSay4
	Private oTexto
	Private cTexto		:= Space(40)
	Private nContSel	:= 0

	Private cInf 		:= ""

	Static oDlg2

	If Alltrim(ReadVar()) == "M->U88_TPOCOR"

		aInf := IIF(!Empty(M->U88_TPOCOR),StrTokArr(AllTrim(M->U88_TPOCOR),"/"),{})
		cInf := M->U88_TPOCOR

		aContent := FWGetSX5('24') // Vetor com os dados do SX5 com: [1] FILIAL [2] TABELA [3] CHAVE [4] DESCRICAO

		For nX:=1 to Len(aContent)
			If RTrim(aContent[nX][3]) $ cTpFat
				aAdd(aDados,{aContent[nX][3],aContent[nX][4]})
			EndIf
		Next nX

		//cria a tabela temporaria
		oTempTable2 := FWTemporaryTable():New("TRBAUXG")
		oTempTable2:SetFields(aCampos)
		oTempTable2:Create()

		DbSelectArea("TRBAUXG")

		If Len(aDados) > 0
			For nI := 1 to Len(aDados)
				TRBAUXG->(RecLock("TRBAUXG",.T.))
				If Len(aInf) > 0
					nPosIt := aScan(aInf,{|x| AllTrim(x) == AllTrim(aDados[nI][1])})
					If nPosIt > 0
						TRBAUXG->OK := "mk"
						nContSel++
					Else
						TRBAUXG->OK := "  "
					Endif
				Else
					TRBAUXG->OK := "  "
				Endif
				TRBAUXG->COL1 := aDados[nI][1]
				TRBAUXG->COL2 := aDados[nI][2]
				TRBAUXG->(MsUnlock())
			Next
		Else
			TRBAUXG->(RecLock("TRBAUXG",.T.))
			TRBAUXG->OK		:= "  "
			TRBAUXG->COL1	:= Space(6)
			TRBAUXG->COL2 	:= Space(40)
			TRBAUXG->(MsUnlock())
		Endif

		TRBAUXG->(DbGoTop())

		DEFINE MSDIALOG oDlg2 TITLE "Formas de Pagamentos" From 000,000 TO 450,700 COLORS 0, 16777215 PIXEL

		@ 005, 005 SAY oSay1 PROMPT "Descrição:" SIZE 060, 007 OF oDlg2 COLORS 0, 16777215 PIXEL
		@ 004, 050 MSGET oTexto VAR cTexto SIZE 200, 010 OF oDlg2 COLORS 0, 16777215 PIXEL Picture "@!"
		@ 005, 272 BUTTON oButton1 PROMPT "Localizar" SIZE 040, 010 OF oDlg2 ACTION Localiza(cTexto) PIXEL

		//Browse
		oMark := MsSelect():New("TRBAUXG","OK","",aCampos2,,@cMarca,{020,005,190,348})
		oMark:bMark 				:= {||MarcaIt2()}
		oMark:oBrowse:LCANALLMARK 	:= .T.
		oMark:oBrowse:LHASMARK    	:= .T.
		oMark:oBrowse:bAllMark 		:= {||MarcaT2()}

		@ 193, 005 SAY oSay2 PROMPT "Total de registros selecionados:" SIZE 200, 007 OF oDlg2 COLORS 0, 16777215 PIXEL
		@ 193, 090 SAY oSay3 PROMPT cValToChar(nContSel) SIZE 040, 007 OF oDlg2 COLORS 0, 16777215 PIXEL

		//Linha horizontal
		@ 203, 005 SAY oSay4 PROMPT Repl("_",342) SIZE 342, 007 OF oDlg2 COLORS CLR_GRAY, 16777215 PIXEL

		@ 213, 272 BUTTON oButton2 PROMPT "Confirmar" SIZE 040, 010 OF oDlg2 ACTION Conf002(oDlg2) PIXEL
		@ 213, 317 BUTTON oButton3 PROMPT "Fechar" SIZE 030, 010 OF oDlg2 ACTION Fech002(oDlg2) PIXEL

		ACTIVATE MSDIALOG oDlg2 CENTERED VALID lImpFechar //impede o usuario fechar a janela atraves do [X]
	Endif

Return .T.

//-------------------------------------------------------------------
/*/{Protheus.doc} Conf002
description
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
Static Function Conf002(oDlg2)

	Local lAux 	:= .F.
	Local nAux	:= 0

	TRBAUXG->(dbGoTop())

	While TRBAUXG->(!EOF())
		If TRBAUXG->OK == "mk"
			If !lAux
				M->U88_TPOCOR := AllTrim(TRBAUXG->COL1)
				lAux := .T.
			Else
				M->U88_TPOCOR += "/" + AllTrim(TRBAUXG->COL1)
			Endif
			nAux += Len(TRBAUXG->COL1)
		Endif

		TRBAUXG->(dbSkip())
	EndDo

	Fech002(oDlg2)

Return

//-------------------------------------------------------------------
/*/{Protheus.doc} Fech002
description
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
Static Function Fech002(oDlg2)

	lImpFechar := .T.

	If Select("TRBAUXG") > 0
		TRBAUXG->(DbCloseArea())
	Endif

	oTempTable2:Delete()

	oDlg2:End()

Return

//-------------------------------------------------------------------
/*/{Protheus.doc} MarcaIt2
description
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
Static Function MarcaIt2()

	If TRBAUXG->OK == "mk"
		nContSel++
	Else
		--nContSel
	Endif

	oSay3:Refresh()

Return

//-------------------------------------------------------------------
/*/{Protheus.doc} MarcaT2
description
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
Static Function MarcaT2()

	Local lMarca 	:= .F.
	Local lNMARCA 	:= .F.

	nContSel := 0

	TRBAUXG->(dbGoTop())

	While TRBAUXG->(!EOF())
		If TRBAUXG->OK == "mk" .And. !lMarca
			RecLock("TRBAUXG",.F.)
			TRBAUXG->OK := "  "

			TRBAUXG->(MsUnlock())
			lNMarca := .T.
		Else
			If !lNMarca
				RecLock("TRBAUXG",.F.)
				TRBAUXG->OK := "mk"
				TRBAUXG->(MsUnlock())
				nContSel++
				lMarca := .T.
			Endif
		Endif

		TRBAUXG->(dbSkip())
	EndDo

	TRBAUXG->(dbGoTop())

	oSay3:Refresh()

Return

//-------------------------------------------------------------------
/*/{Protheus.doc} LeSM0
GMdS | Função para ler a SM0 e retornar os códigos das filiais.
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
Static Function LeSM0()

	Local cRet 		:= ""
	Local aAreaSM0  := SM0->( GetArea() )

	SM0->( DbGoTop() )
	While SM0->(!EOF())
		If AllTrim(SM0->M0_CODIGO) == AllTrim(cEmpAnt)
			If Empty(AllTrim(cRet))
				cRet := AllTrim(SM0->M0_CODFIL)
			Else
				cRet += "/" + AllTrim(SM0->M0_CODFIL)
			EndIf
		Endif
		SM0->(dbSkip())
	EndDo

	RestArea( aAreaSM0 )
Return cRet

//-------------------------------------------------------------------
/*/{Protheus.doc} TRETA17B
description
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
User Function TRETA17B(cAlias,nReg,nOpc)

	AxInclui(cAlias,nReg,nOpc,,,,"U_TRETA17C()")

Return

//-------------------------------------------------------------------
/*/{Protheus.doc} TRETA17C
description
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
User Function TRETA17C()

	Local lRet := .T.

	If U88->(DbSeek(xFilial("U88")+M->U88_FORMAP+M->U88_CLIENT+M->U88_LOJA))
		MsgInfo("O Cliente "+AllTrim(M->U88_CLIENT)+" / "+AllTrim(M->U88_LOJA)+" já possui configuração para a forma de pagamento "+AllTrim(M->U88_FORMAP)+", operação não permitida.","Atenção")
		lRet := .F.
	Endif

Return lRet

/*/{Protheus.doc} TRETA17G
TRETA17G -> RetCli
Inicializador padrão dos campos U88_CLIENT, U88_LOJACLI e U88_NOME
@author Maiki Perin
@since 16/01/2015
@version P11
@param nCampo
@return String
/*/
User Function TRETA17G(nCampo)

	Local cInf := ""

	If AllTrim(FunName()) == "RPC" .And. __cOri == "CADCLI"

		If nCampo == 1 //U88_CLIENT

			cInf := SA1->A1_COD

		ElseIf nCampo == 2 //U88_LOJA

			cInf := SA1->A1_LOJA

		Else //U88_NOME

			cInf := SA1->A1_NOME
		Endif
	Endif

Return cInf


/*--------------------------------------------------------------------------------------------------
Função: fFilial
Tipo: Função Estática
Descrição: Abre uma checkbox para o usuário selecionar as filiais que deseja buscar as informações
Uso: Marajó
Parâmetros:
Retorno:
----------------------------------------------------------------------------------------------------
Atualizações:
- 30/03/2016 - Gianluka Moraes de Sousa - Construção Inicial do Fonte
--------------------------------------------------------------------------------------------------*/

Static Function fFilial(aLisFil)

Local aFilsCalc:={}

// Variaveis utilizadas na selecao de categorias
Local oChkQual,lQual,oQual,cVarQ

// Carrega bitmaps
Local oOk       := LoadBitmap( GetResources(), "LBOK")
Local oNo       := LoadBitmap( GetResources(), "LBNO")

// Variaveis utilizadas para lista de filiais
Local lStat		:= .F.
Local nPos 		:= 0
Local aAreaSM0	:= SM0->( GetArea() )
//Local aFilsCalc := FWLoadSM0()
Local oDlg

DEFAULT aLisFil := {}


//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Carrega filiais da empresa corrente                          ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
DbSelectArea("SM0")
DbSeek(cEmpAnt)
Do While ! Eof() .And. SM0->M0_CODIGO == cEmpAnt

	lStat := .f.

	nPos := aScan( aLisFil,{ |x| x[2] = Alltrim(SM0->M0_CODFIL) } )

	If nPos > 0
		lStat := aLisFil[nPos,1]
	EndIf

	Aadd(aFilsCalc,{lStat,Alltrim(SM0->M0_CODFIL),Alltrim(SM0->M0_FILIAL),SM0->M0_CGC})

	dbSkip()
EndDo

RestArea(aAreaSM0)

If Len(aFilsCalc) > 0

	DEFINE MSDIALOG oDlg TITLE OemToAnsi("Seleção de Filiais") STYLE DS_MODALFRAME From 145,0 To 445,628 OF oMainWnd PIXEL
	oDlg:lEscClose := .F.
	@ 05,15 TO 125,300 LABEL OemToAnsi("Marque as Filiais a serem consideradas no processamento") OF oDlg  PIXEL
	@ 15,20 CHECKBOX oChkQual VAR lQual PROMPT OemToAnsi("Inverte Selecao") SIZE 50, 10 OF oDlg PIXEL ON CLICK (AEval(aFilsCalc, {|z| z[1] := If(z[1]==.T.,.F.,.T.)}), oQual:Refresh(.F.))
	@ 30,20 LISTBOX oQual VAR cVarQ Fields HEADER "",OemToAnsi("Filial"),OemToAnsi("Nome"),OemToAnsi("CNPJ") SIZE 273,090 ON DBLCLICK (aFilsCalc:=MtFClTroca(oQual:nAt,aFilsCalc),oQual:Refresh()) NoScroll OF oDlg PIXEL
	oQual:SetArray(aFilsCalc)
	oQual:bLine := { || {If(aFilsCalc[oQual:nAt,1],oOk,oNo),aFilsCalc[oQual:nAt,2],aFilsCalc[oQual:nAt,3]}}
	DEFINE SBUTTON FROM 134,240 TYPE 1 ACTION If(MtFCalOk(aFilsCalc,.T.,.T.),oDlg:End(),) ENABLE OF oDlg
	DEFINE SBUTTON FROM 134,270 TYPE 2 ACTION (lCancMultiFil:=.T.,oDlg:End()) ENABLE OF oDlg

	ACTIVATE MSDIALOG oDlg CENTERED
Else
	MsgInfo("Sem Filial")
EndIf
Return aFilsCalc

/*--------------------------------------------------------------------------------------------------
Função: MtFCalOk
Tipo: Função Estática
Descrição: Checa marcacao das filiais
Uso:  ExpA1 = Array com a selecao das filiais
      ExpL1 = Valida array de filiais (.t. se ok e .f. se cancel)
      ExpL2 = Mostra tela de aviso no caso de inconsistencia
Parâmetros:
Retorno:
----------------------------------------------------------------------------------------------------
Atualizações:
- 30/03/2016 - Gianluka Moraes de Sousa - Construção Inicial do Fonte
--------------------------------------------------------------------------------------------------*/

Static Function MtFCalOk(aFilsCalc,lValidaArray,lMostraTela)
 Local lRet:=.F.
 Local nx:=0

 Default lMostraTela := .T.

 If !lValidaArray
  aFilsCalc := {}
  lRet := .T.
 Else
 // Checa marcacoes efetuadas
  For nx:=1 To Len(aFilsCalc)
   If aFilsCalc[nx,1]
    lRet:=.T.
   EndIf
  Next nx
 // Checa se existe alguma filial marcada na confirmacao
  If !lRet
   Aviso(OemToAnsi("Atenção"),OemToAnsi("Deve ser selecionada ao menos uma filial para o processamento"),{"Ok"})
  EndIf
 EndIf

Return lRet

/*--------------------------------------------------------------------------------------------------
Função: MtFClTroca
Tipo: Função Estática
Descrição: Troca marcador entre x e branco
Uso:  ExpN1 = Linha onde o click do mouse ocorreu
	  ExpA2 = Array com as opcoes para selecao
Parâmetros:
Retorno:
----------------------------------------------------------------------------------------------------
Atualizações:
- 30/03/2016 - Gianluka Moraes de Sousa - Construção Inicial do Fonte
--------------------------------------------------------------------------------------------------*/
Static Function MtFClTroca(nIt,aArray)
	 aArray[nIt,1] := !aArray[nIt,1]
Return aArray

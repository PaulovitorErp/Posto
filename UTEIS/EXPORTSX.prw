#INCLUDE "TOTVS.CH"
#INCLUDE "hbutton.ch"
#INCLUDE "topconn.ch"
#INCLUDE "TbiConn.ch"

/*/{Protheus.doc} EXPORTSX
Função que exporta o dicionário de dados.

@author Totvs GO
@since 10/04/2015
@version 1.0

@return ${return}, ${return_description}

@type function
/*/
User Function EXPORTSX() //U_EXPORTSX()

	Local oButton1
	Local oButton2
	Local oGetAmb1
	Local oGetAmb2
	Local oGetEmp1
	Local oGetEmp2
	Local oGetFil1
	Local oGetFil2
	Local oGetIP1
	Local oGetIP2
	Local oGetPt1
	Local oGetPt2
	Local oGrpOrigem
	Local oGrpDestino
	Local oGroupSX2
	Local oGroupSX3
	Local oGroupSX6
	Local oGroupSXB
	Local oGroupBTN
	Local oSay1
	Local oSay2
	Local oSay3
	Local oSay4
	Local oSay5
	Local oSay6
	Local oMultSX2
	Local oMultSX3
	Local oMultSX6
	Local oMultSXB
	Local cGetAmb1 	:= PADR(GetEnvServer(),20) //SPACE(20)
	Local cGetAmb2 	:= SPACE(20)
	Local cGetIP1 	:= PADR(GetServerIP(),15) //SPACE(15)
	Local cGetIP2 	:= SPACE(15)
	Local cDriver 	:= GetPVProfString("Drivers",'ACTIVE',"",GetADV97())
	Local nGetPt1 	:= Val(GetPVProfString(cDriver,'PORT',"",GetADV97()))
	Local nGetPt2 	:= 0
	Local cGetEmp1 	:= "01"// SPACE(2)
	Local cGetEmp2 	:= "01"// SPACE(2)
	Local cGetFil1 	:= "0101    "// SPACE(8)
	Local cGetFil2 	:= "0101    "// SPACE(8)
	Local cMultSX2 	:= ""
	Local cMultSX3 	:= ""
	Local cMultSX6 	:= ""
	Local cMultSXB 	:= ""
	Local oLevaSIX
	Local lLevaSIX 	:= .T.
	Local oLevaSX7
	Local lLevaSX7	:= .T.
	Local oLevaSXB
	Local lLevaSXB	:= .T.
	Static oDlg

//If '12' $ cVersao //para a versao do Protheus 12
	// Abre a tela em fullscreen
//	FWVldFullScreen()
//EndIf

	DEFINE MSDIALOG oDlg TITLE " EXPORTAÇÃO DO DICIONÁRIO DE DADOS " FROM 000, 000  TO 624, 970 COLORS 0, 16777215 PIXEL

//////////////////////////////////////////  GRUPO DO SERVIDOR DE ORIGEM  /////////////////////////////////////////////

	@ 005, 005 GROUP oGrpOrigem TO 064, 240 PROMPT "  Servidor de Origem  " OF oDlg COLOR 0, 16777215 PIXEL

	@ 018, 010 SAY oSay1 PROMPT "IP:" SIZE 012, 007 OF oDlg COLORS 0, 16777215 PIXEL
	@ 017, 022 MSGET oGetIP1 VAR cGetIP1 SIZE 050, 010 OF oDlg COLORS 0, 16777215 PIXEL

	@ 018, 083 SAY oSay2 PROMPT "Porta:" SIZE 017, 007 OF oDlg COLORS 0, 16777215 PIXEL
	@ 017, 105 MSGET oGetPt1 VAR nGetPt1 SIZE 025, 010 OF oDlg PICTURE "@E 99999" COLORS 0, 16777215 PIXEL

	@ 018, 145 SAY oSay3 PROMPT "Ambiente:" SIZE 025, 007 OF oDlg COLORS 0, 16777215 PIXEL
	@ 017, 180 MSGET oGetAmb1 VAR cGetAmb1 SIZE 055, 010 OF oDlg COLORS 0, 16777215 PIXEL

	@ 046, 010 SAY oSay3 PROMPT "Empresa:" SIZE 025, 007 OF oDlg COLORS 0, 16777215 PIXEL
	@ 045, 035 MSGET oGetEmp1 VAR cGetEmp1 SIZE 030, 010 OF oDlg COLORS 0, 16777215 PIXEL

	@ 046, 083 SAY oSay3 PROMPT "Filial:" SIZE 025, 007 OF oDlg COLORS 0, 16777215 PIXEL
	@ 045, 100 MSGET oGetFil1 VAR cGetFil1 SIZE 055, 010 OF oDlg COLORS 0, 16777215 PIXEL

/////////////////////////////////////////  GRUPO DO SERVIDOR DE DESTINO  /////////////////////////////////////////////
	@ 005, 245 GROUP oGrpDestino TO 064, 480 PROMPT "  Servidor de Destino  " OF oDlg COLOR 0, 16777215 PIXEL

	@ 018, 250 SAY oSay4 PROMPT "IP:" SIZE 012, 007 OF oDlg COLORS 0, 16777215 PIXEL
	@ 017, 265 MSGET oGetIP2 VAR cGetIP2 SIZE 050, 010 OF oDlg COLORS 0, 16777215 PIXEL

	@ 018, 325 SAY oSay5 PROMPT "Porta:" SIZE 017, 007 OF oDlg COLORS 0, 16777215 PIXEL
	@ 017, 347 MSGET oGetPt2 VAR nGetPt2 SIZE 025, 010 OF oDlg PICTURE "@E 99999" COLORS 0, 16777215 PIXEL

	@ 018, 385 SAY oSay6 PROMPT "Ambiente:" SIZE 025, 007 OF oDlg COLORS 0, 16777215 PIXEL
	@ 017, 420 MSGET oGetAmb2 VAR cGetAmb2 SIZE 055, 010 OF oDlg COLORS 0, 16777215 PIXEL

	@ 046, 250 SAY oSay3 PROMPT "Empresa:" SIZE 025, 007 OF oDlg COLORS 0, 16777215 PIXEL
	@ 045, 280 MSGET oGetEmp2 VAR cGetEmp2 SIZE 030, 010 OF oDlg COLORS 0, 16777215 PIXEL

	@ 046, 325 SAY oSay3 PROMPT "Filial:" SIZE 025, 007 OF oDlg COLORS 0, 16777215 PIXEL
	@ 045, 345 MSGET oGetFil2 VAR cGetFil2 SIZE 055, 010 OF oDlg COLORS 0, 16777215 PIXEL

//////////////////////////////////////////////////  GRUPO SX2  ///////////////////////////////////////////////////////

	@ 072, 005 GROUP oGroupSX2 TO 174, 240 PROMPT "  SX2  " OF oDlg COLOR 0, 16777215 PIXEL
	@ 087, 010 SAY oSay7 PROMPT "Informe as tabelas separadas por espaço. Ex: SA1 SA2 SA3" SIZE 250, 007 OF oDlg COLORS 0, 16777215 PIXEL
	@ 102, 010 GET oMultSX2 VAR cMultSX2 OF oDlg MULTILINE SIZE 225, 057 COLORS 0, 16777215 HSCROLL PIXEL
	@ 160, 010 CHECKBOX oLevaSIX VAR lLevaSIX PROMPT "Considerar Índices (SIX) das tabelas?" SIZE 150,10 OF oDlg PIXEL

//////////////////////////////////////////////////  GRUPO SX3  ///////////////////////////////////////////////////////

	@ 072, 245 GROUP oGroupSX3 TO 174, 480 PROMPT "  SX3  " OF oDlg COLOR 0, 16777215 PIXEL
	@ 087, 250 SAY oSay7 PROMPT "Informe os campos separados por espaço. Ex: A1_COD A1_LOJA A1_NOME" SIZE 250, 007 OF oDlg COLORS 0, 16777215 PIXEL
	@ 102, 250 GET oMultSX3 VAR cMultSX3 OF oDlg MULTILINE SIZE 225, 057 COLORS 0, 16777215 HSCROLL PIXEL
	@ 160, 250 CHECKBOX oLevaSX7 VAR lLevaSX7 PROMPT "Considerar Gatilhos (SX7) dos campos?" SIZE 150,10 OF oDlg PIXEL

//////////////////////////////////////////////////  GRUPO SX6  ///////////////////////////////////////////////////////

	@ 177, 005 GROUP oGroupSX6 TO 279, 240 PROMPT "  SX6  " OF oDlg COLOR 0, 16777215 PIXEL
	@ 192, 010 SAY oSay7 PROMPT "Informe os parâmetros separados por espaço. Ex: MV_ESTNEG MV_CLIPAD" SIZE 250, 007 OF oDlg COLORS 0, 16777215 PIXEL
	@ 207, 010 GET oMultSX6 VAR cMultSX6 OF oDlg MULTILINE SIZE 225, 067 COLORS 0, 16777215 HSCROLL PIXEL

//////////////////////////////////////////////////  GRUPO SXB  ///////////////////////////////////////////////////////

	@ 177, 245 GROUP oGroupSXB TO 279, 480 PROMPT "  SXB  " OF oDlg COLOR 0, 16777215 PIXEL
	@ 192, 250 SAY oSay7 PROMPT "Informe as consultas padrões separadas por espaço. Ex: ACY2 SA11" SIZE 250, 007 OF oDlg COLORS 0, 16777215 PIXEL
	@ 207, 250 GET oMultSXB VAR cMultSXB OF oDlg MULTILINE SIZE 225, 057 COLORS 0, 16777215 HSCROLL PIXEL
	@ 265, 250 CHECKBOX oLevaSXB VAR lLevaSXB PROMPT "Considerar Consultas (SXB) dos campos?" SIZE 150,10 OF oDlg PIXEL

///////////////////////////////////////////////  GRUPO DE BOTOES  ////////////////////////////////////////////////////

	@ 284, 005 GROUP oGroupBTN TO 254, 480 OF oDlg COLOR 0, 16777215 PIXEL
	@ 292, 005 BUTTON oButton3 PROMPT "Lista SX3" SIZE 040, 015 OF oDlg ACTION(GeraSX3(cGetIP1,nGetPt1,cGetAmb1,cGetEmp1,cGetFil1)) PIXEL
	@ 292, 050 BUTTON oButton5 PROMPT "UPD Posto" SIZE 040, 015 OF oDlg ACTION(U_UPDPOSTO()) PIXEL
	@ 292, 095 BUTTON oButton7 PROMPT "Parâmetros" SIZE 040, 015 OF oDlg ACTION(U_USX6POST()) PIXEL

	@ 292, 395 BUTTON oButton4 PROMPT "Salvar CSV"  SIZE 040, 015 OF oDlg ACTION(Confirmar(cGetIP1,nGetPt1,cGetAmb1,cGetIP2,nGetPt2,cGetAmb2,cMultSX2,cMultSX3,cMultSX6,cMultSXB,cGetEmp1,cGetFil1,cGetEmp2,cGetFil2,lLevaSIX,lLevaSX7,lLevaSXB,.T.)) PIXEL
	@ 292, 440 BUTTON oButton1 PROMPT "Confirmar" SIZE 040, 015 OF oDlg ACTION(Confirmar(cGetIP1,nGetPt1,cGetAmb1,cGetIP2,nGetPt2,cGetAmb2,cMultSX2,cMultSX3,cMultSX6,cMultSXB,cGetEmp1,cGetFil1,cGetEmp2,cGetFil2,lLevaSIX,lLevaSX7,lLevaSXB)) PIXEL
	@ 292, 350 BUTTON oButton2 PROMPT "Cancelar"  SIZE 040, 015 OF oDlg ACTION(oDlg:End()) PIXEL

	ACTIVATE MSDIALOG oDlg CENTERED

Return()


/*/{Protheus.doc} GeraSX3
Carrega TODOS os campos de um intervalo de tabelas informada no ambiente de origem...

@author pablo
@since 27/09/2018
@version 1.0
@return ${return}, ${return_description}
@param cGetIP1, characters, descricao
@param nGetPt1, numeric, descricao
@param cGetAmb1, characters, descricao
@param cGetEmp1, characters, descricao
@param cGetFil1, characters, descricao
@type function
/*/
Static Function GeraSX3(cGetIP1,nGetPt1,cGetAmb1,cGetEmp1,cGetFil1)
	Local cListCamp	:= ""
	Local cErro		:= ""
	Local nOpc  	:= "0"
	Local oButton1
	Local oGet1
	Local cAliasDe := Space(3)
	Local oGet2
	Local cAliasAt := Space(3)
	Local oSay1
	Local oSay2
	Static oDlgFil

	If Empty(cGetIP1) .OR. nGetPt1 <= 0 .OR. Empty(cGetAmb1)
		Aviso( "Atenção!", "Informe os dados do servidor de origem!", {"Ok"} )
		Return
	EndIf

	DEFINE MSDIALOG oDlgFil TITLE "Filtro de Tabelas" FROM 000, 000  TO 120, 200 COLORS 0, 16777215 PIXEL

	@ 011, 004 SAY oSay1 PROMPT "Tabela Inical:" SIZE 036, 007 OF oDlgFil COLORS 0, 16777215 PIXEL
	@ 028, 004 SAY oSay2 PROMPT "Tabela Final:" SIZE 037, 007 OF oDlgFil COLORS 0, 16777215 PIXEL
	@ 010, 042 MSGET oGet1 VAR cAliasDe SIZE 030, 010 OF oDlgFil COLORS 0, 16777215 PIXEL
	@ 027, 042 MSGET oGet2 VAR cAliasAt SIZE 031, 010 OF oDlgFil COLORS 0, 16777215 PIXEL
	@ 043, 058 BUTTON oButton1 PROMPT "OK" SIZE 037, 012 OF oDlgFil ACTION(nOpc:="1",oDlgFil:End()) PIXEL

	ACTIVATE MSDIALOG oDlgFil CENTERED

	If nOpc == "1"
		MsAguarde({|| cListCamp := RPCOrigemSX3(cGetIP1,nGetPt1,cGetAmb1,cGetEmp1,cGetFil1,@cErro,cAliasDe,cAliasAt) },"Aguarde! Conectando no servidor de origem...")
	EndIf

	If !Empty(cListCamp) .and. Empty(cErro)

		cFileLog := MemoWrite( CriaTrab( , .F. ) + ".log", cListCamp )
		Define Font oFont Name "Mono AS" Size 5, 12
		Define MsDialog oDlgDet Title "Lista Gerada" From 3, 0 to 340, 417 Pixel

		@ 5, 5 Get oMemo Var cListCamp Memo Size 200, 145 Of oDlgDet Pixel
		oMemo:bRClicked := { || AllwaysTrue() }
		oMemo:oFont     := oFont

		Define SButton From 153, 175 Type  1 Action oDlgDet:End() Enable Of oDlgDet Pixel // Apaga
		Define SButton From 153, 145 Type 13 Action ( cFile := cGetFile( cMask, "" ), If( cFile == "", .T., ;
			MemoWrite( cFile, cListCamp ) ) ) Enable Of oDlgDet Pixel

		Activate MsDialog oDlgDet Center

	ElseIf !Empty(cErro)
		Aviso( "Atenção!", "Ocorreu o seguinte erro:"+cErro, {"Ok"} )
	EndIf

Return


/*/{Protheus.doc} RPCOrigemSX3
Conecta no ambiente de origem, para carregar os campos da SX3.

@author pablo
@since 27/09/2018
@version 1.0
@return ${return}, ${return_description}
@param cIP, characters, descricao
@param nPorta, numeric, descricao
@param cEnv, characters, descricao
@param cGetEmp, characters, descricao
@param cGetFil, characters, descricao
@param cErro, characters, descricao
@param cAliasDe, characters, descricao
@param cAliasAt, characters, descricao
@type function
/*/
Static Function RPCOrigemSX3(cIP,nPorta,cEnv,cGetEmp,cGetFil,cErro,cAliasDe,cAliasAt)

	Local cRetorno	:= ""
	Local oRpcSrv
	Default cErro	:= ""

	oRpcSrv := TRpc():New(cEnv)
	If ( oRpcSrv:Connect( cIP, nPorta ) )

		//Uso NÃO PERMITIDO de chamada de API de Console --conout( ">> CONEXAO ESTABELECIDA COM O SERVIDOR - " + cIP + " PORTA - " + cValToChar(nPorta))

		// Executa função através do CallProc
		cRetorno := oRpcSrv:CallProc('U_USX3Origem',cGetEmp,cGetFil,@cErro,cAliasDe,cAliasAt)

		// Desconecta do servidor
		oRpcSrv:Disconnect()

	Else
		cErro := "NAO FOI POSSIVEL CONECTAR NO SERVIDOR - " + cIP + " PORTA - " + cValToChar(nPorta)
		//Uso NÃO PERMITIDO de chamada de API de Console --conout( ">> " + cErro)
	Endif

Return(cRetorno)


/*/{Protheus.doc} USX3Origem
Função executada no lado do ambiente de origem para retornar os campos da SX3.

@author pablo
@since 27/09/2018
@version 1.0
@return ${return}, ${return_description}
@param cEmp, characters, descricao
@param cFil, characters, descricao
@param cErro, characters, descricao
@param cAliasDe, characters, descricao
@param cAliasAt, characters, descricao
@type function
/*/
User Function USX3Origem(cEmp,cFil,cErro,cAliasDe,cAliasAt)

	Local aArea := GetArea()
	Local cRet 		:= ""
	Local aSX3		:= {}
	Local cCondicao	:= ""
	Local bCondicao
	Local lConect := .T.
	Local cAliasSX3 := GetNextAlias() // apelido para o arquivo de trabalho
	Local aEstrut := {}

	Default cErro	:= ""

	aEstrut := { "X3_ARQUIVO", "X3_ORDEM"  , "X3_CAMPO"  , "X3_TIPO"   , "X3_TAMANHO", "X3_DECIMAL", ;
		"X3_TITULO" , "X3_TITSPA" , "X3_TITENG" , "X3_DESCRIC", "X3_DESCSPA", "X3_DESCENG", ;
		"X3_PICTURE", "X3_VALID"  , "X3_USADO"  , "X3_RELACAO", "X3_F3"     , "X3_NIVEL"  , ;
		"X3_RESERV" , "X3_CHECK"  , "X3_TRIGGER", "X3_PROPRI" , "X3_BROWSE" , "X3_VISUAL" , ;
		"X3_CONTEXT", "X3_OBRIGAT", "X3_VLDUSER", "X3_CBOX"   , "X3_CBOXSPA", "X3_CBOXENG", ;
		"X3_PICTVAR", "X3_WHEN"   , "X3_INIBRW" , "X3_GRPSXG" , "X3_FOLDER" , "X3_PYME"   }

	// preparo o ambiente para empresa e filial passados como parâmetro
	//RpcSetType(3)
	//Reset Environment
	//lConect := RpcSetEnv(cEmp,cFil)

	cEmpAnt := cEmp
	cFilAnt := cFil

	//-- Preparar ambiente local na retagauarda
	RpcSetType(3)
	PREPARE ENVIRONMENT EMPRESA cEmpAnt FILIAL cFilAnt MODULO "FRT"

	If lConect
		//Uso NÃO PERMITIDO de chamada de API de Console --conout(">> CONEXAO REALIZADA COM SUCESSO NA EMPRESA: " + Alltrim(cEmp) + " FILIAL: " + Alltrim(cFil))
	Else
		cErro := "NAO FOI POSSIVEL REALIZAR CONEXAO NA EMPRESA: " + Alltrim(cEmp) + " FILIAL: " + Alltrim(cFil)
		//Uso NÃO PERMITIDO de chamada de API de Console --conout(">> " + cErro)
		Return(cRet)
	EndIf

	// abre o dicionário SX3
	OpenSXs(NIL, NIL, NIL, NIL, cEmpAnt, cAliasSX3, "SX3", NIL, .F.)

	// caso aberto, posiciona no topo
	If !(Select(cAliasSX3) > 0)
		Return .F.
	EndIf
	DbSelectArea(cAliasSX3)
	(cAliasSX3)->( DbSetOrder( 1 ) ) //X3_ARQUIVO+X3_ORDEM
	(cAliasSX3)->( DbGoTop() )

	If (cAliasSX3)->(DbSeek(cAliasDe))
		While (cAliasSX3)->(!Eof()) .AND. (cAliasSX3)->&("X3_ARQUIVO") >= cAliasDe .AND. (cAliasSX3)->&("X3_ARQUIVO") <= cAliasAt
			cRet += " "+AllTrim((cAliasSX3)->&("X3_CAMPO"))
			(cAliasSX3)->(DbSkip())
		EndDo
	EndIf

	cRet := AllTrim(cRet)

	RestArea(aArea)

Return(cRet)

/*/{Protheus.doc} Confirmar
Função chamada na confirmação da rotina.

@author pablo
@since 27/09/2018
@version 1.0
@return ${return}, ${return_description}
@param cGetIP1, characters, descricao
@param nGetPt1, numeric, descricao
@param cGetAmb1, characters, descricao
@param cGetIP2, characters, descricao
@param nGetPt2, numeric, descricao
@param cGetAmb2, characters, descricao
@param cMultSX2, characters, descricao
@param cMultSX3, characters, descricao
@param cMultSX6, characters, descricao
@param cMultSXB, characters, descricao
@param cGetEmp1, characters, descricao
@param cGetFil1, characters, descricao
@param cGetEmp2, characters, descricao
@param cGetFil2, characters, descricao
@param lLevaSIX, logical, descricao
@param lLevaSX7, logical, descricao
@param lSalvaCSV, logical, descricao
@type function
/*/
Static Function Confirmar(cGetIP1,nGetPt1,cGetAmb1,cGetIP2,nGetPt2,cGetAmb2,cMultSX2,cMultSX3,cMultSX6,cMultSXB,cGetEmp1,cGetFil1,cGetEmp2,cGetFil2,lLevaSIX,lLevaSX7,lLevaSXB,lSalvaCSV)

	Local aArea 		:= GetArea()
	Local aRetorno1		:= {}
	Local aRetorno2		:= {}
	Local cErro			:= ""

	Default lSalvaCSV	:= .F.

	if Empty(cGetIP1) .OR. nGetPt1 <= 0 .OR. Empty(cGetAmb1)
		Aviso( "Atenção!", "Informe os dados do servidor de origem!", {"Ok"} )
	elseif !lSalvaCSV .and. (Empty(cGetIP2) .OR. nGetPt2 <= 0 .OR. Empty(cGetAmb2))
		Aviso( "Atenção!", "Informe os dados do servidor de destino!", {"Ok"} )
	elseif Empty(cMultSX2) .AND. Empty(cMultSX3) .AND. Empty(cMultSX6) .AND. Empty(cMultSXB)
		Aviso( "Atenção!", "Não foram informados registros para serem exportados!", {"Ok"} )
	else

		MsAguarde({|| aRetorno1 := RPCOrigem(cGetIP1,nGetPt1,cGetAmb1,cGetEmp1,cGetFil1,cMultSX2,cMultSX3,cMultSX6,cMultSXB,@cErro,lLevaSIX,lLevaSX7,lLevaSXB) },"Aguarde! Conectando no servidor de origem...")

		// se existir ao menos um registro para ser replicado
		if empty(cErro) .AND. lSalvaCSV
			SalvaCSV(cGetEmp2,cGetFil2,aClone(aRetorno1),@cErro)
		elseif empty(cErro) .AND. ( !Empty(aRetorno1[1]) .OR. !Empty(aRetorno1[2]) .OR. !Empty(aRetorno1[3]) .OR. !Empty(aRetorno1[4]) )
			MsAguarde({|| aRetorno2 := RPCDestino(cGetIP2,nGetPt2,cGetAmb2,cGetEmp2,cGetFil2,aClone(aRetorno1),@cErro) },"Aguarde! Conectando no servidor de destino...")
		endif

		if Empty(cErro)
			if !lSalvaCSV
				Aviso( "Concluído!", "Atualização concluída com sucesso!", {"Ok"} )
			else
				Aviso( "Concluído!", "Exportação CSV concluída com sucesso!", {"Ok"} )
			endif
		else
			Aviso( "Erro!", cErro, {"Ok"} )
		endif

	endif

	RestArea(aArea)

Return()

/*/{Protheus.doc} RPCOrigem
Função que conecta no servidor de origem.

@author pablo
@since 27/09/2018
@version 1.0
@return ${return}, ${return_description}
@param cIP, characters, descricao
@param nPorta, numeric, descricao
@param cEnv, characters, descricao
@param cGetEmp, characters, descricao
@param cGetFil, characters, descricao
@param cMultSX2, characters, descricao
@param cMultSX3, characters, descricao
@param cMultSX6, characters, descricao
@param cMultSXB, characters, descricao
@param cErro, characters, descricao
@param lLevaSIX, logical, descricao
@param lLevaSX7, logical, descricao
@param lLevaSXB, logical, descricao
@type function
/*/
Static Function RPCOrigem(cIP,nPorta,cEnv,cGetEmp,cGetFil,cMultSX2,cMultSX3,cMultSX6,cMultSXB,cErro,lLevaSIX,lLevaSX7,lLevaSXB)

	Local aRetorno	:= {{},{},{},{},{},{}}
	Local oRpcSrv
	Default cErro	:= ""

	oRpcSrv := TRpc():New(cEnv)
	If ( oRpcSrv:Connect( cIP, nPorta ) )

		//Uso NÃO PERMITIDO de chamada de API de Console --conout( ">> CONEXAO ESTABELECIDA COM O SERVIDOR - " + cIP + " PORTA - " + cValToChar(nPorta))

		// Executa função através do CallProc
		aRetorno := aClone(oRpcSrv:CallProc('U_UConOrigem',cGetEmp,cGetFil,cMultSX2,cMultSX3,cMultSX6,cMultSXB,@cErro,lLevaSIX,lLevaSX7,lLevaSXB))

		// Desconecta do servidor
		oRpcSrv:Disconnect()

	Else
		cErro := "NAO FOI POSSIVEL CONECTAR NO SERVIDOR - " + cIP + " PORTA - " + cValToChar(nPorta)
		//Uso NÃO PERMITIDO de chamada de API de Console --conout( ">> " + cErro)
	Endif

Return(aRetorno)


/*/{Protheus.doc} RPCDestino
Função que conecta no servidor de destino.

@author pablo
@since 27/09/2018
@version 1.0
@return ${return}, ${return_description}
@param cIP, characters, descricao
@param nPorta, numeric, descricao
@param cEnv, characters, descricao
@param cGetEmp, characters, descricao
@param cGetFil, characters, descricao
@param aDados, array, descricao
@param cErro, characters, descricao
@type function
/*/
Static Function RPCDestino(cIP,nPorta,cEnv,cGetEmp,cGetFil,aDados,cErro)

	Local aRetorno	:= {}
	Local oRpcSrv
	Default cErro	:= ""

	oRpcSrv := TRpc():New(cEnv)
	If ( oRpcSrv:Connect( cIP, nPorta ) )

		//Uso NÃO PERMITIDO de chamada de API de Console --conout( ">> CONEXAO ESTABELECIDA COM O SERVIDOR - " + cIP + " PORTA - " + cValToChar(nPorta))

		// Executa função através do CallProc
		aRetorno := aClone(oRpcSrv:CallProc('U_UConDestino',cGetEmp,cGetFil,aDados,@cErro))

		// Desconecta do servidor
		oRpcSrv:Disconnect()

	Else
		cErro := "NAO FOI POSSIVEL CONECTAR NO SERVIDOR - " + cIP + " PORTA - " + cValToChar(nPorta)
		//Uso NÃO PERMITIDO de chamada de API de Console --conout( ">> " + cErro )
	Endif

Return(aRetorno)


/*/{Protheus.doc} UConOrigem
Função executada no servidor de origem.
Responsável por captar as informações do dicionário de dados.

@author pablo
@since 27/09/2018
@version 1.0
@return ${return}, ${return_description}
@param cEmp, characters, descricao
@param cFil, characters, descricao
@param cMultSX2, characters, descricao
@param cMultSX3, characters, descricao
@param cMultSX6, characters, descricao
@param cMultSXB, characters, descricao
@param cErro, characters, descricao
@param lLevaSIX, logical, descricao
@param lLevaSX7, logical, descricao
@param lLevaSXB, logical, descricao
@type function
/*/
User Function UConOrigem(cEmp,cFil,cMultSX2,cMultSX3,cMultSX6,cMultSXB,cErro,lLevaSIX,lLevaSX7,lLevaSXB)

	Local aArea 	:= GetArea()
	Local aRet 		:= {{},{},{},{},{},{}}
	Local aSX2		:= {}
	Local aSX3		:= {}
	Local aSX6		:= {}
	Local aSXB		:= {}
	Local cCondicao	:= ""
	Local bCondicao
	Local lConect := .T.
	Local nX, nY

	Local cAliasSX2 := GetNextAlias()
	Local cAliasSX3 := GetNextAlias()
	Local cAliasSX6 := GetNextAlias()
	Local cAliasSXB := GetNextAlias()
	Local cAliasSIX := GetNextAlias()
	Local cAliasSX7 := GetNextAlias()

	Local aEstSX2 := RetStrutDic("SX2")
	Local aEstSX3 := RetStrutDic("SX3")
	Local aEstSX6 := RetStrutDic("SX6")
	Local aEstSXB := RetStrutDic("SXB")
	Local aEstSIX := RetStrutDic("SIX")
	Local aEstSX7 := RetStrutDic("SX7")

	Default cErro	:= ""

// preparo o ambiente para empresa e filial passados como parâmetro
//RpcSetType(3)
//Reset Environment
//lConect := RpcSetEnv(cEmp,cFil)

	cEmpAnt := cEmp
	cFilAnt := cFil

//-- Preparar ambiente local na retagauarda
	RpcSetType(3)
	PREPARE ENVIRONMENT EMPRESA cEmpAnt FILIAL cFilAnt MODULO "FRT"

	if lConect
		//Uso NÃO PERMITIDO de chamada de API de Console --conout(">> CONEXAO REALIZADA COM SUCESSO NA EMPRESA: " + Alltrim(cEmp) + " FILIAL: " + Alltrim(cFil))
	else
		cErro := "NAO FOI POSSIVEL REALIZAR CONEXAO NA EMPRESA: " + Alltrim(cEmp) + " FILIAL: " + Alltrim(cFil)
		//Uso NÃO PERMITIDO de chamada de API de Console --conout(">> " + cErro)
		Return(aRet)
	endif

	aSX2 := StrToKarr(cMultSX2," ")
	aSX3 := StrToKarr(cMultSX3," ")
	aSX6 := StrToKarr(cMultSX6," ")
	aSXB := StrToKarr(cMultSXB," ")

	// abre o dicionário SX2
	OpenSXs(NIL, NIL, NIL, NIL, cEmpAnt, cAliasSX2, "SX2", NIL, .F.)

	// caso aberto, posiciona no topo
	If !(Select(cAliasSX2) > 0)
		Return(aRet)
	EndIf
	DbSelectArea(cAliasSX2)
	(cAliasSX2)->( DbSetOrder( 1 ) ) //X2_CHAVE
	(cAliasSX2)->( DbGoTop() )

	// abre o dicionário SX3
	OpenSXs(NIL, NIL, NIL, NIL, cEmpAnt, cAliasSX3, "SX3", NIL, .F.)

	// caso aberto, posiciona no topo
	If !(Select(cAliasSX3) > 0)
		Return(aRet)
	EndIf
	DbSelectArea(cAliasSX3)
	(cAliasSX3)->( DbSetOrder( 2 ) ) //X3_CAMPO
	(cAliasSX3)->( DbGoTop() )

	// abre o dicionário SX6
	OpenSXs(NIL, NIL, NIL, NIL, cEmpAnt, cAliasSX6, "SX6", NIL, .F.)

	// caso aberto, posiciona no topo
	If !(Select(cAliasSX6) > 0)
		Return(aRet)
	EndIf
	DbSelectArea(cAliasSX6)
	(cAliasSX6)->( DbSetOrder( 1 ) ) //X6_FIL+X6_VAR
	(cAliasSX6)->( DbGoTop() )

	// abre o dicionário SXB
	OpenSXs(NIL, NIL, NIL, NIL, cEmpAnt, cAliasSXB, "SXB", NIL, .F.)

	// caso aberto, posiciona no topo
	If !(Select(cAliasSXB) > 0)
		Return(aRet)
	EndIf
	DbSelectArea(cAliasSXB)
	(cAliasSXB)->( DbSetOrder( 1 ) ) //XB_ALIAS+XB_TIPO+XB_SEQ+XB_COLUNA
	(cAliasSXB)->( DbGoTop() )

	// abre o dicionário SIX
	OpenSXs(NIL, NIL, NIL, NIL, cEmpAnt, cAliasSIX, "SIX", NIL, .F.)

	// caso aberto, posiciona no topo
	If !(Select(cAliasSIX) > 0)
		Return(aRet)
	EndIf
	DbSelectArea(cAliasSIX)
	(cAliasSIX)->( DbSetOrder( 1 ) ) //INDICE+ORDEM
	(cAliasSIX)->( DbGoTop() )

	// abre o dicionário SX7
	OpenSXs(NIL, NIL, NIL, NIL, cEmpAnt, cAliasSX7, "SX7", NIL, .F.)

	// caso aberto, posiciona no topo
	If !(Select(cAliasSX7) > 0)
		Return(aRet)
	EndIf
	DbSelectArea(cAliasSX7)
	(cAliasSX7)->( DbSetOrder( 1 ) ) //X7_CAMPO+X7_SEQUENC
	(cAliasSX7)->( DbGoTop() )

	For nX := 1 To Len(aSX2)

		if (cAliasSX2)->(DbSeek(aSX2[nX]))

			aAux := {}
			For nY := 1 to Len(aEstSX2)
				aadd(aAux,{aEstSX2[nY], (cAliasSX2)->&(aEstSX2[nY]) })
			Next nY

			aadd(aRet[1],{aSX2[nX],aAux})

			if lLevaSIX
				if (cAliasSIX)->(DbSeek(aSX2[nX]))
					while (cAliasSIX)->(!Eof()) .AND. (cAliasSIX)->&("INDICE") == aSX2[nX]

						aAux := {}
						For nY := 1 to Len(aEstSIX)
							aadd(aAux,{aEstSIX[nY], (cAliasSIX)->&(aEstSIX[nY]) })
						Next nY

						aadd(aRet[5],{(cAliasSIX)->&("INDICE")+(cAliasSIX)->&("ORDEM"), aAux})

						(cAliasSIX)->(DbSkip())
					enddo
				endif
			endif

		endif

	Next nX

	For nX := 1 To Len(aSX3)

		if (cAliasSX3)->(DbSeek(aSX3[nX]))

			aAux := {}
			For nY := 1 to Len(aEstSX3)
				aadd(aAux,{aEstSX3[nY], (cAliasSX3)->&(aEstSX3[nY]) })
			Next nY
			
			aadd(aRet[2],{aSX3[nX],aAux})

			if lLevaSX7
				if (cAliasSX7)->(DbSeek( (cAliasSX3)->&("X3_CAMPO") ))
					while (cAliasSX7)->(!Eof()) .AND. (cAliasSX7)->&("X7_CAMPO") == (cAliasSX3)->&("X3_CAMPO")
						aAux := {}
						For nY := 1 to Len(aEstSX7)
							aadd(aAux,{aEstSX7[nY], (cAliasSX7)->&(aEstSX7[nY]) })
						Next nY

						aadd(aRet[6],{(cAliasSX7)->&("X7_CAMPO")+(cAliasSX7)->&("X7_SEQUENC"), aAux})

						(cAliasSX7)->(DbSkip())
					enddo
				endif
			endif

			if lLevaSXB .and. !Empty( (cAliasSX3)->&("X3_F3") )
				if (cAliasSXB)->(DbSeek( (cAliasSX3)->&("X3_F3") ))
					while (cAliasSXB)->(!Eof()) .AND. (cAliasSXB)->&("XB_ALIAS") == (cAliasSX3)->&("X3_F3")
						if aScan(aRet[4],{|x| AllTrim(x[1])==AllTrim((cAliasSXB)->&("XB_ALIAS+XB_TIPO+XB_SEQ+XB_COLUNA"))}) <= 0
							aAux := {}
							For nY := 1 to Len(aEstSXB)
								aadd(aAux,{aEstSXB[nY], (cAliasSXB)->&(aEstSXB[nY]) })
							Next nY
							
							aadd(aRet[4],{(cAliasSXB)->&("XB_ALIAS") + (cAliasSXB)->&("XB_TIPO") + (cAliasSXB)->&("XB_SEQ") + (cAliasSXB)->&("XB_COLUNA"), aAux})
						endif
						(cAliasSXB)->(DbSkip())
					enddo
				endif
			endif

		endif

	Next nX

	For nX := 1 To Len(aSX6)

		// limpo os filtros da SX6
		(cAliasSX6)->(DbClearFilter())

		cCondicao := " AllTrim(X6_VAR) = '" + aSX6[nX] + "' "
		bCondicao := "{|| " + cCondicao + " }"

		// faço um filtro na SX6
		(cAliasSX6)->(DbSetFilter(&bCondicao,cCondicao))

		(cAliasSX6)->(DbGoTop())

		While (cAliasSX6)->(!Eof())

			aAux := {}
			For nY := 1 to Len(aEstSX6)
				aadd(aAux,{aEstSX6[nY], (cAliasSX6)->&(aEstSX6[nY]) })
			Next nY

			aadd(aRet[3],{(cAliasSX6)->&("X6_FIL") + (cAliasSX6)->&("X6_VAR"), aAux})

			(cAliasSX6)->(DbSkip())

		EndDo

		// limpo os filtros da SX6
		(cAliasSX6)->(DbClearFilter())

	Next nX

	For nX := 1 To Len(aSXB)

		// limpo os filtros da SXB
		(cAliasSXB)->(DbClearFilter())

		cCondicao := " AllTrim(XB_ALIAS) = '" + aSXB[nX] + "' "
		bCondicao := "{|| " + cCondicao + " }"

		// faço um filtro na SXB
		(cAliasSXB)->(DbSetFilter(&bCondicao,cCondicao))

		(cAliasSXB)->(DbGoTop())

		While (cAliasSXB)->(!Eof())
			if aScan(aRet[4],{|x| AllTrim(x[1])==AllTrim((cAliasSXB)->&("XB_ALIAS+XB_TIPO+XB_SEQ+XB_COLUNA"))}) <= 0
				aAux := {}
				For nY := 1 to Len(aEstSXB)
					aadd(aAux,{aEstSXB[nY], (cAliasSXB)->&(aEstSXB[nY]) })
				Next nY

				aadd(aRet[4],{(cAliasSXB)->&("XB_ALIAS") + (cAliasSXB)->&("XB_TIPO") + (cAliasSXB)->&("XB_SEQ") + (cAliasSXB)->&("XB_COLUNA"), aAux})
			endif
			(cAliasSXB)->(DbSkip())

		EndDo

		// limpo os filtros da SXB
		(cAliasSXB)->(DbClearFilter())

	Next nX

	RestArea(aArea)

Return(aRet)


/*/{Protheus.doc} UConDestino
Função executada no servidor de destino.
Responsável por atualizar o dicionário de dados.

@author pablo
@since 27/09/2018
@version 1.0
@return ${return}, ${return_description}
@param cEmp, characters, descricao
@param cFil, characters, descricao
@param aDados, array, descricao
@param cErro, characters, descricao
@type function
/*/
User Function UConDestino(cEmp,cFil,aDados,cErro)

	Local aArea := GetArea()
	Local aRet 		:= {}
	Local lLock		:= .F.
	Local lConect := .T.
	Local nY,nX

	Local cAliasSX2 := GetNextAlias()
	Local cAliasSX3 := GetNextAlias()
	Local cAliasSX6 := GetNextAlias()
	Local cAliasSXB := GetNextAlias()
	Local cAliasSIX := GetNextAlias()
	Local cAliasSX7 := GetNextAlias()

	Default cErro	:= ""

/*
	If !MyOpenSm0(.F.,@cErro)
	cErro := "SEM ACESSO EXCLUSIVO A EMPRESA"
	//Uso NÃO PERMITIDO de chamada de API de Console --conout(">> " + cErro  )
	Return(aRet)
	EndIf
*/

// preparo o ambiente para empresa e filial passados como parâmetro
//RpcSetType(3)
//Reset Environment
//lConect := RpcSetEnv(cEmp,cFil)

	cEmpAnt := cEmp
	cFilAnt := cFil

//-- Preparar ambiente local na retagauarda
	RpcSetType(3)
	PREPARE ENVIRONMENT EMPRESA cEmpAnt FILIAL cFilAnt MODULO "FRT"

	if lConect
		//Uso NÃO PERMITIDO de chamada de API de Console --conout(">> CONEXAO REALIZADA COM SUCESSO NA EMPRESA: " + Alltrim(cEmp) + " FILIAL: " + Alltrim(cFil))
	else
		cErro :=  "NAO FOI POSSIVEL REALIZAR CONEXAO NA EMPRESA: " + Alltrim(cEmp) + " FILIAL: " + Alltrim(cFil)
		//Uso NÃO PERMITIDO de chamada de API de Console --conout(">> " + cErro  )
		Return(aRet)
	endif

	// abre o dicionário SX2
	OpenSXs(NIL, NIL, NIL, NIL, cEmpAnt, cAliasSX3, "SX2", NIL, .F.)

	// caso aberto, posiciona no topo
	If !(Select(cAliasSX2) > 0)
		Return .F.
	EndIf
	DbSelectArea(cAliasSX2)
	(cAliasSX2)->( DbSetOrder( 1 ) ) //X2_CHAVE
	(cAliasSX2)->( DbGoTop() )

	// abre o dicionário SX3
	OpenSXs(NIL, NIL, NIL, NIL, cEmpAnt, cAliasSX3, "SX3", NIL, .F.)

	// caso aberto, posiciona no topo
	If !(Select(cAliasSX3) > 0)
		Return .F.
	EndIf
	DbSelectArea(cAliasSX3)
	(cAliasSX3)->( DbSetOrder( 2 ) ) //X3_CAMPO
	(cAliasSX3)->( DbGoTop() )

	// abre o dicionário SX6
	OpenSXs(NIL, NIL, NIL, NIL, cEmpAnt, cAliasSX6, "SX6", NIL, .F.)

	// caso aberto, posiciona no topo
	If !(Select(cAliasSX6) > 0)
		Return .F.
	EndIf
	DbSelectArea(cAliasSX6)
	(cAliasSX6)->( DbSetOrder( 1 ) ) //X6_FIL+X6_VAR
	(cAliasSX6)->( DbGoTop() )

	// abre o dicionário SXB
	OpenSXs(NIL, NIL, NIL, NIL, cEmpAnt, cAliasSXB, "SXB", NIL, .F.)

	// caso aberto, posiciona no topo
	If !(Select(cAliasSXB) > 0)
		Return .F.
	EndIf
	DbSelectArea(cAliasSXB)
	(cAliasSXB)->( DbSetOrder( 1 ) ) //XB_ALIAS+XB_TIPO+XB_SEQ+XB_COLUNA
	(cAliasSXB)->( DbGoTop() )

	// abre o dicionário SIX
	OpenSXs(NIL, NIL, NIL, NIL, cEmpAnt, cAliasSIX, "SIX", NIL, .F.)

	// caso aberto, posiciona no topo
	If !(Select(cAliasSIX) > 0)
		Return .F.
	EndIf
	DbSelectArea(cAliasSIX)
	(cAliasSIX)->( DbSetOrder( 1 ) ) //INDICE+ORDEM
	(cAliasSIX)->( DbGoTop() )

	// abre o dicionário SX7
	OpenSXs(NIL, NIL, NIL, NIL, cEmpAnt, cAliasSX7, "SX7", NIL, .F.)

	// caso aberto, posiciona no topo
	If !(Select(cAliasSX7) > 0)
		Return .F.
	EndIf
	DbSelectArea(cAliasSX7)
	(cAliasSX7)->( DbSetOrder( 1 ) ) //X7_CAMPO+X7_SEQUENC
	(cAliasSX7)->( DbGoTop() )

	For nX := 1 To Len(aDados[1])

		if (cAliasSX2)->(DbSeek(aDados[1][nX][1]))
			lLock := RecLock(cAliasSX2,.F.)
		else
			lLock := RecLock(cAliasSX2,.T.)
		endif

		if lLock

			For nY := 1 To Len(aDados[1][nX][2])
				&(aDados[1][nX][2][nY][1]) := aDados[1][nX][2][nY][2]
			Next nY

			(cAliasSX2)->(MsUnLock())

		endif

	Next nX

	For nX := 1 To Len(aDados[2])

		if (cAliasSX3)->(DbSeek(aDados[2][nX][1]))
			lLock := RecLock(cAliasSX3,.F.) // Altera
		else
			lLock := RecLock(cAliasSX3,.T.) // Inclui
		endif

		if lLock

			For nY := 1 To Len(aDados[2][nX][2])
				&(aDados[2][nX][2][nY][1]) := aDados[2][nX][2][nY][2]
			Next nY

			(cAliasSX3)->(MsUnLock())

		endif

	Next nX

	For nX := 1 To Len(aDados[3])

		if (cAliasSX6)->(DbSeek(aDados[3][nX][1]))
			//Uso NÃO PERMITIDO de chamada de API de Console --conout(">> ALTERACAO - " + aDados[3][nX][1])
			lLock := RecLock(cAliasSX6,.F.) // Altera
		else
			//Uso NÃO PERMITIDO de chamada de API de Console --conout(">> INCLUSAO - " + aDados[3][nX][1])
			lLock := RecLock(cAliasSX6,.T.) // Inclui
		endif

		if lLock

			For nY := 1 To Len(aDados[3][nX][2])
				&(aDados[3][nX][2][nY][1]) := aDados[3][nX][2][nY][2]
			Next nY

			(cAliasSX6)->(MsUnLock())

		endif

	Next nX

	For nX := 1 To Len(aDados[4])

		if (cAliasSXB)->(DbSeek(aDados[4][nX][1]))
			//Uso NÃO PERMITIDO de chamada de API de Console --conout(">> ALTERACAO - " + aDados[4][nX][1])
			lLock := RecLock(cAliasSXB,.F.) // Altera
		else
			//Uso NÃO PERMITIDO de chamada de API de Console --conout(">> INCLUSAO - " + aDados[4][nX][1])
			lLock := RecLock(cAliasSXB,.T.) // Inclui
		endif

		if lLock

			For nY := 1 To Len(aDados[4][nX][2])
				&(aDados[4][nX][2][nY][1]) := aDados[4][nX][2][nY][2]
			Next nY

			(cAliasSXB)->(MsUnLock())

		endif

	Next nX

	For nX := 1 To Len(aDados[5])

		if (cAliasSIX)->(DbSeek(aDados[5][nX][1]))
			lLock := RecLock(cAliasSIX,.F.)
		else
			lLock := RecLock(cAliasSIX,.T.)
		endif

		if lLock

			For nY := 1 To Len(aDados[5][nX][2])
				&(aDados[5][nX][2][nY][1]) := aDados[5][nX][2][nY][2]
			Next nY

			(cAliasSIX)->(MsUnLock())

		endif

	Next nX

	For nX := 1 To Len(aDados[6])

		if (cAliasSX7)->(DbSeek(aDados[6][nX][1]))
			lLock := RecLock(cAliasSX7,.F.)
		else
			lLock := RecLock(cAliasSX7,.T.)
		endif

		if lLock

			For nY := 1 To Len(aDados[6][nX][2])
				&(aDados[6][nX][2][nY][1]) := aDados[6][nX][2][nY][2]
			Next nY

			(cAliasSX7)->(MsUnLock())

		endif

	Next nX

	RestArea(aArea)

Return(aRet)


/*/{Protheus.doc} MyOpenSM0
Função que verifica se a empresa está com acesso exclusivo.

@author pablo
@since 27/09/2018
@version 1.0
@return ${return}, ${return_description}
@param lShared, logical, descricao
@param cErro, characters, descricao
@type function
/*/
Static Function MyOpenSM0(lShared,cErro)

	Local lOpen 	:= .F.
	Local nLoop 		:= 0
	Default cErro	:= ""

	For nLoop := 1 To 20 //faz 20 tentativas

		If lShared
			OpenSm0() //Essa função realiza a abertura do SIGAMAT, utilizando como alias o SM0.
		Else
			OpenSM0Excl() //Essa função realiza a abertura do SIGAMAT em modo EXCLUSIVO, utilizando como alias o SM0.
		EndIf

		If !Empty( Select( "SM0" ) )
			lOpen := .T.
			Exit
		EndIf

		Sleep( 500 )

	Next nLoop

	If !lOpen
		cErro := "Nao foi possível a abertura da tabela " + iif( lShared, "de empresas (SM0).", "de empresas (SM0) de forma exclusiva." )
	EndIf

Return lOpen


/*/{Protheus.doc} SalvaCSV
Salva o dicionario em arquivo CSV local...

@author pablo
@since 27/09/2018
@version 1.0

@return ${return}, ${return_description}
@param cGetEmp2, characters, descricao
@param cGetFil2, characters, descricao
@param aRetorno1, array, descricao
@param cErro, characters, descricao
@type function
/*/
Static Function SalvaCSV(cGetEmp2,cGetFil2,aRet,cErro)
	Local cPathSX := ""
	Local nX := 1, nY := 1, nZ := 1
	Local cCab := "", cLin := ""

	cPathSX := cGetFile( "Selecione Diretoriro CSV | " , OemToAnsi( "Selecione Diretorio CSV" ) , NIL , "C:\" , .F. , GETF_LOCALHARD+GETF_RETDIRECTORY )
	iif((len(cPathSX)>0) .and. (substr(cPathSX,Len(cPathSX),1)<>iif(IsSrvUnix(),"/","\")), cPathSX:=cPathSX+iif(IsSrvUnix(),"/","\"), )

	For nZ:=1 to Len(aRet)

		DO CASE
		case nZ == 1
			//aRet[1] -> SX2
			cNomeArq := "SX2.CSV" //"SX2_"+AllTrim(cGetEmp2)+"_"+AllTrim(cGetFil2)+".CSV"
		case nZ == 2
			//aRet[2] -> SX3
			cNomeArq := "SX3.CSV" //"SX3_"+AllTrim(cGetEmp2)+"_"+AllTrim(cGetFil2)+".CSV"
		case nZ == 3
			//aRet[3] -> SX6
			cNomeArq := "SX6.CSV" //"SX6_"+AllTrim(cGetEmp2)+"_"+AllTrim(cGetFil2)+".CSV"
		case nZ == 4
			//aRet[3] -> SXB
			cNomeArq := "SXB.CSV" //"SXB_"+AllTrim(cGetEmp2)+"_"+AllTrim(cGetFil2)+".CSV"
		case nZ == 5
			//aRet[5] -> SIX
			cNomeArq := "SIX.CSV" //"SIX_"+AllTrim(cGetEmp2)+"_"+AllTrim(cGetFil2)+".CSV"
		case nZ == 6
			//aRet[6] -> SX7
			cNomeArq := "SX7.CSV" //"SX7_"+AllTrim(cGetEmp2)+"_"+AllTrim(cGetFil2)+".CSV"
		ENDCASE

		cCab := ""; cLin := ""
		nPosX3Obr := 0 //--tratamento para caracter NUL dentro do campo X3_OBRIGAT
		nPosX3cB1 := 0 //--tratamento para caracteres ";" dentro dos campo X3_CBOX
		nPosX3cB2 := 0 //--tratamento para caracteres ";" dentro dos campo X3_CBOXSPA
		nPosX3cB3 := 0 //--tratamento para caracteres ";" dentro dos campo X3_CBOXENG
		nPosXBcB1 := 0 //--tratamento para caracteres ";" dentro dos campo XB_CONTEM
		For nX:=1 to Len(aRet[nZ])
			For nY:=1 to Len(aRet[nZ][nX][2])

				//-- preenche o array de cabeçalho
				If nX==1
					cCab += aRet[nZ][nX][2][nY][1] + iif(nY<>Len(aRet[nZ][nX][2]),";","")
					If AllTrim(aRet[nZ][nX][2][nY][1]) == "X3_OBRIGAT"
						nPosX3Obr := nY
					EndIf
					If AllTrim(aRet[nZ][nX][2][nY][1]) == "X3_CBOX"
						nPosX3cB1 := nY
					EndIf
					If AllTrim(aRet[nZ][nX][2][nY][1]) == "X3_CBOXSPA"
						nPosX3cB2 := nY
					EndIf
					If AllTrim(aRet[nZ][nX][2][nY][1]) == "X3_CBOXENG"
						nPosX3cB3 := nY
					EndIf
					If AllTrim(aRet[nZ][nX][2][nY][1]) == "XB_CONTEM"
						nPosXBcB1 := nY
					EndIf
				EndIf

				//-- preenche o array de linhas
				//--tratamento para caracter NUL dentro do campo X3_OBRIGAT
				If nPosX3Obr>0 .and. nPosX3Obr=nY
					cLin += ""  + iif(nY<>Len(aRet[nZ][nX][2]),";","")
					//--tratamento para caracteres ";" dentro dos campos: X3_CBOX, X3_CBOXSPA, X3_CBOXENG, XB_CONTEM
				ElseIf (nPosX3cB1>0 .and. nPosX3cB1=nY) .or. (nPosX3cB2>0 .and. nPosX3cB2=nY) .or. (nPosX3cB3>0 .and. nPosX3cB3=nY) .or. (nPosXBcB1>0 .and. nPosXBcB1=nY)
					cLin += StrTran( AllTrim(UtoString(aRet[nZ][nX][2][nY][2])), ";", "|" )  + iif(nY<>Len(aRet[nZ][nX][2]),";","")
				Else
					cLin += AllTrim(UtoString(aRet[nZ][nX][2][nY][2]))  + iif(nY<>Len(aRet[nZ][nX][2]),";","")
				EndIf

			Next nY
			cLin += iif(nX<>Len(aRet[nZ]),CRLF,"")
		Next nX

		cTexto := cCab + CRLF + cLin
		If !Empty(cCab) .and. !Empty(cLin)
			If FindFunction("U_UCriaLog")
				U_UCriaLog(cPathSX,cNomeArq,cTexto)
			ElseIf FindFunction("U_CriaLog")
				U_CriaLog(cPathSX,cNomeArq,cTexto)
			EndIf
		EndIf

	Next nZ

Return


/*/{Protheus.doc} UtoString
Funcao para transformar variavis em string.

@author pablo
@since 27/09/2018
@version 1.0
@return ${return}, ${return_description}
@param xValue, , descricao
@type function
/*/
Static Function UtoString(xValue)

	Local cRet, nI, cType
	Local cAspas := ''//'"'

	cType := valType(xValue)

	DO CASE
	case cType == "C"
		return cAspas+ xValue +cAspas
	case cType == "N"
		return CvalToChar(xValue)
	case cType == "L"
		return if(xValue,'.T.','.F.')
	case cType == "D"
		return cAspas+ DtoC(xValue) +cAspas
	case cType == "U"
		return "null"
	case cType == "A"
		cRet := '['
		For nI := 1 to len(xValue)
			if(nI != 1)
				cRet += ', '
			endif
			cRet += UtoString(xValue[nI])
		Next
		return cRet + ']'
	case cType == "B"
		return cAspas+'Type Block'+cAspas
	case cType == "M"
		return cAspas+'Type Memo'+cAspas
	case cType =="O"
		return cAspas+'Type Object'+cAspas
	case cType =="H"
		return cAspas+'Type Object'+cAspas
	ENDCASE

return "invalid type"

/*/{Protheus.doc} RetStrutDic
Retorna o nome das colunas de um dicionario em formato de array.

@author pablo
@since 12/05/2020
@version 1.0

@param cDicionario, nome do dicionário
@return aEstrut, array com as colunas do dicionário

@type function
/*/
Static Function RetStrutDic(cDicionario)

	Local aEstrut := {}

	DO CASE
	case cDicionario == "SIX"

		aEstrut := { "INDICE" , "ORDEM" , "CHAVE", "DESCRICAO", "DESCSPA"  , ;
			"DESCENG", "PROPRI", "F3"   , "NICKNAME" , "SHOWPESQ" }

	case cDicionario == "SX2"
		
		aEstrut := { "X2_CHAVE", "X2_PATH", "X2_ARQUIVO", "X2_NOME", "X2_NOMESPA", "X2_NOMEENG", ;
			"X2_ROTINA", "X2_MODO", "X2_MODOUN", "X2_MODOEMP", "X2_DELET", "X2_TTS", "X2_UNICO", ;
			"X2_PYME", "X2_MODULO", "X2_DISPLAY" }

	case cDicionario == "SX3"

		aEstrut := { "X3_ARQUIVO", "X3_ORDEM"  , "X3_CAMPO"  , "X3_TIPO"   , "X3_TAMANHO", "X3_DECIMAL", ;
			"X3_TITULO" , "X3_TITSPA" , "X3_TITENG" , "X3_DESCRIC", "X3_DESCSPA", "X3_DESCENG", ;
			"X3_PICTURE", "X3_VALID"  , "X3_USADO"  , "X3_RELACAO", "X3_F3"     , "X3_NIVEL"  , ;
			"X3_RESERV" , "X3_CHECK"  , "X3_TRIGGER", "X3_PROPRI" , "X3_BROWSE" , "X3_VISUAL" , ;
			"X3_CONTEXT", "X3_OBRIGAT", "X3_VLDUSER", "X3_CBOX"   , "X3_CBOXSPA", "X3_CBOXENG", ;
			"X3_PICTVAR", "X3_WHEN"   , "X3_INIBRW" , "X3_GRPSXG" , "X3_FOLDER" , "X3_PYME"   , ;
			"X3_CONDSQL", "X3_CHKSQL" , "X3_IDXSRV" , "X3_ORTOGRA", "X3_IDXFLD" , "X3_TELA"   , ;
			"X3_AGRUP" } // "X3_POSLGT"

	case cDicionario == "SXG"

		aEstSXG := { "XG_GRUPO", "XG_DESCRI", "XG_DESSPA", "XG_DESENG", "XG_SIZEMAX", ;
			"XG_SIZEMIN", "XG_SIZE", "XG_PICTURE", "XG_CHECK1", "XG_CHECK2" }

	case cDicionario == "SX6"

		aEstrut := { "X6_FIL", "X6_VAR", "X6_TIPO", "X6_DESCRIC", "X6_DSCSPA", "X6_DSCENG", "X6_DESC1", "X6_DSCSPA1", ;
			"X6_DSCENG1", "X6_DESC2", "X6_DSCSPA2", "X6_DSCENG2", "X6_CONTEUD", "X6_CONTSPA", "X6_CONTENG", "X6_PROPRI", ;
			"X6_VALID", "X6_INIT", "X6_DEFPOR", "X6_DEFSPA", "X6_DEFENG" }

	case cDicionario == "SX7"

		aEstrut := { "X7_CAMPO", "X7_SEQUENC", "X7_REGRA", "X7_CDOMIN", "X7_TIPO", "X7_SEEK", ;
			"X7_ALIAS", "X7_ORDEM"  , "X7_CHAVE", "X7_CONDIC", "X7_PROPRI" }

	case cDicionario == "SXA"

		aEstrut := { "XA_ALIAS", "XA_ORDEM", "XA_DESCRIC", "XA_DESCSPA", ;
			"XA_DESCENG", "XA_PROPRI", "XA_AGRUP", "XA_TIPO" }

	case cDicionario == "SXB"

		aEstrut := { "XB_ALIAS", "XB_TIPO", "XB_SEQ", "XB_COLUNA", ;
			"XB_DESCRI", "XB_DESCSPA", "XB_DESCENG", "XB_CONTEM", "XB_WCONTEM" }

	ENDCASE

Return aEstrut

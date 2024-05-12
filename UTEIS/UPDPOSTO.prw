#INCLUDE "TOTVS.CH"
#INCLUDE "topconn.ch"
#INCLUDE "TbiConn.ch"

#DEFINE SIMPLES Char( 39 )
#DEFINE DUPLAS  Char( 34 )

/*/{Protheus.doc} UPDPOSTO
Função de update dos dicionários para compatibilização do Posto Inteligente.

@author Totvs TBC
@since 31/10/2017
@version 1.0

@param cEmpAmb, characters, empresa
@param cFilAmb, characters, filial

@type function
/*/
User Function UPDPOSTO( cEmpAmb, cFilAmb )

	Local   aSay      := {}
	Local   aButton   := {}
	Local   aMarcadas := {}
	Local   cTitulo   := "ATUALIZAÇÃO DE DICIONÁRIOS E TABELAS - POSTO INTELIGENTE"
	Local   cDesc1    := "Esta rotina tem como função fazer  a atualização  dos dicionários do Sistema ( SX?/SIX )"
	Local   cDesc2    := "Este processo deve ser executado em modo EXCLUSIVO, ou seja não podem haver outros"
	Local   cDesc3    := "usuários  ou  jobs utilizando  o sistema.  É extremamente recomendavél  que  se  faça um"
	Local   cDesc4    := "BACKUP  dos DICIONÁRIOS  e da  BASE DE DADOS antes desta atualização, para que caso "
	Local   cDesc5    := "ocorra eventuais falhas, esse backup seja ser restaurado."
	Local   cDesc6    := ""
	Local   cDesc7    := ""
	Local   lOk       := .F.
	Local   lAuto     := ( cEmpAmb <> NIL .or. cFilAmb <> NIL )

	Private	cPathSX	  := ""

	Private oMainWnd  := NIL
	Private oProcess  := NIL

	#IFDEF TOP
		TCInternal( 5, "*OFF" ) // Desliga Refresh no Lock do Top
	#ENDIF

	__cInterNet := NIL
	__lPYME     := .F.

	Set Dele On

	// Mensagens de Tela Inicial
	aAdd( aSay, "ATUALIZAÇÃO DE DICIONÁRIOS E TABELAS - POSTO INTELIGENTE")
	aAdd( aSay, "" )
	aAdd( aSay, cDesc1 )
	aAdd( aSay, cDesc2 )
	aAdd( aSay, cDesc3 )
	aAdd( aSay, cDesc4 )
	aAdd( aSay, cDesc5 )
	//aAdd( aSay, cDesc6 )
	//aAdd( aSay, cDesc7 )

	// Botoes Tela Inicial
	aAdd(  aButton, {  1, .T., { || lOk := .T., FechaBatch() } } )
	aAdd(  aButton, {  2, .T., { || lOk := .F., FechaBatch() } } )

	If lAuto
		lOk := .T.
	Else
		FormBatch(  cTitulo,  aSay,  aButton )
	EndIf

	If lOk
		If lAuto
			aMarcadas :={{ cEmpAmb, cFilAmb, "" }}
		Else
			aMarcadas := EscEmpresa()
		EndIf

		If !Empty( aMarcadas )

			cPathSX := cGetFile( "Selecione o Diretorio | " , OemToAnsi( "Selecione diretório onde estão os dicionários no formato CSV" ) , NIL , "C:\" , .F. , GETF_LOCALHARD+GETF_RETDIRECTORY )

			If lAuto .OR. MsgNoYes( "Confirma a atualização dos dicionários ?", cTitulo )
				oProcess := MsNewProcess():New( { | lEnd | lOk := FSTProc( @lEnd, aMarcadas ) }, "Atualizando", "Aguarde, atualizando ...", .F. )
				oProcess:Activate()

				If lAuto
					If lOk
						Help(NIL, NIL, "UPDPOSTO", NIL, "Atualização Realizada.", 1, 0, NIL, NIL, NIL, NIL, NIL, {""})
						dbCloseAll()
					Else
						Help(NIL, NIL, "UPDPOSTO", NIL, "Atualização não Realizada.", 1, 0, NIL, NIL, NIL, NIL, NIL, {""})
						dbCloseAll()
					EndIf
				Else
					If lOk
						Final( "Atualização Concluída." )
					Else
						Final( "Atualização não Realizada." )
					EndIf
				EndIf

			Else
				Help(NIL, NIL, "UPDPOSTO", NIL, "Atualização não Realizada.", 1, 0, NIL, NIL, NIL, NIL, NIL, {""})

			EndIf

		Else
			Help(NIL, NIL, "UPDPOSTO", NIL, "Atualização não Realizada.", 1, 0, NIL, NIL, NIL, NIL, NIL, {""})

		EndIf

	EndIf

Return NIL


/*/{Protheus.doc} FSTProc
Funcao de processamento da gravação dos arquivos.

@author Totvs TBC
@since 31/10/2017
@version 1.0

@return ${return}, ${return_description}
@param lEnd, logical, descricao
@param aMarcadas, array, descricao

@type function
/*/
Static Function FSTProc( lEnd, aMarcadas )

	Local   aInfo     := {}
	Local   aRecnoSM0 := {}
	Local   cAux      := ""
	Local   cFile     := ""
	Local   cFileLog  := ""
	Local   cMask     := "Arquivos Texto" + "(*.TXT)|*.txt|"
	Local   cTCBuild  := "TCGetBuild"
	Local   cTexto    := ""
	Local   cTopBuild := ""
	Local   lOpen     := .F.
	Local   lRet      := .T.
	Local   nI        := 0
	Local   nPos      := 0
	Local   nX        := 0
	Local   oDlg      := NIL
	Local   oFont     := NIL
	Local   oMemo     := NIL

	Private aArqUpd   := {}

	If ( lOpen := MyOpenSm0(.T.) )

		dbSelectArea( "SM0" )
		SM0->(dbGoTop())

		While !SM0->( EOF() )
			// So adiciona no aRecnoSM0 se a empresa for diferente
			If aScan( aRecnoSM0, { |x| x[2] == SM0->M0_CODIGO } ) == 0 ;
					.AND. aScan( aMarcadas, { |x| x[1] == SM0->M0_CODIGO } ) > 0
				aAdd( aRecnoSM0, { Recno(), SM0->M0_CODIGO } )
			EndIf
			SM0->( dbSkip() )
		End

		SM0->( dbCloseArea() )

		If lOpen

			For nI := 1 To Len( aRecnoSM0 )

				If !( lOpen := MyOpenSm0(.F.) )
					Help(NIL, NIL, "ATENÇÃO", NIL, "Atualização da empresa " + aRecnoSM0[nI][2] + " não efetuada.", 1, 0, NIL, NIL, NIL, NIL, NIL, {""})
					Exit
				EndIf

				SM0->( dbGoTo( aRecnoSM0[nI][1] ) )

				// preparo o ambiente para empresa e filial
				//RpcSetType(3)
				//RpcSetEnv( SM0->M0_CODIGO, SM0->M0_CODFIL )

				cEmpAnt := AllTrim(SM0->M0_CODIGO)
				cFilAnt := AllTrim(SM0->M0_CODFIL)

				//-- Preparar ambiente local na retagauarda
				RpcSetType(3)
				PREPARE ENVIRONMENT EMPRESA cEmpAnt FILIAL cFilAnt MODULO "CFG"

				lMsFinalAuto := .F.
				lMsHelpAuto  := .F.

				cTexto += Replicate( "-", 128 ) + CRLF
				cTexto += "Empresa : " + SM0->M0_CODIGO + "/" + SM0->M0_NOME + CRLF + CRLF

				oProcess:SetRegua1( 8 )

				//------------------------------------
				// Atualiza o dicionário SX2
				//------------------------------------
				oProcess:IncRegua1( "Dicionário de arquivos" + " - " + SM0->M0_CODIGO + " " + SM0->M0_NOME + " ..." )
				FSAtuSX2( @cTexto )

				//------------------------------------
				// Atualiza o dicionário SX3
				//------------------------------------
				FSAtuSX3( @cTexto )

				//------------------------------------
				// Atualiza o dicionário SIX
				//------------------------------------
				oProcess:IncRegua1( "Dicionário de índices" + " - " + SM0->M0_CODIGO + " " + SM0->M0_NOME + " ..." )
				FSAtuSIX( @cTexto )

				oProcess:IncRegua1( "Dicionário de dados" + " - " + SM0->M0_CODIGO + " " + SM0->M0_NOME + " ..." )
				oProcess:IncRegua2( "Atualizando campos/índices" )

				//Bloqueia alterações no Dicionário
				__SetX31Mode( .F. )

				If FindFunction(cTCBuild)
					cTopBuild := &cTCBuild.()
				EndIf

				//Uso NÃO PERMITIDO de chamada de API de Console --conout(" >> UPDPOSTO - aArqUpd:")
				//Uso NÃO PERMITIDO de chamada de API de Console --conout(UtoString(aArqUpd))

				For nX := 1 To Len( aArqUpd )

					If cTopBuild >= "20090811" .AND. TcInternal( 89 ) == "CLOB_SUPPORTED"
						If ( ( aArqUpd[nX] >= "NQ " .AND. aArqUpd[nX] <= "NZZ" ) .OR. ( aArqUpd[nX] >= "O0 " .AND. aArqUpd[nX] <= "NZZ" ) ) .AND.;
								!aArqUpd[nX] $ "NQD,NQF,NQP,NQT"
							TcInternal( 25, "CLOB" )
						EndIf
					EndIf

					If Select( aArqUpd[nX] ) > 0
						dbSelectArea( aArqUpd[nX] )
						dbCloseArea()
					EndIf

					//Uso NÃO PERMITIDO de chamada de API de Console --conout(" >> UPDPOSTO - X31UpdTable: "+aArqUpd[nX])
					X31UpdTable( aArqUpd[nX] )

					If __GetX31Error()
						//Alert( __GetX31Trace() )
						Help(NIL, NIL, "ATENÇÃO", NIL, "Ocorreu um erro desconhecido durante a atualização da tabela : " + aArqUpd[nX] + ". Verifique a integridade do dicionário e da tabela.", 1, 0, NIL, NIL, NIL, NIL, NIL, {""})
						cTexto += "Ocorreu um erro desconhecido durante a atualização da estrutura da tabela : " + aArqUpd[nX] + CRLF
					EndIf

					If cTopBuild >= "20090811" .AND. TcInternal( 89 ) == "CLOB_SUPPORTED"
						TcInternal( 25, "OFF" )
					EndIf

				Next nX

				//Desbloqueando alterações no dicionário
				__SetX31Mode(.T.)

				//------------------------------------
				//³Atualiza o dicionário SX6
				//------------------------------------
				oProcess:IncRegua1( "Dicionário de parâmetros" + " - " + SM0->M0_CODIGO + " " + SM0->M0_NOME + " ..." )
				FSAtuSX6( @cTexto )

				//------------------------------------
				// Atualiza o dicionário SX7
				//------------------------------------
				oProcess:IncRegua1( "Dicionário de gatilhos" + " - " + SM0->M0_CODIGO + " " + SM0->M0_NOME + " ..." )
				FSAtuSX7( @cTexto )

				//------------------------------------
				// Atualiza o dicionário SXA
				//------------------------------------
				oProcess:IncRegua1( "Dicionário de Pastas e Agrupamentos de campos" + " - " + SM0->M0_CODIGO + " " + SM0->M0_NOME + " ..." )
				FSAtuSXA( @cTexto )

				//------------------------------------
				// Atualiza o dicionário SXB
				//------------------------------------
				oProcess:IncRegua1( "Dicionário de consultas padrão" + " - " + SM0->M0_CODIGO + " " + SM0->M0_NOME + " ..." )
				FSAtuSXB( @cTexto )

				//------------------------------------
				// Atualiza os helps
				//------------------------------------
				oProcess:IncRegua1( "Helps de Campo" + " - " + SM0->M0_CODIGO + " " + SM0->M0_NOME + " ..." )
				FSAtuHlp( @cTexto )

				RpcClearEnv()

			Next nI

			If MyOpenSm0(.T.)

				cAux += Replicate( "-", 128 ) + CRLF
				cAux += Replicate( " ", 128 ) + CRLF
				cAux += "LOG DA ATUALIZACAO DOS DICIONÁRIOS" + CRLF
				cAux += Replicate( " ", 128 ) + CRLF
				cAux += Replicate( "-", 128 ) + CRLF
				cAux += CRLF
				cAux += " Dados Ambiente" + CRLF
				cAux += " --------------------"  + CRLF
				cAux += " Empresa / Filial...: " + cEmpAnt + "/" + cFilAnt  + CRLF
				cAux += " Nome Empresa.......: " + Capital( AllTrim( GetAdvFVal( "SM0", "M0_NOMECOM", cEmpAnt + cFilAnt, 1, "" ) ) ) + CRLF
				cAux += " Nome Filial........: " + Capital( AllTrim( GetAdvFVal( "SM0", "M0_FILIAL" , cEmpAnt + cFilAnt, 1, "" ) ) ) + CRLF
				cAux += " DataBase...........: " + DtoC( dDataBase )  + CRLF
				cAux += " Data / Hora Inicio.: " + DtoC( Date() )  + " / " + Time()  + CRLF
				cAux += " Environment........: " + GetEnvServer()  + CRLF
				cAux += " StartPath..........: " + GetSrvProfString( "StartPath", "" )  + CRLF
				cAux += " RootPath...........: " + GetSrvProfString( "RootPath" , "" )  + CRLF
				cAux += " Versao.............: " + GetVersao(.T.)  + CRLF
				cAux += " Usuario TOTVS .....: " + __cUserId + " " +  cUserName + CRLF
				cAux += " Computer Name......: " + GetComputerName() + CRLF

				aInfo   := GetUserInfo()
				If ( nPos    := aScan( aInfo,{ |x,y| x[3] == ThreadId() } ) ) > 0
					cAux += " "  + CRLF
					cAux += " Dados Thread" + CRLF
					cAux += " --------------------"  + CRLF
					cAux += " Usuario da Rede....: " + aInfo[nPos][1] + CRLF
					cAux += " Estacao............: " + aInfo[nPos][2] + CRLF
					cAux += " Programa Inicial...: " + aInfo[nPos][5] + CRLF
					cAux += " Environment........: " + aInfo[nPos][6] + CRLF
					cAux += " Conexao............: " + AllTrim( StrTran( StrTran( aInfo[nPos][7], Chr( 13 ), "" ), Chr( 10 ), "" ) )  + CRLF
				EndIf
				cAux += Replicate( "-", 128 ) + CRLF
				cAux += CRLF

				cTexto := cAux + cTexto + CRLF

				cTexto += Replicate( "-", 128 ) + CRLF
				cTexto += " Data / Hora Final.: " + DtoC( Date() ) + " / " + Time()  + CRLF
				cTexto += Replicate( "-", 128 ) + CRLF

				cFileLog := MemoWrite( CriaTrab( , .F. ) + ".log", cTexto )

				Define Font oFont Name "Mono AS" Size 5, 12

				Define MsDialog oDlg Title "Atualizacao concluida." From 3, 0 to 340, 417 Pixel

				@ 5, 5 Get oMemo Var cTexto Memo Size 200, 145 Of oDlg Pixel
				oMemo:bRClicked := { || AllwaysTrue() }
				oMemo:oFont     := oFont

				Define SButton From 153, 175 Type  1 Action oDlg:End() Enable Of oDlg Pixel // Apaga
				Define SButton From 153, 145 Type 13 Action ( cFile := cGetFile( cMask, "" ), If( cFile == "", .T., ;
					MemoWrite( cFile, cTexto ) ) ) Enable Of oDlg Pixel

				Activate MsDialog oDlg Center

			EndIf

		EndIf

	Else

		lRet := .F.

	EndIf

Return lRet


/*/{Protheus.doc} FSAtuSX2
Função de processamento da gravação do SX2 - Arquivos.

@author Totvs TBC
@since 31/10/2017
@version 1.0

@return ${return}, ${return_description}
@param cTexto, characters, descricao

@type function
/*/
Static Function FSAtuSX2( cTexto )

	Local aEstrut   := {}
	Local aSX2      := {}
	Local cAlias    := ""
	Local cEmpr     := ""
	Local cPath     := ""
	Local nI        := 0
	Local nJ        := 0
	Local cAliasSX2 := GetNextAlias() // apelido para o arquivo de trabalho
	Local lOpen   	:= .F. // valida se foi aberto a tabela
	Local nPosUnico := 0

	cTexto  += "Ínicio da Atualização" + " SX2" + CRLF + CRLF

	aEstrut := RetStrutDic("SX2")

	// abre o dicionário SX2
	OpenSXs(NIL, NIL, NIL, NIL, cEmpAnt, cAliasSX2, "SX2", NIL, .F.)
	lOpen := Select(cAliasSX2) > 0

	// caso aberto, posiciona no topo
	If !(lOpen)
		Return .F.
	EndIf
	DbSelectArea(cAliasSX2)
	(cAliasSX2)->( DbSetOrder( 1 ) ) //X2_CHAVE
	(cAliasSX2)->( DbGoTop() )

	cPath := (cAliasSX2)->&("X2_PATH") //pega o patch do primeiro registro
	cPath := IIf( Right( AllTrim( cPath ), 1 ) <> "\", PadR( AllTrim( cPath ) + "\", Len( cPath ) ), cPath )
	cEmpr := Substr( (cAliasSX2)->&("X2_ARQUIVO"), 4 )


	aSX2 := AbreCSV(cPathSX+"SX2.CSV",@aEstrut)

	nPosUnico := aScan(aEstrut, {|x| AllTrim(x) == "X2_UNICO" })

	//
	// Atualizando dicionário
	//
	oProcess:SetRegua2( Len( aSX2 ) )

	DbSelectArea(cAliasSX2)
	(cAliasSX2)->( DbSetOrder( 1 ) ) //X2_CHAVE

	For nI := 1 To Len( aSX2 )

		oProcess:IncRegua2( "Atualizando Arquivos (SX2)..." )

		If !(cAliasSX2)->( dbSeek( aSX2[nI][1] ) )

			If !( aSX2[nI][1] $ cAlias )
				cAlias += aSX2[nI][1] + "/"
				cTexto += "Foi incluída a tabela " + aSX2[nI][1] + CRLF
			EndIf

			RecLock( cAliasSX2, .T. )
			For nJ := 1 To Len( aSX2[nI] )
				If FieldPos( aEstrut[nJ] ) > 0
					If AllTrim( aEstrut[nJ] ) == "X2_ARQUIVO"
						FieldPut( FieldPos( aEstrut[nJ] ), SubStr( aSX2[nI][nJ], 1, 3 ) + cEmpAnt +  "0" )
					ElseIF AllTrim( aEstrut[nJ] ) == "X2_DELET" .or. AllTrim( aEstrut[nJ] ) == "X2_MODULO"
						FieldPut( FieldPos( aEstrut[nJ] ), Val(aSX2[nI][nJ]) )
					Else
						FieldPut( FieldPos( aEstrut[nJ] ), aSX2[nI][nJ] )
					EndIf
				EndIf
			Next nJ
			MsUnLock()

		Else

			If  !( StrTran( Upper( AllTrim( (cAliasSX2)->&("X2_UNICO") ) ), " ", "" ) == StrTran( Upper( AllTrim( aSX2[nI][nPosUnico]  ) ), " ", "" ) )

				RecLock( cAliasSX2, .F. )
				(cAliasSX2)->&("X2_UNICO") := aSX2[nI][nPosUnico]
				MsUnlock()
				cTexto += "Foi ajustado a chave unica do dicionário SX2: " + aSX2[nI][1] + CRLF

				#IFDEF TOP
					If TcCanOpen((cAliasSX2)->&("X2_ARQUIVO")) //Verifica existência da tabela no banco de dados
						//If MSFILE( RetSqlName( aSX2[nI][1] ),RetSqlName( aSX2[nI][1] ) + "_UNQ"  ) //retorna: verdadeiro se arquivo/tabela ou índice foi encontrado
						TcInternal( 60, RetSqlName( aSX2[nI][1] ) + "|" + RetSqlName( aSX2[nI][1] ) + "_UNQ" )
						cTexto += "Foi alterada chave unica da tabela " + aSX2[nI][1] + CRLF
					EndIf
					cTexto += "Foi criada chave unica da tabela " + aSX2[nI][1] + CRLF
				Else
				#ENDIF

			EndIf

		EndIf

	Next nI

	cTexto += CRLF + "Final da Atualização" + " SX2" + CRLF + Replicate( "-", 128 ) + CRLF + CRLF

Return NIL


/*/{Protheus.doc} FSAtuSX3
Funcao de processamento da gravacao do SX3 - Campos.

@author Totvs TBC
@since 31/10/2017
@version 1.0

@return ${return}, ${return_description}
@param cTexto, characters, descricao

@type function
/*/
Static Function FSAtuSX3( cTexto )

	Local aEstrut   := {}
	Local aEstSXG	:= {}
	Local aSX3      := {}
	Local cAlias    := ""
	Local cAliasAtu := ""
	Local cMsg      := ""
	Local cSeqAtu   := ""
	Local lTodosNao := .F.
	Local lTodosSim := .F.
	Local nI        := 0
	Local nJ        := 0
	Local nX        := 0
	Local nOpcA     := 0
	Local nPosArq   := 0
	Local nPosCpo   := 0
	Local nPosOrd   := 0
	Local nPosSXG   := 0
	Local nPosTam   := 0
	Local nSeqAtu   := 0
	Local nTamSeek  := 0
	Local cAliasSX3 := GetNextAlias() // apelido para o arquivo de trabalho
	Local cAliasSXG := GetNextAlias() // apelido para o arquivo de trabalho
	Local lOpen   	:= .F. // valida se foi aberto a tabela

	cTexto  += "Inicio da Atualizacao" + " SX3" + CRLF + CRLF

	aEstrut := RetStrutDic("SX3")
	aEstSXG := RetStrutDic("SXG")

	aSX3 := AbreCSV(cPathSX+"SX3.CSV",@aEstrut)

	//
	// Como o arquivo que gerar o dicionado é CSV (separado por ponto-e-virgula), 
	// foi necessário ajustar as colunas de combobox para separação com pipelilne.
	// Neste ponto eu altero o caracter pipiline por ponto-e-virgula novamente.
	//
	nPosBoxP := aScan( aEstrut, { |x| AllTrim( x ) == "X3_CBOX" } )
	nPosBoxS := aScan( aEstrut, { |x| AllTrim( x ) == "X3_CBOXSPA" } )
	nPosBoxE := aScan( aEstrut, { |x| AllTrim( x ) == "X3_CBOXENG" } )

	For nX := 1 to Len( aSX3 )
		If !Empty(aSX3[nX][nPosBoxP])
			aSX3[nX][nPosBoxP] :=  StrTran( aSX3[nX][nPosBoxP], "|", ";" )
		EndIf
		If !Empty(aSX3[nX][nPosBoxS])
			aSX3[nX][nPosBoxS] :=  StrTran( aSX3[nX][nPosBoxS], "|", ";" )
		EndIf
		If !Empty(aSX3[nX][nPosBoxE])
			aSX3[nX][nPosBoxE] :=  StrTran( aSX3[nX][nPosBoxE], "|", ";" )
		EndIf
	Next nX

	/* COMENTADO POR DANILO, PARA PROJETO 2210 SEMPRE SERÁ DICIONARIO NO BANCO
	//
	// Quando dicionário no banco de dados, 
	// ajusto os campos: X3_RESERV e X3_USADO 
	//
	nPosRese := aScan( aEstrut, { |x| AllTrim( x ) == "X3_RESERV" } )
	nPosUsad := aScan( aEstrut, { |x| AllTrim( x ) == "X3_USADO" } )
	//Retorna a extensão em uso para as tabelas acessadas através do driver ou RDD "DBFCDX"
	cDBExt := GetSrvProfString( "LocalDBExtension", ".dbf" ) //GetDBExtension()
	cDBExt := Lower( cDBExt )

	If (FindFunction("MPDicInDB") .AND. MPDicInDB() ) .OR. (cDBExt <> '.dbf' .and. cDBExt <> '.dtc') //dicionário não é DBF ou CTREE
		For nX := 1 to Len( aSX3 )
			aSX3[nX][nPosRese] := '  xxxx x        '
			If aSX3[nX][nPosUsad] == '€€€€€€€€€€€€€€€' //não usado
				aSX3[nX][nPosUsad] := 'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x       '
			Else
				aSX3[nX][nPosUsad] := 'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x     '
			EndIf
		Next nX
	EndIf
	*/

	//
	// Atualizando dicionário
	//
	nPosArq := aScan( aEstrut, { |x| AllTrim( x ) == "X3_ARQUIVO" } )
	nPosOrd := aScan( aEstrut, { |x| AllTrim( x ) == "X3_ORDEM"   } )
	nPosCpo := aScan( aEstrut, { |x| AllTrim( x ) == "X3_CAMPO"   } )
	nPosTam := aScan( aEstrut, { |x| AllTrim( x ) == "X3_TAMANHO" } )
	nPosSXG := aScan( aEstrut, { |x| AllTrim( x ) == "X3_GRPSXG"  } )

	For nX := 1 to Len( aSX3 )
		aSX3[nX][nPosOrd] := PadL(AllTrim(aSX3[nX][nPosOrd]),2,"0")
		Iif(!Empty(aSX3[nX][nPosSXG]),aSX3[nX][nPosSXG] := PadL(AllTrim(aSX3[nX][nPosSXG]),3,"0"),)
	Next nX

	aSort( aSX3,,, { |x,y| x[nPosArq]+x[nPosOrd]+x[nPosCpo] < y[nPosArq]+y[nPosOrd]+y[nPosCpo] } )

	oProcess:SetRegua2( Len( aSX3 ) )

	// abre o dicionário SX3
	OpenSXs(NIL, NIL, NIL, NIL, cEmpAnt, cAliasSX3, "SX3", NIL, .F.)
	lOpen := Select(cAliasSX3) > 0

	// caso aberto, posiciona no topo
	If !(lOpen)
		Return .F.
	EndIf
	DbSelectArea(cAliasSX3)
	(cAliasSX3)->( DbSetOrder( 2 ) ) //X3_CAMPO
	(cAliasSX3)->( DbGoTop() )

	// abre o dicionário SXG
	OpenSXs(NIL, NIL, NIL, NIL, cEmpAnt, cAliasSXG, "SXG", NIL, .F.)
	lOpen := Select(cAliasSXG) > 0

	// caso aberto, posiciona no topo
	If !(lOpen)
		Return .F.
	EndIf
	DbSelectArea(cAliasSXG)
	(cAliasSXG)->( dbSetOrder( 1 ) ) //XG_GRUPO
	(cAliasSXG)->( DbGoTop() )

	cAliasAtu := ""
	nTamSeek  := Len( (cAliasSX3)->&("X3_CAMPO") )

	For nI := 1 To Len( aSX3 )

		//
		// Verifica se o campo faz parte de um grupo e ajsuta tamanho
		//
		If !Empty( aSX3[nI][nPosSXG] )
			If (cAliasSXG)->( MSSeek( aSX3[nI][nPosSXG] ) )
				If Val(aSX3[nI][nPosTam]) <> (cAliasSXG)->&("XG_SIZE")
					aSX3[nI][nPosTam] := cValToChar( (cAliasSXG)->&("XG_SIZE") )
					cTexto += "O tamanho do campo " + aSX3[nI][nPosCpo] + " nao atualizado e foi mantido em ["
					cTexto += AllTrim( Str( (cAliasSXG)->&("XG_SIZE") ) ) + "]" + CRLF
					cTexto += "   por pertencer ao grupo de campos [" + aSX3[nI][nPosSXG] + "]" + CRLF + CRLF
				EndIf
			EndIf
		EndIf

		//Verifrica campos cujo tamanho é soma de varios campos
		if alltrim(aSX3[nI][nPosCpo]) $ "U56_PREFIX/U57_PREFIX"
			aSX3[nI][nPosTam] := 1 + Posicione(cAliasSX3, 2, PadR("E1_FILIAL",nTamSeek),"X3_TAMANHO")
		elseif alltrim(aSX3[nI][nPosCpo]) $ "E1_XCODBAR/UF2_CODBAR/EF_XCODBAR/U0H_CODBAR"
			//U57_PREFIX + U57_CODIGO (8) + U57_PARCEL (3)
			aSX3[nI][nPosTam] := 1 + Posicione(cAliasSX3, 2, PadR("E1_FILIAL",nTamSeek),"X3_TAMANHO") //U57_PREFIX
			aSX3[nI][nPosTam] += 8 //U57_CODIGO
			aSX3[nI][nPosTam] += Posicione(cAliasSX3, 2, PadR("E1_PARCELA",nTamSeek),"X3_TAMANHO") //U57_PARCEL
		endif

		(cAliasSX3)->( dbSetOrder( 2 ) ) //X3_CAMPO

		If !( aSX3[nI][nPosArq] $ cAlias ) .and. aScan( aArqUpd, { |x| AllTrim( x ) == aSX3[nI][nPosArq] } ) <= 0
			cAlias += aSX3[nI][nPosArq] + "/"
			aAdd( aArqUpd, aSX3[nI][nPosArq] )
		EndIf

		If !(cAliasSX3)->( dbSeek( PadR( aSX3[nI][nPosCpo], nTamSeek ) ) )

			//
			// Busca ultima ocorrencia do alias
			//
			If ( aSX3[nI][nPosArq] <> cAliasAtu )
				cSeqAtu   := "00"
				cAliasAtu := aSX3[nI][nPosArq]

				(cAliasSX3)->( dbSetOrder( 1 ) ) //X3_ARQUIVO+X3_ORDEM
				(cAliasSX3)->( dbSeek( cAliasAtu + "ZZ", .T. ) )
				(cAliasSX3)->( dbSkip( -1 ) )

				If ( (cAliasSX3)->&("X3_ARQUIVO") == cAliasAtu )
					cSeqAtu := (cAliasSX3)->&("X3_ORDEM")
				EndIf

				nSeqAtu := Val( RetAsc( cSeqAtu, 3, .F. ) )
			EndIf

			nSeqAtu++
			cSeqAtu := RetAsc( Str( nSeqAtu ), 2, .T. )

			RecLock( cAliasSX3, .T. )
			For nJ := 1 To Len( aSX3[nI] )
				If nJ == nPosOrd  // Ordem
					FieldPut( FieldPos( aEstrut[nJ] ), cSeqAtu )
				ElseIF AllTrim( aEstrut[nJ] ) == "X3_TAMANHO" .or. AllTrim( aEstrut[nJ] ) == "X3_DECIMAL" .or. AllTrim( aEstrut[nJ] ) == "X3_NIVEL"
					FieldPut( FieldPos( aEstrut[nJ] ), Val(aSX3[nI][nJ]) )
				ElseIf FieldPos( aEstrut[nJ] ) > 0
					FieldPut( FieldPos( aEstrut[nJ] ), aSX3[nI][nJ] )
				EndIf
			Next nJ

			dbCommit()
			MsUnLock()

			cTexto += "Criado o campo " + aSX3[nI][nPosCpo] + CRLF

		Else

			//
			// Verifica se o campo faz parte de um grupo e ajusta tamanho
			//
			If !Empty( (cAliasSX3)->&("X3_GRPSXG") ) .AND. (cAliasSX3)->&("X3_GRPSXG") <> aSX3[nI][nPosSXG]
				If (cAliasSXG)->( MSSeek( (cAliasSX3)->&("X3_GRPSXG") ) )
					If Val(aSX3[nI][nPosTam]) <> (cAliasSXG)->&("XG_SIZE")
						aSX3[nI][nPosTam] := cValToChar( (cAliasSXG)->&("XG_SIZE") )
						cTexto +=  "O tamanho do campo " + aSX3[nI][nPosCpo] + " nao atualizado e foi mantido em ["
						cTexto += AllTrim( Str( (cAliasSXG)->&("XG_SIZE") ) ) + "]"+ CRLF
						cTexto +=  "   por pertencer ao grupo de campos [" + (cAliasSX3)->&("X3_GRPSXG") + "]" + CRLF + CRLF
					EndIf
				EndIf
			EndIf

			//
			// Verifica todos os campos
			//
			For nJ := 1 To Len( aSX3[nI] )

				//
				// Se o campo estiver diferente da estrutura
				//
				If aEstrut[nJ] == (cAliasSX3)->( FieldName( nJ ) ) .AND. ;
						PadR( StrTran( AllToChar( (cAliasSX3)->( FieldGet( nJ ) ) ), " ", "" ), 250 ) <> ;
						PadR( StrTran( AllToChar( aSX3[nI][nJ] )           , " ", "" ), 250 ) .AND. ;
						AllTrim( (cAliasSX3)->( FieldName( nJ ) ) ) <> "X3_ORDEM"

					cMsg := "O campo " + aSX3[nI][nPosCpo] + " está com o " + (cAliasSX3)->( FieldName( nJ ) ) + ;
						" com o conteúdo" + CRLF + ;
						"[" + RTrim( AllToChar( (cAliasSX3)->( FieldGet( nJ ) ) ) ) + "]" + CRLF + ;
						"que será substituido pelo NOVO conteúdo" + CRLF + ;
						"[" + RTrim( AllToChar( aSX3[nI][nJ] ) ) + "]" + CRLF + ;
						"Deseja substituir ? "

					If      lTodosSim
						nOpcA := 1
					ElseIf  lTodosNao
						nOpcA := 2
					Else
						nOpcA := Aviso( "ATUALIZAÇÃO DE DICIONÁRIOS E TABELAS", cMsg, { "Sim", "Não", "Sim p/Todos", "Não p/Todos" }, 3, "Diferença de conteúdo - SX3" )
						lTodosSim := ( nOpcA == 3 )
						lTodosNao := ( nOpcA == 4 )

						If lTodosSim
							nOpcA := 1
							lTodosSim := MsgNoYes( "Foi selecionada a opção de REALIZAR TODAS alterações no SX3 e NÃO MOSTRAR mais a tela de aviso." + CRLF + "Confirma a ação [Sim p/Todos] ?" )
						EndIf

						If lTodosNao
							nOpcA := 2
							lTodosNao := MsgNoYes( "Foi selecionada a opção de NÃO REALIZAR nenhuma alteração no SX3 que esteja diferente da base e NÃO MOSTRAR mais a tela de aviso." + CRLF + "Confirma esta ação [Não p/Todos]?" )
						EndIf

					EndIf

					If nOpcA == 1
						cTexto += "Alterado o campo " + aSX3[nI][nPosCpo] + CRLF
						cTexto += "   " + PadR( (cAliasSX3)->( FieldName( nJ ) ), 10 ) + " de [" + AllToChar( (cAliasSX3)->( FieldGet( nJ ) ) ) + "]" + CRLF
						cTexto += "            para [" + AllToChar( aSX3[nI][nJ] )          + "]" + CRLF + CRLF

						RecLock( cAliasSX3, .F. )
						If AllTrim( aEstrut[nJ] ) == "X3_TAMANHO" .or. AllTrim( aEstrut[nJ] ) == "X3_DECIMAL" .or. AllTrim( aEstrut[nJ] ) == "X3_NIVEL"
							FieldPut( FieldPos( aEstrut[nJ] ), Val(aSX3[nI][nJ]) )
						Else
							FieldPut( FieldPos( aEstrut[nJ] ), aSX3[nI][nJ] )
						EndIf
						dbCommit()
						MsUnLock()
					EndIf

				EndIf

			Next

		EndIf

		oProcess:IncRegua2( "Atualizando Campos de Tabelas (SX3/SXG)..." )

	Next nI

	cTexto += CRLF + "Final da Atualizacao" + " SX3/SXG" + CRLF + Replicate( "-", 128 ) + CRLF + CRLF

Return NIL


/*/{Protheus.doc} FSAtuSIX
Funcao de processamento da gravacao do SIX - Indices.

@author Totvs TBC
@since 31/10/2017
@version 1.0

@return ${return}, ${return_description}
@param cTexto, characters, descricao

@type function
/*/
Static Function FSAtuSIX( cTexto )

	Local aEstrut   := {}
	Local aSIX      := {}
	Local lAlt      := .F.
	Local lDelInd   := .F.
	Local cAlias	:= ""
	Local nI        := 0
	Local nJ        := 0
	Local cAliasSIX := GetNextAlias() // apelido para o arquivo de trabalho
	Local lOpen   	:= .F. // valida se foi aberto a tabela

	cTexto  += "Inicio da Atualizacao" + " SIX" + CRLF + CRLF

	aEstrut := RetStrutDic("SIX")

	aSIX := AbreCSV(cPathSX+"SIX.CSV",@aEstrut)

	//
	// Atualizando dicionário
	//
	oProcess:SetRegua2( Len( aSIX ) )

	// abre o dicionário SIX
	OpenSXs(NIL, NIL, NIL, NIL, cEmpAnt, cAliasSIX, "SIX", NIL, .F.)
	lOpen := Select(cAliasSIX) > 0

	// caso aberto, posiciona no topo
	If !(lOpen)
		Return .F.
	EndIf
	DbSelectArea(cAliasSIX)
	(cAliasSIX)->( DbSetOrder( 1 ) ) //INDICE+ORDEM
	(cAliasSIX)->( DbGoTop() )

	For nI := 1 To Len( aSIX )

		lAlt    := .F.
		lDelInd := .F.

		nPosArq := aScan( aEstrut, { |x| AllTrim( x ) == "INDICE" } )

		If !( aSIX[nI][nPosArq] $ cAlias ) .and. aScan( aArqUpd, { |x| AllTrim( x ) == aSIX[nI][nPosArq] } ) <= 0
			cAlias += aSIX[nI][nPosArq] + "/"
			aAdd( aArqUpd, aSIX[nI][nPosArq] )
		EndIf

		If !(cAliasSIX)->( dbSeek( aSIX[nI][1] + aSIX[nI][2] ) )
			cTexto += "Índice criado " + aSIX[nI][1] + "/" + aSIX[nI][2] + " - " + aSIX[nI][3] + CRLF
		Else
			lAlt := .T.

			If !StrTran( Upper( AllTrim( CHAVE )       ), " ", "") == ;
					StrTran( Upper( AllTrim( aSIX[nI][3] ) ), " ", "" )
				cTexto += "Chave do índice alterado " + aSIX[nI][1] + "/" + aSIX[nI][2] + " - " + aSIX[nI][3] + CRLF
				lDelInd := .T. // Se for alteracao precisa apagar o indice do banco
			Else
				cTexto += "Indice alterado " + aSIX[nI][1] + "/" + aSIX[nI][2] + " - " + aSIX[nI][3] + CRLF
			EndIf
		EndIf

		RecLock( cAliasSIX, !lAlt )
		For nJ := 1 To Len( aSIX[nI] )
			If FieldPos( aEstrut[nJ] ) > 0
				FieldPut( FieldPos( aEstrut[nJ] ), aSIX[nI][nJ] )
			EndIf
		Next nJ
		MsUnLock()

		dbCommit()

		If lDelInd
			TcInternal( 60,  aSIX[nI][1] + "020" + "|" + aSIX[nI][1] + "020" + aSIX[nI][2] )
		EndIf

		oProcess:IncRegua2( "Atualizando índices..." )

	Next nI

	cTexto += CRLF + "Final da Atualizacao" + " SIX" + CRLF + Replicate( "-", 128 ) + CRLF + CRLF

Return NIL


/*/{Protheus.doc} FSAtuSX6
Funcao de processamento da gravacao do SX6 - Parâmetros.

@author Totvs TBC
@since 31/10/2017
@version 1.0

@return ${return}, ${return_description}
@param cTexto, characters, descricao

@type function
/*/
Static Function FSAtuSX6( cTexto )

	Local aEstrut   := {}
	Local aSX6      := {}
	Local cAlias    := ""
	Local cMsg      := ""
	Local lContinua := .T.
	Local lReclock  := .T.
	Local lTodosNao := .F.
	Local lTodosSim := .F.
	Local nI        := 0
	Local nJ        := 0
	Local nOpcA     := 0
	Local nTamFil   := 0
	Local nTamVar   := 0
	Local cAliasSX6 := GetNextAlias() // apelido para o arquivo de trabalho
	Local lOpen   	:= .F. // valida se foi aberto a tabela

	cTexto  += "Inicio da Atualizacao" + " SX6" + CRLF + CRLF

	aEstrut := RetStrutDic("SX6")

	aSX6 := AbreCSV(cPathSX+"SX6.CSV",@aEstrut)

	//
	// Atualizando dicionário
	//
	oProcess:SetRegua2( Len( aSX6 ) )

	// abre o dicionário SIX
	OpenSXs(NIL, NIL, NIL, NIL, cEmpAnt, cAliasSX6, "SX6", NIL, .F.)
	lOpen := Select(cAliasSX6) > 0

	// caso aberto, posiciona no topo
	If !(lOpen)
		Return .F.
	EndIf
	DbSelectArea(cAliasSX6)
	(cAliasSX6)->( DbSetOrder( 1 ) ) //X6_FIL+X6_VAR
	(cAliasSX6)->( DbGoTop() )

	nTamFil   := Len( (cAliasSX6)->&("X6_FIL") )
	nTamVar   := Len( (cAliasSX6)->&("X6_VAR") )

	For nI := 1 To Len( aSX6 )
		lContinua := .F.
		lReclock  := .F.

		If !(cAliasSX6)->( dbSeek( PadR( aSX6[nI][1], nTamFil ) + PadR( aSX6[nI][2], nTamVar ) ) )
			lContinua := .T.
			lReclock  := .T.
			cTexto += "Foi incluído o parâmetro " + aSX6[nI][1] + aSX6[nI][2] + " Conteúdo [" + AllTrim( aSX6[nI][13] ) + "]"+ CRLF
		EndIf

		If lContinua
			If !( aSX6[nI][1] $ cAlias )
				cAlias += aSX6[nI][1] + "/"
			EndIf

			RecLock( cAliasSX6, lReclock )
			For nJ := 1 To Len( aSX6[nI] )
				If FieldPos( aEstrut[nJ] ) > 0
					FieldPut( FieldPos( aEstrut[nJ] ), aSX6[nI][nJ] )
				EndIf
			Next nJ
			dbCommit()
			MsUnLock()
		EndIf

		oProcess:IncRegua2( "Atualizando Arquivos (SX6)..." )

	Next nI

	cTexto += CRLF + "Final da Atualizacao" + " SX6" + CRLF + Replicate( "-", 128 ) + CRLF + CRLF

Return NIL

/*/{Protheus.doc} FSAtuSX7
Funcao de processamento da gravacao do SX7 - Gatilhos.

@author Totvs TBC
@since 31/10/2017
@version 1.0

@return ${return}, ${return_description}
@param cTexto, characters, descricao

@type function
/*/
Static Function FSAtuSX7( cTexto )

	Local aEstrut   := {}
	Local aSX7      := {}
	Local cAlias    := ""
	Local nI        := 0
	Local nJ        := 0
	Local nTamSeek  := 0
	Local cAliasSX7 := GetNextAlias() // apelido para o arquivo de trabalho
	Local lOpen   	:= .F. // valida se foi aberto a tabela

	cTexto  += "Inicio da Atualizacao" + " SX7" + CRLF + CRLF

	aEstrut := RetStrutDic("SX7")

	aSX7 := AbreCSV(cPathSX+"SX7.CSV",@aEstrut)

	//
	// Atualizando dicionário
	//
	oProcess:SetRegua2( Len( aSX7 ) )

	// abre o dicionário SX7
	OpenSXs(NIL, NIL, NIL, NIL, cEmpAnt, cAliasSX7, "SX7", NIL, .F.)
	lOpen := Select(cAliasSX7) > 0

	// caso aberto, posiciona no topo
	If !(lOpen)
		Return .F.
	EndIf
	DbSelectArea(cAliasSX7)
	(cAliasSX7)->( DbSetOrder( 1 ) ) //X7_CAMPO+X7_SEQUENC
	(cAliasSX7)->( DbGoTop() )

	nTamSeek  := Len( (cAliasSX7)->&("X7_CAMPO") )

	For nI := 1 To Len( aSX7 )

		If !(cAliasSX7)->( dbSeek( PadR( aSX7[nI][1], nTamSeek ) + aSX7[nI][2] ) )

			If !( aSX7[nI][1] $ cAlias )
				cAlias += aSX7[nI][1] + "/"
				cTexto += "Foi incluído o gatilho " + aSX7[nI][1] + "/" + aSX7[nI][2] + CRLF
			EndIf

			RecLock( cAliasSX7, .T. )
		Else

			If !( aSX7[nI][1] $ cAlias )
				cAlias += aSX7[nI][1] + "/"
				cTexto += "Foi alterado o gatilho " + aSX7[nI][1] + "/" + aSX7[nI][2] + CRLF
			EndIf

			RecLock( cAliasSX7, .F. )
		EndIf

		For nJ := 1 To Len( aSX7[nI] )
			If FieldPos( aEstrut[nJ] ) > 0
				If AllTrim( aEstrut[nJ] ) == "X7_ORDEM"
					FieldPut( FieldPos( aEstrut[nJ] ), Val(aSX7[nI][nJ]) )
				Else
					FieldPut( FieldPos( aEstrut[nJ] ), aSX7[nI][nJ] )
				EndIf
			EndIf
		Next nJ

		dbCommit()
		MsUnLock()

		oProcess:IncRegua2( "Atualizando Arquivos (SX7)..." )

	Next nI

	cTexto += CRLF + "Final da Atualizacao" + " SX7" + CRLF + Replicate( "-", 128 ) + CRLF + CRLF

Return NIL


/*/{Protheus.doc} FSAtuSXA
Funcao de processamento da gravacao do SXA - Pastas e Agrupamentos de Campos.

@author Totvs TBC
@since 31/10/2017
@version 1.0
@return ${return}, ${return_description}
@param cTexto, characters, descricao
@type function
/*/
Static Function FSAtuSXA( cTexto )

	Local aEstrut   := {}
	Local aSXA      := {}
	Local cAlias    := ""
	Local cMsg      := ""
	Local lTodosNao := .F.
	Local lTodosSim := .F.
	Local nI        := 0
	Local nJ        := 0
	Local nOpcA     := 0
	Local cAliasSXA := GetNextAlias() // apelido para o arquivo de trabalho
	Local lOpen   	:= .F. // valida se foi aberto a tabela

	cTexto  += "Inicio da Atualizacao" + " SXA" + CRLF + CRLF

	aEstrut := RetStrutDic("SXA")

	aSXA := AbreCSV(cPathSX+"SXA.CSV",@aEstrut)

	//
	// Atualizando dicionário
	//
	oProcess:SetRegua2( Len( aSXA ) )

	// abre o dicionário SXA
	OpenSXs(NIL, NIL, NIL, NIL, cEmpAnt, cAliasSXA, "SXA", NIL, .F.)
	lOpen := Select(cAliasSXA) > 0

	// caso aberto, posiciona no topo
	If !(lOpen)
		Return .F.
	EndIf
	DbSelectArea(cAliasSXA)
	(cAliasSXA)->( DbSetOrder( 1 ) ) //XA_ALIAS+XA_ORDEM
	(cAliasSXA)->( DbGoTop() )

	For nI := 1 To Len( aSXA )

		If !Empty( aSXA[nI][1] )

			If !(cAliasSXA)->( dbSeek( PadR( aSXA[nI][1], Len( (cAliasSXA)->&("XA_ALIAS") ) ) + aSXA[nI][2] ) )

				If !( aSXA[nI][1] $ cAlias )
					cAlias += aSXA[nI][1] + "/"
					cTexto += "Foi incluída a pasta e agrupamento de campos " + aSXA[nI][1] + CRLF
				EndIf

				RecLock( cAliasSXA, .T. )

				For nJ := 1 To Len( aSXA[nI] )
					If !Empty( FieldName( FieldPos( aEstrut[nJ] ) ) )
						FieldPut( FieldPos( aEstrut[nJ] ), aSXA[nI][nJ] )
					EndIf
				Next nJ

				dbCommit()
				MsUnLock()

			Else

				//
				// Verifica todos os campos
				//
				For nJ := 1 To Len( aSXA[nI] )

					//
					// Se o campo estiver diferente da estrutura
					//
					If aEstrut[nJ] == (cAliasSXA)->( FieldName( nJ ) ) .AND. ;
							!StrTran( AllToChar( (cAliasSXA)->( FieldGet( nJ ) ) ), " ", "" ) == ;
							StrTran( AllToChar( aSXA[nI][nJ]            ), " ", "" )

						cMsg := "A pasta e agrupamento de campos " + aSXA[nI][1] + " está com o " + (cAliasSXA)->( FieldName( nJ ) ) + ;
							" com o conteúdo" + CRLF + ;
							"[" + RTrim( AllToChar( (cAliasSXA)->( FieldGet( nJ ) ) ) ) + "]" + CRLF + ;
							", e este é diferente do conteúdo" + CRLF + ;
							"[" + RTrim( AllToChar( aSXA[nI][nJ] ) ) + "]" + CRLF +;
							"Deseja substituir ? "

						If      lTodosSim
							nOpcA := 1
						ElseIf  lTodosNao
							nOpcA := 2
						Else
							nOpcA := Aviso( "ATUALIZAÇÃO DE DICIONÁRIOS E TABELAS", cMsg, { "Sim", "Não", "Sim p/Todos", "Não p/Todos" }, 3, "Diferença de conteúdo - SXA" )
							lTodosSim := ( nOpcA == 3 )
							lTodosNao := ( nOpcA == 4 )

							If lTodosSim
								nOpcA := 1
								lTodosSim := MsgNoYes( "Foi selecionada a opção de REALIZAR TODAS alterações no SXA e NÃO MOSTRAR mais a tela de aviso." + CRLF + "Confirma a ação [Sim p/Todos] ?" )
							EndIf

							If lTodosNao
								nOpcA := 2
								lTodosNao := MsgNoYes( "Foi selecionada a opção de NÃO REALIZAR nenhuma alteração no SXA que esteja diferente da base e NÃO MOSTRAR mais a tela de aviso." + CRLF + "Confirma esta ação [Não p/Todos]?" )
							EndIf

						EndIf

						If nOpcA == 1
							RecLock( cAliasSXA, .F. )
							FieldPut( FieldPos( aEstrut[nJ] ), aSXA[nI][nJ] )
							dbCommit()
							MsUnLock()

							If !( aSXA[nI][1] $ cAlias )
								cAlias += aSXA[nI][1] + "/"
								cTexto += "Foi Alterada a pasta e agrupamento de campos " + aSXA[nI][1] + CRLF
							EndIf

						EndIf

					EndIf

				Next

			EndIf

		EndIf

		oProcess:IncRegua2( "Atualizando Pastas e Agrupamentos de Campos (SXA)..." )

	Next nI

	cTexto += CRLF + "Final da Atualizacao" + " SXA" + CRLF + Replicate( "-", 128 ) + CRLF + CRLF

Return NIL

/*/{Protheus.doc} FSAtuSXB
Funcao de processamento da gravacao do SXB - Consultas Padrao.

@author Totvs TBC
@since 31/10/2017
@version 1.0
@return ${return}, ${return_description}
@param cTexto, characters, descricao
@type function
/*/
Static Function FSAtuSXB( cTexto )

	Local aEstrut   := {}
	Local aSXB      := {}
	Local cAlias    := ""
	Local cMsg      := ""
	Local lTodosNao := .F.
	Local lTodosSim := .F.
	Local nI        := 0
	Local nJ        := 0
	Local nX        := 0
	Local nOpcA     := 0
	Local cAliasSXB := GetNextAlias() // apelido para o arquivo de trabalho
	Local lOpen   	:= .F. // valida se foi aberto a tabela

	cTexto  += "Inicio da Atualizacao" + " SXB" + CRLF + CRLF

	aEstrut := RetStrutDic("SXB")

	aSXB := AbreCSV(cPathSX+"SXB.CSV",@aEstrut)

	//
	// Atualizando dicionário
	//
	oProcess:SetRegua2( Len( aSXB ) )

	// abre o dicionário SIX
	OpenSXs(NIL, NIL, NIL, NIL, cEmpAnt, cAliasSXB, "SXB", NIL, .F.)
	lOpen := Select(cAliasSXB) > 0

	// caso aberto, posiciona no topo
	If !(lOpen)
		Return .F.
	EndIf
	DbSelectArea(cAliasSXB)
	(cAliasSXB)->( DbSetOrder( 1 ) ) //XB_ALIAS+XB_TIPO+XB_SEQ+XB_COLUNA
	(cAliasSXB)->( DbGoTop() )

	For nX := 1 to Len( aSXB )
		If !Empty(aSXB[nX][8])
			aSXB[nX][8] :=  StrTran( aSXB[nX][8], "|", ";" ) //XB_CONTEM
		EndIf
	Next nX

	For nI := 1 To Len( aSXB )

		If !Empty( aSXB[nI][1] )

			If !(cAliasSXB)->( dbSeek( PadR( aSXB[nI][1], Len( (cAliasSXB)->&("XB_ALIAS") ) ) + aSXB[nI][2] + aSXB[nI][3] + aSXB[nI][4] ) )

				If !( aSXB[nI][1] $ cAlias )
					cAlias += aSXB[nI][1] + "/"
					cTexto += "Foi incluída a consulta padrão " + aSXB[nI][1] + CRLF
				EndIf

				RecLock( cAliasSXB, .T. )

				For nJ := 1 To Len( aSXB[nI] )
					If !Empty( FieldName( FieldPos( aEstrut[nJ] ) ) )
						FieldPut( FieldPos( aEstrut[nJ] ), aSXB[nI][nJ] )
					EndIf
				Next nJ

				dbCommit()
				MsUnLock()

			Else

				//
				// Verifica todos os campos
				//
				For nJ := 1 To Len( aSXB[nI] )

					//
					// Se o campo estiver diferente da estrutura
					//
					If aEstrut[nJ] == (cAliasSXB)->( FieldName( nJ ) ) .AND. ;
							!StrTran( AllToChar( (cAliasSXB)->( FieldGet( nJ ) ) ), " ", "" ) == ;
							StrTran( AllToChar( aSXB[nI][nJ]            ), " ", "" )

						cMsg := "A consulta padrao " + aSXB[nI][1] + " está com o " + (cAliasSXB)->( FieldName( nJ ) ) + ;
							" com o conteúdo" + CRLF + ;
							"[" + RTrim( AllToChar( (cAliasSXB)->( FieldGet( nJ ) ) ) ) + "]" + CRLF + ;
							", e este é diferente do conteúdo" + CRLF + ;
							"[" + RTrim( AllToChar( aSXB[nI][nJ] ) ) + "]" + CRLF +;
							"Deseja substituir ? "

						If      lTodosSim
							nOpcA := 1
						ElseIf  lTodosNao
							nOpcA := 2
						Else
							nOpcA := Aviso( "ATUALIZAÇÃO DE DICIONÁRIOS E TABELAS", cMsg, { "Sim", "Não", "Sim p/Todos", "Não p/Todos" }, 3, "Diferença de conteúdo - SXB" )
							lTodosSim := ( nOpcA == 3 )
							lTodosNao := ( nOpcA == 4 )

							If lTodosSim
								nOpcA := 1
								lTodosSim := MsgNoYes( "Foi selecionada a opção de REALIZAR TODAS alterações no SXB e NÃO MOSTRAR mais a tela de aviso." + CRLF + "Confirma a ação [Sim p/Todos] ?" )
							EndIf

							If lTodosNao
								nOpcA := 2
								lTodosNao := MsgNoYes( "Foi selecionada a opção de NÃO REALIZAR nenhuma alteração no SXB que esteja diferente da base e NÃO MOSTRAR mais a tela de aviso." + CRLF + "Confirma esta ação [Não p/Todos]?" )
							EndIf

						EndIf

						If nOpcA == 1
							RecLock( cAliasSXB, .F. )
							FieldPut( FieldPos( aEstrut[nJ] ), aSXB[nI][nJ] )
							dbCommit()
							MsUnLock()

							If !( aSXB[nI][1] $ cAlias )
								cAlias += aSXB[nI][1] + "/"
								cTexto += "Foi Alterada a consulta padrao " + aSXB[nI][1] + CRLF
							EndIf

						EndIf

					EndIf

				Next

			EndIf

		EndIf

		oProcess:IncRegua2( "Atualizando Consultas Padroes (SXB)..." )

	Next nI

	cTexto += CRLF + "Final da Atualizacao" + " SXB" + CRLF + Replicate( "-", 128 ) + CRLF + CRLF

Return NIL


/*/{Protheus.doc} FSAtuHlp
Funcao de processamento da gravacao dos Helps de Campos.

@author Totvs TBC
@since 31/10/2017
@version 1.0

@return ${return}, ${return_description}
@param cTexto, characters, descricao

@type function
/*/
Static Function FSAtuHlp( cTexto )

	Local aHlpPor   := {}
	Local aHlpEng   := {}
	Local aHlpSpa   := {}

	cTexto  += "Inicio da Atualizacao" + " " + "Helps de Campos" + CRLF + CRLF

	oProcess:IncRegua2( "Atualizando Helps de Campos ..." )

/*
//
// Helps Tabela U48
//
aHlpPor := {}
aAdd( aHlpPor, 'Concentradora de combustivel' )
aHlpEng := {}
aHlpSpa := {}

PutHelp( "PU48_CONCEN", aHlpPor, aHlpEng, aHlpSpa, .T. )
cTexto += "Atualizado o Help do campo " + "U48_CONCEN" + CRLF

aHlpPor := {}
aAdd( aHlpPor, 'Modelo da Conentradora' )
aHlpEng := {}
aHlpSpa := {}

PutHelp( "PU48_FABCON", aHlpPor, aHlpEng, aHlpSpa, .T. )
cTexto += "Atualizado o Help do campo " + "U48_FABCON" + CRLF

aHlpPor := {}
aAdd( aHlpPor, 'Lado 1 da Bomba' )
aHlpEng := {}
aHlpSpa := {}

PutHelp( "PU48_LADO1 ", aHlpPor, aHlpEng, aHlpSpa, .T. )
cTexto += "Atualizado o Help do campo " + "U48_LADO1" + CRLF

aHlpPor := {}
aAdd( aHlpPor, 'Lado 2 da bomba' )
aHlpEng := {}
aHlpSpa := {}

PutHelp( "PU48_LADO2 ", aHlpPor, aHlpEng, aHlpSpa, .T. )
cTexto += "Atualizado o Help do campo " + "U48_LADO2" + CRLF

//
// Helps Tabela U51
//
aHlpPor := {}
aAdd( aHlpPor, 'Numero da bomba' )
aHlpEng := {}
aHlpSpa := {}

PutHelp( "PU51_BOMBA ", aHlpPor, aHlpEng, aHlpSpa, .T. )
cTexto += "Atualizado o Help do campo " + "U51_BOMBA" + CRLF

aHlpPor := {}
aAdd( aHlpPor, 'Lado da bomba' )
aHlpEng := {}
aHlpSpa := {}

PutHelp( "PU51_LADO  ", aHlpPor, aHlpEng, aHlpSpa, .T. )
cTexto += "Atualizado o Help do campo " + "U51_LADO" + CRLF

cTexto += CRLF + "Final da Atualizacao" + " " + "Helps de Campos" + CRLF + Replicate( "-", 128 ) + CRLF + CRLF
*/
Return {}


/*/{Protheus.doc} EscEmpresa
Funcao Generica para escolha de Empresa, montado pelo SM0.
Retorna vetor contendo as selecoes feitas.
Se nao For marcada nenhuma o vetor volta vazio.

@author Totvs TBC
@since 31/10/2017

@version 1.0
@return ${return}, ${return_description}

@type function
/*/
User Function UPDESEMP(lShared)
Return EscEmpresa(lShared)
Static Function EscEmpresa(lShared)
//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Parametro  nTipo                           ³
//³ 1  - Monta com Todas Empresas/Filiais      ³
//³ 2  - Monta so com Empresas                 ³
//³ 3  - Monta so com Filiais de uma Empresa   ³
//³                                            ³
//³ Parametro  aMarcadas                       ³
//³ Vetor com Empresas/Filiais pre marcadas    ³
//³                                            ³
//³ Parametro  cEmpSel                         ³
//³ Empresa que sera usada para montar selecao ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	Local   aSalvAmb := GetArea()
	Local   aSalvSM0 := {}
	Local   aRet     := {}
	Local   aVetor   := {}
	Local   oDlg     := NIL
	Local   oChkMar  := NIL
	Local   oLbx     := NIL
	Local   oMascEmp := NIL
	Local   oMascFil := NIL
	Local   oButMarc := NIL
	Local   oButDMar := NIL
	Local   oButInv  := NIL
	Local   oSay     := NIL
	Local   oOk      := LoadBitmap( GetResources(), "LBOK" )
	Local   oNo      := LoadBitmap( GetResources(), "LBNO" )
	Local   lChk     := .F.
	Local   lOk      := .F.
	Local   lTeveMarc:= .F.
	Local   cVar     := ""
	Local   cNomEmp  := ""
	Local   cMascEmp := "??"
	Local   cMascFil := "??"
	Local   aMarcadas:= {}

	Default lShared	:= .F. //Caso verdadeiro, indica que a tabela deve ser aberta em modo compartilhado, isto é, outros processos também poderão abrir esta tabela.

	If !MyOpenSm0(lShared)
		Return aRet
	EndIf

	dbSelectArea( "SM0" )
	aSalvSM0 := SM0->( GetArea() )
	SM0->( dbSetOrder( 1 )) //M0_CODIGO+M0_CODFIL
	SM0->( dbGoTop() )

	While !SM0->( EOF() )

		If aScan( aVetor, {|x| x[2] == SM0->M0_CODIGO} ) == 0
			aAdd(  aVetor, { aScan( aMarcadas, {|x| x[1] == SM0->M0_CODIGO .and. x[2] == SM0->M0_CODFIL} ) > 0, SM0->M0_CODIGO, SM0->M0_CODFIL, SM0->M0_NOME, SM0->M0_FILIAL } )
		EndIf

		dbSkip()
	EndDo

	RestArea( aSalvSM0 )

	Define MSDialog  oDlg Title "" From 0, 0 To 270, 396 Pixel

	oDlg:cToolTip := "Tela para Múltiplas Seleções de Empresas/Filiais"

	oDlg:cTitle   := "Selecione a(s) Empresa(s) para Atualização"

	@ 10, 10 Listbox  oLbx Var  cVar Fields Header " ", " ", "Empresa" Size 178, 095 Of oDlg Pixel
	oLbx:SetArray(  aVetor )
	oLbx:bLine := {|| {IIf( aVetor[oLbx:nAt, 1], oOk, oNo ), ;
		aVetor[oLbx:nAt, 2], ;
		aVetor[oLbx:nAt, 4]}}
	oLbx:BlDblClick := { || aVetor[oLbx:nAt, 1] := !aVetor[oLbx:nAt, 1], VerTodos( aVetor, @lChk, oChkMar ), oChkMar:Refresh(), oLbx:Refresh()}
	oLbx:cToolTip   :=  oDlg:cTitle
	oLbx:lHScroll   := .F. // NoScroll

	@ 112, 10 CheckBox oChkMar Var  lChk Prompt "Todos"   Message  Size 40, 007 Pixel Of oDlg;
		on Click MarcaTodos( lChk, @aVetor, oLbx )

	@ 123, 10 Button oButInv Prompt "&Inverter"  Size 32, 12 Pixel Action ( InvSelecao( @aVetor, oLbx, @lChk, oChkMar ), VerTodos( aVetor, @lChk, oChkMar ) ) ;
		Message "Inverter Seleção" Of oDlg

	// Marca/Desmarca por mascara
	@ 113, 51 Say  oSay Prompt "Empresa" Size  40, 08 Of oDlg Pixel
	@ 112, 80 MSGet  oMascEmp Var  cMascEmp Size  05, 05 Pixel Picture "@!"  Valid (  cMascEmp := StrTran( cMascEmp, " ", "?" ), cMascFil := StrTran( cMascFil, " ", "?" ), oMascEmp:Refresh(), .T. ) ;
		Message "Máscara Empresa ( ?? )"  Of oDlg
	@ 123, 50 Button oButMarc Prompt "&Marcar"    Size 32, 12 Pixel Action ( MarcaMas( oLbx, aVetor, cMascEmp, .T. ), VerTodos( aVetor, @lChk, oChkMar ) ) ;
		Message "Marcar usando máscara ( ?? )"    Of oDlg
	@ 123, 80 Button oButDMar Prompt "&Desmarcar" Size 32, 12 Pixel Action ( MarcaMas( oLbx, aVetor, cMascEmp, .F. ), VerTodos( aVetor, @lChk, oChkMar ) ) ;
		Message "Desmarcar usando máscara ( ?? )" Of oDlg

	Define SButton From 111, 125 Type 1 Action ( RetSelecao( @aRet, aVetor ), oDlg:End() ) OnStop "Confirma a Seleção"  Enable Of oDlg
	Define SButton From 111, 158 Type 2 Action ( IIf( lTeveMarc, aRet :=  aMarcadas, .T. ), oDlg:End() ) OnStop "Abandona a Seleção" Enable Of oDlg
	Activate MSDialog  oDlg Center

	RestArea( aSalvAmb )
	dbSelectArea( "SM0" )
	dbCloseArea()

Return  aRet


/*/{Protheus.doc} MarcaTodos
Funcao Auxiliar para marcar/desmarcar todos os itens do ListBox ativo.

@author Ernani Forastieri
@since 31/10/2017
@version 1.0
@return ${return}, ${return_description}
@param lMarca, logical, descricao
@param aVetor, array, descricao
@param oLbx, object, descricao
@type function
/*/
Static Function MarcaTodos( lMarca, aVetor, oLbx )

	Local  nI := 0

	For nI := 1 To Len( aVetor )
		aVetor[nI][1] := lMarca
	Next nI

	oLbx:Refresh()

Return NIL


/*/{Protheus.doc} InvSelecao
Funcao Auxiliar para inverter selecao do ListBox Ativo.

@author Ernani Forastieri
@since 31/10/2017
@version 1.0

@return ${return}, ${return_description}
@param aVetor, array, descricao
@param oLbx, object, descricao

@type function
/*/
Static Function InvSelecao( aVetor, oLbx )

	Local  nI := 0

	For nI := 1 To Len( aVetor )
		aVetor[nI][1] := !aVetor[nI][1]
	Next nI

	oLbx:Refresh()

Return NIL


/*/{Protheus.doc} RetSelecao
Funcao Auxiliar que monta o retorno com as selecoes.

@author Ernani Forastieri
@since 31/10/2017
@version 1.0

@return ${return}, ${return_description}
@param aRet, array, descricao
@param aVetor, array, descricao

@type function
/*/
Static Function RetSelecao( aRet, aVetor )

	Local  nI    := 0

	aRet := {}
	For nI := 1 To Len( aVetor )
		If aVetor[nI][1]
			aAdd( aRet, { aVetor[nI][2] , aVetor[nI][3], aVetor[nI][2] +  aVetor[nI][3] } )
		EndIf
	Next nI

Return NIL


/*/{Protheus.doc} MarcaMas
Funcao para marcar/desmarcar usando mascaras.

@author Ernani Forastieri
@since 31/10/2017
@version 1.0

@return ${return}, ${return_description}

@param oLbx, object, descricao
@param aVetor, array, descricao
@param cMascEmp, characters, descricao
@param lMarDes, logical, descricao

@type function
/*/
Static Function MarcaMas( oLbx, aVetor, cMascEmp, lMarDes )

	Local cPos1 := SubStr( cMascEmp, 1, 1 )
	Local cPos2 := SubStr( cMascEmp, 2, 1 )
	Local nPos  := oLbx:nAt
	Local nZ    := 0

	For nZ := 1 To Len( aVetor )
		If cPos1 == "?" .or. SubStr( aVetor[nZ][2], 1, 1 ) == cPos1
			If cPos2 == "?" .or. SubStr( aVetor[nZ][2], 2, 1 ) == cPos2
				aVetor[nZ][1] :=  lMarDes
			EndIf
		EndIf
	Next

	oLbx:nAt := nPos
	oLbx:Refresh()

Return NIL


/*/{Protheus.doc} VerTodos
Funcao auxiliar para verificar se estao todos marcardos ou nao.

@author Ernani Forastieri
@since 31/10/2017
@version 1.0

@return ${return}, ${return_description}

@param aVetor, array, descricao
@param lChk, logical, descricao
@param oChkMar, object, descricao

@type function
/*/
Static Function VerTodos( aVetor, lChk, oChkMar )

	Local lTTrue := .T.
	Local nI     := 0

	For nI := 1 To Len( aVetor )
		lTTrue := IIf( !aVetor[nI][1], .F., lTTrue )
	Next nI

	lChk := IIf( lTTrue, .T., .F. )
	oChkMar:Refresh()

Return NIL


/*/{Protheus.doc} MyOpenSM0
Funcao de processamento abertura do SM0 modo exclusivo.

@author Totvs TBC
@since 19/08/2015
@version 1.0

@return ${return}, ${return_description}
@param lShared, logical, Caso verdadeiro, indica que a tabela deve ser aberta em modo compartilhado, isto é, outros processos também poderão abrir esta tabela.

@type function
/*/
User Function UPDOPSM0(lShared)
Return MyOpenSM0(lShared)
Static Function MyOpenSM0(lShared)

	Local lOpen := .F.
	Local nLoop := 0

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
		Help(NIL, NIL, "ATENÇÃO", NIL, "Não foi possível a abertura da tabela " + ;
			IIf( lShared, "de empresas (SM0).", "de empresas (SM0) de forma exclusiva." ), 1, 0, NIL, NIL, NIL, NIL, NIL, {""})
	EndIf

Return lOpen


/*/{Protheus.doc} AbreCSV
Função que faz a abertura do arquivo .CSV

@author Totvs TBC
@since 31/10/2017
@version 1.0

@return aRet, array, retorna itens conforme aEstrut

@param aEstrut, array, estrutura do arquivo de retorno (posição das colunas)
@param cArquivo, characters, nome do arquivo .CSV a ser lido

@type function
/*/
Static Function AbreCSV(cArquivo,aEstrut)

	Local cEOL 	:= CHR(13)+CHR(10)
	Local aRet	:= {}

	//Private _nQtdProc := 0

	// valido se os campos estão preenchidos
	if Empty(AllTrim(cArquivo))
		//MsgAlert("Informe o arquivo para importação!","Atenção!")
		//Uso NÃO PERMITIDO de chamada de API de Console --conout(">> UPDPOSTO - Informe o arquivo para importação!")
		Return(aRet)
	endif

	//Caso ocorra erro na abertura do arquivo
	If !File(cArquivo) .Or. Empty(cArquivo)
		//MsgAlert("Arquivo: " + cArquivo + " não localizado!","Atenção!")
		//Uso NÃO PERMITIDO de chamada de API de Console --conout(">> UPDPOSTO - Arquivo: " + cArquivo + " não localizado!")
		Return(aRet)
	Endif

	//Abre arquivo texto
	FT_FUSE(cArquivo)

	//Posiciona no topo
	FT_FGOTOP()

	//Carrega quantidade de linhas
	//_nQtdProc := FT_FLASTREC()

	//Cria regua de processamento
	//ProcRegua(_nQtdProc)

	//barra de processo e chamada para a função que cria o arquivo de trabalho
	//oProcess := MsNewProcess():New({|lEnd| aRet := ProcessaCSV(aEstrut)})
	//oProcess:Activate()

	aRet := ProcessaCSV(@aEstrut)

	//Fecha o arquivo
	FT_FUSE()

	//Uso NÃO PERMITIDO de chamada de API de Console --conout(">> UPDPOSTO - cArquivo: "+cArquivo)
	//Uso NÃO PERMITIDO de chamada de API de Console --conout(">> UPDPOSTO - aEstrut:")
	//Uso NÃO PERMITIDO de chamada de API de Console --conout(UtoString(aEstrut))
	//Uso NÃO PERMITIDO de chamada de API de Console --conout(">> UPDPOSTO - aRet:")
	//Uso NÃO PERMITIDO de chamada de API de Console --conout(UtoString(aRet))

Return(aRet)

/*/{Protheus.doc} ProcessaCSV
Função que faz o processamento do arquivo.

@author Totvs TBC
@since 31/10/2017
@version 1.0

@return aRet, array, retorna itens conforme aEstrut
@param aEstrut, array, estrutura do arquivo de retorno (posição das colunas)

@type function
/*/
Static Function ProcessaCSV(aEstrut)

	Local aRet 			:= {}
	Local nCount		:= 1
	Local aBuffer		:= {}
	Local aCabCSV		:= {}
	Local aTemp 		:= {}
	Local lContinua		:= .T.
	Local nX

	//Enquanto não estiver no fim do arquivo
	While !(FT_FEOF()) .and. lContinua

		//incrementa a regua com a quantidade de linhas lidas e a quantidade do total de linhas
		//oProcess:IncRegua2("Lendo Linha " + cValToChar(nCount) + " de um total de " + cValToChar(_nQtdProc) + ".")

		//carrega a linha para leitura
		cBuffer	:= FT_FREADLN()

		//primeira linha é a linha do cabeçalho
		If nCount == 1

			aCabCSV := StrTokArr2(cBuffer,';',.T.)

			//verifica se todos as colunas do aEstrut existem no aCabCSV
			For nX:=1 to Len(aEstrut)
				If aScan(aCabCSV,{|x| AllTrim(x) == AllTrim(aEstrut[nX])}) <= 0
					//Uso NÃO PERMITIDO de chamada de API de Console --conout(">> UPDPOSTO - A coluna "+AllTrim(aEstrut[nX])+" do aEstrut não existe no cabeçalho do arquivo.")
					aRet := {}
					lContinua := .F.
					Exit //sai do for
				EndIf
			Next nX

			FT_FSKIP()
			nCount++
			Loop
		EndIf

		//ignora as linhas em branco e pula para a próxima
		If Empty(cBuffer)
			FT_FSKIP()
			Loop
		EndIf

		aBuffer := StrTokArr2(cBuffer,';',.T.)

		If Len(aBuffer) >= Len(aCabCSV)
			aTemp := {}
			For nX:=1 To Len(aEstrut)
				aadd(aTemp, aBuffer[aScan(aCabCSV,{|x| AllTrim(x) == AllTrim(aEstrut[nX])})])
			Next nX

			aadd(aRet,aTemp)
		Else
			//Uso NÃO PERMITIDO de chamada de API de Console --conout(">> UPDPOSTO - A linha " + cValToChar(nCount) + " possui menos colunas ("+cValToChar(Len(aBuffer))+") que o numero de colunas do cabeçalho ("+cValToChar(Len(aCabCSV))+") do arquivo.")
			aRet := {}
			lContinua := .F.
			Exit //sai do While
		EndIf

		FT_FSKIP()
		nCount++

	EndDo

	//MsgInfo('Importação concluida com sucesso!','Sucesso')

Return(aRet)

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

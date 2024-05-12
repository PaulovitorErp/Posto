#INCLUDE "TOTVS.CH"
#INCLUDE "TbiConn.ch"

#DEFINE SIMPLES Char( 39 )
#DEFINE DUPLAS  Char( 34 )


/*/{Protheus.doc} UAJUSEXP
Função de update dos dicionários para compatibilização do Posto Inteligente.
	CAMPOS: _SITUA, _MSEXP, _HREXP

@author Totvs TBC
@since 31/10/2017
@version 1.0

@param cEmpAmb, characters, empresa
@param cFilAmb, characters, filial

@type function
/*/
User Function UAJUSEXP( cEmpAmb, cFilAmb )

	Local   aSay      := {}
	Local   aButton   := {}
	Local   aMarcadas := {}
	Local   cTitulo   := "ATUALIZAÇÃO DE DICIONÁRIOS E TABELAS - POSTO INTELIGENTE"
	Local   cDesc1    := "Esta rotina tem como função fazer  a atualização  dos dicionários do Sistema ( SX?/SIX )"
	Local   cDesc2    := "Este processo deve ser executado em modo EXCLUSIVO, ou seja não podem haver outros"
	Local   cDesc3    := "usuários  ou  jobs utilizando  o sistema.  É extremamente recomendavél  que  se  faça um"
	Local   cDesc4    := "BACKUP  dos DICIONÁRIOS  e da  BASE DE DADOS antes desta atualização, para que caso "
	Local   cDesc5    := "ocorra eventuais falhas, esse backup seja ser restaurado."
	//Local   cDesc6    := ""
	//Local   cDesc7    := ""
	Local   lOk       := .F.
	Local   lAuto     := .F. //( cEmpAmb <> NIL .or. cFilAmb <> NIL )

	Local nOpc := "0"
	Local oButton1
	Local oMultSX2
	Local cMultSX2
	Local oSay1

	Private	aMultSX2  := {}

	Private oMainWnd  := NIL
	Private oProcess  := NIL

	Static oDlgFil

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

			DEFINE MSDIALOG oDlgFil TITLE "Criação de Campos: _SITUA, _MSEXP, _HREXP" FROM 000, 000  TO 180, 380 COLORS 0, 16777215 PIXEL

			@ 003, 005 SAY oSay1 PROMPT "Informe as tabelas separadas por espaço. Ex: SA1 SA2 SA3:" SIZE 250, 007 OF oDlgFil COLORS 0, 16777215 PIXEL
			@ 015, 005 GET oMultSX2 VAR cMultSX2 OF oDlgFil MULTILINE SIZE 180, 050 COLORS 0, 16777215 HSCROLL PIXEL
			@ 070, 150 BUTTON oButton1 PROMPT "OK" SIZE 037, 012 OF oDlgFil ACTION(nOpc:="1",oDlgFil:End()) PIXEL

			ACTIVATE MSDIALOG oDlgFil CENTERED

			If nOpc == "1"
				aMultSX2 := StrToKarr(cMultSX2," ")
			EndIf

			If lAuto .OR. MsgNoYes( "Confirma a atualização dos dicionários ?", cTitulo )
				oProcess := MsNewProcess():New( { | lEnd | lOk := FSTProc( @lEnd, aMarcadas ) }, "Atualizando", "Aguarde, atualizando ...", .F. )
				oProcess:Activate()

				If lAuto
					If lOk
						MsgStop( "Atualização Realizada.", "UAJUSEXP" )
						dbCloseAll()
					Else
						MsgStop( "Atualização não Realizada.", "UAJUSEXP" )
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
				MsgStop( "Atualização não Realizada.", "UAJUSEXP" )

			EndIf

		Else
			MsgStop( "Atualização não Realizada.", "UAJUSEXP" )

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
		dbGoTop()

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
					MsgStop( "Atualização da empresa " + aRecnoSM0[nI][2] + " não efetuada." )
					Exit
				EndIf

				SM0->( dbGoTo( aRecnoSM0[nI][1] ) )

				//-- Preparar ambiente local
				//RpcSetType( 3 )
				//RpcSetEnv( SM0->M0_CODIGO, SM0->M0_CODFIL )

				cEmpAnt := AllTrim(SM0->M0_CODIGO)
				cFilAnt := AllTrim(SM0->M0_CODFIL)

				//-- Preparar ambiente local na retagauarda
				RpcSetType(3)
				//PREPARE ENVIRONMENT EMPRESA cEmpAnt FILIAL cFilAnt MODULO "SIGALOJA"
				PREPARE ENVIRONMENT EMPRESA cEmpAnt FILIAL cFilAnt MODULO "FRT"

				lMsFinalAuto := .F.
				lMsHelpAuto  := .F.

				cTexto += Replicate( "-", 128 ) + CRLF
				cTexto += "Empresa : " + SM0->M0_CODIGO + "/" + SM0->M0_NOME + CRLF + CRLF

				oProcess:SetRegua1( 8 )

				//------------------------------------
				// Atualiza o dicionário SX3
				//------------------------------------
				FSAtuSX3( @cTexto )

				oProcess:IncRegua1( "Dicionário de dados" + " - " + SM0->M0_CODIGO + " " + SM0->M0_NOME + " ..." )
				oProcess:IncRegua2( "Atualizando campos/índices" )

				//Bloqueia alterações no Dicionário
				__SetX31Mode( .F. )

				If FindFunction(cTCBuild)
					cTopBuild := &cTCBuild.()
				EndIf

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

					//conout(" >> UAJUSEXP - X31UpdTable: "+aArqUpd[nX])
					X31UpdTable( aArqUpd[nX] )

					If __GetX31Error()
						Alert( __GetX31Trace() )
						MsgStop( "Ocorreu um erro desconhecido durante a atualização da tabela : " + aArqUpd[nX] + ". Verifique a integridade do dicionário e da tabela.", "ATENÇÃO" )
						cTexto += "Ocorreu um erro desconhecido durante a atualização da estrutura da tabela : " + aArqUpd[nX] + CRLF
					EndIf

					If cTopBuild >= "20090811" .AND. TcInternal( 89 ) == "CLOB_SUPPORTED"
						TcInternal( 25, "OFF" )
					EndIf

				Next nX

				//Desbloqueando alterações no dicionário
				__SetX31Mode(.T.)


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

				cFileLog := MemoWrite( GetNextAlias() + ".log", cTexto )

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

//conout(" >> UAJUSEXP:")
//conout(cTexto)

Return lRet

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
	Local aAuxS		:= {}

	Local cAliasSX3 := GetNextAlias() // apelido para o arquivo de trabalho
	Local cAliasSXG := GetNextAlias() // apelido para o arquivo de trabalho
	Local lOpen   	:= .F. // valida se foi aberto a tabela

	cTexto  += "Inicio da Atualizacao" + " SX3" + CRLF + CRLF

	aEstrut := { "X3_ARQUIVO", "X3_ORDEM"  , "X3_CAMPO"  , "X3_TIPO"   , "X3_TAMANHO", "X3_DECIMAL", ;
		"X3_TITULO" , "X3_TITSPA" , "X3_TITENG" , "X3_DESCRIC", "X3_DESCSPA", "X3_DESCENG", ;
		"X3_PICTURE", "X3_VALID"  , "X3_USADO"  , "X3_RELACAO", "X3_F3"     , "X3_NIVEL"  , ;
		"X3_RESERV" , "X3_CHECK"  , "X3_TRIGGER", "X3_PROPRI" , "X3_BROWSE" , "X3_VISUAL" , ;
		"X3_CONTEXT", "X3_OBRIGAT", "X3_VLDUSER", "X3_CBOX"   , "X3_CBOXSPA", "X3_CBOXENG", ;
		"X3_PICTVAR", "X3_WHEN"   , "X3_INIBRW" , "X3_GRPSXG" , "X3_FOLDER" , "X3_PYME"   }

	For nX := 1 to Len(aMultSX2)
		aAuxS := ListCamp( aMultSX2[nX] )
		For nI := 1 to Len(aAuxS)
			aadd( aSX3, aAuxS[nI]  )
		Next nI
	Next nX

//conout(" >> UAJUSEXP - aSX3:")
//conout(U_toString(aSX3))

//
// Atualizando dicionário
//

	nPosArq := aScan( aEstrut, { |x| AllTrim( x ) == "X3_ARQUIVO" } )
	nPosOrd := aScan( aEstrut, { |x| AllTrim( x ) == "X3_ORDEM"   } )
	nPosCpo := aScan( aEstrut, { |x| AllTrim( x ) == "X3_CAMPO"   } )
	nPosTam := aScan( aEstrut, { |x| AllTrim( x ) == "X3_TAMANHO" } )
	nPosSXG := aScan( aEstrut, { |x| AllTrim( x ) == "X3_GRPSXG"  } )

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
					Val(aSX3[nI][nPosTam]) := (cAliasSXG)->&("XG_SIZE")
					cTexto += "O tamanho do campo " + aSX3[nI][nPosCpo] + " nao atualizado e foi mantido em ["
					cTexto += AllTrim( Str( (cAliasSXG)->&("XG_SIZE") ) ) + "]" + CRLF
					cTexto += "   por pertencer ao grupo de campos [" + (cAliasSX3)->&("X3_GRPSXG") + "]" + CRLF + CRLF
				EndIf
			EndIf
		EndIf

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
						Val(aSX3[nI][nPosTam]) := (cAliasSXG)->&("XG_SIZE")
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
							lTodosSim := MsgNoYes( "Foi selecionada a opção de REALIZAR TODAS alterações no SX3 e NÃO MOSTRAR mais a tela de aviso." + CRLF + "Confirma a ação [Sim p/Todos] ?", "Atenção")
						EndIf

						If lTodosNao
							nOpcA := 2
							lTodosNao := MsgNoYes( "Foi selecionada a opção de NÃO REALIZAR nenhuma alteração no SX3 que esteja diferente da base e NÃO MOSTRAR mais a tela de aviso." + CRLF + "Confirma esta ação [Não p/Todos]?", "Atenção")
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
Static Function EscEmpresa()
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
	Local   oButMarc := NIL
	Local   oButDMar := NIL
	Local   oButInv  := NIL
	Local   oSay     := NIL
	Local   oOk      := LoadBitmap( GetResources(), "LBOK" )
	Local   oNo      := LoadBitmap( GetResources(), "LBNO" )
	Local   lChk     := .F.
	Local   lTeveMarc:= .F.
	Local   cVar     := ""
	Local   cMascEmp := "??"
	Local   cMascFil := "??"
	Local   aMarcadas  := {}

	If !MyOpenSm0(.F.)
		Return aRet
	EndIf

	dbSelectArea( "SM0" )
	aSalvSM0 := SM0->( GetArea() )
	dbSetOrder( 1 )
	dbGoTop()

	While !SM0->( EOF() )

		If aScan( aVetor, {|x| x[2] == SM0->M0_CODIGO} ) == 0
			aAdd(  aVetor, { aScan( aMarcadas, {|x| x[1] == SM0->M0_CODIGO .and. x[2] == SM0->M0_CODFIL} ) > 0, SM0->M0_CODIGO, SM0->M0_CODFIL, SM0->M0_NOME, SM0->M0_FILIAL } )
		EndIf

		dbSkip()
	End

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

	@ 123, 10 Button oButInv Prompt "&Inverter"  Size 32, 12 Pixel Action ( InvSelecao( @aVetor, oLbx ), VerTodos( aVetor, @lChk, oChkMar ) ) ;
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

//-------------------------------------------------------------------
/*/{Protheus.doc} ListCamp
Retorna a SX3 para os campos: _SITUA, _MSEXP, _HREXP
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
Static Function ListCamp(cTabela)

	Local aAuxS		:= {}
	Local cOrdem 	:= RetProx(cTabela)
	Local cPrefix 	:= Iif(substr(cTabela,1,1)=="S",substr(cTabela,2,2),substr(cTabela,1,3))
	Local lDicTop 	:= .F.
	Local cDBExt	:= ""

	//Retorna a extensão em uso para as tabelas acessadas através do driver ou RDD "DBFCDX"
	cDBExt := GetSrvProfString( "LocalDBExtension", "" ) //GetDBExtension()
	cDBExt := Lower( cDBExt )
	lDicTop := (FindFunction("MPDicInDB") .AND. MPDicInDB() ) .OR. (cDBExt <> '.dbf' .and. cDBExt <> '.dtc')

	// _SITUA
	aAdd( aAuxS, { ;
		cTabela																	, ; //X3_ARQUIVO
	cOrdem																	, ; //X3_ORDEM
	cPrefix+'_SITUA'														, ; //X3_CAMPO
	'C'																		, ; //X3_TIPO
	'2'																		, ; //X3_TAMANHO
	'0'																		, ; //X3_DECIMAL
	'Situacao    '															, ; //X3_TITULO
	'Situacion   '															, ; //X3_TITSPA
	'Status      '															, ; //X3_TITENG
	'Situacao do Registro     '												, ; //X3_DESCRIC
	'Situacion de Registro    '												, ; //X3_DESCSPA
	'Record Status            '												, ; //X3_DESCENG
	''																		, ; //X3_PICTURE
	''																		, ; //X3_VALID
	iif(!lDicTop,'€€€€€€€€€€€€€€€',"x       x       x       x       x       x       x       x       x       x       x       x       x       x       x"), ; //X3_USADO
	''																		, ; //X3_RELACAO
	''																		, ; //X3_F3
	'0'																		, ; //X3_NIVEL
	iif(!lDicTop,'€€','  xxxx x')											, ; //X3_RESERV
	''																		, ; //X3_CHECK
	''																		, ; //X3_TRIGGER
	'U'																		, ; //X3_PROPRI
	'N'																		, ; //X3_BROWSE
	'V'																		, ; //X3_VISUAL
	'R'																		, ; //X3_CONTEXT
	''																		, ; //X3_OBRIGAT
	''																		, ; //X3_VLDUSER
	''																		, ; //X3_CBOX
	''																		, ; //X3_CBOXSPA
	''																		, ; //X3_CBOXENG
	''																		, ; //X3_PICTVAR
	''																		, ; //X3_WHEN
	''																		, ; //X3_INIBRW
	''																		, ; //X3_GRPSXG
	''																		, ; //X3_FOLDER
	'S'																		} ) //X3_PYME

	// _XSITUA
	//aAdd( aAuxS, { ;
	//	cTabela																	, ; //X3_ARQUIVO
	//cOrdem																	, ; //X3_ORDEM
	//cPrefix+'_XSITUA'														, ; //X3_CAMPO
	//'C'																		, ; //X3_TIPO
	//'1'																		, ; //X3_TAMANHO
	//'0'																		, ; //X3_DECIMAL
	//'Situacao    '															, ; //X3_TITULO
	//'Situacion   '															, ; //X3_TITSPA
	//'Status      '															, ; //X3_TITENG
	//'Situacao da Integracao   '												, ; //X3_DESCRIC
	//'Situacao da Integracao   '												, ; //X3_DESCSPA
	//'Situacao da Integracao   '												, ; //X3_DESCENG
	//''																		, ; //X3_PICTURE
	//''																		, ; //X3_VALID
	//iif(!lDicTop,'€€€€€€€€€€€€€€€',"x       x       x       x       x       x       x       x       x       x       x       x       x       x       x"), ; //X3_USADO
	//''																		, ; //X3_RELACAO
	//''																		, ; //X3_F3
	//'0'																		, ; //X3_NIVEL
	//iif(!lDicTop,'€€','  xxxx x')									, ; //X3_RESERV
	//''																		, ; //X3_CHECK
	//''																		, ; //X3_TRIGGER
	//'U'																		, ; //X3_PROPRI
	//'N'																		, ; //X3_BROWSE
	//'V'																		, ; //X3_VISUAL
	//'R'																		, ; //X3_CONTEXT
	//''																		, ; //X3_OBRIGAT
	//''																		, ; //X3_VLDUSER
	//''																		, ; //X3_CBOX
	//''																		, ; //X3_CBOXSPA
	//''																		, ; //X3_CBOXENG
	//''																		, ; //X3_PICTVAR
	//''																		, ; //X3_WHEN
	//''																		, ; //X3_INIBRW
	//''																		, ; //X3_GRPSXG
	//''																		, ; //X3_FOLDER
	//'S'																		} ) //X3_PYME

	//_MSEXP
	aAdd( aAuxS, { ;
		cTabela																	, ; //X3_ARQUIVO
	Soma1(cOrdem)															, ; //X3_ORDEM
	cPrefix+'_MSEXP'														, ; //X3_CAMPO
	'C'																		, ; //X3_TIPO
	'8'																		, ; //X3_TAMANHO
	'0'																		, ; //X3_DECIMAL
	'Ident.Exp.  '															, ; //X3_TITULO
	'Ident.Exp.  '															, ; //X3_TITSPA
	'Exp. ID     '															, ; //X3_TITENG
	'Ident.Exp.Dados          '												, ; //X3_DESCRIC
	'Ident.Exp.Datos          '												, ; //X3_DESCSPA
	'Data Exp. Ident.         '												, ; //X3_DESCENG
	''																		, ; //X3_PICTURE
	''																		, ; //X3_VALID
	iif(!lDicTop,'€€€€€€€€€€€€€€€',"x       x       x       x       x       x       x       x       x       x       x       x       x       x       x"), ; //X3_USADO
	''																		, ; //X3_RELACAO
	''																		, ; //X3_F3
	'0'																		, ; //X3_NIVEL
	iif(!lDicTop,'€€','  xxxx x')									, ; //X3_RESERV
	''																		, ; //X3_CHECK
	''																		, ; //X3_TRIGGER
	'U'																		, ; //X3_PROPRI
	'N'																		, ; //X3_BROWSE
	'V'																		, ; //X3_VISUAL
	'R'																		, ; //X3_CONTEXT
	''																		, ; //X3_OBRIGAT
	''																		, ; //X3_VLDUSER
	''																		, ; //X3_CBOX
	''																		, ; //X3_CBOXSPA
	''																		, ; //X3_CBOXENG
	''																		, ; //X3_PICTVAR
	''																		, ; //X3_WHEN
	''																		, ; //X3_INIBRW
	''																		, ; //X3_GRPSXG
	''																		, ; //X3_FOLDER
	'S'																		} ) //X3_PYME

	//_HREXP
	aAdd( aAuxS, { ;
		cTabela																	, ; //X3_ARQUIVO
	Soma1(cOrdem)															, ; //X3_ORDEM
	cPrefix+'_HREXP'														, ; //X3_CAMPO
	'C'																		, ; //X3_TIPO
	'8'																		, ; //X3_TAMANHO
	'0'																		, ; //X3_DECIMAL
	'Hora Exp    '															, ; //X3_TITULO
	'Hora Exp    '															, ; //X3_TITSPA
	'Hora Exp    '															, ; //X3_TITENG
	'Hora da Exportacao       '												, ; //X3_DESCRIC
	'Hora da Exportacao       '												, ; //X3_DESCSPA
	'Hora da Exportacao       '												, ; //X3_DESCENG
	''																		, ; //X3_PICTURE
	''																		, ; //X3_VALID
	iif(!lDicTop,'€€€€€€€€€€€€€€€',"x       x       x       x       x       x       x       x       x       x       x       x       x       x       x"), ; //X3_USADO
	''																		, ; //X3_RELACAO
	''																		, ; //X3_F3
	'0'																		, ; //X3_NIVEL
	iif(!lDicTop,'€€','  xxxx x')									, ; //X3_RESERV
	''																		, ; //X3_CHECK
	''																		, ; //X3_TRIGGER
	'U'																		, ; //X3_PROPRI
	'N'																		, ; //X3_BROWSE
	'V'																		, ; //X3_VISUAL
	'R'																		, ; //X3_CONTEXT
	''																		, ; //X3_OBRIGAT
	''																		, ; //X3_VLDUSER
	''																		, ; //X3_CBOX
	''																		, ; //X3_CBOXSPA
	''																		, ; //X3_CBOXENG
	''																		, ; //X3_PICTVAR
	''																		, ; //X3_WHEN
	''																		, ; //X3_INIBRW
	''																		, ; //X3_GRPSXG
	''																		, ; //X3_FOLDER
	'S'																		} ) //X3_PYME

	////_XINDEX
	//aAdd( aAuxS, { ;
	//	cTabela																	, ; //X3_ARQUIVO
	//Soma1(cOrdem)															, ; //X3_ORDEM
	//cPrefix+'_XINDEX'														, ; //X3_CAMPO
	//'N'																		, ; //X3_TIPO
	//'2'																		, ; //X3_TAMANHO
	//'0'																		, ; //X3_DECIMAL
	//'Indice      '															, ; //X3_TITULO
	//'Indice      '															, ; //X3_TITSPA
	//'Indice      '															, ; //X3_TITENG
	//'Indice da integracao     '												, ; //X3_DESCRIC
	//'Indice da integracao     '												, ; //X3_DESCSPA
	//'Indice da integracao     '												, ; //X3_DESCENG
	//'99'																	, ; //X3_PICTURE
	//''																		, ; //X3_VALID
	//iif(!lDicTop,'€€€€€€€€€€€€€€€',"x       x       x       x       x       x       x       x       x       x       x       x       x       x       x"), ; //X3_USADO
	//''																		, ; //X3_RELACAO
	//''																		, ; //X3_F3
	//'0'																		, ; //X3_NIVEL
	//iif(!lDicTop,'€€','  xxxx x')									, ; //X3_RESERV
	//''																		, ; //X3_CHECK
	//''																		, ; //X3_TRIGGER
	//'U'																		, ; //X3_PROPRI
	//'N'																		, ; //X3_BROWSE
	//'V'																		, ; //X3_VISUAL
	//'R'																		, ; //X3_CONTEXT
	//''																		, ; //X3_OBRIGAT
	//''																		, ; //X3_VLDUSER
	//''																		, ; //X3_CBOX
	//''																		, ; //X3_CBOXSPA
	//''																		, ; //X3_CBOXENG
	//''																		, ; //X3_PICTVAR
	//''																		, ; //X3_WHEN
	//''																		, ; //X3_INIBRW
	//''																		, ; //X3_GRPSXG
	//''																		, ; //X3_FOLDER
	//'S'																		} ) //X3_PYME

Return aAuxS

//-------------------------------------------------------------------
/*/{Protheus.doc} RetProx
Retorna a proxima ordem da SX3
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
Static Function RetProx(cChave)

	Local aArea 	:= GetArea()
	Local cRet 		:= "ZZ"

	Local cAliasSX3 := GetNextAlias() // apelido para o arquivo de trabalho
	Local lOpen   	:= .F. // valida se foi aberto a tabela

// abre o dicionário SX3
	OpenSXs(NIL, NIL, NIL, NIL, cEmpAnt, cAliasSX3, "SX3", NIL, .F.)
	lOpen := Select(cAliasSX3) > 0

// caso aberto, posiciona no topo
	If !(lOpen)
		Return .F.
	EndIf
	DbSelectArea(cAliasSX3)
	(cAliasSX3)->(DbSetOrder(1)) //X3_ARQUIVO+X3_ORDEM
	If (cAliasSX3)->(DbSeek(cChave))
		While (cAliasSX3)->(!Eof()) .and. (cAliasSX3)->&("X3_ARQUIVO") == cChave
			(cAliasSX3)->(DbSkip())
		EndDo
		(cAliasSX3)->(DbSkip(-1))
		cRet := Soma1((cAliasSX3)->&("X3_ORDEM"))
	EndIf

	RestArea(aArea)

Return cRet

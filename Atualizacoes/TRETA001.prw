#include 'protheus.ch'
#include 'parmtype.ch'
#INCLUDE "TOPCONN.CH"

/*/{Protheus.doc} TRETA001
Função de importação de Cadastros de Motoristas (DA4)
@author Danilo Brito
@since 24/09/2018
@version 1.0
@return Nil
@type function
/*/
User function TRETA001()

	Local aSay := {}
	Local aBut := {}
	Local lOk		:= .F.
	Local cArquivo	:= ""
	Local aAreaDA4 := DA4->(GetArea())

	//texto da tela
	aAdd(aSay, "Esta rotina tem por objetivo importar motoristas conforme arquivo selecionado pelo usuário.")
	aAdd(aSay, "O arquivo deve ter na primeira linha os nomes dos campos, e nas demais os conteudos.")
	aAdd(aSay, " ")
	aAdd(aSay, "Exemplo:")
	aAdd(aSay, "DA4_CGC;DA4_NOME;DA4_NREDUZ")
	aAdd(aSay, "00000000000;NOME MOTORISTA GENERICO;MOTORISTA GEN")

	//botoes da tela
	If ChkFile("U07")
		aAdd(aBut, {04, .T., {|| FechaBatch(), Processa({|lEnd| U_TRETA01B(@lEnd) }, NIL, NIL, .T.) } }) // MIGRACAO U07 p/ DA4 (botao inclui)
	endif
	aAdd(aBut, {14, .T., {|| cArquivo := RetFile()} })		// Abrir pasta
	aAdd(aBut, {01, .T., {|| iif(empty(cArquivo),MsgInfo("Selecione um arquivo!","File"),(lOk := .T., FechaBatch())) } })	// Confirma
	aAdd(aBut, {02, .T., {|| (lOk := .F., FechaBatch())} })	// Cancela

	//abre tela
	FormBatch("Importação de motoristas", aSay, aBut)

	if lOk
		Processa({|lEnd| DoImpFile(@lEnd, cArquivo) }, NIL, NIL, .T.)
	endif

	RestArea(aAreaDA4)

Return


/*/{Protheus.doc} RetFile
Abre a tela de seleção de arquivo, e retorna caminho.

@author Danilo Brito
@since 24/09/2018
@version 1.0
@return cPasta, caminho do arquivo selecionado

@type function
/*/
Static Function RetFile()

	Local cArquivo := cGetFile("Arquivos csv (*.csv)|*.csv", "Abrir arquivo", 1, "C:\", .F., nOR( GETF_LOCALHARD, GETF_LOCALFLOPPY ), .T., .T.)

	if !empty(cArquivo)
		if !File(alltrim(cArquivo))
			MsgInfo("Arquivo não pode ser localizado.","Atençao")
			return("")
		endif
	endif

Return cArquivo

/*/{Protheus.doc} DoImpFile
Faz a importacao do arquivo, valida a linha e chama gravaçao

@author thebr
@since 24/09/2018
@version 1.0
@return Nil
@param lEnd, controle de saida
@param cArquivo, nome do arquivo
@type function
/*/
Static Function DoImpFile(lEnd, cArquivo)

	Local nHdl, nX, nOpc, nLin
	Local aCpDef //definicao dos campos
	Local cLinha //conteudo da linha
	Local aLinha //conteudo da linha
	Local aCampos //array para execauto
	Local nPosCGC := 0
	Local nPosCod := 0
	Private lMsErroAuto := .F.

	// abre arquivo
	nHdl	:= FT_FUse( cArquivo )

	If nHdl < 0
		MsgAlert("Problemas na abertura do arquivo de motoristas", ProcName() + "-" + StrZero(ProcLine(), 5))
		Return
	EndIf

	//Conout("TRETA001-> Iniciando importacao arquivo " + cArquivo)
	ProcRegua(FT_FLastRec())

	DbSelectArea("DA4")
	FT_FGoTop()
	nLin := 1
	While !FT_FEof() .AND. !lEnd

		IncProc("Importanto motoristas... "+cValtoChar(nLin))

		if empty(aCpDef)
			cLinha := FT_FReadLn()
			if !empty(cLinha)
				//Conout("TRETA001-> Estrutura: " + cLinha)
				aCpDef := StrToKArr(cLinha, ";")
				nPosCGC := aScan(aCpDef, {|x| alltrim(x) == "DA4_CGC" } )
				nPosCod := aScan(aCpDef, {|x| alltrim(x) == "DA4_COD" } )
				if nPosCGC+nPosCod == 0
					MsgAlert("Primeira linha do arquivo deve conter a definição dos campos, incluindo um dos campos chaves DA4_CGC ou DA4_COD.")
					EXIT
				endif
			endif
		else

			aCampos := {}
			nOpc := 3 //inclusao
			cLinha := FT_FReadLn()
			aLinha := StrToKArr(cLinha, ";")
			lMsErroAuto := .F.

			if len(aLinha) <> len(aCpDef)
				//Conout("TRETA001-> Linha " + cValTochar(nLin) + " incompativel nao importada!")
				EXIT
			endif

			//verificando se vai ser alteracao
			if nPosCGC > 0
				DA4->(DbSetOrder(3)) //DA4_FILIAL+DA4_CGC
				if DA4->(DbSeek(xFilial("DA4")+aLinha[nPosCGC] ))
					nOpc := 4 //alteracao
				endif
			elseif nPosCod > 0
				DA4->(DbSetOrder(1)) //DA4_FILIAL+DA4_COD
				if DA4->(DbSeek(xFilial("DA4")+aLinha[nPosCod] ))
					nOpc := 4 //alteracao
				endif
			endif

			//montando array de dados a passar para execauto
			for nX := 1 to len(aCpDef)
				aadd(aCampos, {aCpDef[nX], TpCampo(aCpDef[nX], aLinha[nX]) })
			next nX

			//chama a gravacao execauto MVC
			FWMVCRotAuto(FWLoadModel("OMSA040"),"DA4",nOpc,{{"OMSA040_DA4",aCampos}},,.T.)

			//chama a gravacao execauto MVC
			if !lMsErroAuto
				//Conout("TRETA001-> Linha " + cValTochar(nLin) + " importada com sucesso!")
			else
				//Conout("TRETA001-> Linha " + cValTochar(nLin) + " falha na importacao!")
			endif
		endif

		nLin++
		FT_FSkip()
	enddo

	//Conout("TRETA001-> Fim da importacao!")
	FT_FUse() // Fecha o arquivo

Return

/*/{Protheus.doc} TpCampo
Compatibiliza o conteudo com o tipo do campo
@author thebr
@since 24/09/2018
@version 1.0
@return xRet
@type function
/*/
Static Function TpCampo(cCampo, cContent)

	Local xRet
	Local cTipo := GetSx3Cache(cCampo,"X3_TIPO")

	If cTipo == "N"
		xRet	:= Val(cContent)
	ElseIf cTipo == "D"
		xRet	:= CTOD(cContent)
	Elseif cTipo == "C"
		xRet := PadR(cContent, TamSX3(cCampo)[1])
	Else
		xRet := cContent
	EndIf

Return xRet

/*/{Protheus.doc} TRETA01A
Programa de migracao dos dados do antigo cadastro (U07) para o novo (DA4)

@author thebr
@since 24/09/2018
@version 1.0
@return Nil
@type function
/*/
User Function TRETA01A(lEnd)

	Local aCampos //array para execauto
	Local nOpc, nCount := 0
	Local lProcAll := MsgYesNo("Importar todos? 'SIM'- importará todas os cadastros de motoristas. 'NAO'- importará apenas os 50 primeiros (para teste)","Importar")
	Local lConfirmSX8 := .F.
	Local aSX3DA4, nX

	//Conout("TRETA001-> Iniciando Migracao")
	ProcRegua(1000)

	DbSelectArea("U07")
	U07->(DbSetOrder(1)) //U07_FILIAL+U07_CPF
	U07->(DbGoTop())
	While U07->(!Eof()) .AND. !lEnd  .AND. (lProcAll .OR. nCount < 50)

		IncProc("Migrando motoristas... "+cValToChar(nCount))

		aCampos := {}
		nOpc := 3 //inclusao

		if len(alltrim(U07->U07_CPF)) == 11

			DA4->(DbSetOrder(3)) //DA4_FILIAL+DA4_CGC
			if DA4->(DbSeek(xFilial("DA4")+U07->U07_CPF ))
				RecLock("DA4", .F.) //altera
			else
				RecLock("DA4", .T.) //inclui

				//inicializa campos
				aSX3DA4 := FWSX3Util():GetAllFields( "DA4" , .F./*lVirtual*/ )
				if !empty(aSX3DA4)
					for nX := 1 to len(aSX3DA4)
						DA4->&(aSX3DA4[nX]) := CriaVar(aSX3DA4[nX], .T.)
						if Alltrim(aSX3DA4[nX]) == "DA4_COD" .AND. "GETSX" $ Upper(GetSx3Cache(aSX3DA4[nX],"X3_RELACAO"))
							lConfirmSX8 := .T.
						endif
					next nX
				endif
			endif

			//campos que vou preencher
			DA4->DA4_CGC := xFilial("DA4")
			DA4->DA4_CGC := TpCampo("DA4_CGC", U07->U07_CPF)
			DA4->DA4_NOME := TpCampo("DA4_NOME", U07->U07_NOME)
			DA4->DA4_NREDUZ := TpCampo("DA4_NREDUZ", U07->U07_NOME)

			if !empty(U07->U07_RG)
				DA4->DA4_RG := TpCampo("DA4_RG", U07->U07_RG)
			endif
			if !empty(U07->U07_DTNAS)
				DA4->DA4_DATNAS := U07->U07_DTNAS
			endif
			if !empty(U07->U07_DDD1)
				DA4->DA4_DDD := TpCampo("DA4_DDD", U07->U07_DDD1)
			endif
			if !empty(U07->U07_TEL1)
				DA4->DA4_TEL := TpCampo("DA4_TEL", U07->U07_TEL1)
			endif

			DA4->(MsUnlock())

			if lConfirmSX8
				ConfirmSX8()
			endif
		endif

		nCount++
		U07->(DbSkip())
	Enddo

	//Conout("TRETA001-> Fim da importacao!")

Return

User Function TRETA01B(lEnd)

	Local aCampos //array para execauto
	Local nOpc, nCount := 0
	Local cQry
	Local lConfirmSX8 := .F.
	Local aSX3DA4, nX

	//Conout("TRETA001-> Iniciando Migracao")
	ProcRegua(1000)

	cQry := " SELECT * FROM "+RetSqlName("U07")+" U07 WHERE U07.D_E_L_E_T_= ' ' "
	cQry += " AND U07_CPF NOT IN (SELECT DA4_CGC FROM "+RetSqlName("DA4")+" DA4 WHERE DA4.D_E_L_E_T_= ' ') "

	if Select("TU07") > 0
		TU07->(DbCloseArea())
	Endif
	cQry := ChangeQuery(cQry)
	TcQuery cQry New Alias "TU07" // Cria uma nova area com o resultado do query

	While TU07->(!Eof()) .AND. !lEnd

		IncProc("Migrando motoristas... "+cValToChar(nCount))

		aCampos := {}
		nOpc := 3 //inclusao

		if len(alltrim(TU07->U07_CPF)) == 11

			DA4->(DbSetOrder(3)) //DA4_FILIAL+DA4_CGC
			if DA4->(DbSeek(xFilial("DA4")+TU07->U07_CPF ))
				RecLock("DA4", .F.) //altera
			else
				RecLock("DA4", .T.) //inclui

				//inicializa campos
				aSX3DA4 := FWSX3Util():GetAllFields( "DA4" , .F./*lVirtual*/ )
				if !empty(aSX3DA4)
					for nX := 1 to len(aSX3DA4)
						DA4->&(aSX3DA4[nX]) := CriaVar(aSX3DA4[nX], .T.)
						if Alltrim(aSX3DA4[nX]) == "DA4_COD" .AND. "GETSX" $ Upper(GetSx3Cache(aSX3DA4[nX],"X3_RELACAO"))
							lConfirmSX8 := .T.
						endif
					next nX
				endif
			endif

			//campos que vou preencher
			DA4->DA4_CGC := xFilial("DA4")
			DA4->DA4_CGC := TpCampo("DA4_CGC", TU07->U07_CPF)
			DA4->DA4_NOME := TpCampo("DA4_NOME", TU07->U07_NOME)
			DA4->DA4_NREDUZ := TpCampo("DA4_NREDUZ", TU07->U07_NOME)

			if !empty(TU07->U07_RG)
				DA4->DA4_RG := TpCampo("DA4_RG", TU07->U07_RG)
			endif
			if !empty(TU07->U07_DTNAS)
				DA4->DA4_DATNAS := STOD(TU07->U07_DTNAS)
			endif
			if !empty(TU07->U07_DDD1)
				DA4->DA4_DDD := TpCampo("DA4_DDD", TU07->U07_DDD1)
			endif
			if !empty(TU07->U07_TEL1)
				DA4->DA4_TEL := TpCampo("DA4_TEL", TU07->U07_TEL1)
			endif

			DA4->DA4_MSEXP := ""
			DA4->DA4_HREXP := ""

			DA4->(MsUnlock())

			if lConfirmSX8
				ConfirmSX8()
			endif
		endif

		nCount++
		TU07->(DbSkip())
	Enddo

	//Conout("TRETA001-> Fim da importacao!")
	TU07->(DbCloseArea())

Return

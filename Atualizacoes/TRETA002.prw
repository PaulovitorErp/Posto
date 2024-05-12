#include 'protheus.ch'
#include 'parmtype.ch'
#INCLUDE "TOPCONN.CH"

/*/{Protheus.doc} TRETA002
Função de importação de Cadastros de Veiculos (DA3)
@author Danilo Brito
@since 24/09/2018
@version 1.0
@return Nil
@type function
/*/
User function TRETA002()

	Local aSay := {}
	Local aBut := {}
	Local lOk		:= .F.
	Local cArquivo	:= ""
	Local aAreaDA3 := DA3->(GetArea())

	//texto da tela
	aAdd(aSay, "Esta rotina tem por objetivo importar veiculos conforme arquivo selecionado pelo usuário.")
	aAdd(aSay, "O arquivo deve ter na primeira linha os nomes dos campos, e nas demais os conteudos.")
	aAdd(aSay, " ")
	aAdd(aSay, "Exemplo:")
	aAdd(aSay, "DA3_PLACA;DA3_DESC;DA3_XCODCL;DA3_XLOJCL")
	aAdd(aSay, "AAA-0000;VEICULO GENERICO;000001;01")

	//botoes da tela
	If ChkFile("U08")
	aAdd(aBut, {04, .T., {|| FechaBatch(), Processa({|lEnd| U_TRETA02B(@lEnd) }, NIL, NIL, .T.) } }) // MIGRACAO U08 p/ DA3 (botao inclui)
	EndIf
	aAdd(aBut, {14, .T., {|| cArquivo := RetFile()} })		// Abrir pasta
	aAdd(aBut, {01, .T., {|| iif(empty(cArquivo),MsgInfo("Selecione um arquivo!","File"),(lOk := .T., FechaBatch())) } })	// Confirma
	aAdd(aBut, {02, .T., {|| (lOk := .F., FechaBatch())} })	// Cancela

	//abre tela
	FormBatch("Importação de veículos", aSay, aBut)

	if lOk
		Processa({|lEnd| DoImpFile(@lEnd, cArquivo) }, NIL, NIL, .T.)
	endif

	RestArea(aAreaDA3)

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
	Local nPosPlaca := 0
	Local nPosCod := 0
	Local nPosDesc := 0
	Local nPosCli := 0
	Local nPosGrp := 0
	Local nPosMot := 0
	Local cCodCli := ""
	Local cLojCli := ""
	Local cGrpCli := ""
	Local nTipImp := SuperGetMV("TP_DA4SOBR",.F.,"0") //"Define se na importação de placas, quando placa ja vinculada a cliente/grupo se: 0 - Perguntar/1 - Sobrescrever/2 - Pular." })

	Private lMsErroAuto := .F.

	// abre arquivo
	nHdl	:= FT_FUse( cArquivo )

	If nHdl < 0
		msgAlert("Problemas na abertura do arquivo de veiculos", ProcName() + "-" + StrZero(ProcLine(), 5))
		Return
	EndIf

	//Conout("TRETA002-> Iniciando importacao arquivo " + cArquivo)
	ProcRegua(FT_FLastRec())

	DbSelectArea("DA3")
	FT_FGoTop()
	nLin := 0
	While !FT_FEof() .AND. !lEnd

		IncProc("Importanto motoristas... "+cValtoChar(nLin))
		lMsErroAuto := .F.

		if empty(aCpDef)
			cLinha := FT_FReadLn()
			if !empty(cLinha)
				//Conout("TRETA002-> Estrutura: " + cLinha)
				aCpDef := StrTokArr2(cLinha,";",.T.)
				nPosPlaca := aScan(aCpDef, {|x| alltrim(x) == "DA3_PLACA" } )
				nPosCod := aScan(aCpDef, {|x| alltrim(x) == "DA3_COD" } )
				nPosDesc := aScan(aCpDef, {|x| alltrim(x) == "DA3_DESC" } )
				nPosCli := aScan(aCpDef, {|x| alltrim(x) == "DA3_XCODCL" } )
				nPosGrp := aScan(aCpDef, {|x| alltrim(x) == "DA3_XGRPCL" } )
				nPosMot := aScan(aCpDef, {|x| alltrim(x) == "DA3_MOTORI" } )

				if nPosPlaca == 0
					MsgAlert("Arquivo não configurado corretamente. Deve ter na primeira linha o nome dos campos, sendo obrigatório ter campo DA3_PLACA.","Atenção")
					EXIT
				endif

				if nPosCli+nPosGrp == 0
					if MsgYesNo("Deseja vincular os registros a importar com algum Cliente ou Grupo?","Atencao")
						aPergs := {}
						aParamEnc := {}
						aAdd( aPergs ,{1,"Cliente:", Space(TamSX3("DA3_XCODCL")[1]),"@!",'Empty(MV_PAR01).OR.ExistCpo("SA1")',"SA1",'Empty(MV_PAR03)',60,.F.})
						aAdd( aPergs ,{1,"Loja:",Space(TamSX3("DA3_XLOJCL")[1]),"@!",'.T.',"",'Empty(MV_PAR03)',30,.F.})
						aAdd( aPergs ,{1,"Grupo Cliente:",Space(TamSX3("DA3_XGRPCL")[1]),"@!",'Empty(MV_PAR03) .OR. ExistCpo("ACY")',"ACY",'Empty(MV_PAR01)',60,.F.})
						aAdd( aPergs ,{2,"Desvincular todos veículos do         cliente/grupo antes","1",{"1=Não","2=Sim"},30,"",.F.})
						if ParamBox(aPergs ,"Vincular Cliente/Grupo",@aParamEnc,{|| iif(empty(MV_PAR01+MV_PAR03),MsgInfo("Informe um cliente ou grupo!","Atencao"),.T.) },,,,,,.F.,.F.)
							cCodCli := aParamEnc[1]
							cLojCli := aParamEnc[2]
							cGrpCli := aParamEnc[3]
							//se exclui antes
							if aParamEnc[4] == "2" .AND. !empty(cCodCli+cLojCli+cGrpCli)
								U_TRETA02C(cCodCli,cLojCli,cGrpCli)
							endif
						else
							EXIT //aborta
						endif
					endif
				endif
			endif
		else

			aCampos := {}
			nOpc := 3 //inclusao
			cLinha := FT_FReadLn()
			aLinha := StrTokArr2(cLinha,";",.T.)

			if len(aLinha) <> len(aCpDef)
				//Conout("TRETA002-> Linha " + cValTochar(nLin) + " incompativel nao importada!")
				EXIT
			endif

			if len(Alltrim(Transform(aLinha[nPosPlaca], "@!R AAA-9X99"))) != 8
				MsgInfo("Linha "+cValtoChar(nLin)+". Placa "+aLinha[nPosPlaca]+" do arquivo inconsistente. Registro ignorado!","Atenção!")
				nLin++
				FT_FSkip()
				LOOP
			endif

			//verificando se vai ser alteracao
			if nPosPlaca > 0
				DA3->(DbSetOrder(3)) //DA3_FILIAL+DA3_PLACA
				if DA3->(DbSeek(xFilial("DA3")+aLinha[nPosPlaca] ))
					nOpc := 4 //alteracao
				Endif
				if nPosCod == 0
					if nOpc == 4
						aadd(aCampos, {"DA3_COD", DA3->DA3_COD }) 
					else
						aadd(aCampos, {"DA3_COD", TpCampo("DA3_COD", aLinha[nPosPlaca]) }) //coloco a placa como codigo
					endif
				endif
			elseif nPosCod > 0
				DA3->(DbSetOrder(1)) //DA3_FILIAL+DA3_COD
				if DA3->(DbSeek(xFilial("DA3")+aLinha[nPosCod] ))
					nOpc := 4 //alteracao
				endif
			endif

			if nOpc == 4
				if !empty(DA3->DA3_XCODCL+DA3->DA3_XLOJCL) .AND. DA3->DA3_XCODCL+DA3->DA3_XLOJCL <> cCodCli+cLojCli
					//nTipImp -> 0 - Perguntar/1 - Sobrescrever/2 - Pular
					if ((nTipImp == 2) .or. (nTipImp == 0 .and. Aviso("Atenção!", "Placa "+DA3->DA3_PLACA+" já vinculada com cliente "+DA3->DA3_XCODCL+"/"+DA3->DA3_XLOJCL+". Deseja sobrescrever ou pular gravação?", {"Sobrescrever", "Pular"}, 2) == 2))
						nLin++
						FT_FSkip()
						LOOP
					endif
				endif
				if !empty(DA3->DA3_XGRPCL) .AND. DA3->DA3_XGRPCL <> cGrpCli
					//nTipImp -> 0 - Perguntar/1 - Sobrescrever/2 - Pular
					if ((nTipImp == 2) .or. (nTipImp == 0 .and. Aviso("Atenção!", "Placa "+DA3->DA3_PLACA+" já vinculada com grupo "+DA3->DA3_XGRPCL+". Deseja sobrescrever ou pular gravação?", {"Sobrescrever", "Pular"}, 2) == 2))
						nLin++
						FT_FSkip()
						LOOP
					endif
				endif
			endif

			//montando array de dados a passar para execauto
			for nX := 1 to len(aCpDef)
				if nPosMot > 0 .AND. aCpDef[nX] == 'DA3_MOTORI' .AND. Len(AllTrim( TpCampo(aCpDef[nX], aLinha[nX]) )) == 11 //se passou o CPF
					//verifico se tem motorista
					cCodDA4 := Posicione("DA4",3,xFilial("DA4")+cCPFMot,"DA4_COD")
					if !empty(cCodDA4)
						aadd(aCampos, {aCpDef[nX], cCodDA4 })
					endif
				else
					aadd(aCampos, {aCpDef[nX], TpCampo(aCpDef[nX], aLinha[nX]) })
				endif
			next nX

			if nPosDesc == 0
				aadd(aCampos, {"DA3_DESC", "."})
			endif
			if nPosCli == 0 .AND. !empty(cCodCli)
				aadd(aCampos, {"DA3_XCODCL", cCodCli})
				aadd(aCampos, {"DA3_XLOJCL", cLojCli})
			endif
			if nPosGrp == 0 .AND. !empty(cGrpCli)
				aadd(aCampos, {"DA3_XGRPCL", cGrpCli})
			endif

			//chama a gravacao execauto MVC
			FWMVCRotAuto(FWLoadModel("OMSA060"),"DA3",nOpc,{{"OMSA060_DA3",aCampos}},,.T.)

			//chama a gravacao execauto MVC
			if !lMsErroAuto
				//Conout("TRETA002-> Linha " + cValTochar(nLin) + " importada com sucesso!")
			else
				//Conout("TRETA002-> Linha " + cValTochar(nLin) + " falha na importacao!")
			endif
		endif

		nLin++
		FT_FSkip()
	enddo

	//Conout("TRETA002-> Fim da importacao!")
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

/*/{Protheus.doc} TRETA02A
Programa de migracao dos dados do antigo cadastro (U08) para o novo (DA3)

@author thebr
@since 24/09/2018
@version 1.0
@return Nil
@type function
/*/
User Function TRETA02A(lEnd)

	Local aCampos //array para execauto
	Local nOpc, nCount := 0
	Local lProcAll := MsgYesNo("Importar todos? 'SIM'- importará todas as amarrações de placa x cliente. 'NAO'- importará apenas os 50 primeiros (para teste)","Importar")
	Local cCPFMot := ""
	Local aSX3DA3, nX

	//Conout("TRETA002-> Iniciando Migracao")
	ProcRegua(1000)

	DbSelectArea("U08")
	U08->(DbSetOrder(1)) //U08_FILIAL+U08_PLACA

	DbSelectArea("U70")
	U70->(DbSetOrder(2)) //U70_FILIAL+U70_PLACA
	U70->(DbGoTop())
	While U70->(!Eof()) .AND. !lEnd .AND. (lProcAll .OR. nCount < 50)

		IncProc("Migrando veículos... "+cValToChar(nCount))

		aCampos := {}
		nOpc := 3 //inclusao

		if len(alltrim(U70->U70_PLACA)) == 7 //somente placas com 7 digitos

			//posiciono no U08
			if U08->(DbSeek(xFilial("U08")+U70->U70_PLACA ))

				DA3->(DbSetOrder(3)) //DA3_FILIAL+DA3_PLACA
				if DA3->(DbSeek(xFilial("DA3")+U08->U08_PLACA ))
					RecLock("DA3", .F.)//altera
				else
					RecLock("DA3", .T.)//inclui

					//inicializa campos
					aSX3DA3 := FWSX3Util():GetAllFields( "DA3" , .F./*lVirtual*/ )
					if !empty(aSX3DA3)
						for nX := 1 to len(aSX3DA3)
							DA3->&(aSX3DA3[nX]) := CriaVar(aSX3DA3[nX], .T.)
						next nX
					endif
				endif

				//campos que vou preencher
				DA3->DA3_FILIAL := xfilial("DA3")
				DA3->DA3_COD := TpCampo("DA3_COD", U70->U70_PLACA)
				DA3->DA3_PLACA := TpCampo("DA3_PLACA", U70->U70_PLACA)

				if len(Alltrim(U08->U08_DES)) > 1
					DA3->DA3_DESC := TpCampo("DA3_DESC", Alltrim(U08->U08_DES))
				else
					DA3->DA3_DESC := TpCampo("DA3_DESC", "VEICULO" )
				endif

				if !empty(U70->U70_CODCLI)
					DA3->DA3_XCODCL := TpCampo("DA3_XCODCL", U70->U70_CODCLI )
					DA3->DA3_XLOJCL := TpCampo("DA3_XLOJCL", U70->U70_LOJA )
				endif
				if !empty(U70->U70_GRUPO)
					DA3->DA3_XGRPCL := TpCampo("DA3_XGRPCL", U70->U70_GRUPO )
				endif

				//verifico se tem motorista
				cCPFMot := Posicione("U36",4,xFilial("U36")+U70->U70_PLACA,"U36_CPF")
				if !empty(cCPFMot)
					DA3->DA3_MOTORI := Posicione("DA4",3,xFilial("DA4")+cCPFMot,"DA4_COD")
				endif

				DA3->(MsUnlock())

			endif
		endif

		nCount++
		U70->(DbSkip())
	Enddo

	//Conout("TRETA002-> Fim da importacao!")

Return


/*/{Protheus.doc} TRETA02B
Programa de migracao dos dados do antigo cadastro (U08) para o novo (DA3)

@author thebr
@since 24/09/2018
@version 1.0
@return Nil
@type function
/*/
User Function TRETA02B(lEnd)

	Local aCampos //array para execauto
	Local nOpc, nCount := 0
	Local lProcAll := MsgYesNo("Importar todos? 'SIM'- importará todas as amarrações de placa x cliente. 'NAO'- importará apenas os 50 primeiros (para teste)","Importar")
	Local cCPFMot := ""
	Local aSX3DA3, nX

	//Conout("TRETA002-> Iniciando Migracao")
	ProcRegua(10000)

	DbSelectArea("U08")
	U08->(DbSetOrder(1)) //U08_FILIAL+U08_PLACA

	cQry := " SELECT * FROM "+RetSqlName("U70")+" U70 WHERE U70.D_E_L_E_T_= ' ' "
	cQry += " AND ((U70_PLACA NOT IN (SELECT DA3_PLACA FROM "+RetSqlName("DA3")+" DA3 WHERE DA3.D_E_L_E_T_= ' ')) "
	cQry += " OR (U70_CODCLI+U70_LOJA+U70_GRUPO <> (SELECT DA3_XCODCL+DA3_XLOJCL+DA3_XGRPCL FROM "+RetSqlName("DA3")+" DA3 WHERE DA3.D_E_L_E_T_= ' ' AND DA3_PLACA = U70_PLACA))) "

	if Select("TU07") > 0
		TU07->(DbCloseArea())
	Endif
	cQry := ChangeQuery(cQry)
	TcQuery cQry New Alias "TU07" // Cria uma nova area com o resultado do query

	While TU07->(!Eof()) .AND. !lEnd

		IncProc("Migrando veículos... "+cValToChar(nCount))

		aCampos := {}
		nOpc := 3 //inclusao

		if len(alltrim(TU07->U70_PLACA)) == 7 //somente placas com 7 digitos

			//posiciono no U08
			if U08->(DbSeek(xFilial("U08")+TU07->U70_PLACA ))

				DA3->(DbSetOrder(3)) //DA3_FILIAL+DA3_PLACA
				if DA3->(DbSeek(xFilial("DA3")+U08->U08_PLACA ))
					RecLock("DA3", .F.)//altera
				else
					RecLock("DA3", .T.)//inclui

					//inicializa campos
					aSX3DA3 := FWSX3Util():GetAllFields( "DA3" , .F./*lVirtual*/ )
					if !empty(aSX3DA3)
						for nX := 1 to len(aSX3DA3)
							DA3->&(aSX3DA3[nX]) := CriaVar(aSX3DA3[nX], .T.)
						next nX
					endif
				endif

				//campos que vou preencher
				DA3->DA3_FILIAL := xfilial("DA3")
				DA3->DA3_COD := TpCampo("DA3_COD", TU07->U70_PLACA)
				DA3->DA3_PLACA := TpCampo("DA3_PLACA", TU07->U70_PLACA)

				if len(Alltrim(U08->U08_DES)) > 1
					DA3->DA3_DESC := TpCampo("DA3_DESC", Alltrim(U08->U08_DES))
				else
					DA3->DA3_DESC := TpCampo("DA3_DESC", "VEICULO" )
				endif

				if !empty(TU07->U70_CODCLI)
					DA3->DA3_XCODCL := TpCampo("DA3_XCODCL", TU07->U70_CODCLI )
					DA3->DA3_XLOJCL := TpCampo("DA3_XLOJCL", TU07->U70_LOJA )
				endif
				if !empty(TU07->U70_GRUPO)
					DA3->DA3_XGRPCL := TpCampo("DA3_XGRPCL", TU07->U70_GRUPO )
				endif

				//verifico se tem motorista
				cCPFMot := Posicione("U36",4,xFilial("U36")+TU07->U70_PLACA,"U36_CPF")
				if !empty(cCPFMot)
					DA3->DA3_MOTORI := Posicione("DA4",3,xFilial("DA4")+cCPFMot,"DA4_COD")
				endif

				DA3->DA3_MSEXP := ""
				DA3->DA3_HREXP := ""

				DA3->(MsUnlock())

			endif
		endif

		nCount++
		TU07->(DbSkip())
	Enddo

	TU07->(DbCloseArea())

	//Conout("TRETA002-> Fim da importacao!")

Return

/*/{Protheus.doc} ExcluiVinc
Desvincula as placas do cliente ou grupo

@author thebr
@since 24/09/2018
@version 1.0
@return Nil
@type function
/*/
User Function TRETA02C(cCodCli,cLojCli,cGrpCli)

	Local cQry
	Default cCodCli := ""
	Default cLojCli := ""
	Default cGrpCli := ""

	if empty(cCodCli+cLojCli+cGrpCli)

		aPergs := {}
		aParamEnc := {}
		aAdd( aPergs ,{1,"Cliente:", Space(TamSX3("DA3_XCODCL")[1]),"@!",'Empty(MV_PAR01).OR.ExistCpo("SA1")',"SA1",'Empty(MV_PAR03)',60,.F.})
		aAdd( aPergs ,{1,"Loja:",Space(TamSX3("DA3_XLOJCL")[1]),"@!",'.T.',"",'Empty(MV_PAR03)',30,.F.})
		aAdd( aPergs ,{1,"Grupo Cliente:",Space(TamSX3("DA3_XGRPCL")[1]),"@!",'Empty(MV_PAR03) .OR. ExistCpo("ACY")',"ACY",'Empty(MV_PAR01)',60,.F.})
		if ParamBox(aPergs ,"Desvincular Cliente/Grupo",@aParamEnc,{|| iif(empty(MV_PAR01+MV_PAR03),MsgInfo("Informe um cliente ou grupo para desvincular placas!","Atencao"),.T.) },,,,,,.F.,.F.)
			cCodCli := aParamEnc[1]
			cLojCli := aParamEnc[2]
			cGrpCli := aParamEnc[3]
			if empty(cCodCli+cLojCli+cGrpCli)
				Return //aborta
			endif
		else
			Return //aborta
		endif

	endif

	cQry := " SELECT DA3.R_E_C_N_O_ RECDA3 FROM "+RetSqlName("DA3")+" DA3 WHERE DA3.D_E_L_E_T_= ' ' "
	if !empty(cCodCli+cLojCli)
		cQry += " AND DA3_XCODCL+DA3_XLOJCL = '"+cCodCli+cLojCli+"' "
	else
		cQry += " AND DA3_XGRPCL = '"+cGrpCli+"' "
	endif

	if Select("TDA3") > 0
		TDA3->(DbCloseArea())
	Endif
	cQry := ChangeQuery(cQry)
	TcQuery cQry New Alias "TDA3" // Cria uma nova area com o resultado do query

	While TDA3->(!Eof())

		DA3->(DBGoto(TDA3->RECDA3 ))

		RecLock("DA3", .F.)//altera

			DA3->DA3_XCODCL := ""
			DA3->DA3_XLOJCL := ""
			DA3->DA3_XGRPCL := ""

			DA3->DA3_MSEXP := ""
			DA3->DA3_HREXP := ""

		DA3->(MsUnlock())

		TDA3->(DbSkip())
	Enddo

	TDA3->(DbCloseArea())

	if !empty(cGrpCli)
		MsgInfo("Placas do grupo "+cGrpCli+" desvinculadas com sucesso!")
	else
		MsgInfo("Placas do cliente "+cCodCli+"/"+cLojCli+" desvinculadas com sucesso!")
	endif

Return

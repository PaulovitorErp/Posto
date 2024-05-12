#include 'protheus.ch'
#include 'parmType.ch'
#include 'poscss.ch'

#DEFINE FONT_NAME 1
#DEFINE FONT_SIZE 2
#DEFINE FONT_BOLD 3
#DEFINE FONT_ITALIC 4
#DEFINE FONT_UNDERLINE 5

Static aFontInfo := { "Arial", 12, .T., .F., .F. }

Static oTBCCliSel
Static cTBCCliSel := ""
Static aUltDados := {"","","","",0,"",""} //cgc, nome, endereço, placa, odomentro, ccgcmotor, cnomemotor
Static lStValCGC := .T.
Static oLimiteBMP
Static oLimiteBTN
Static oChangeTpNF 
Static nChangeTpNf := 0 


/*/{Protheus.doc} TPDVP008
Ponto de entrada StiVlCgc (release 27) ou StValCGC (release 17) de validação da tela de digitação do CPF

@author Danilo Brito
@since 01/10/2018
@version 1.0
@return lRet
@Type function
/*/
User Function TPDVP008()

	Local lRet 		:= .T.
	Local aArea 	:= GetArea()
	Local aAreaSA1 	:= SA1->(GetArea())
	Local cCGC 		:= Alltrim(PARAMIXB[1])
	Local cNome 	:= PARAMIXB[2]
	Local cEnder 	:= PARAMIXB[3]
	Local cPlaca 	:= Alltrim(PARAMIXB[4])
	Local nOdome 	:= PARAMIXB[5]
	Local cCgcCli 	:= ""
	Local cNomCli 	:= ""
	Local lImpOrc 	:= .F.
	
	Local lMvPosto := SuperGetMv("MV_XPOSTO",.F.,.F.) //Habilita Posto de Combustível (Posto Inteligente).
	//Caso o Posto Inteligente não esteja habilitado não faz nada...
	If !lMvPosto
		Return lRet
	EndIf

	//Caso seja do PE StiVlCgc (release 27)
	If Len(PARAMIXB) > 5 //{cCGCCli, cNome, cEND, cPlaca, nKm, cCGCMotor, cNomeMotor }
		lStValCGC 	:= .F.
		cCgcCli 	:= AllTrim(PARAMIXB[1])
		cNomCli 	:= PARAMIXB[2]
		cCGC 		:= Alltrim(PARAMIXB[6])
		cNome 		:= PARAMIXB[7]
	EndIf

	If oTBCCliSel == Nil
		CriaGetCli()
	EndIf

	If !Empty(cCGC) .AND. Empty(cNome)
		STFMessage("TPDVP008_1","STOP", "Informe o Nome do Motorista!" )
		STFShowMessage("TPDVP008_1")
		lRet := .F.
	EndIf

	//Gatilhos de campos a partir dos dados da tela
	If lRet

		If Empty(Alltrim(STDGPBasket("SL1","L1_PLACA"))) .OR. STDGPBasket("SL1","L1_PLACA") <> cPlaca
			STDSPBasket("SL1","L1_PLACA", cPlaca )
		EndIf
		
		//gravacao do nome do motorista
		If SL1->(FieldPos("L1_NOMMOTO")) > 0 .and. Empty(Alltrim(STDGPBasket("SL1","L1_NOMMOTO")))
			STDSPBasket("SL1","L1_NOMMOTO", Upper(SubStr(cNome,1,TamSX3("L1_NOMMOTO")[1])) )
		EndIf

		//gravacao do endereco
		If SL1->(FieldPos("L1_ENDCOB")) > 0 .and. Empty(Alltrim(STDGPBasket("SL1","L1_ENDCOB")))
			STDSPBasket("SL1","L1_ENDCOB", Upper(SubStr(cEnder,1,TamSX3("L1_ENDCOB")[1])) )
		EndIf

		//gatilhar motorista, caso existe amarração de placa com motorista
		If !Empty(cPlaca) .and. SL1->(FieldPos("L1_CGCMOTO")) > 0 .and. Empty(Alltrim(STDGPBasket("SL1","L1_CGCMOTO")))
			DbSelectArea("DA3")
			DA3->(DbSetOrder(3)) //DA3_FILIAL+DA3_PLACA
			If DA3->(DbSeek(xFilial("DA3")+cPlaca)) .and. !Empty(DA3->DA3_MOTORI)
				DA4->(DbSetOrder(1)) //DA4_FILIAL+DA4_COD
				If DA4->(DbSeek(xFilial("DA4")+DA3->DA3_MOTORI))
					STDSPBasket("SL1","L1_CGCMOTO", DA4->DA4_CGC)
					If Empty(Alltrim(STDGPBasket("SL1","L1_NOMMOTO")))
						STDSPBasket("SL1","L1_NOMMOTO", SubStr(DA4->DA4_NOME,1,TamSX3("L1_NOMMOTO")[1]))
					EndIf
				EndIf
			EndIf
		EndIf

		//Verifico se tem orçamentos amarrados a placa
		If lRet .AND. SuperGetMv("TP_ACTORC",,.F.) .AND.  !Empty(cPlaca)
			lImpOrc := MsgOrcPlaca(cPlaca)
		EndIf

		lRet := BuscaCli(cPlaca, cCGC, nOdome, lImpOrc)

	EndIf

	If lRet //guarda o histórico da ultima seleção dos dados
		If lStValCGC
			aUltDados := {cCGC, cNome, cEnder, cPlaca, nOdome}
		Else
			aUltDados := {cCgcCli, cNomCli, cEnder, cPlaca, nOdome, cCGC, cNome}
		EndIf
	EndIf
	
	//tratativa para PDV autopeças, para nao abrir tela de abastecimentos
	if lRet .AND. SuperGetMV("MV_LJPLNAB", ,.F.) .AND. SuperGetMV("MV_LJPDVEN", ,.F.) == .F.
		if !STIGSelVend()
			STISSelVend(.T.)
		endif
	endif

	RestArea(aAreaSA1)
	RestArea(aArea)

Return lRet

//-----------------------------------------------------------------------------------
// Busca cliente a partir da placa, e seta nos campos de memória
//-----------------------------------------------------------------------------------
Static Function BuscaCli(cPlaca, cCGC, nOdome, lImpOrc)

	Local lRet 		:= .T.
	Local lTemPlaca := .F.
	Local cCliSel 	:= STDGPBasket("SL1","L1_CLIENTE")
	Local cLojSel 	:= STDGPBasket("SL1","L1_LOJA")
	Local cCliPad 	:= SuperGetMv("MV_CLIPAD") // Cliente padrao
	Local cLojaPad 	:= SuperGetMV("MV_LOJAPAD") // Loja padrao
	Local oTotal  		:= STFGetTot() 					// Recebe o Objeto totalizador
	Local nTotalVend	:= iif(ValType(oTotal)=="O",oTotal:GetValue("L1_VLRTOT"),0) // Valor total da venda
	Local lBlqAI0 		:= SuperGetMv("MV_XBLQAI0",,.F.) .AND. AI0->(FieldPos("AI0_XBLFIL")) > 0 //Habilita bloqueio de venda na filial, olhando para tabela AI0
	Local aCliByGrp 	:= {}
	Local nPosCliGrp 	:= 1

	//verifico se ja foi selecionado o cliente
	If Empty(cCliSel) .OR. cCliPad+cLojaPad == cCliSel+cLojSel //se nao selecionou, ou é o cliente padrao (gatilho)

		//Aqui começa o tratamento para gatilhar o cliente a partir da placa
		If !Empty(cPlaca) .AND. nTotalVend==0  //somente se nao add itens ainda, pq ai nao pode alterar cliente mais

			LjMsgRun("Buscando cadastro veículo...","Aguarde...",{|| lTemPlaca := BuscaPlaca(cPlaca) })

			//verificar se a placa está amarrada com cliente, e gatilhar
			If lTemPlaca .AND. !Empty(DA3->DA3_XCODCL)
				SA1->(DbSetOrder(1))
				If SA1->(DbSeek(xFilial("SA1")+DA3->DA3_XCODCL+DA3->DA3_XLOJCL))

					// verifico se o cadastro tem autorização para ser utilizado nesta filial/empresa
					If lBlqAI0 .AND. Posicione("AI0",1,xFilial("AI0")+SA1->A1_COD+SA1->A1_LOJA,"AI0_XBLFIL")=="S"
						STFMessage(ProcName(),"STOP", "O cliente "+SA1->A1_COD+"/"+SA1->A1_LOJA+" - "+AllTrim(SA1->A1_NOME)+" não está autorizado nesta filial." )
						STFShowMessage(ProcName())
						lRet := .F.

					ElseIf !lBlqAI0 .AND. SA1->(FieldPos("A1_XFILBLQ")) > 0 .and. !Empty(SA1->A1_XFILBLQ) .and. (cFilAnt $ SA1->A1_XFILBLQ)
						//Aviso("Atenção!", "O cliente "+SA1->A1_COD+"/"+SA1->A1_LOJA+" - "+AllTrim(SA1->A1_NOME)+" não está autorizado nesta filial.", {"OK"}, 2)
						STFMessage(ProcName(),"STOP", "O cliente "+SA1->A1_COD+"/"+SA1->A1_LOJA+" - "+AllTrim(SA1->A1_NOME)+" não está autorizado nesta filial." )
						STFShowMessage(ProcName())
						lRet := .F.

					Else

						If SetCliModel(DA3->DA3_XCODCL, DA3->DA3_XLOJCL, cPlaca, cCGC)
							cCliSel := SA1->A1_COD
							cLojSel := SA1->A1_LOJA
						Else
							STFMessage(ProcName(),"STOP", "Não foi possível atribuir cliente para venda a partir da placa " + cPlaca + "." )
							STFShowMessage(ProcName())
						EndIf

					EndIf
				EndIf

				//verificar se a placa está amarrada com grupo cliente, e gatilhar
			ElseIf lTemPlaca .AND. !empty(DA3->DA3_XGRPCL)

				SA1->(DbSetOrder(6)) //A1_FILIAL+A1_GRPVEN
				If SA1->(DbSeek(xFilial("SA1")+DA3->DA3_XGRPCL))
					While SA1->(!Eof()) .AND. SA1->A1_FILIAL+SA1->A1_GRPVEN == xFilial("SA1")+DA3->DA3_XGRPCL
						// verifico se o cadastro tem autorização para ser utilizado nesta filial/empresa
						If lBlqAI0 .AND. Posicione("AI0",1,xFilial("AI0")+SA1->A1_COD+SA1->A1_LOJA,"AI0_XBLFIL")=="S"
						ElseIf !lBlqAI0 .AND. SA1->(FieldPos("A1_XFILBLQ")) > 0 .and. !Empty(SA1->A1_XFILBLQ) .and. (cFilAnt $ SA1->A1_XFILBLQ)
						Else
							aadd(aCliByGrp, {SA1->A1_COD, SA1->A1_LOJA, SA1->A1_NOME, SA1->A1_MUN, SA1->A1_EST, SA1->A1_CGC } )
						EndIf
						SA1->(DbSkip())
					EndDo
				EndIf

				If len(aCliByGrp) > 0
					aSort(aCliByGrp,,,{|x,y| x[1]+x[2] < y[1]+y[2]}) //ordem crescente: A1_COD + A1_LOJA
					If len(aCliByGrp) > 1
						//abrir tela para seleçao cliente
						nPosCliGrp := U_TPDVP08B(aCliByGrp, DA3->DA3_XGRPCL, cPlaca, .T.)
					EndIf

					If SetCliModel(aCliByGrp[nPosCliGrp][1], aCliByGrp[nPosCliGrp][2], cPlaca, cCGC)
						cCliSel := SA1->A1_COD
						cLojSel := SA1->A1_LOJA
					Else
						STFMessage(ProcName(),"STOP", "Não foi possível atribuir cliente para venda a partir da placa " + cPlaca + "." )
						STFShowMessage(ProcName())
					EndIf

				EndIf

			EndIf
		EndIf

	ElseIf !lImpOrc //se ja selecionou (validacao)

		//Avisos de obrigatoriedade de placa, cliente e amarracao
		SA1->(DbSetOrder(1))
		If SA1->(DbSeek(xFilial("SA1")+cCliSel+cLojSel))
			// verifico se o cadastro tem autorização para ser utilizado nesta filial/empresa
			If lBlqAI0 .AND. Posicione("AI0",1,xFilial("AI0")+SA1->A1_COD+SA1->A1_LOJA,"AI0_XBLFIL")=="S"
				STFMessage(ProcName(),"STOP", "O cliente "+SA1->A1_COD+"/"+SA1->A1_LOJA+" - "+AllTrim(SA1->A1_NOME)+" não está autorizado nesta filial." )
				STFShowMessage(ProcName())
				lRet := .F.

			ElseIf !lBlqAI0 .AND. SA1->(FieldPos("A1_XFILBLQ")) > 0 .and. !Empty(SA1->A1_XFILBLQ) .and. (cFilAnt $ SA1->A1_XFILBLQ)
				//Aviso("Atenção!", "O cliente "+SA1->A1_COD+"/"+SA1->A1_LOJA+" - "+AllTrim(SA1->A1_NOME)+" não está autorizado nesta filial.", {"OK"}, 2)
				STFMessage(ProcName(),"STOP", "O cliente "+SA1->A1_COD+"/"+SA1->A1_LOJA+" - "+AllTrim(SA1->A1_NOME)+" não está autorizado nesta filial." )
				STFShowMessage(ProcName())
				lRet := .F.

			ElseIf SA1->(ColumnPos("A1_XMOTOR")) > 0 .AND. SA1->A1_XMOTOR == "S" .AND. Empty(cCGC)
				//Aviso("Atenção!", "Para o cliente "+Alltrim(SA1->A1_NOME)+",é obrigatório informar o CPF do Motorista!", {"OK"}, 2)
				STFMessage("TPDVP008_1","STOP", "Cliente obriga informar CPF Motorista!" )
				STFShowMessage("TPDVP008_1")
				lRet := .F.

			ElseIf SA1->(ColumnPos("A1_XFROTA")) > 0 .AND. SA1->A1_XFROTA == "S" .AND. Empty(cPlaca)
				//Aviso("Atenção!", "Para o cliente "+Alltrim(SA1->A1_NOME)+", é obrigatório informar a Placa do Veículo!", {"OK"}, 2)
				STFMessage("TPDVP008_1","STOP", "Cliente obriga informar Placa!" )
				STFShowMessage("TPDVP008_1")
				lRet := .F.

			ElseIf SA1->(ColumnPos("A1_XRESTRI")) > 0 .AND. SA1->A1_XRESTRI == "S" .AND. !Empty(cPlaca)
				LjMsgRun("Buscando cadastro veículo...","Aguarde...",{|| lRet := BuscaPlaca(cPlaca) })

				If !lRet .OR. Empty(DA3->DA3_XCODCL+DA3->DA3_XLOJCL+DA3->DA3_XGRPCL) .OR. !(DA3->DA3_XCODCL+DA3->DA3_XLOJCL==SA1->A1_COD+SA1->A1_LOJA .OR. DA3->DA3_XGRPCL==SA1->A1_GRPVEN )
					//Aviso("Atenção!", "A placa "+cPlaca+" informada não está vinculada ao cliente "+Alltrim(SA1->A1_NOME)+"! Cliente exige amarração da placa do veículo!", {"OK"}, 2)
					STFMessage("TPDVP008_1","STOP", "A placa "+cPlaca+" informada não está vinculada ao cliente!" )
					STFShowMessage("TPDVP008_1")
					lRet := .F.

				EndIf
			ElseIf SA1->(ColumnPos("A1_XODOMET")) > 0 .AND. SA1->A1_XODOMET == "S" .AND. Empty(nOdome)
				//Aviso("Atenção!", "Para o cliente "+Alltrim(SA1->A1_NOME)+",é obrigatório informar o valor de Odômetro (KM)!", {"OK"}, 2)
				STFMessage("TPDVP008_1","STOP", "Cliente obriga informar o valor de Odômetro (KM)!" )
				STFShowMessage("TPDVP008_1")
				lRet := .F.

			EndIf
		EndIf

	EndIf

	//atualizo campo nome do cliente na tela
	If lRet .AND. !Empty(cCliSel+cLojSel)
		SA1->(DbSetOrder(1))
		SA1->(DbSeek(xFilial("SA1")+cCliSel+cLojSel))
		U_SetTbcCli(Alltrim(SA1->A1_NOME), SA1->A1_CGC, Alltrim(SA1->A1_MUN)+"-"+SA1->A1_EST)
	EndIf

Return lRet

//----------------------------------------------
//Seta o cliente nos models da venda 
//----------------------------------------------
Static Function SetCliModel(cCodCli, cLojaCli, cPlaca, cCGC)

	Local lRet := .T.
	Local oModelCli

	oModelCli := STWCustomerSelection(cCodCli+cLojaCli)
	If !empty(oModelCli:GetValue("SA1MASTER","A1_COD"))

		//setando cliente na SL1
		STDSPBasket("SL1","L1_CLIENTE" ,oModelCli:GetValue("SA1MASTER","A1_COD"))
		STDSPBasket("SL1","L1_LOJA"  ,oModelCli:GetValue("SA1MASTER","A1_LOJA"))
		STDSPBasket("SL1","L1_TIPOCLI" ,oModelCli:GetValue("SA1MASTER","A1_TIPO"))

		//Copiado do fonte padrao
		//Seta o Cpf/CNPJ do cliente para ser utilizado no Panel de Recebimento de Titulo
		If ExistFunc("STISCnpjRec")
			STISCnpjRec( oModelCli:GetValue("SA1MASTER","A1_CGC") )
			//Responsável por setar codigo do cliente e codigo da loja para o recebimento de titulo
			If ExistFunc("STWSCliLoj")
				STWSCliLoj(oModelCli:GetValue("SA1MASTER","A1_COD"), oModelCli:GetValue("SA1MASTER","A1_LOJA"))
			EndIf
		EndIf

		SA1->(DbSetOrder(1)) //A1_FILIAL+A1_COD+A1_LOJA
		If SA1->(DbSeek(xFilial("SA1")+cCodCli+cLojaCli))
			U_GetRecado(cPlaca,cCGC,SA1->A1_COD,SA1->A1_LOJA,SA1->A1_GRPVEN)
		EndIf
	Else
		lRet := .F.
	EndIf

Return lRet

//-----------------------------------------------------------------------------------
// Busca placa na retaguarda, inclui na base pdv (caso nao tenha) e deixa posicionado caso encontrou
//-----------------------------------------------------------------------------------
Static Function BuscaPlaca(cPlaca)

	Local lRet := .F.
	Local aFields, aTables, cWhere, cOrderBy, aParam, aResult, nX
	Local nLimitRegs := 1
	Local aCpGrava := {}
	Local nCodRet := 0
	Local lHasConnect := .F.
	Local lHostError := .F.
	Local lPlacRet := SuperGetMv("MV_XPLARET",,.F.)

	//primeiro busco a placa na base do PDV
	DbSelectArea("DA3")
	DA3->(DbSetOrder(3)) //DA3_FILIAL+DA3_PLACA
	If DA3->(DbSeek(xFilial("DA3")+cPlaca ))
		lRet := .T.
	EndIf

	If lPlacRet	//se busca placa na retaguarda
		//Monta os campos da query
		aFields := {"DA3_COD", "DA3_DESC", "DA3_PLACA", "DA3_ATIVO", "DA3_XCODCL","DA3_XLOJCL","DA3_XGRPCL"}

		//Tabela da Query
		aTables := {"DA3"}

		//Monta a Cláusula Where da query
		cWhere := " DA3_FILIAL = '"+xFilial("DA3")+"' AND"
		cWhere += " DA3_PLACA = '" + Alltrim(cPlaca) + "' AND"
		cWhere += " D_E_L_E_T_ = ' ' "

		//Monta a Cláusula Order By da query
		cOrderBy := "DA3_PLACA"

		//parametros para busca
		aParam := {aFields, aTables, cWhere,cOrderBy,nLimitRegs}
		aParam := {"STDQueryDB",aParam}

		//busca na retaguarda
		If STBRemoteExecute("_EXEC_RET", aParam,,,@aResult,/*cType*/,/*cKeyOri*/, @nCodRet )
			// Se retornar esses codigos siginifica que a retaguarda esta off
			lHasConnect := !(nCodRet == -105 .OR. nCodRet == -107 .OR. nCodRet == -104)
			// Verifica erro de execucao por parte do host
			//-103 : erro na execução ,-106 : 'erro deserializar os parametros (JSON)
			lHostError := (nCodRet == -103 .OR. nCodRet == -106)

			If lHostError
				//Conout("TPDVP008 - Erro de conexão retagarda")
				lRet := .F.
			EndIf
		ElseIf nCodRet == -101 .OR. nCodRet == -108
			//Conout( "TPDVP008 - Servidor PDV nao Preparado. Funcionalidade nao existe ou host responsavel não associado. Cadastre a funcionalidade e vincule ao Host da Retaguarda.")
			lRet := .F.
		Else
			//Conout("TPDVP008 - Erro de conexão retagarda")
			lRet := .F.
		EndIf

		If lHasConnect .AND. ValType(aResult)=="A" .AND. len(aResult)>0

			//Atualiza algumas informacoes importantes da placa, caso ja cadastrado.
			DA3->(DbSetOrder(1)) //DA3_FILIAL+DA3_COD
			If DA3->(DbSeek(xFilial("DA3")+aResult[1][1] ))
				aadd(aCpGrava, {"DA3_ATIVO", aResult[1][4]} )
				aadd(aCpGrava, {"DA3_XCODCL", aResult[1][5]} )
				aadd(aCpGrava, {"DA3_XLOJCL", aResult[1][6]} )
				aadd(aCpGrava, {"DA3_XGRPCL", aResult[1][7]} )
				LjGrvLog( "Placa",  "Atualiza campos de bloqueio e amarracao" )
				lRet := STFSaveTab( "DA3" , aCpGrava ) //alteracao
			Else
				LjGrvLog( "Placa",  "Placa não encontrada no PDV sera incluído. "+aResult[1][3] )
				For nX := 1 to len(aFields)
					aadd(aCpGrava, {aFields[nX], aResult[1][nX]} )
				Next nX
				lRet := STFSaveTab( "DA3" , aCpGrava , .T. ) //inclusao
			EndIf

			lRet := .T.

		EndIf
	EndIf

	If lRet .AND. DA3->DA3_ATIVO == '2' //se nao está bloqueado
		lRet := .F.
	EndIf

Return lRet

//-----------------------------------------------------------------------------------
// cria um SAY no cabeçalho da tela para por nome do cliente
//-----------------------------------------------------------------------------------
Static Function CriaGetCli()

	Local oTelaPDV, oPnlAux, cCssSay
	Local cCSSRadio
	Local cCor := SuperGetMv( "MV_LJCOLOR",,"07334C")// Cor da tela

	// crio o css para aplicar no radiobutton
	cCSSRadio := " QRadioButton { "
	cCSSRadio += " font-size: 13px; "
	cCSSRadio += " font-weight: bold; color: #FFFFFF; "
	cCSSRadio += " } "
	//cCSSRadio := " QRadioButton::disabled { "
	//cCSSRadio += " font-weight: bold; color: #CCCCCC; "
	//cCSSRadio += " } "
	cCSSRadio += " QRadioButton::indicator { "
	cCSSRadio += "	width: 24px; "
	cCSSRadio += "	height: 24px; "
	cCSSRadio += " } "
	//cCSSRadio += "QRadioButton::indicator::unchecked{ border: 3px solid #FFFFFF; border-radius: 6px; background-color: white; }"
	cCSSRadio += "QRadioButton::indicator::unchecked{ border: 0; background-color: #"+cCor+"; background-image:url(rpo:UNCHECKED.PNG);background-repeat: no-repeat; background-attachment: fixed; background-position: -3px -3px; }"
	//cCSSRadio += "QRadioButton::indicator::checked{ border: 3px solid #FFFFFF; border-radius: 6px; background-color: #"+cCor+"; }"
	cCSSRadio += "QRadioButton::indicator::checked{ border: 0; background-color: #"+cCor+"; background-image:url(rpo:CHECKED.PNG);background-repeat: no-repeat; background-attachment: fixed; background-position: -3px -3px;}"
	//cCSSRadio += "QRadioButton::indicator::disabled{ border: 3px solid #AAAAAA; border-radius: 6px; background-color: #333333; }"

	oTelaPDV := STIGetObjTela() //pego objeto da tela
	oPnlAux := oTelaPDV:oOwner:aControls[1] //pego painel barra superior

	@ 004, 061 BITMAP oLimiteBMP RESOURCE "VENDEDOR" NOBORDER SIZE 012, 012 OF oPnlAux ADJUST PIXEL
	oLimiteBMP:ReadClientCoors(.T.,.T.)
	oLimiteBTN := THButton():New(002, 059, "", oPnlAux, {|| U_TPDVA013(.T.) }, 016, 016,,"Consulta Limite de Crédito (SHIFT+F9)")

	@ 001, 075 SAY oTBCCliSel PROMPT cTBCCliSel SIZE 500,20 OF oPnlAux PIXEL
	cCssSay := "TSay{font: 14px 'Arial'; font-weight: bold; color: #FFFFFF; background-color: transparent; border: none; margin: 0px; }"
	oTBCCliSel:SetCSS( cCssSay ) //POSCSS (GetClassName(oTBCCliSel), CSS_LABEL_NORMAL ) CSS_BREADCUMB

	oChangeTpNF := TRadMenu():New (009,105, {'NFC-e','NF-e'}, {|u|Iif (PCount()==0,nChangeTpNf,nChangeTpNf:=u)},oPnlAux,,,CLR_WHITE,,"Defina o tipo de documento que será emtido.",,,100,12,,,,.T.,.T.)
	oChangeTpNF:SetCss(cCSSRadio)

Return

//-----------------------------------------------------------------------------------
// Seta cliente no label topo da tela
//-----------------------------------------------------------------------------------
User Function SetTbcCli(cNomCli, cCgc, cLocal)

	Local cCliPad 	:= SuperGetMv("MV_CLIPAD") // Cliente padrao
	Local cLojaPad 	:= SuperGetMV("MV_LOJAPAD") // Loja padrao
	Local cMVLOJANF		:= AllTrim( SuperGetMV("MV_LOJANF", .F. ,"UNI") )
	Local lMVFISNOTA	:= SuperGetMV("MV_FISNOTA", .F., .F.) .and. !Empty(cMVLOJANF) .and. cMVLOJANF <> "UNI"
	Local cPlaca := STDGPBasket("SL1","L1_PLACA")
	Local cTextAux1 := ""
	Local cTextAux2 := ""
	Default cCgc := ""
	Default cLocal := ""

	If oTBCCliSel == Nil
		CriaGetCli()
	EndIf

	If Empty(cNomCli)
		cTBCCliSel := ""
		If ValType(oLimiteBMP)=="O"
			oLimiteBMP:Hide()
			oLimiteBTN:Hide()
		EndIf
		if ValType(oChangeTpNF)=="O"
			oChangeTpNF:Hide()
		endif
		nChangeTpNf := 0 
	Else
		cTextAux1 := "Cliente: " + cNomCli + " ("+cLocal+")"
		cTextAux2 := "Tp.Doc: " + Space(50)+;
					"Cod/Loja: " + SA1->A1_COD+"/"+SA1->A1_LOJA + "      " +;
					iif(empty(cCgc),"","CPF/CNPJ: " + cCgc + "      ")+;
					iif(empty(cPlaca),"","Placa: " + cPlaca + "      ")

		//se esta passando pela primeira vez, ou o cliente foi modificado
		if nChangeTpNf == 0 .OR. !("Cod/Loja: " + SA1->A1_COD+"/"+SA1->A1_LOJA $ cTBCCliSel)
			nChangeTpNf := U_TPDVP007(SA1->A1_COD, SA1->A1_LOJA, .T.)
			if nChangeTpNf == 2 .AND. !lMVFISNOTA
				nChangeTpNf := 1 //se vem com NFe mas não está configurado NFe corretamente, mudo pra NFCe
			endif
		endif

		cTBCCliSel := cTextAux1 + chr(13)+chr(10) + cTextAux2 

		if ValType(oChangeTpNF)=="O"
			oChangeTpNF:Show()
			if SA1->A1_COD+SA1->A1_LOJA == cCliPad+cLojaPad .OR. !Empty(SA1->A1_XTIPONF) .OR. !lMVFISNOTA
				oChangeTpNF:Disable()
			else
				oChangeTpNF:Enable()
			endif
		endif

		If ValType(oLimiteBMP)=="O"
			oLimiteBMP:Show()
			oLimiteBTN:Show()
		EndIf
	EndIf

	If ValType(oTBCCliSel)=="O"
		oTBCCliSel:Refresh()
	EndIf

Return

//pega o tipo de nota a ser emitida
User Function TPDVP08T()
Return nChangeTpNf

//-----------------------------------------------------------------------------------
// Verifica se tem orçamentos na central amarrados a placa
//-----------------------------------------------------------------------------------
Static Function MsgOrcPlaca(cPlaca)

	Local lRet				:= .F.
	Local aAux				:= {}	// Armazena retorno função temporariamente
	Local lUserSelect		:= .F.	// Indica se orçamento deve ser selecionado
	Local aOrcamentos		:= {}	// recebe os orçamentos
	Local cOrcAux			:= ""
	Local oTotal, nTotalVend
	Local nX, aImported, lContinua
	Local aSelectedSales := {}, aGetOrc

	oTotal := STFGetTot()
	nTotalVend := iif(ValType(oTotal)=="O",oTotal:GetValue("L1_VLRTOT"),0)
	If nTotalVend == 0
		MsgRun('Buscando orcamentos amarrados a Placa...','Aguarde...',{||aAux := STWISSearchOptions( "L1_PLACA" , cPlaca)})

		lUserSelect 	:= aAux[1]
		aOrcamentos		:= aAux[2]

		If !Empty(aOrcamentos)

			//pego os orçamentos ja importados
			For nX := 1 to len(aOrcamentos)
				cOrcAux += " "+Alltrim(aOrcamentos[nX][1]) + ","
				aAdd(aSelectedSales, {aOrcamentos[nX,1], aOrcamentos[nX,2],;
					aOrcamentos[nX,3], aOrcamentos[nX,4],;
					aOrcamentos[nX,5]}) // Armazena opções de orçamento selecionadas
			Next nX
			cOrcAux := SubStr(cOrcAux,1,len(cOrcAux)-1) //removo ultima virgula

			If Aviso("Atenção", "Existem orçamentos em aberto para esta placa:"+cOrcAux+". Deseja importa-los agora?", {  "Não", "Sim" }, 1) == 2

				//#####################################################################
				// TRECHO COPIADO DO PADRÃO, FUNCAO STIISAfterSelected
				//#####################################################################
				aImported := STWISImpAllSelected( aSelectedSales , "S" )
				lContinua := aImported[1]
				If lContinua

					aGetOrc := STIGetOrc() //pego array do padrão

					/* Guarda o orcamento que esta sendo importado  */
					For nX := 1 to len(aImported[4])
						aadd(aGetOrc, aImported[4][nX])
					Next nX

					/* Cadastra cliente na base local caso não exista */
					STBCadCli(aGetOrc)

					/* Chamar Importação direto */
					STWISRegSale( aImported[4] ) // aAllSales

					/* Atualiza interface */
					STIGridCupRefresh()

					lRet := .T.

				Else
					STFMessage("STIImportSale", "ALERT", "Não foi possível importar os orçamentos" )
					STFShowMessage("STIImportSale")
				EndIf

			EndIf
		EndIf
	EndIf

Return lRet

//-------------------------------------------------------------------
// monta tela de selecao de clientes do gupo amarrado a placa
//-------------------------------------------------------------------
User function TPDVP08B(aCliByGrp, cGrupoCli, cPlaca, lSetCSS)

	Local nRet := 1
	Local cCor := SuperGetMv( "MV_LJCOLOR",,"07334C")// Cor da tela
	Local cCorBack := RGB(hextodec(SubStr(cCor,1,2)),hextodec(SubStr(cCor,3,2)),hextodec(SubStr(cCor,5,2)))
	Local oPnlPrinc, oPanelMnt, oSay1
	Local oListFont := TFont():New("Courier New") 	// Fonte utilizada no listbox
	Local oGetList
	Local cGetList := ""
	Local aCustomers := {}

	Private oDlgSelCli

	Default lSetCSS := .T.

	//limpa as tecla atalho
	U_UKeyCtr()

	DEFINE MSDIALOG oDlgSelCli TITLE "" FROM 000, 000  TO 350, 510 COLORS 0, 16777215 PIXEL OF GetWndDefault() STYLE DS_MODALFRAME

	@ 0,0 MSPANEL oPnlPrinc SIZE 100, 100 OF oDlgSelCli COLORS 0, cCorBack
	oPnlPrinc:Align := CONTROL_ALIGN_ALLCLIENT

	// crio o panel para mudar a cor da tela
	@ 4, 0 MSPANEL oPanelMnt SIZE 253, 175 OF oPnlPrinc //COLORS 0, RGB(40,79,102)
	If lSetCSS
		oPanelMnt:SetCSS( POSCSS (GetClassName(oPanelMnt), CSS_PANEL_CONTEXT ))
	EndIf

	@ 010, 010 SAY oSay1 PROMPT "Seleção Cliente do Grupo" SIZE 235, 015 OF oPanelMnt COLORS 0, 16777215 PIXEL
	If lSetCSS
		oSay1:SetCSS( POSCSS (GetClassName(oSay1), CSS_BREADCUMB ))
	EndIf

	@ 030, 010 SAY oSay1 PROMPT ("Selecione um dos clientes do grupo "+ ;
		Alltrim(Posicione("ACY",1,xFilial("ACY")+cGrupoCli, "ACY_DESCRI" )) + ;
		" que está vinculado a placa "+cPlaca) ;
		SIZE 200, 400 OF oPanelMnt COLORS 0, 16777215 PIXEL
	If lSetCSS
		oSay1:SetCSS( POSCSS (GetClassName(oSay1), CSS_LABEL_FOCAL ))
	EndIf

	oSay1 := TSay():New(060, 010, {|| "Código / Loja / Nome / Cidade / Estado / CPF/CNPJ" }, oPanelMnt,,,,,,.T.)
	If lSetCSS
		oSay1:SetCSS( POSCSS (GetClassName(oSay1), CSS_LABEL_FOCAL ))
	EndIf

	oGetList := TListBox():Create(oPanelMnt, 070, 010, {|u| If(PCount()>0,cGetList:=u,cGetList)}, , 235 , 070,,,,,.T.,,{|| oDlgSelCli:End() },oListFont)
	If lSetCSS
		oGetList:SetCSS( POSCSS (GetClassName(oGetList), CSS_LISTBOX ))
	EndIf
	aEval(aCliByGrp, {|x| aadd(aCustomers, AllTrim(x[1])+" / "+AllTrim(x[2])+" / "+AllTrim(x[3])+" / "+AllTrim(x[4])+" / "+AllTrim(x[5])+" / "+AllTrim(x[6]) ) })
	oGetList:SetArray(aCustomers)

	// BOTAO CONFIRMAR
	oButton3 := TButton():New(145,;
		200,;
		"&Confirmar",;
		oPanelMnt	,;
		{|| oDlgSelCli:End() },;
		45,;
		20,;
		,,,.T.,;
		,,,{|| .T.})
	If lSetCSS
		oButton3:SetCSS( POSCSS (GetClassName(oButton3), CSS_BTN_FOCAL ))
	EndIf

	ACTIVATE MSDIALOG oDlgSelCli CENTERED VALID (nRet:=oGetList:GetPos(), .T.)

	//restaura as teclas atalho
	U_UKeyCtr(.T.)

Return nRet

//-------------------------------------------------------------------
/*/{Protheus.doc} TPDVP08A
Executa a tela para perguntar o CGC
Preencher os dados, com os ultimos dados escolhidos: atalho (SHIFT+F2)
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
User Function TPDVP08A()

	Local oTotal   := STFGetTot() // Recebe o Objeto totalizador
	Local nTotSale := oTotal:GetValue( "L1_VLRTOT" ) //Total da venda que esta em andamento

	If STBOpenCash() //se caixa está aberto
		//verifico se está na tela de conferencia de caixa do pdv
		oTelaPDV :=STIGetObjTela()
		nConfCx := aScan(oTelaPDV:oowner:acontrols, {|x| iif(valtype(x)=="O", x:cCaption == "Conferência de Caixa", .f.) })

		If nConfCx == 0

			//Executa a tela para perguntar o CGC
			//Se não está registrando a partir da importacao orçamento
			If lStValCGC
				If !(nTotSale > 0) .and. (!Empty(aUltDados[1]) .or. !Empty(aUltDados[2]) .or. !Empty(aUltDados[3]) .or. !Empty(aUltDados[4]) .or. !Empty(aUltDados[5]))
					lInfoEnd := .T. //LJAnalisaLeg(58)[1]  //RS Informa o Endereço?
					STIInfoCNPJ(aUltDados[1], aUltDados[2], aUltDados[3], lInfoEnd,;
						.F., aUltDados[4], aUltDados[5])
				EndIf
			Else
				If !(nTotSale > 0) .and. (!Empty(aUltDados[1]) .or. !Empty(aUltDados[2]) .or. !Empty(aUltDados[3]) .or. !Empty(aUltDados[4]) .or. !Empty(aUltDados[5]) .or. !Empty(aUltDados[6]) .or. !Empty(aUltDados[7]))
					lInfoEnd := .T. //LJAnalisaLeg(58)[1]  //RS Informa o Endereço?
					STIInfoCNPJ(aUltDados[1], aUltDados[2], aUltDados[3], lInfoEnd,;
						.F., aUltDados[4], aUltDados[5], aUltDados[6], aUltDados[7])
				EndIf
			EndIf

		EndIf
	EndIf

Return()










//TODO - rotina temporária para teste da validação dos campos do PDV (STIInfoCNPJ.prw)
/*/{Protheus.doc} TPDVP08C
Função de validação de campo das informações da tela do Totvs PDV

@type function
@version 1
@author pablo
@since 26/02/2021
/*/
User Function TPDVP08C()

	Local lRet := .T.
	Local cCampo := ReadVar()
	Local cCGCSA1 := Alltrim(STDGPBasket("SL1","L1_CGCCLI"))
	Local cNomSA1 := STDGPBasket("SL1","L1_NOMCLI")
	Local cCGC   := Alltrim(STDGPBasket("SL1","L1_CGCMOTO"))
	Local cNome  := STDGPBasket("SL1","L1_NOMMOTO")
	Local cEnder := STDGPBasket("SL1","L1_ENDCOB")
	Local cPlaca := Alltrim(STDGPBasket("SL1","L1_PLACA"))
	Local nOdome := STDGPBasket("SL1","L1_ODOMETR")
	Local lImpOrc := .F.

	Local aStiInfoCNPJ := STIGetICNPJ() //aStiInfoCNPJ := {|| {M->cCgcCli, M->cNome, M->cEnd, M->cPlaca, M->nKM, M->cCGCMotor, M->cNomeMotor} }
	cCGCSA1 := aStiInfoCNPJ[1]
	cNomSA1 := aStiInfoCNPJ[2]
	cEnder := aStiInfoCNPJ[3]
	cPlaca := aStiInfoCNPJ[4]
	nOdome := aStiInfoCNPJ[5]
	cCGC   := aStiInfoCNPJ[6]
	cNome  := aStiInfoCNPJ[7]

	aFldCPF		:= STDISSearchField("L1_CGCCLI")
	aFldNomcli	:= STDISSearchField("L1_NOMCLI")
	aFldCPFMot	:= STDISSearchField("L1_CGCMOTO")
	aFldNomMot	:= STDISSearchField("L1_NOMMOTO")
	aFldPlaMot	:= STDISSearchField("L1_PLACA")
	aFldKmMot	:= STDISSearchField("L1_ODOMETR")
	aFldEnd		:= STDISSearchField("L1_ENDCOB")

	If oTBCCliSel == Nil
		CriaGetCli()
	EndIf

	//Verifico se tem orçamentos amarrados a placa
	If lRet .AND. SuperGetMv("TP_ACTORC",,.F.) .AND.  !Empty(cPlaca)
		lImpOrc := MsgOrcPlaca(cPlaca)
	EndIf

	Do Case
	Case cCampo $ "CCGCCLI" //gatilha o nome do cliente, caso já exista

		If Empty(cNomSA1)
			cNomSA1 := Posicione("SA1",3,xFilial("SA1")+cCGCSA1,"A1_NOME") //A1_FILIAL+A1_CGC
			If !Empty(cNomSA1)
				STDSPBasket("SL1","L1_NOMCLI", cNomSA1)
				M->L1_NOMCLI := cNomSA1
			EndIf
		EndIf

		BuscaCli(cPlaca, cCGCSA1, nOdome, lImpOrc)

	Case cCampo $ "CCGCMOTOR" //gatilha o nome do motorista, caso já exista cadastrado

		If Empty(cNome)
			cNome := Posicione("DA4",3,xFilial("DA4")+cCGC,"DA4_NOME") //DA4_FILIAL+DA4_CGC
			If !Empty(cNome)
				STDSPBasket("SL1","L1_NOMMOTO", SubStr(cNome,1,TamSX3("L1_NOMMOTO")[1]))
				M->L1_NOMMOTO := SubStr(cNome,1,TamSX3("L1_NOMMOTO")[1])
			EndIf
		EndIf

		If !Empty(cCGC) .AND. Empty(cNome)
			STFMessage("TPDVP008_1","STOP", "Informe o Nome do Motorista!" )
			STFShowMessage("TPDVP008_1")
			//lRet := .F.
		EndIf

	Case cCampo == "M->A1_XLIMSQ"
	Case cCampo $ "ACY_XBLPRZ/ACY_XBLRSA
	OtherWise
	End Case

Return lRet

#include "protheus.ch"
#include "topconn.ch"
#include "fwmvcdef.ch"

/*/{Protheus.doc} TRETM010
Pontos de Entrada - Manutenção LMC
@author TOTVS
@since 26/10/2018
@version P12
@param Nao recebe parametros
@return nulo
/*/
User Function TRETM010()

	Local aParam 		:= PARAMIXB
	Local oObj			:= aParam[1]
	Local cIdPonto		:= aParam[2]
	Local oModelMIE		:= oObj:GetModel("MIEMASTER")
	Local nOperation 	:= oObj:GetOperation()

	Local xRet 			:= .T.

	Local nI

	Local aPerda		:= {}
	Local aGanho		:= {}
	Local dBkpDt		:= CToD("")

	Local lLmcKard		:= SuperGetMV("MV_XLMCKAR",,.F.) //habilita ajuste perda ou ganho pelo kardex

	If cIdPonto == 'MODELVLDACTIVE' .And. nOperation == 1 //Ativação do model na visualização
		if ChkFile("U0I")
			U_TRETE039(MIE->MIE_DATA,MIE->MIE_CODPRO)
		endif
	ElseIf cIdPonto == 'MODELVLDACTIVE' .And. nOperation == 3 //Ativação do model na inclusão

		If !ValidPerg()
			Help( ,, 'Help - GeraLMC',, 'Operação cancelada.', 1, 0 )
			xRet := .F.
		Else
			If Empty(MV_PAR01)
				Help( ,, 'Help - GeraLMC',, 'O parâmetro Produto é obrigatório.', 1, 0 )
				xRet := .F.
			Endif
		Endif

	ElseIf cIdPonto == 'BUTTONBAR'
		xRet := {{"Detalhar","DET",{|| MsgRun("Processando...","Aguarde",{|| U_DETPAG(oModelMIE:GetValue('MIE_DATA'),oModelMIE:GetValue('MIE_CODPRO'))})}, "Detalhar"}}

	ElseIf cIdPonto ==  'MODELPRE' .And. nOperation == 3 //Antes da inclusão

		//Tratamento para não dar a mensagem de formulário não alterado
		dBkpDt := oModelMIE:GetValue('MIE_DATA')
		oModelMIE:LoadValue('MIE_DATA',SToD("20991231"))
		oModelMIE:LoadValue('MIE_DATA',dBkpDt)

	ElseIf cIdPonto == 'MODELPOS' .And. nOperation == 3 //Confirmação da inclusão

		//Atualiza perda e ganhos
		xRet := U_TRETE012(1)

		If xRet

			//Se necessário, realiza movimentações internas
			For nI := 1 To Len(__aEstFec)

				if lLmcKard  //se atualizo perda/ganho pelo kardex, sempre vou atualizar coparando o campo estoque final do tanque
					__aEstFec[nI][1] := U_TRETE09B(oModelMIE:GetValue('MIE_CODPRO'), oModelMIE:GetValue('MIE_DATA'), StrZero(nI,2))
				endif

				If !lLmcKard .AND. __aEstFec[nI][3] > 0 //Houve medição agregada

					If __aEstFec[nI][1] <> oModelMIE:GetValue('MIE_VTAQ' + StrZero(nI,2)) //Houve também manipulação manual

						If __aEstFec[nI][1] - oModelMIE:GetValue('MIE_VTAQ' + StrZero(nI,2)) > 0

							//Acumula os Movimentos Internos de perda
							If __aEstFec[nI][1] - oModelMIE:GetValue('MIE_VTAQ' + StrZero(nI,2)) > 0 //.And. oModelMIE:GetValue('MIE_PERDA') > 0
								AAdd(aPerda,{StrZero(nI,2),__aEstFec[nI][1] - oModelMIE:GetValue('MIE_VTAQ' + StrZero(nI,2))})
							Endif
						Else
							//Acumula os Movimentos Internos de ganho
							If oModelMIE:GetValue('MIE_VTAQ' + StrZero(nI,2)) - __aEstFec[nI][1] > 0 //.And. oModelMIE:GetValue('MIE_GANHOS') > 0
								aAdd(aGanho,{StrZero(nI,2),oModelMIE:GetValue('MIE_VTAQ' + StrZero(nI,2)) - __aEstFec[nI][1]})
							Endif
						Endif
					Else

						If __aEstFec[nI][3] <> __aEstFec[nI][2] //Se a medição é diferente do estoque de fechamento (puro)

							If __aEstFec[nI][3] >= __aEstFec[nI][2] //Se a medição é maior que o estoque de fechamento (puro)

								//Acumula os Movimentos Internos de ganho
								If __aEstFec[nI][3] - __aEstFec[nI][2] > 0 //.And. oModelMIE:GetValue('MIE_GANHOS') > 0
									aAdd(aGanho,{StrZero(nI,2),__aEstFec[nI][3] - __aEstFec[nI][2]})
								Endif
							Else
								//Acumula os Movimentos Internos de perda
								If __aEstFec[nI][2] - __aEstFec[nI][3] > 0 //.And. oModelMIE:GetValue('MIE_PERDA') > 0
									aAdd(aPerda,{StrZero(nI,2),__aEstFec[nI][2] - __aEstFec[nI][3]})
								Endif
							Endif
						Endif
					Endif
				Else
					If __aEstFec[nI][1] <> oModelMIE:GetValue('MIE_VTAQ' + StrZero(nI,2))

						If __aEstFec[nI][1] - oModelMIE:GetValue('MIE_VTAQ' + StrZero(nI,2)) > 0
							//Acumula os Movimentos Internos de perda
							If __aEstFec[nI][1] - oModelMIE:GetValue('MIE_VTAQ' + StrZero(nI,2)) > 0 //.And. oModelMIE:GetValue('MIE_PERDA') > 0
								aAdd(aPerda,{StrZero(nI,2),__aEstFec[nI][1] - oModelMIE:GetValue('MIE_VTAQ' + StrZero(nI,2))})
							Endif
						Else
							//Acumula os Movimentos Internos de ganho
							If oModelMIE:GetValue('MIE_VTAQ' + StrZero(nI,2)) - __aEstFec[nI][1] > 0 //.And. oModelMIE:GetValue('MIE_GANHOS') > 0
								aAdd(aGanho,{StrZero(nI,2),oModelMIE:GetValue('MIE_VTAQ' + StrZero(nI,2)) - __aEstFec[nI][1]})
							Endif
						Endif
					Endif
				Endif

			Next nI

			Begin Transaction

			If Len(aPerda) > 0
				FWMsgRun(,{|| xRet := GeraSD3(1,oModelMIE:GetValue('MIE_DATA'),oModelMIE:GetValue('MIE_CODPRO'),aPerda)},"Aguarde","Processando Perdas...")
			Endif

			If xRet .AND. Len(aGanho) > 0
				FWMsgRun(,{|| xRet := GeraSD3(2,oModelMIE:GetValue('MIE_DATA'),oModelMIE:GetValue('MIE_CODPRO'),aGanho)},"Aguarde","Processando Sobras...")
			Endif

			if !xRet 
				DisarmTransaction()
			endif

			End Transaction

			if xRet
				FWMsgRun(,{|| GravaU0I(3, oModelMIE:GetValue('MIE_CODPRO'), oModelMIE:GetValue('MIE_DATA')) },"Aguarde","Gravando Histórico Vendas LMC...")
			endif
		Endif

	ElseIf cIdPonto == 'MODELPOS' .And. nOperation == 5 //Confirmação da exclusão

		dUlMes := If(FindFunction("MVUlmes"),MVUlmes(),GetMV("MV_ULMES"))
		If oModelMIE:GetValue('MIE_DATA') > dUlMes
			If VldExc(oModelMIE:GetValue('MIE_DATA'),oModelMIE:GetValue('MIE_CODPRO'))
				EstSD3(oModelMIE:GetValue('MIE_DATA'),oModelMIE:GetValue('MIE_CODPRO'))

				GravaU0I(5,oModelMIE:GetValue('MIE_CODPRO'), oModelMIE:GetValue('MIE_DATA'))
			Else
				xRet := .F.
				Help(,,'Help - MODELPOS',, 'A exclusão pode ser executada somente na última página LMC gerada.', 1, 0 )
			Endif
		Else
			xRet := .F.
			Help(NIL, NIL, "Help - MODELPOS", NIL, "Não pode ser digitado movimento com data anterior a última data de fechamento (vifada de saldos).", 1, 0, NIL, NIL, NIL, NIL, NIL, {"Utilizar data posterior ao último fechamento de estoque (MV_ULMES) / posterior à data de bloqueio de movimentos (MV_DBLQMOV)."})
		EndIf
	Endif

Return xRet


/*/{Protheus.doc} ValidPerg
Perguntas SX1
@author thebr
@since 30/11/2018
@version 1.0
@return Nil
@type function
/*/
Static Function ValidPerg()

	Local aHelpPor := {}

	U_uAjusSx1(cPerg,"01",OemToAnsi("Produto            ?"),"","","mv_ch1","C",15,0,0,"G","","SB1","","","mv_par02","","","","","","","","","","","","","","","","",aHelpPor,{},{})

Return Pergunte(cPerg,.T.)


/*/{Protheus.doc} GeraSD3
Gravaçao SD3
@author thebr
@since 30/11/2018
@version 1.0
@return Nil
@param nTp, numeric, descricao
@param dData, date, descricao
@param cProd, characters, descricao
@param aItens, array, descricao
@type function
/*/
User Function TRM010GE(nTp,dData,cProd,aItens)
Return GeraSD3(nTp,dData,cProd,aItens)
Static Function GeraSD3(nTp,dData,cProd,aItens)

	Local lRet			:= .T.
	Local nI
	Local aSD3Cab		:= {}
	Local aSD3Itens		:= {}

	Local cTm			:= IIF(nTp == 1,GetMv("MV_XTMPERD"),GetMv("MV_XTMGANH"))
	//Ajustar o Tipo de Movimento com o campo Valorizado (F5_VAL) igual a "N" 
	//-> Se preenchido com N, indica que o custo da movimentação será valorizado automaticamente.	
	
	Local cTq			:= ""

	If Type("lMSErroAuto") <> "L"
		Private lMsHelpAuto := .T. // se .t. direciona as mensagens de help
		Private lMsErroAuto	:= .F.
	EndIf

	If Empty(cTm)
		Help( ,, 'Help - GeraLMC',, 'Favor verificar o preenchimento dos parâmetros MV_XTMPERD e MV_XTMGANH.', 1, 0 )
		Return .F.
	Endif

	aSD3Cab := {{"D3_TM"		,cTm 			,Nil},;
				{"D3_EMISSAO"	,dData			,Nil}}

	SF5->(DbSetOrder(1)) //F5_FILIAL+F5_CODIGO
	SF5->(DbSeek(xFilial("SF5")+cTm))

	DbSelectArea("MHZ")

	For nI := 1 To Len(aItens)
		cTq := ""

		MHZ->(DbGoTop())
		MHZ->(DbSetOrder(3)) //MHZ_FILIAL+MHZ_CODPRO+MHZ_LOCAL

		If MHZ->(DbSeek(xFilial("MHZ")+cProd))

			While MHZ->(!EOF()) .And. MHZ->MHZ_FILIAL == xFilial("MHZ") .And. MHZ->MHZ_CODPRO == cProd
				if ((MHZ->MHZ_STATUS == '1' .AND. MHZ->MHZ_DTATIV <= dData) .OR. (MHZ->MHZ_STATUS == '2' .AND. MHZ->MHZ_DTDESA >= dData))
					If MHZ->MHZ_CODTAN == aItens[nI][1]
						cTq := MHZ->MHZ_LOCAL //MHZ->MHZ_CODTAN
						Exit
					Endif
				endif
				MHZ->(DbSkip())
			EndDo
		Endif

		If !Empty(cTq)
			AAdd(aSD3Itens,{{"D3_COD" 		,cProd	 		,Nil},;
			{"D3_QUANT"		,aItens[nI][2]	,Nil},;
			{"D3_LOCAL" 	,cTq			,Nil};
			})
			/*
			Quando o Tipo de Movimento for Valorizado (F5_VAL) igual a "S", irá gerar o erro: A240VALSD3
			O Campo Custo da Movimentação não foi preenchido, portanto este registro não será gravado. 
			(Este campo só é obrigatório caso o campo F5_VAL esteja com o conteúdo "S").
			*/
		Endif

	Next nI

	//Begin Transaction

		lMsHelpAuto := .T.
		lMsErroAuto	:= .F.
		MSExecAuto({|x,y,z| MATA241(x,y,z)},aSD3Cab,aSD3Itens,3) //3 - Inclusão
		If lMsErroAuto
			MostraErro()
			DisarmTransaction()
			lRet := .F.
		Endif

	//End Transaction

Return lRet

/*/{Protheus.doc} VldExc
Valida Exclusao

@author thebr
@since 30/11/2018
@version 1.0
@return Nil
@param nReg, numeric, descricao
@param cProd, characters, descricao
@type function
/*/
Static Function VldExc(dData,cProd)

	Local lRet := .T.
	Local cQry	:= ""

	If Select("QRYLMC") > 0
		QRYLMC->(DbCloseArea())
	Endif

	cQry := "SELECT MIE.R_E_C_N_O_"
	cQry += " FROM "+RetSqlName("MIE")+" MIE"
	cQry += " WHERE MIE.D_E_L_E_T_ = ' '"
	cQry += " AND MIE.MIE_FILIAL = '"+xFilial("MIE")+"'"
	cQry += " AND MIE.MIE_DATA > "+DTOS(dData)+""
	cQry += " AND MIE.MIE_CODPRO = '"+cProd+"'"

	cQry := ChangeQuery(cQry)
	//MemoWrite("c:\temp\TRETM010.txt",cQry)
	TcQuery cQry NEW Alias "QRYLMC"

	If QRYLMC->(!EOF())
		lRet :=  .F.
	Endif

	If Select("QRYLMC") > 0
		QRYLMC->(DbCloseArea())
	EndIf

Return lRet

/*/{Protheus.doc} EstSD3
Estorno da SD3
@author thebr
@since 30/11/2018
@version 1.0
@return Nil
@param dData, date, descricao
@param cProd, characters, descricao
@type function
/*/
User Function TRM010ES(dData,cProd)
Return EstSD3(dData,cProd)
Static Function EstSD3(dData,cProd)

	Local lRet			:= .T.

	Local aSD3Cab		:= {}
	Local nSD3Rec		:= 0
	Local aSD3Iten		:= {}
	Local aSD3Itens		:= {}

	Local cTmPerda		:= GetMv("MV_XTMPERD")
	Local cTmGanho		:= GetMv("MV_XTMGANH")
	//Ajustar o Tipo de Movimento com o campo Valorizado (F5_VAL) igual a "N" 
	//-> Se preenchido com N, indica que o custo da movimentação será valorizado automaticamente.	

	Local cQry			:= ""
	Local aDocs			:= {}
	Local cChaveSD3 	:= ""

	If Type("lMSErroAuto") <> "L"
		Private lMsHelpAuto := .T. // se .t. direciona as mensagens de help
		Private lMsErroAuto	:= .F.
	EndIf

	If Select("QRYSD3") > 0
		QRYSD3->(DbCloseArea())
	Endif

	cQry := "SELECT R_E_C_N_O_"
	cQry += " FROM "+RetSqlName("SD3")+""
	cQry += " WHERE D_E_L_E_T_ 	<> '*'"
	cQry += " AND D3_FILIAL 	= '"+xFilial("SD3")+"'"
	cQry += " AND (D3_TM		= '"+cTmPerda+"' OR D3_TM = '"+cTmGanho+"')"
	cQry += " AND D3_COD		= '"+cProd+"'"
	cQry += " AND D3_EMISSAO 	= '"+DToS(dData)+"'"
	cQry += " AND D3_ESTORNO	<> 'S'" //filtrando não estornados
	cQry += " ORDER BY D3_FILIAL, D3_DOC, D3_NUMSEQ"

	cQry := ChangeQuery(cQry)
	//MemoWrite("c:\temp\RPOS009.txt",cQry)
	TcQuery cQry NEW Alias "QRYSD3"

	DbSelectArea("SD3")

	//mv_par04 -> Quanto ao Estorno: 1=Por Documento; 2=Por Item
	mv_par04 := 2 //TODO: forçamos para fazer estorno por ITEM, pois por DOCUMENTO estava dando problema...
	If (mv_par04 == 1) //estorno: 1=Por Documento
		cChaveSD3 := "SD3->D3_DOC"
	Else //estorno : 2=Por Item
		cChaveSD3 := "SD3->D3_DOC+SD3->D3_NUMSEQ"
	EndIf
	
	aDocs := {}
	While QRYSD3->(!EOF())

		SD3->(DbGoTo(QRYSD3->R_E_C_N_O_))

		If aScan(aDocs,{|x| x == &(cChaveSD3)}) <= 0 

			If lRet .and. Len(aSD3Cab) > 0 .and. Len(aSD3Itens) > 0
				lMsHelpAuto := .T.
				lMsErroAuto	:= .F.
				SD3->(DbGoTo(nSD3Rec)) //posiciono no SD3 do cabeçalho
				MSExecAuto({|x,y,z| MATA241(x,y,z)},aSD3Cab,aSD3Itens,6) //6 - Estorno
				If lMsErroAuto
					MostraErro()
					lRet := .F.
					Exit //sai do While
				Endif
				SD3->(DbGoTo(QRYSD3->R_E_C_N_O_))
			EndIf

			aSD3Cab := {}
			aSD3Itens := {}
			aSD3Cab := {{"D3_DOC"		,SD3->D3_DOC	, nil},;
						{"D3_TM"        ,SD3->D3_TM     , nil},;
						{"D3_EMISSAO"   ,SD3->D3_EMISSAO, nil}}	
			nSD3Rec := SD3->(RecNo()) //guardo o recno do SD3 do cabeçalho

			AAdd(aDocs,&(cChaveSD3))

		EndIf

		If SD3->D3_ESTORNO == 'S' //documento já estornado
			QRYSD3->(DbSkip())
			Loop
		EndIf

		aSD3Iten:={ {"D3_COD" 	  ,SD3->D3_COD        ,nil},;
					{"D3_UM"      ,SD3->D3_UM         ,nil},;
					{"D3_QUANT"   ,SD3->D3_QUANT      ,nil},;
					{"D3_LOCAL"   ,SD3->D3_LOCAL      ,nil},;
					{"D3_LOTECTL" ,SD3->D3_LOTECTL    ,nil}}
          
    	aadd(aSD3Itens,aSD3Iten)

		QRYSD3->(DbSkip())
	EndDo

	If lRet .and. Len(aSD3Cab) > 0 .and. Len(aSD3Itens) > 0
		lMsHelpAuto := .T.
		lMsErroAuto	:= .F.
		SD3->(DbGoTo(nSD3Rec)) //posiciono no SD3 do cabeçalho
		MSExecAuto({|x,y,z| MATA241(x,y,z)},aSD3Cab,aSD3Itens,6) //Estorno
		If lMsErroAuto
			MostraErro()
			lRet := .F.
		Endif
	EndIf

	If Select("QRYSD3") > 0
		QRYSD3->(DbCloseArea())
	Endif

Return lRet


/*/{Protheus.doc} GravaU0I
Grava hitorico de vendas LCM

@author thebr
@since 10/08/2020
@version 1.0
@return Nil
@param nOpc, numeric, 3=Inclui, 5=Exclui
@param cProd, characters, descricao
@param dData, date, descricao
@type function
/*/
Static Function GravaU0I(nOpc,cProd, dData)

	Local oLMC 
	Local nX

	DbSelectArea("U0I")
	U0I->(DbSetOrder(1)) //U0I_FILIAL+DTOS(U0I_DATA)+U0I_PROD+U0I_TANQUE+U0I_BICO

	if nOpc == 5
		if U0I->(DbSeek(xFilial("U0I")+DTOS(dData)+cProd ))
			While U0I->(!Eof()) .AND. U0I->(U0I_FILIAL+DTOS(U0I_DATA)+U0I_PROD) == xFilial("U0I")+DTOS(dData)+cProd
				Reclock("U0I", .F.)
				U0I->(DbDelete())
				U0I->(MsUnlock())
				U0I->(DbSkip())
			Enddo
		endif

	else

		oLMC := TLmcLib():New(cProd, dData)
		oLMC:SetTRetVen(2) //1=Vlr Total Vendas; 2=Array Dados; 3=Qtd Registros
		oLMC:SetDRetVen({"_TANQUE", "_BICO", "_NLOGIC", "_BOMBA", "_FECH", "_ABERT", "_AFERIC", "_VDBICO"})

		//retorna dados de vendas
		aDados := oLMC:RetVen(.T.)

		for nX := 1 to len(aDados)
			Reclock("U0I", .T.) 

			U0I->U0I_FILIAL := xFilial("U0I")
			U0I->U0I_DATA 	:= dData
			U0I->U0I_PROD 	:= cProd
			U0I->U0I_TANQUE 	:= aDados[nX][1]
			U0I->U0I_BICO 	:= aDados[nX][2]
			U0I->U0I_NLOGIC 	:= aDados[nX][3]
			U0I->U0I_BOMBA 	:= aDados[nX][4]
			U0I->U0I_ENCFEC 	:= aDados[nX][5]
			U0I->U0I_ENCABE 	:= aDados[nX][6]
			U0I->U0I_AFERIC 	:= aDados[nX][7]
			U0I->U0I_VDBICO 	:= aDados[nX][8]
			U0I->U0I_ATUALI	:= "N" //teve atualização? S=Sim;N=Nao

			U0I->(MsUnlock())
		next nX

	endif
	
Return

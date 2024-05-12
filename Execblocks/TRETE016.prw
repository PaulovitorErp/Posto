#include 'protheus.ch'
#include 'topconn.ch'

#Define CRLF chr(13)+chr(10)

/*/{Protheus.doc} TRETE016
Gera liquidação de títulos via ExecAuto(FINA460)
@author Maiki Perin
@since 19/07/2018
@version P12
@param Nao recebe parametros
@return nulo
/*/

/**************************************************************************************************************************************************/
User Function TRETE016(_aReg,cCliFat,cLojaFat,nOpcAuto,cNumLiqCan,lFatFat,lFlex,dDtVencRen,nAcresRen,nDecresRen,cHist,aParcelas,aParcOrig,;
						aParcMult,nSldOrig,aCpoComp,lFatFatCart,_aVlrAcess)
/***************************************************************************************************************************************************/

Local nI, nZ
Local cFiltro 		:= ""
Local aTam 			:= {}
Local cNum			:= ""
Local aRetorno		:= {}
Local aAreaAux

Local nPosTipo		:= U_TRE017CP(5,"nPosTipo")
Local nPosPrefixo	:= U_TRE017CP(5,"nPosPrefixo")
Local nPosNumero	:= U_TRE017CP(5,"nPosNumero")
Local nPosParcela	:= U_TRE017CP(5,"nPosParcela")
Local nPosCliente	:= U_TRE017CP(5,"nPosCliente")
Local nPosLoja		:= U_TRE017CP(5,"nPosLoja")
Local nPosCondPg	:= U_TRE017CP(5,"nPosCondPg")
Local nPosEmissao	:= U_TRE017CP(5,"nPosEmissao")
Local nPosVencto	:= U_TRE017CP(5,"nPosVencto")
Local nPosSaldo		:= U_TRE017CP(5,"nPosSaldo")
Local nPosAcresc	:= U_TRE017CP(5,"nPosAcresc")
Local nPosDecres	:= U_TRE017CP(5,"nPosDecres")
Local nPosVlAcess	:= U_TRE017CP(5,"nPosVlAcess")
Local nPosRecno		:= U_TRE017CP(5,"nPosRecno")

Local cAuxCond		:= ""
Local nDiasVenc		:= SuperGetMv("MV_XDIASVC",.F.,1)
Local lVencCf		:= SuperGetMv("MV_XVENCCF",.F.,.F.)
Local lCalcVenc		:= SuperGetMv("MV_XCALVEN",.F.,.F.)
Local lValcCond		:= SuperGetMv("MV_XVALCON",.F.,.T.) // Valida se a condição dos titulos selecionados são iguais, quando MV_XCALVEN estiver ativo.
Local nRecCond		:= 0
Local aConds		:= {}
Local aParcVenc 	:= {}
Local nDiasCf		:= 0
Local cPfxCf		:= ""
Local dDtEmis		:= CToD("")
Local cCliCf 		:= ""
Local cLojaCf		:= ""
Local aTipos		:= {}
//Local cQry			:= ""

Local nSldTit		:= 0
Local nSldAux		:= 0

//Local aParcelas		:= {}
Local aCab			:= {}
Local aItens		:= {}

Local cNat			:= SuperGetMv( "MV_XNATFAT" , .F. , "OUTROS    ",)
Local lFatNatOr		:= SuperGetMv("MV_XFTNATO",,.F.) //define se a fatura irá assuimir a mesma natureza dos titulos origem

Local lContinua		
//Local cUsrFat		:= ""

Local cPref			:= ""
Local cParc			:= ""
Local nVlrParc		:= 0
Local nVlrAux		:= 0
Local cPfxCmp		:= SuperGetMv("MV_XPFXCOM", .F., "CMP")
Local cCondCF		:= SuperGetMv("MV_XCONDCF", .F., "")
Local nVlrBrt		:= 0
Local nVlrTaxas		:= 0
Local lHasCard		:= .F.
Local cLogFatur		:= ""
Local cDirLogs		:= "\autocom\faturas\"+cEmpAnt+cFilAnt+"\"+PadL(Month(dDatabase),2,"0")+cValToChar(Year(dDatabase))+"\"
Local lLogFat		:= SuperGetMV("MV_XLOGFAT",,.T.) //habilita gravacao de log ao gerar faturas
Local aDUPNUMLIQ 	:= {}
Local aFO0NUMLIQ 	:= {}

Private lMsErroAuto	:= .F.

Private dDtVenc		:= CToD("")
Private nAcresTit	:= 0
Private nDescTit	:= 0
//Private nTxCobr		:= 0
Private nSldFlex	:= 0
Private __cNumParc  := "" //número título/parcela da fatura (variável usada no PE SE5FI460)

Private oGetVlAces

Default lFatFat		:= .F.
Default lFlex		:= .F.
Default lFatFatCart := .F.
Default dDtVencRen	:= CToD("")
Default nAcresRen	:= 0
Default nDecresRen	:= 0
Default cHist		:= Space(TamSX3("E1_HIST")[1])
Default aParcelas	:= {}
Default aParcOrig	:= {}
Default aParcMult	:= {}
Default nSldOrig	:= 0
Default aCpoComp	:= {}
Default _aVlrAcess  := {}

Private __aTitTR016	:= {} //variavel usada no PE_FINA460A TRETP018
Private aVlrAcess := _aVlrAcess

lHasCard := lFatFatCart

If nOpcAuto == 3 .Or. nOpcAuto == 4 // Liquidação ou Reliquidação
	if lFatNatOr
		cNat := ""
	endif
	if lLogFat
		U_TRETE20A(cDirLogs) //cria pasta para logs
		cLogFatur += "TRETE016 - INICIO " + DTOC(date()) + " " + Time() +CRLF
		cLogFatur += "Rotina origem: " + FunName()+CRLF
		cLogFatur += "Titulos que irao compor a fatura: (CHAVESE1|E1_VLRREAL|E1_VALOR|E1_SALDO)"+CRLF
	endif
	//PABLO: tratamento para evitar a criação de NCC na liquidação, caso um dos titulos selecionado tenha sido baixado ou náo possua saldo
	For nI := 1 To Len(_aReg)
		SE1->(DbGoTo(_aReg[nI][nPosRecno]))
		If SE1->(Eof()) //título pode ter sido baixado por outra rotina (concorrencia)
			If !IsBlind()
				MsgInfo("O Título ["+AllTrim(_aReg[nI][nPosNumero])+"] não foi encontrado, operação não permitida.","Atenção")
			Endif
			Return aRetorno
		ElseIf (SE1->E1_SALDO <= 0) //título com saldo zerado (completamente baixado)
			If !IsBlind()
				MsgInfo("O Título ["+AllTrim(SE1->E1_NUM)+"] não possui saldo, operação não permitida.","Atenção")
			Endif
			Return aRetorno
		EndIf

		if lLogFat
			cLogFatur += "|" +SE1->E1_FILIAL + SE1->E1_PREFIXO + SE1->E1_NUM + SE1->E1_PARCELA + ;
							SE1->E1_TIPO + SE1->E1_CLIENTE + SE1->E1_LOJA + ;
							"|" + STR(SE1->E1_VLRREAL) + "|" + STR(SE1->E1_VALOR) + "|" + STR(SE1->E1_SALDO) +CRLF
			nSldAux += SE1->E1_SALDO
		endif

		if SE1->E1_VLRREAL > 0
			nVlrBrt += SE1->E1_VLRREAL
			nVlrTaxas += (SE1->E1_VLRREAL - SE1->E1_VALOR)
		else
			nVlrBrt += SE1->E1_VALOR
		endif

		if !lHasCard .AND. Alltrim(SE1->E1_TIPO) $ "CC/CD"
			lHasCard := .T.
		endif

		if lFatNatOr .AND. empty(cNat)
			cNat := SE1->E1_NATUREZ
		endif
	Next nI

	if lLogFat
		cLogFatur += "Total Vlr Bruto: " + Str(nVlrBrt) +CRLF
		cLogFatur += "Total Saldo: " + Str(nSldAux) +CRLF
		nSldAux := 0
	endif
	if lFatNatOr .AND. empty(cNat)
		cNat := SuperGetMv( "MV_XNATFAT" , .F. , "OUTROS    ",)
	endif

	If nOpcAuto == 3 //Liquidação
		
		cPref := "FAT"
		cParc := Strzero(1,TamSX3("E1_PARCELA")[1])

		if !empty(cNumLiqCan)
			cNum := cNumLiqCan
		else
			//Gera número da fatura
			aTam 	:= TamSx3("E1_NUM")
			cNum	:= Soma1(GetMv("MV_NUMFAT"), aTam[1])
			cNum	+= Space(aTam[1] - Len(cNum))

			//tratativa para não pegar uma numeração já utilizada
			SE1->(DbSetOrder(1)) //E1_FILIAL+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO
			While SE1->(DbSeek(xFilial("SE1")+cPref+cNum+cParc+"FT " ))
				cNum	:= Soma1(cNum, aTam[1])
				cNum	+= Space(aTam[1] - Len(cNum))
			EndDo
			PutMvPar("MV_NUMFAT", cNum )
		endif

		if lLogFat
			cLogFatur += "Numero da fatura: " + cNum +CRLF
		endif

		//tratativa para gerar número único: YYYYMMDDHHMMSS
		cDtHrFiltro := DtoS(Date())+StrTran(Time(),':','')+cNum

		//DANILO: NOVO FILTRO
		/*__aTitTR016 := aClone(_aReg)
		cFiltro += "E1_FILIAL == '"+xFilial("SE1")+"'"
		cFiltro += " .And. Empty(E1_NUMLIQ)"
		cFiltro += " .And. aScan(__aTitTR016,{|x|"
		cFiltro += " E1_CLIENTE == x["+cValToChar(nPosCliente)+"]"
		cFiltro += " .AND. E1_LOJA == x["+cValToChar(nPosLoja)+"]"
		cFiltro += " .AND. E1_PREFIXO == x["+cValToChar(nPosPrefixo)+"]"
		cFiltro += " .AND. E1_NUM == x["+cValToChar(nPosNumero)+"]"
		cFiltro += " .AND. E1_PARCELA == x["+cValToChar(nPosParcela)+"]"
		cFiltro += " .AND. E1_TIPO == x["+cValToChar(nPosTipo)+"]"
		cFiltro += " }) > 0" */
		cFiltro += "E1_FILIAL == '"+xFilial("SE1")+"'"
		cFiltro += " .AND. E1_JURFAT = '"+cDtHrFiltro+"'" //num ordem pagamento
		cFiltro += " .AND. E1_SALDO > 0 " //para evitar erro execauto FO1_SALDO obrigatorio
		If !lFatFatCart //retirado rotina importar extrato, pois pode haver liquidaçao dos titulos de cartão para juntar
			cFiltro += " .AND. Empty(E1_NUMLIQ)" 
		endif

		if lLogFat
			cLogFatur += "Filtro: " + cFiltro +CRLF
		endif

		For nI := 1 To Len(_aReg)

			SE1->(DbGoTo(_aReg[nI][nPosRecno]))
			Reclock("SE1",.F.)
				SE1->E1_JURFAT := cDtHrFiltro
			SE1->(MsUnlock())
			aadd(__aTitTR016, SE1->E1_FILIAL + SE1->E1_PREFIXO + SE1->E1_NUM + SE1->E1_PARCELA + ;
							SE1->E1_TIPO + SE1->E1_CLIENTE + SE1->E1_LOJA)

			//COMENTADO POR DANILO.
			//ESTAVA GERANDO ERRO Filter greater than 2000 bytes. NO EXECAUTO.
			//VIDE: https://tdn.totvs.com/pages/viewpage.action?pageId=118885093
			/*
			If Len(_aReg) == 1
			
				//E1_FILIAL+E1_CLIENTE+E1_LOJA+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO
				cFiltro += "E1_FILIAL == '"+xFilial("SE1")+"'"
				cFiltro += " .And. E1_CLIENTE	== '"+_aReg[nI][nPosCliente]+"'"
				cFiltro += " .And. E1_LOJA 		== '"+_aReg[nI][nPosLoja]+"'"
				cFiltro += " .And. E1_PREFIXO 	== '"+_aReg[nI][nPosPrefixo]+"'"
				cFiltro += " .And. E1_NUM 		== '"+_aReg[nI][nPosNumero]+"'"
				cFiltro += " .And. E1_PARCELA 	== '"+_aReg[nI][nPosParcela]+"'"
				cFiltro += " .And. E1_TIPO 		== '"+_aReg[nI][nPosTipo]+"'"
				cFiltro += " .And. Empty(E1_NUMLIQ)"
			Else
				
				If nI == 1
					cFiltro += "("
				Else
					cFiltro += ") .Or. ("
				Endif
				
				//E1_FILIAL+E1_CLIENTE+E1_LOJA+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO
				cFiltro += "E1_FILIAL == '"+xFilial("SE1")+"'"
				cFiltro += " .And. E1_CLIENTE	== '"+_aReg[nI][nPosCliente]+"'"
				cFiltro += " .And. E1_LOJA 		== '"+_aReg[nI][nPosLoja]+"'"
				cFiltro += " .And. E1_PREFIXO 	== '"+_aReg[nI][nPosPrefixo]+"'"
				cFiltro += " .And. E1_NUM 		== '"+_aReg[nI][nPosNumero]+"'"
				cFiltro += " .And. E1_PARCELA 	== '"+_aReg[nI][nPosParcela]+"'"
				cFiltro += " .And. E1_TIPO 		== '"+_aReg[nI][nPosTipo]+"'"
				cFiltro += " .And. Empty(E1_NUMLIQ)"
				
				If nI == Len(_aReg)
					cFiltro += ")"
				Endif
			Endif
			*/

			If Empty(dDtEmis)
				dDtEmis := CToD(_aReg[nI][nPosEmissao]) //Dt. vencimento
			Else
				If dDtEmis < CToD(_aReg[nI][nPosEmissao])
					dDtEmis := CToD(_aReg[nI][nPosEmissao])
				Endif
			Endif

			If Empty(dDtVenc)
				dDtVenc := CToD(_aReg[nI][nPosVencto]) //Dt. vencimento
			Else
				If dDtVenc < CToD(_aReg[nI][nPosVencto])
					dDtVenc := CToD(_aReg[nI][nPosVencto])
				Endif
			Endif

			If lCalcVenc
				If Len(aConds) > 0
					If lValcCond
						If aScan(aConds,{|x| AllTrim(x) == _aReg[nI][nPosCondPg]}) == 0
							If !IsBlind()
								MsgInfo("Dentre os registros selecionados, há condições de pagamento distintas, operação cancelada!","Atenção")
							Endif
							Return aRetorno
						Endif
					Else
						lCalcVenc := .F.
					EndIf
				Else
					AAdd(aConds,_aReg[nI][nPosCondPg])
					nRecCond := _aReg[nI][nPosRecno]
				Endif
			Endif

			If lVencCf
				If Len(aTipos) > 0
					If aScan(aTipos,{|x| AllTrim(x) == AllTrim(_aReg[nI][nPosTipo])}) == 0
						If !IsBlind()
							MsgInfo("Dentre os registros selecionados, há tipos de títulos disntintos, operação cancelada!","Atenção")
						Endif
						Return aRetorno
					Endif
				Else
					If AllTrim(_aReg[nI][nPosTipo]) == "CF" //Carta Frete
						AAdd(aTipos,_aReg[nI][nPosTipo])
						cPfxCf	:= _aReg[nI][nPosPrefixo]
						cCliCf 	:= _aReg[nI][nPosCliente]
						cLojaCf	:= _aReg[nI][nPosLoja]
					Endif
				Endif
			Endif
			//SE NECESSARIO, AJUSTA A DATA DE VENCIMENTO
			
			//Se a data de vencimento for inferior a data atual
			If dDtVenc <= dDataBase
				dDtVenc := dDataBase + nDiasVenc
			Endif
			
			//Se o intervalo entre a data de vencimento e a data atual for inferior a quantidade de dias necessários
			If dDtVenc - dDataBase < nDiasVenc
				dDtVenc := dDtVenc + (nDiasVenc - (dDtVenc - dDataBase))
			Endif

			//Tratamento diferenciado para Faturamento Manual
			If AllTrim(FunName()) == "TRETE017" .And. lCalcVenc .and. nRecCond > 0
			
				DbSelectArea("SE1")
				SE1->(DbGoTo(nRecCond))
			
				cAuxCond := SE1->E1_XCOND
			
				If !Empty(cAuxCond)
			
			   		DbSelectArea("SE4")
					SE4->(DbSetOrder(1)) //E4_FILIAL+E4_CODIGO
			
			   		If SE4->(DbSeek(xFilial("SE4")+cAuxCond))
						If SE4->E4_TIPO == '1' .AND. VAL(SE4->E4_COND) > 0
			   				dDtVenc := dDataBase + Val(SE4->E4_COND)
						EndIf
				    Endif
				Endif
			Endif
			
			//Tratamento diferenciado para Carta Frete
			If AllTrim(_aReg[nI][nPosTipo]) == "CF" .AND. lVencCf .And. Len(aTipos) == Len(_aReg)
					
				//prioriza o do proprio titulo (ja feita escolha no pdv qual a condição)
				cAuxCond := _aReg[nI][nPosCondPg] 

				//senao, tenta pegar do cliente
				if Empty(cAuxCond)
					cAuxCond := Posicione("SA1",1,xFilial("SA1")+cCliCf+cLojaCf,"A1_XCONDCF")
				endif

				//quando compensacao
				if Empty(cAuxCond) .AND. SE1->E1_PREFIXO == cPfxCmp .AND. !empty(cCondCF)
					cAuxCond := cCondCF
				endif

				If !Empty(cAuxCond)
				    aParcVenc 	:= Condicao(1,cAuxCond,0.00,dDatabase,0.00,{},,0)
					if Len(aParcVenc) > 0 //caso nao encontre a condicao na SE4, retorna vazio
						nDiasCf		:= aParcVenc[1][1] - dDataBase
						dDtVenc 	:= dDtEmis + nDiasCf
				
						If dDtVenc < dDataBase
							dDtVenc := dDataBase + 1
						EndIf
					endif
				Endif
			Endif

			dDtVenc := DataValida(dDtVenc) //Compatibilidade com a data de vencimento do Boleto Bancário

			//FIM AJUSTE DATA DE VENCIMENTO

			If ValType(_aReg[nI][nPosSaldo]) == "C" //Saldo
				nSldTit += Val(StrTran(StrTran(cValToChar(_aReg[nI][nPosSaldo]),".",""),",","."))
			Else
				nSldTit += _aReg[nI][nPosSaldo]
			Endif

			//add Danilo, para considerar acrescimos e decrescimos dos titulos
			If ValType(_aReg[nI][nPosAcresc]) == "C" //acrescimos
				nSldTit += Val(StrTran(StrTran(cValToChar(_aReg[nI][nPosAcresc]),".",""),",","."))
			Else
				nSldTit += _aReg[nI][nPosAcresc]
			Endif
			If ValType(_aReg[nI][nPosDecres]) == "C" //decrescimos
				nSldTit -= Val(StrTran(StrTran(cValToChar(_aReg[nI][nPosDecres]),".",""),",","."))
			Else
				nSldTit -= _aReg[nI][nPosDecres]
			Endif
			If ValType(_aReg[nI][nPosVlAcess]) == "C" //Valores acessórios
				nSldTit += Val(StrTran(StrTran(cValToChar(_aReg[nI][nPosVlAcess]),".",""),",","."))
			Else
				nSldTit += _aReg[nI][nPosVlAcess]
			Endif
		Next nI

		if lLogFat
			cLogFatur += "Total Saldo Liq: " + Str(nSldTit) +CRLF
		endif
	
	Else //Reliquidação

		cNum := _aReg[1][nPosNumero]

		if lLogFat
			cLogFatur += "Numero da reliquidacao: " + cNum +CRLF
		endif
		
		//DANILO NOVO FILTRO
		/*__aTitTR016 := aClone(_aReg)
		cFiltro += "E1_FILIAL == '"+xFilial("SE1")+"'"
		cFiltro += " .And. !Empty(E1_NUMLIQ)"
		cFiltro += " .And. aScan(__aTitTR016, {|x|"
		cFiltro += " E1_CLIENTE == x["+cValToChar(nPosCliente)+"]"
		cFiltro += " .AND. E1_LOJA == x["+cValToChar(nPosLoja)+"]"
		cFiltro += " .AND. E1_PREFIXO == x["+cValToChar(nPosPrefixo)+"]"
		cFiltro += " .AND. E1_NUM == x["+cValToChar(nPosNumero)+"]"
		cFiltro += " .AND. E1_PARCELA == x["+cValToChar(nPosParcela)+"]"
		cFiltro += " .AND. E1_TIPO == x["+cValToChar(nPosTipo)+"]"
		cFiltro += " }) > 0"*/
		cFiltro += "E1_FILIAL == '"+xFilial("SE1")+"'"
		cFiltro += " .AND. E1_JURFAT = 'RELIQ"+cNum+"'" //num ordem pagamento
		cFiltro += " .AND. E1_SALDO > 0 " //para evitar erro execauto FO1_SALDO obrigatorio
		cFiltro += " .AND. !Empty(E1_NUMLIQ)"

		if lLogFat
			cLogFatur += "Filtro: " + cFiltro +CRLF
		endif

		For nI := 1 To Len(_aReg)
			
			SE1->(DbGoTo(_aReg[nI][nPosRecno]))
			Reclock("SE1",.F.)
				SE1->E1_JURFAT := "RELIQ"+cNum
			SE1->(MsUnlock())
			aadd(__aTitTR016, SE1->E1_FILIAL + SE1->E1_PREFIXO + SE1->E1_NUM + SE1->E1_PARCELA + ;
							SE1->E1_TIPO + SE1->E1_CLIENTE + SE1->E1_LOJA)

			//COMENTADO POR DANILO.
			//ESTAVA GERANDO ERRO Filter greater than 2000 bytes. NO EXECAUTO.
			//VIDE: https://tdn.totvs.com/pages/viewpage.action?pageId=118885093
			/*If Len(_aReg) == 1
			
				//E1_FILIAL+E1_CLIENTE+E1_LOJA+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO
				cFiltro += "E1_FILIAL == '"+xFilial("SE1")+"'"
				cFiltro += " .And. E1_CLIENTE	== '"+_aReg[nI][nPosCliente]+"'"
				cFiltro += " .And. E1_LOJA 		== '"+_aReg[nI][nPosLoja]+"'"
				cFiltro += " .And. E1_PREFIXO 	== '"+_aReg[nI][nPosPrefixo]+"'"
				cFiltro += " .And. E1_NUM 		== '"+_aReg[nI][nPosNumero]+"'"
				cFiltro += " .And. E1_PARCELA 	== '"+_aReg[nI][nPosParcela]+"'"
				cFiltro += " .And. E1_TIPO 		== '"+_aReg[nI][nPosTipo]+"'"
				cFiltro += " .And. !Empty(E1_NUMLIQ)"
			Else
				
				If nI == 1
					cFiltro += "("
				Else
					cFiltro += ") .Or. ("
				Endif
				
				//E1_FILIAL+E1_CLIENTE+E1_LOJA+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO
				cFiltro += "E1_FILIAL == '"+xFilial("SE1")+"'"
				cFiltro += " .And. E1_CLIENTE	== '"+_aReg[nI][nPosCliente]+"'"
				cFiltro += " .And. E1_LOJA 		== '"+_aReg[nI][nPosLoja]+"'"
				cFiltro += " .And. E1_PREFIXO 	== '"+_aReg[nI][nPosPrefixo]+"'"
				cFiltro += " .And. E1_NUM 		== '"+_aReg[nI][nPosNumero]+"'"
				cFiltro += " .And. E1_PARCELA 	== '"+_aReg[nI][nPosParcela]+"'"
				cFiltro += " .And. E1_TIPO 		== '"+_aReg[nI][nPosTipo]+"'"
				cFiltro += " .And. !Empty(E1_NUMLIQ)"
				
				If nI == Len(_aReg)
					cFiltro += ")"
				Endif
			Endif*/

			If Empty(dDtVencRen)
				dDtVencRen := CToD(_aReg[nI][nPosVencto]) //Dt. vencimento
			Else
				If dDtVencRen < CToD(_aReg[nI][nPosVencto])
					dDtVencRen := CToD(_aReg[nI][nPosVencto])
				Endif
			Endif
					
			If ValType(_aReg[nI][nPosSaldo]) == "C" //Saldo
				nSldTit += Val(StrTran(StrTran(cValToChar(_aReg[nI][nPosSaldo]),".",""),",","."))
			Else
				nSldTit += _aReg[nI][nPosSaldo]
			Endif

			//add Danilo, para considerar acrescimos e decrescimos dos titulos
			If ValType(_aReg[nI][nPosAcresc]) == "C" //acrescimos
				nSldTit += Val(StrTran(StrTran(cValToChar(_aReg[nI][nPosAcresc]),".",""),",","."))
			Else
				nSldTit += _aReg[nI][nPosAcresc]
			Endif
			If ValType(_aReg[nI][nPosDecres]) == "C" //decrescimos
				nSldTit -= Val(StrTran(StrTran(cValToChar(_aReg[nI][nPosDecres]),".",""),",","."))
			Else
				nSldTit -= _aReg[nI][nPosDecres]
			Endif
			If ValType(_aReg[nI][nPosVlAcess]) == "C" //Valores acessórios
				nSldTit += Val(StrTran(StrTran(cValToChar(_aReg[nI][nPosVlAcess]),".",""),",","."))
			Else
				nSldTit += _aReg[nI][nPosVlAcess]
			Endif

		Next nI

		if lLogFat
			cLogFatur += "Total Saldo Liq: " + Str(nSldTit) +CRLF
		endif
	Endif

	If lFlex //Fatura Flexível
		if lLogFat
			cLogFatur += "Tela Flex: "  +CRLF
		endif
		lContinua := TelaFlex(dDtVenc,nSldTit, lHasCard, nVlrBrt, nVlrTaxas, @cHist, cCliFat,cLojaFat)
		If !lContinua
			Return aRetorno
		Endif
		if lLogFat
			cLogFatur += "Saldo apos Tela Flex: " + Str(nSldFlex) +CRLF
		endif
	Endif

	If nOpcAuto == 3 //Liquidação
		
		cParc := Strzero(1,TamSX3("E1_PARCELA")[1])
		While !empty(Posicione("SE1",1,xFilial("SE1")+cPref+cNum+cParc+"FT ", "E1_NUM"))
			cParc := Soma1(cParc)
		enddo
	
		//Array do processo automatico (aAutoCab)
		aCab := {{"cCondicao",	"001"},;
				{"cNatureza",	cNat},;
				{"E1_TIPO",		"FT "},;
				{"cCLIENTE",	cCliFat},;
				{"nMoeda",		1},; 
				{"cLOJA",		cLojaFat}}

		cPref := "FAT"
	
		//------------------------------------------------------------
		//Monta as parcelas de acordo com a condição de pagamento
		//------------------------------------------------------------
		//aParcelas := Condicao(nValor,cCond,,dDataBase)
		
		//--------------------------------------------------------------
		//Não é possivel mandar Acrescimo e Decrescimo junto.
		//Se mandar os dois valores maiores que zero considera Acrescimo
		//--------------------------------------------------------------
		//For nZ := 1 to Len(aParcelas)
			
			If Len(aCpoComp) > 0 .And. aScan(aCpoComp,{|x| x[1] == "E1_VENCTO"}) > 0
				dDtVenc := aCpoComp[aScan(aCpoComp,{|x| x[1] == "E1_VENCTO"})][2]
			EndIf
			If Len(aCpoComp) > 0 .And. aScan(aCpoComp,{|x| x[1] == "E1_ACRESC"}) > 0
				nAcresTit := aCpoComp[aScan(aCpoComp,{|x| x[1] == "E1_ACRESC"})][2]
			EndIf
			If Len(aCpoComp) > 0 .And. aScan(aCpoComp,{|x| x[1] == "E1_DECRESC"}) > 0
				nDescTit := aCpoComp[aScan(aCpoComp,{|x| x[1] == "E1_DECRESC"})][2]
			EndIf
	
			AAdd(aItens,{{"E1_PREFIXO",	cPref},; 				//Prefixo
						{"E1_BCOCHQ",	""},;					//Banco
						{"E1_AGECHQ",	""},;					//Agencia
						{"E1_CTACHQ",	""},;			 		//Conta
						{"E1_NUM",		cNum},; 				//Nro. cheque (dará origem ao numero do titulo)
						{"E1_PARCELA",	cParc},; 				//Parcela
						{"E1_EMITCHQ",	"EXECAUTO"},; 			//Emitente do cheque
						{"E1_VENCTO",	dDtVenc},;				//Data boa 
						{"E1_VLCRUZ",	nSldTit},;		 		//Valor do cheque/titulo
						{"E1_ACRESC",	nAcresTit},;			//Acrescimo
						{"E1_DECRESC",	nDescTit};				//Decrescimo
						})

			if lLogFat
				cLogFatur += "Parcelas Destino: (CHAVESE1|E1_VALOR|E1_ACRESC|E1_DECRESC) "+CRLF
				cLogFatur += "|" +cFilAnt + cPref + cNum + cParc + "FT " + cCliFat + cLojaFat + ;
							"|" + STR(nSldTit) + "|" + STR(nAcresTit) + "|" + STR(nDescTit) +CRLF
			endif

			//cNum := Soma1(cNum, Len( Alltrim(cNum))) 
		//Next nZ
	
	Else // Reliquidação  

		cPref := "REN"

		if lLogFat
			cLogFatur += "Parcelas Destino: (CHAVESE1|E1_VALOR|E1_ACRESC|E1_DECRESC) "+CRLF
		endif

		//------------------------------------------------------------
		//Monta as parcelas de acordo com a condição de pagamento
		//------------------------------------------------------------
		//aParcelas := Condicao(nValor,cCond,,dDataBase)
		
		//--------------------------------------------------------------
		//Não é possivel mandar Acrescimo e Decrescimo junto.
		//Se mandar os dois valores maiores que zero considera Acrescimo
		//--------------------------------------------------------------
		
		If Len(aParcelas) > 0 // Renegociação com parcelamento via cond. pagto.

			//Array do processo automatico (aAutoCab)
			aCab := {{"cCondicao",	"001"},;
					{"cNatureza",	cNat},;
					{"E1_TIPO",		"FT "},;
					{"cCLIENTE",	cCliFat},;
					{"nMoeda",		1},; 
					{"cLOJA",		cLojaFat}}
		
			For nZ := 1 to Len(aParcelas)
				
				If nZ == 1
					aAreaAux := SE1->(GetArea())
					If Empty(_aReg[1][nPosParcela])
						cParc := Strzero(1,TamSX3("E1_PARCELA")[1])
					Else
						cParc := Soma1(_aReg[1][nPosParcela])
					EndIf
					While !empty(Posicione("SE1",1,xFilial("SE1")+cPref+cNum+cParc+"FT ", "E1_NUM"))
						cParc := Soma1(cParc)
					enddo
					RestArea(aAreaAux)
				Else
					cParc := Soma1(cParc)
					//cParc := PadR(Soma1(AllTrim(cParc)),TamSX3("E1_PARCELA")[1])
				EndIf

				nSldAux += aParcelas[nZ][2]
		
				AAdd(aItens,{{"E1_PREFIXO",	cPref},; 				//Prefixo
							{"E1_BCOCHQ",	""},;					//Banco
							{"E1_AGECHQ",	""},;					//Agencia
							{"E1_CTACHQ",	""},;		 			//Conta
							{"E1_NUM",		cNum},; 				//Nro. cheque (dará origem ao numero do titulo)
							{"E1_PARCELA",	cParc},; 				//Parcela
							{"E1_EMITCHQ",	"EXECAUTO"},; 			//Emitente do cheque
							{"E1_VENCTO",	aParcelas[nZ][1]}})		//Data boa 				
		
				If nZ == Len(aParcelas) // Última parcela

					// Acrescenta acréscimo ou decréscimo
					nVlrParc := aParcelas[nZ][2]

					If nSldAux - (nSldOrig + nAcresRen -nDecresRen) > 0 //Acréscimo
						nVlrAux := nVlrParc - (nSldAux - (nSldOrig + nAcresRen -nDecresRen))
					ElseIf (nSldOrig + nAcresRen -nDecresRen) - nSldAux > 0 //Decréscimo
						nVlrAux := nVlrParc + ((nSldOrig + nAcresRen -nDecresRen) - nSldAux)
					Endif
					
					If nVlrAux > 0
					
						AAdd(aItens[Len(aItens)], {"E1_VLCRUZ", nVlrAux})											//Valor do cheque/titulo
						AAdd(aItens[Len(aItens)], {"E1_ACRESC", IIF(nSldAux - (nSldOrig + nAcresRen -nDecresRen) > 0,nSldAux - (nSldOrig + nAcresRen -nDecresRen),0)})	//Acrescimo
						AAdd(aItens[Len(aItens)], {"E1_DECRESC", IIF((nSldOrig + nAcresRen -nDecresRen) - nSldAux > 0,(nSldOrig + nAcresRen -nDecresRen) - nSldAux,0)})	//Decrescimo
					Else
						AAdd(aItens[Len(aItens)], {"E1_VLCRUZ", nVlrParc})	//Valor do cheque/titulo
						AAdd(aItens[Len(aItens)], {"E1_ACRESC", 0})			//Acrescimo
						AAdd(aItens[Len(aItens)], {"E1_DECRESC", 0})		//Decrescimo
					Endif
				Else
					AAdd(aItens[Len(aItens)], {"E1_VLCRUZ", aParcelas[nZ][2]})	//Valor do cheque/titulo
					AAdd(aItens[Len(aItens)], {"E1_ACRESC", 0})					//Acrescimo
					AAdd(aItens[Len(aItens)], {"E1_DECRESC", 0})				//Decrescimo
				Endif

				if lLogFat
					cLogFatur += "|" +cFilAnt + cPref + cNum + cParc + "FT " + cCliFat + cLojaFat + ;
							"|" + STR(aItens[Len(aItens)][9][2]) + "|" + STR(aItens[Len(aItens)][10][2]) + "|" + STR(aItens[Len(aItens)][11][2]) +CRLF
				endif

			Next nZ
		
		ElseIf Len(aParcMult) > 0 // Renegociação com parcelamento flexível

			//Array do processo automatico (aAutoCab)
			aCab := {{"cCondicao",	"001"},;
					{"cNatureza",	cNat},;
					{"E1_TIPO",		"FT "},;
					{"cCLIENTE",	cCliFat},;
					{"nMoeda",		1},; 
					{"cLOJA",		cLojaFat}}
		
			For nZ := 1 to Len(aParcMult)

				If nZ == 1
					aAreaAux := SE1->(GetArea())
					If Empty(_aReg[1][nPosParcela])
						cParc := Strzero(1,TamSX3("E1_PARCELA")[1])
					Else
						cParc := Soma1(_aReg[1][nPosParcela])
					EndIf
					While !empty(Posicione("SE1",1,xFilial("SE1")+cPref+cNum+cParc+"FT ", "E1_NUM"))
						cParc := Soma1(cParc)
					enddo
					RestArea(aAreaAux)
				Else
					cParc := Soma1(cParc)
					//cParc := PadR(Soma1(AllTrim(cParc)),TamSX3("E1_PARCELA")[1])
				EndIf

				nSldAux += aParcMult[nZ][2]

				AAdd(aItens,{{"E1_PREFIXO",	cPref},; 				//Prefixo
							{"E1_BCOCHQ",	""},;					//Banco
							{"E1_AGECHQ",	""},;					//Agencia
							{"E1_CTACHQ",	""},;		 			//Conta
							{"E1_NUM",		cNum},; 				//Nro. cheque (dará origem ao numero do titulo)
							{"E1_PARCELA",	cParc},; 				//Parcela
							{"E1_EMITCHQ",	"EXECAUTO"},; 			//Emitente do cheque
							{"E1_VENCTO",	aParcMult[nZ][1]}})		//Data boa 

				If nZ == Len(aParcMult) // Última parcela

					// Acrescenta acréscimo ou decréscimo
					nVlrParc := aParcMult[nZ][2]

					If nSldAux - (nSldOrig + nAcresRen -nDecresRen) > 0 //Acréscimo
						nVlrAux := nVlrParc - (nSldAux - (nSldOrig + nAcresRen -nDecresRen))
					ElseIf (nSldOrig + nAcresRen -nDecresRen) - nSldAux > 0 //Decréscimo
						nVlrAux := nVlrParc + ((nSldOrig + nAcresRen -nDecresRen) - nSldAux)
					Endif
					
					If nVlrAux > 0
					
						AAdd(aItens[Len(aItens)], {"E1_VLCRUZ", nVlrAux})											//Valor do cheque/titulo
						AAdd(aItens[Len(aItens)], {"E1_ACRESC", IIF(nSldAux - (nSldOrig + nAcresRen -nDecresRen) > 0,nSldAux - (nSldOrig + nAcresRen -nDecresRen),0)})	//Acrescimo
						AAdd(aItens[Len(aItens)], {"E1_DECRESC", IIF((nSldOrig + nAcresRen -nDecresRen) - nSldAux > 0,(nSldOrig + nAcresRen -nDecresRen) - nSldAux,0)})	//Decrescimo
					Else
						AAdd(aItens[Len(aItens)], {"E1_VLCRUZ", nVlrParc})	//Valor do cheque/titulo
						AAdd(aItens[Len(aItens)], {"E1_ACRESC", 0})			//Acrescimo
						AAdd(aItens[Len(aItens)], {"E1_DECRESC", 0})		//Decrescimo
					Endif
				Else
					AAdd(aItens[Len(aItens)], {"E1_VLCRUZ", aParcMult[nZ][2]})	//Valor do cheque/titulo
					AAdd(aItens[Len(aItens)], {"E1_ACRESC", 0})					//Acrescimo
					AAdd(aItens[Len(aItens)], {"E1_DECRESC", 0})				//Decrescimo
				Endif

				if lLogFat
					cLogFatur += "|" +cFilAnt + cPref + cNum + cParc + "FT " + cCliFat + cLojaFat + ;
							"|" + STR(aItens[Len(aItens)][9][2]) + "|" + STR(aItens[Len(aItens)][10][2]) + "|" + STR(aItens[Len(aItens)][11][2]) +CRLF
				endif
			Next nZ
		
		Else // Vencimento Único

			//Array do processo automatico (aAutoCab)
			aCab := {{"cCondicao",	"001"},;
					{"cNatureza",	cNat},;
					{"E1_TIPO",		"FT "},;
					{"cCLIENTE",	cCliFat},;
					{"nMoeda",		1},; 
					{"cLOJA",		cLojaFat}}

			aAreaAux := SE1->(GetArea())
			If Empty(_aReg[1][nPosParcela])
				cParc := Strzero(1,TamSX3("E1_PARCELA")[1])
			Else
				cParc := Soma1(_aReg[1][nPosParcela])
			EndIf
			While !empty(Posicione("SE1",1,xFilial("SE1")+cPref+cNum+cParc+"FT ", "E1_NUM"))
				cParc := Soma1(cParc)
			enddo
			RestArea(aAreaAux)

			AAdd(aItens,{{"E1_PREFIXO",	cPref},; 				//Prefixo
						{"E1_BCOCHQ",	""},;					//Banco
						{"E1_AGECHQ",	""},;					//Agencia
						{"E1_CTACHQ",	""},;		 			//Conta
						{"E1_NUM",		cNum},; 				//Nro. cheque (dará origem ao numero do titulo)
						{"E1_PARCELA",	cParc},; 				//Parcela
						{"E1_EMITCHQ",	"EXECAUTO"},; 			//Emitente do cheque
						{"E1_VENCTO",	dDtVencRen},;			//Data boa 
						{"E1_VLCRUZ",	nSldTit},;		 		//Valor do cheque/titulo
						{"E1_ACRESC",	nAcresRen},;			//Acrescimo
						{"E1_DECRESC",	nDecresRen};			//Decrescimo
						})	
			if lLogFat
				cLogFatur += "|" +cFilAnt + cPref + cNum + cParc + "FT " + cCliFat + cLojaFat + ;
							"|" + STR(nSldTit) + "|" + STR(nAcresRen) + "|" + STR(nDecresRen) +CRLF			
			endif
		Endif
	Endif

	if lLogFat
		cLogFatur += "Antes Execauto "+ DTOC(date()) + " " + Time() +CRLF
	endif

	lMsErroAuto := .F. // variavel interna da rotina automatica
	lMsHelpAuto := .F.
	//If Len( aParcelas) > 0
		__cNumParc := cNum + "/" + cParc //número título/parcela da fatura (variável usada no PE SE5FI460)
		Fina460( , aCab, aItens, nOpcAuto, cFiltro ) 
		//MSExecAuto( {|a,b,c,d,e| Fina460(a,b,c,d,e)}, , aCab, aItens, nOpcAuto, cFiltro )
	//Endif
	if lLogFat
		cLogFatur += "Depois Execauto "+ DTOC(date()) + " " + Time() +CRLF
	endif

Else //Cancelamento 

	AAdd(aRetorno, .F.)

	BeginTran()

	//Tratamento para caso de E1_NUMLIQ repetida em outra filial (SE1 - Contas a Receber)
	//Verifico se tem outra liquidação com mesmo numero em outra filial
	aDUPNUMLIQ := {}
	aAreaSE1 := SE1->(GetArea())
    cQry:=" SELECT R_E_C_N_O_ "
    cQry+=" FROM "+RetSqlName("SE1")+" SE1"
    cQry+=" WHERE D_E_L_E_T_ = ' ' "
    cQry+="   AND E1_NUMLIQ = '"+cNumLiqCan+"' "
    cQry+="   AND E1_FILIAL <> '"+xFilial("SE1")+"' "
	cQry := ChangeQuery(cQry)
	If Select("DUPNUMLIQ") > 0
		DUPNUMLIQ->(DbCloseArea())
	EndIf
    Tcquery cQry New alias "DUPNUMLIQ"
	if DUPNUMLIQ->(!eof()) 
		While DUPNUMLIQ->(!eof())
			aadd(aDUPNUMLIQ, DUPNUMLIQ->R_E_C_N_O_)
			SE1->(DbGoTo(DUPNUMLIQ->R_E_C_N_O_))
			RecLock("SE1",.F.)
				SE1->E1_NUMLIQ := "000000"
			SE1->(MsUnlock())
			DUPNUMLIQ->(DbSkip())
		Enddo
	endif
	DUPNUMLIQ->(DbCloseArea())
	RestArea(aAreaSE1)

	//Tratamento para caso de FO0_NUMLIQ repetida em outra filial (FO0 - Cabeçalho de Simulaçao)
	//Verifico se tem outra liquidação com mesmo numero em outra filial
	aFO0NUMLIQ := {}
	aAreaFO0 := FO0->(GetArea())
    cQry:=" SELECT R_E_C_N_O_ "
    cQry+=" FROM "+RetSqlName("FO0")+" FO0"
    cQry+=" WHERE D_E_L_E_T_ = ' ' "
    cQry+="   AND FO0_NUMLIQ = '"+cNumLiqCan+"' "
    cQry+="   AND FO0_FILIAL <> '"+xFilial("FO0")+"' "
	cQry := ChangeQuery(cQry)
	If Select("FO0NUMLIQ") > 0
		FO0NUMLIQ->(DbCloseArea())
	EndIf
    Tcquery cQry New alias "FO0NUMLIQ"
	if FO0NUMLIQ->(!eof()) 
		While FO0NUMLIQ->(!eof())
			aadd(aFO0NUMLIQ, FO0NUMLIQ->R_E_C_N_O_)
			FO0->(DbGoTo(FO0NUMLIQ->R_E_C_N_O_))
			RecLock("FO0",.F.)
				FO0->FO0_NUMLIQ := "000000"
			FO0->(MsUnlock())
			FO0NUMLIQ->(DbSkip())
		Enddo
	endif
	FO0NUMLIQ->(DbCloseArea())
	RestArea(aAreaFO0)

	lMsErroAuto := !Fina460(,,,nOpcAuto,,cNumLiqCan)
	
	//SE1: independente se deu certo ou não, volto
	aAreaSE1 := SE1->(GetArea())
	for nI := 1 to len(aDUPNUMLIQ)
		SE1->(DbGoTo(aDUPNUMLIQ[nI]))
		RecLock("SE1",.F.)
			SE1->E1_NUMLIQ := cNumLiqCan
		SE1->(MsUnlock())
	next nI
	RestArea(aAreaSE1)

	//FO0: independente se deu certo ou não, volto...	
	aAreaFO0 := FO0->(GetArea())
	for nI := 1 to len(aFO0NUMLIQ)
		FO0->(DbGoTo(aFO0NUMLIQ[nI]))
		RecLock("FO0",.F.)
			FO0->FO0_NUMLIQ := cNumLiqCan
		FO0->(MsUnlock())
	next nI
	RestArea(aAreaFO0)

	EndTran()
	
Endif

If !lMsErroAuto

	If nOpcAuto == 3 .Or. nOpcAuto == 4
		if lLogFat
			cLogFatur += "Sucesso no execauto "+CRLF
		endif

		AAdd(aRetorno,{cNum,cCliFat,cLojaFat,cPref,cParc,"FT "})

		If nOpcAuto == 3 
			SE1->(DbSetOrder(1)) //E1_FILIAL+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO
			if SE1->(DbSeek(xFilial("SE1")+cPref+cNum+cParc+"FT " ))
				if nVlrBrt > 0
					Reclock("SE1", .F.)
						SE1->E1_VLRREAL := nVlrBrt
					SE1->(MsUnlock())
				endif

				if !empty(aVlrAcess)
					if lLogFat
						cLogFatur += "Vai por Valores acessorios "+CRLF
					endif
					AddVlrAcess()
				endif
			endif
		Endif
		
		if !empty(cHist) .AND. aCpoComp <> Nil
			aAdd(aCpoComp , {"E1_HIST"	 , cHist, NIL})
		endif

		//DANILO: Adicionado para colocar campos adicionais
		If aCpoComp <> Nil .AND. !empty(aCpoComp)
			SE1->(DbSetOrder(1)) //E1_FILIAL+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO
			if SE1->(DbSeek(xFilial("SE1")+cPref+cNum+cParc+"FT " ))
				Reclock("SE1", .F.)
				For nI := 1 to len(aCpoComp)
					if !(aCpoComp[nI][1] $ "E1_VENCTO,E1_ACRESC,E1_DECRESC") //esses nao
						SE1->&(aCpoComp[nI][1]) := aCpoComp[nI][2]
					endif
				Next nI
				SE1->(MsUnlock())
			endif
		Endif
		//FIM Danilo
	
	Else //se exclusao
		aRetorno[1] := .T.
	Endif

Else
	if lLogFat
		cLogFatur += "Falha no execauto FINA460"+CRLF
	endif
	If !IsBlind()
		MostraErro()
	Else
		ConOut("Erro no execauto FINA460")
	Endif
Endif

//limpa novamente o campo fatura dos titulos
If nOpcAuto == 3 .Or. nOpcAuto == 4
	For nI := 1 To Len(_aReg)
		SE1->(DbGoTo(_aReg[nI][nPosRecno]))
		Reclock("SE1",.F.)
			SE1->E1_JURFAT := ""
		SE1->(MsUnlock())
	Next nI
	if lLogFat
		cLogFatur += "TRETE016 - FIM " + DTOC(date()) + " " + Time() +CRLF
		MemoWrite(cDirLogs+"fat_"+cFilAnt+cPref+cNum+cParc+"ft.txt", cLogFatur)
	endif
EndIf

//DBUnlockAll()

Return aRetorno

/***********************************/
Static Function TelaFlex(dVenc,nSld,lHasCard,_nVlrReal,_nVlrTaxa, cHist, cCliFat,cLojaFat)
/***********************************/

Local lRet 			:= .T.
Local nVlrOutr		:= 0

Local oGroup1, oGroup2
Local oSay1, oSay2, oSay3, oSay4, oSay5, oSay6, oSay7, oSay8
Local oButton1, oButton2

Local nPixHCard := iif(lHasCard, 13, 0)
Local lTxAcessor := lHasCard .AND. SuperGetMV("MV_XTXACES",,.F.) //habilita uso de valores acessórios
Local nPixHAcess := iif(lTxAcessor, 70, 0)
Local nPixWAcess := iif(lTxAcessor, 100, 0)

if FKC->(FieldPos("FKC_XTXCAR")) == 0 //se nao criou o campo, desabilita parametro
	lTxAcessor := .F.
	nPixHAcess := 0
	nPixWAcess := 0
endif

Private oDtAtual
Private dDtAtual 	:= dVenc

Private oSldAtual
Private nSldAtual 	:= nSld

Private oDtNova
Private dDtNova 	:= IIf(SuperGetMV("MV_XSUGDTN",,.F.), dVenc, CToD(""))

Private oVlAcres
Private nVlrAcres	:= 0

Private oVlrDesc
Private nVlrDesc	:= 0

Private oVlrTx
Private nVlrTx		:= 0

Private oSldNovo
Private nSldNovo	:= nSld

Private oGetCliFat
Private cGetCliFat	:= cCliFat + "/" + cLojaFat + " - " + Posicione("SA1",1,xFilial("SA1")+cCliFat+cLojaFat,"A1_NOME")

Private lImpFechar	:= .F.

if lTxAcessor
	Private bVldVlrAces := {|nVlrInf| oGetVlAces:aCols[oGetVlAces:nAt][3]:=nVlrInf, VldVlrs(nVlrAcres,nVlrDesc,nVlrTx, .T., _nVlrReal, _nVlrTaxa) }
endif

Static oDlgFlex

nVlrOutr := (_nVlrReal-_nVlrTaxa-nSldAtual)*(-1)
_nVlrTaxa := (_nVlrTaxa*(-1))

DEFINE MSDIALOG oDlgFlex TITLE "Alterar Dados Fatura" From 000,000 TO 290+(nPixHAcess*2),500+(nPixWAcess*2) PIXEL

@ 008, 010 SAY oSay3 PROMPT "Cliente:" SIZE 080, 007 OF oDlgFlex COLORS CLR_BLUE, 16777215 PIXEL
@ 006, 045 MSGET oGetCliFat VAR cGetCliFat SIZE 200+nPixWAcess, 010 OF oDlgFlex COLORS 0, 16777215 PIXEL Picture "@!" WHEN .F.

@ 025, 005 GROUP oGroup1 TO 106+nPixHAcess, 120 PROMPT "Dados atuais" OF oDlgFlex COLOR 0, 16777215 PIXEL
@ 035, 010 SAY oSay1 PROMPT "Dt. Vencimento" SIZE 080, 007 OF oGroup1 COLORS 0, 16777215 PIXEL
@ 035, 055 MSGET oDtAtual VAR dDtAtual SIZE 060, 010 OF oGroup1 WHEN .F. COLORS 0, 16777215 PIXEL Picture "@D"

@ 048, 010 SAY oSay2 PROMPT "Valor Bruto" SIZE 080, 007 OF oGroup1 COLORS 0, 16777215 PIXEL
@ 048, 055 MSGET oVlrBruto VAR _nVlrReal SIZE 060, 010 OF oGroup1 WHEN .F. COLORS 0, 16777215 PIXEL Picture "@E 9,999,999,999,999.99"

if lHasCard
	@ 061, 010 SAY oSay2 PROMPT "Taxas Transação:" SIZE 080, 007 OF oGroup1 COLORS 0, 16777215 PIXEL
	@ 061, 055 MSGET oTaxas VAR _nVlrTaxa SIZE 060, 010 OF oGroup1 WHEN .F. COLORS 0, 16777215 PIXEL Picture "@E 9,999,999,999,999.99"
endif

@ 061+nPixHCard, 010 SAY oSay2 PROMPT "Baixas e Outros:" SIZE 080, 007 OF oGroup1 COLORS 0, 16777215 PIXEL
@ 061+nPixHCard, 055 MSGET oOutros VAR nVlrOutr SIZE 060, 010 OF oGroup1 WHEN .F. COLORS 0, 16777215 PIXEL Picture "@E 9,999,999,999,999.99"

@ 074+nPixHCard, 010 SAY oSay2 PROMPT "Saldo" SIZE 080, 007 OF oGroup1 COLORS 0, 16777215 PIXEL
@ 074+nPixHCard, 055 MSGET oSldAtual VAR nSldAtual SIZE 060, 010 OF oGroup1 WHEN .F. COLORS 0, 16777215 PIXEL Picture "@E 9,999,999,999,999.99"

@ 025, 130 GROUP oGroup2 TO 106+nPixHAcess, 245+nPixWAcess PROMPT "Dados novos" OF oDlgFlex COLOR 0, 16777215 PIXEL

@ 035, 135 SAY oSay3 PROMPT "Dt. Vencimento" SIZE 080, 007 OF oGroup2 COLORS CLR_BLUE, 16777215 PIXEL
@ 035, 180+nPixWAcess MSGET oDtNova VAR dDtNova SIZE 060, 010 OF oGroup2 COLORS 0, 16777215 PIXEL Picture "@D" Valid(IIF(!Empty(dDtNova),VldDt(dDtNova),.T.))

@ 048, 135 SAY oSay4 PROMPT "Acréscimo (R$)" SIZE 080, 007 OF oGroup2 COLORS 0, 16777215 PIXEL
@ 048, 180+nPixWAcess MSGET oVlrAcres VAR nVlrAcres SIZE 060, 010 OF oGroup2 COLORS 0, 16777215 PIXEL Picture "@E 9,999,999,999,999.99";
 Valid(VldVlrs(nVlrAcres,nVlrDesc,nVlrTx,lTxAcessor,_nVlrReal,_nVlrTaxa))

@ 061, 135 SAY oSay5 PROMPT "Desconto (R$)" SIZE 080, 007 OF oGroup2 COLORS 0, 16777215 PIXEL
@ 061, 180+nPixWAcess MSGET oVlrDesc VAR nVlrDesc SIZE 060, 010 OF oGroup2 COLORS 0, 16777215 PIXEL Picture "@E 9,999,999,999,999.99";
 Valid(VldVlrs(nVlrAcres,nVlrDesc,nVlrTx,lTxAcessor,_nVlrReal,_nVlrTaxa))

if lTxAcessor
	TSay():New( 074, 135, {|| "Outras Taxas / Valores Acessórios (-):" }, oGroup2,,,,,,.T.,CLR_BLACK,,200,9 )
		
	oPnlGrid := tPanel():New(084,135,,oGroup2,,,,,,205,nPixHAcess)
	DoNewGetVlA(oPnlGrid)
else
	@ 074, 135 SAY oSay6 PROMPT "Tx. cobrança (R$)" SIZE 080, 007 OF oGroup2 COLORS 0, 16777215 PIXEL
	@ 074, 180+nPixWAcess MSGET oVlrTx VAR nVlrTx SIZE 060, 010 OF oGroup2 COLORS 0, 16777215 PIXEL Picture "@E 9,999,999,999,999.99";
	Valid(VldVlrs(nVlrAcres,nVlrDesc,nVlrTx,lTxAcessor,_nVlrReal,_nVlrTaxa))
endif

@ 087+nPixHAcess, 135 SAY oSay7 PROMPT "Saldo" SIZE 080, 007 OF oGroup2 COLORS 0, 16777215 PIXEL
@ 087+nPixHAcess, 180+nPixWAcess MSGET oSldNovo VAR nSldNovo SIZE 060, 010 OF oGroup2 WHEN .F. COLORS 0, 16777215 PIXEL Picture "@E 9,999,999,999,999.99"

@ 110+nPixHAcess, 010 SAY oSay3 PROMPT "Obs. Titulo Fatura:" SIZE 080, 007 OF oDlgFlex COLORS CLR_BLUE, 16777215 PIXEL
@ 108+nPixHAcess, 060 MSGET oDtNova VAR cHist SIZE 180+nPixWAcess, 010 OF oDlgFlex COLORS 0, 16777215 PIXEL Picture "@!" 

//Linha horizontal
@ 118+nPixHAcess, 005 SAY oSay8 PROMPT Repl("_",240+nPixWAcess) SIZE 240+nPixWAcess, 007 OF oDlgFlex COLORS CLR_GRAY, 16777215 PIXEL

@ 129+nPixHAcess, 160+nPixWAcess BUTTON oButton1 PROMPT "Confirmar" SIZE 040, 010 OF oDlgFlex ACTION MsgRun("Processando...","Aguarde",{||ConfAlt(lTxAcessor)}) PIXEL
@ 129+nPixHAcess, 205+nPixWAcess BUTTON oButton2 PROMPT "Fechar" SIZE 040, 010 OF oDlgFlex ACTION {||lImpFechar := .T.,oDlgFlex:End(),lRet :=  .F.} PIXEL

ACTIVATE MSDIALOG oDlgFlex CENTERED VALID lImpFechar

Return lRet

/******************************/
Static Function VldDt(_dDtNova)
/******************************/

Local lRet := .T.

If _dDtNova < dDataBase
	MsgInfo("A Dt. Vencimento (nova) não pode ser inferior a data atual.","Atenção")
	lRet :=  .F.
Endif

Return lRet

/****************************************************/
Static Function VldVlrs(_nVlrAcres,_nVlrDesc,_nVlrTx, lTxAcessor, _nVlrReal, nVlrTaxas)
/****************************************************/

Local lRet := .T.
Local nX
Local nVlrAcess

If _nVlrAcres > 0 .And. _nVlrDesc > 0
	MsgInfo("Não pode haver acréscimo e decréscimo na mesma operação.","Atenção")
	lRet := .F.
Else
	nSldNovo := nSldAtual + _nVlrAcres - _nVlrDesc - _nVlrTx

	if lTxAcessor
		For nX := 1 to len(oGetVlAces:aCols)
			
			nVlrAcess := oGetVlAces:aCols[nX][3]
			if nVlrAcess > 0
				if oGetVlAces:aCols[nX][4] == '1'  //percentual
					if oGetVlAces:aCols[nX][2] == '-'
						nSldNovo -= Round(nSldAtual * (nVlrAcess / 100), 2)
					else
						nSldNovo += Round(nSldAtual * (nVlrAcess / 100), 2)
					endif
				elseif oGetVlAces:aCols[nX][4] == '2'  //valor
					if oGetVlAces:aCols[nX][2] == '-'
						nSldNovo -= nVlrAcess
					else
						nSldNovo += nVlrAcess
					endif
				endif
			endif
			
		next nX
	endif

	oSldNovo:Refresh()
Endif

Return lRet

/************************/
Static Function ConfAlt(lTxAcessor)
/************************/
Local nX

If !Empty(dDtNova)

	dDtVenc		:= dDtNova
	nAcresTit	:= nVlrAcres
	nDescTit	:= nVlrDesc + nVlrTx
	//nTxCobr		:= nVlrTx
	nSldFlex	:= nSldNovo
	
	if lTxAcessor
		for nX := 1 to len(oGetVlAces:aCols)
			if oGetVlAces:aCols[nX][3] > 0
				aAdd(aVlrAcess, {oGetVlAces:aCols[nX][5], oGetVlAces:aCols[nX][3]}) 
			endif
		next nX
	endif

	lImpFechar 	:= .T.
	lRet 		:= .T.

	oDlgFlex:End()
Else
	MsgInfo("Campo Dt. Vencimento (nova) obrigatório.","Atenção")
Endif

Return

//---------------------------------------------------------------
// Faz montagem do NewGetDados Valores acessorios
//---------------------------------------------------------------
Static Function DoNewGetVlA(oPnl) 

	Local aAlterFields := {"FKD_VALOR"}
	Local aHeadTmp := {}
	Local cTrue := "AllwaysTrue"
	Local aHeader := {}
	Local aColsEx := {}
	Local aEmptyLin := {}

	aHeadTmp := U_UAHEADER("FKC_DESC")
	aHeadTmp[4] := 25
	aadd(aHeader, aClone(aHeadTmp) )
	aAdd(aEmptyLin, Space(40))

	Aadd(aHeader,{ ' ','SINAL','@!',1,0,'','€€€€€€€€€€€€€€','C','','','',''})
	aAdd(aEmptyLin, " " )

	aHeadTmp := U_UAHEADER("FKD_VALOR")
	aHeadTmp[4] := 12
	aHeadTmp[6] := "Positivo(M->FKD_VALOR) .AND. Eval(bVldVlrAces, M->FKD_VALOR)"
	aadd(aHeader, aClone(aHeadTmp) )
	aAdd(aEmptyLin, 0 )

	aHeadTmp := U_UAHEADER("FKC_TPVAL")
	aadd(aHeader, aClone(aHeadTmp) )
	aAdd(aEmptyLin, Space(1) )

	aHeadTmp := U_UAHEADER("FKD_CODIGO")
	aadd(aHeader, aClone(aHeadTmp) )
	aAdd(aEmptyLin, Space(6) )

	aAdd(aEmptyLin, .F.) //deleted

	//Busco os valores acessorios na base
	If Select("QRYFKC") > 0
		QRYFKC->(DbCloseArea())
	Endif

	cQry := " SELECT FKC_CODIGO, FKC_DESC, FKC_ACAO, FKC_TPVAL "
	cQry += " FROM "+RetSqlName("FKC")+"  "
	cQry += " WHERE D_E_L_E_T_ = ' ' "
	cQry += " 	AND FKC_FILIAL = '"+xFilial("FKC")+"' "
	cQry += " 	AND FKC_ATIVO = '1' " //so ativos
	cQry += " 	AND FKC_APLIC = '3' " //fixa
	cQry += " 	AND FKC_PERIOD = '1' " //periodo unico
	cQry += "	AND FKC_RECPAG IN ('2','3') " //carteira receber ou ambas
	cQry += "	AND FKC_XTXCAR = 'S' " //carteira receber ou ambas
	cQry += " ORDER BY FKC_CODIGO "

	cQry := ChangeQuery(cQry)
	TcQuery cQry NEW Alias "QRYFKC"
	if QRYFKC->(!Eof())
		while QRYFKC->(!Eof())

			aadd(aColsEx, {;
				QRYFKC->FKC_DESC ,;
				iif(QRYFKC->FKC_ACAO == '2', "-", "+") ,;
				0,;
				QRYFKC->FKC_TPVAL ,;
				QRYFKC->FKC_CODIGO ,;
				.F. ; //deleted
			})

			QRYFKC->(DbSkip())
		enddo
	endif
	QRYFKC->(DbCloseArea())

	if empty(aColsEx)
		aadd(aColsEx, aEmptyLin)
	endif

	oGetVlAces := MsNewGetDados():New( 000,000,100,100,GD_UPDATE,;
			cTrue, cTrue,, aAlterFields,, 999, cTrue, "", cTrue, oPnl, aHeader, aColsEx)
	oGetVlAces:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT

Return

//Adiciona valores acessorios ao titulo de fatura
Static Function AddVlrAcess()
	
	Local aFin040 := {}

	//Montando array para execauto
	AADD(aFin040, {"E1_FILIAL"	,SE1->E1_FILIAL		,Nil } )
	AADD(aFin040, {"E1_PREFIXO"	,SE1->E1_PREFIXO	,Nil } )
	AADD(aFin040, {"E1_NUM"		,SE1->E1_NUM		,Nil } )
	AADD(aFin040, {"E1_PARCELA"	,SE1->E1_PARCELA  	,Nil } )
	AADD(aFin040, {"E1_TIPO"	,SE1->E1_TIPO	   	,Nil } )
	AADD(aFin040, {"E1_CLIENTE"	,SE1->E1_CLIENTE	,Nil } )
	AADD(aFin040, {"E1_LOJA"	,SE1->E1_LOJA		,Nil } )

	lMsErroAuto := .F. // variavel interna da rotina automatica
	lMsHelpAuto := .F.
	MsExecAuto( { |x,y,z,w,k,a,b,c| FINA040(x,y,z,w,k,a,b,c)}, aFin040, 4,,,,,,aVlrAcess)

	if lMsErroAuto
		MostraErro()
	endif

Return

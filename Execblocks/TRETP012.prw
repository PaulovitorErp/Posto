#include "protheus.ch"
#include "topconn.ch"

/*/{Protheus.doc} TRETP012
Chamado pelo P.E. SPED1300 com objetivo de informar a Movimentação Diária de Combustíveis
@author Maiki Perin
@since 24/10/2018
@version 1.0
@param ParamIxb[1] - cAlias
@param ParamIxb[2] - dDataDe
@param ParamIxb[3] - dDataAte
@param ParamIxb[4] - aReg0200
@param ParamIxb[5] - aReg0190
@return nulo
/*/

/*****************************************************************************************/
User Function TRETP012(cAlias,dDataDe,dDataAte,cProdNv,cDataNv,aReg1300,aReg1310,aReg1320)
/*****************************************************************************************/

Local aReg0200	:= (ParamIxb[4])
Local aReg0190	:= (ParamIxb[5])

Local lMvPosto := SuperGetMv("MV_XPOSTO",.F.,.F.) //Habilita Posto de Combustível (Posto Inteligente).

Default cAlias		:= (ParamIxb[1])
Default dDataDe		:= (ParamIxb[2])
Default	dDataAte	:= (ParamIxb[3])

Default cProdNv		:= ""
Default cDataNv		:= ""
Default	aReg1300	:= {}
Default	aReg1310	:= {}
Default	aReg1320	:= {}

//Caso o Posto Inteligente não esteja habilitado não faz nada...
If !lMvPosto
	Return
EndIf

if type("aAuxBicos")=="U" //se ainda nao declarou
	Private aAuxBicos	:= {}
endif

Reg1300P(cAlias,dDataDe,dDataAte,@aReg1300,@aReg1310,@aReg1320,cProdNv,cDataNv)

//Caso as variáveis cProdNv e cDataNv estejam vazias se trata de execução única, caso contrário, a execução é compartilhada com o
//fonte UPIPEI01
If Empty(cProdNv) .And. Empty(cDataNv)
	Reg1350P(cAlias,dDataDe,dDataAte,aReg0200,aReg0190)
Endif

Return()

//////////////////////////////////////////////////////////
// Registro 1300 - MOVIMENTACAO DIARIA DE COMBUSTIVEIS  //
//////////////////////////////////////////////////////////

Static Function Reg1300P(cAlias,dDataDe,dDataAte,aReg1300,aReg1310,aReg1320,cProdNv,cDataNv)

Local cQry		:= ""
Local nPos		:= 0
Local nI,nJ,nX
Local nReg1300	:= 0
Local nReg1310	:= 0

Local aTanques	:= {}
Local aBicos	:= {}

Local cAbert	:= ""
Local cFech		:= ""
Local nEnt		:= 0
Local nVen		:= 0
Local nPerda	:= 0
Local nGanho	:= 0

Local cTq	:= ""

Local cFilConc := iif(SuperGetMv("MV_COFLSPD",,.T.),cFilAnt,"")

Local oLMC := TLmcLib():New()
oLMC:SetTRetVen(1) //1=Vlr Total Vendas; 2=Array Dados; 3=Qtd Registros

DbSelectArea("MIE")
MIE->(DbSetOrder(1)) //MIE_FILIAL+MIE_CODPRO+DTOS(MIE_DATA)+MIE_CODTAN+MIE_CODBIC

If Select("QRYMIE") > 0
	QRYMIE->(dbCloseArea())
Endif

cQry := "SELECT MIE_CODPRO, MIN(MIE_DATA) AS MIE_DATA"
cQry += " FROM "+RetSqlName("MIE")+""
cQry += " WHERE D_E_L_E_T_ 	<> '*'"
cQry += " AND MIE_FILIAL	= '"+xFilial("MIE")+"'"

If !Empty(cProdNv) .And. !Empty(cDataNv)
	cQry += " AND MIE_DATA 		= '"+cDataNv+"'"
	cQry += " AND MIE_CODPRO	= '"+cProdNv+"'"
Else
	cQry += " AND MIE_DATA 		BETWEEN '"+DToS(dDataDe)+"' AND '"+DToS(dDataAte)+"'"
Endif
cQry += " GROUP BY MIE_CODPRO"
cQry += " ORDER BY 1"

cQry := ChangeQuery(cQry)
//MemoWrite("c:\temp\QRYMIE.txt",cQry)
TcQuery cQry NEW Alias "QRYMIE"

While QRYMIE->(!EOF())

	If MIE->(DbSeek(xFilial("MIE")+QRYMIE->MIE_CODPRO+QRYMIE->MIE_DATA))

		While MIE->(!EOF()) .And. MIE->MIE_FILIAL == xFilial("MIE") .And. MIE->MIE_CODPRO == QRYMIE->MIE_CODPRO .And. MIE->MIE_DATA <= dDataAte

			aTanques 	:= {}
			cTq			:= ""
			aBicos		:= {}

			cData 		:= DToS(MIE->MIE_DATA)
			cProd		:= MIE->MIE_CODPRO
			oLMC:SetChave(cProd, MIE->MIE_DATA)

			aAdd(aReg1300,{"1300",;															//01 - REG - Texto fixo contendo "1300"
			cProd+cFilConc,;    															//02 - COD_ITEM - Código do Produto, constante do registro 0200
			Substr(cData,7,2) + Substr(cData,5,2) + Substr(cData,1,4),;						//03 - DT_FECH - Data do fechamento da movimentação, formato “ddmmaaaa”
			StrTran(Str(Round(MIE->MIE_ABERT,3)),".",","),;									//04 - ESTQ_ABERT - Estoque no inicio do dia, em litros
			StrTran(Str(Round(MIE->MIE_ENTRAD,3)),".",","),;								//05 - VOL_ENTR - Volume Recebido no dia (em litros)
			StrTran(Str(Round(MIE->MIE_ENTRAD + MIE->MIE_ABERT,3)),".",","),;				//06 - VOL_DISP - Volume Disponível (04 + 05), em litros
			StrTran(Str(Round(MIE->MIE_VENDAS,3)),".",","),;								//07 - VOL_SAIDAS - Volume Total das Saídas, em litros
			StrTran(Str(Round(MIE->MIE_ENTRAD + MIE->MIE_ABERT - MIE->MIE_VENDAS,3)),".",","),;		//08 - ESTQ_ESCR - Estoque Escritural (06 – 07), litros
			StrTran(Str(Round(MIE->MIE_PERDA,3)),".",","),;									//09 - VAL_AJ_PERDA - Valor da Perda, em litros
			StrTran(Str(Round(MIE->MIE_GANHOS,3)),".",","),;								//10 - VAL_AJ_GANHO - Valor do ganho, em litros
			StrTran(Str(Round(MIE->MIE_ESTFEC,3)),".",",")})	                            //11 - FECH_FISICO - Estoque de Fechamento, em litros

			nReg1300 := Len(aReg1300)

			////////////////////////////////////////////////////////////////////
			// Registro 1310 - MOVIMENTACAO DIARIA DE COMBUSTIVEIS POR TANQUE //
			////////////////////////////////////////////////////////////////////

			If Select("QRYTQ") > 0
				QRYTQ->(DbCloseArea())
			Endif

			cQry := "SELECT MHZ_CODTAN, MHZ_TQSPED"
			cQry += " FROM "+RetSqlName("MHZ")+""
			cQry += " WHERE D_E_L_E_T_ 	<> '*'"
			cQry += " AND MHZ_FILIAL	= '"+xFilial("MHZ")+"'"
			cQry += " AND MHZ_CODPRO	= '"+cProd+"'"
			cQry += " AND ((MHZ_STATUS = '1' AND MHZ_DTATIV <= '"+cData+"') OR (MHZ_STATUS = '2' AND MHZ_DTDESA >= '"+cData+"'))"
			cQry += " ORDER BY 1"

			cQry := ChangeQuery(cQry)
			//MemoWrite("c:\temp\QRYTQ.txt",cQry)
			TcQuery cQry NEW Alias "QRYTQ"

			While QRYTQ->(!EOF())

				AAdd(aTanques,{QRYTQ->MHZ_CODTAN,QRYTQ->MHZ_TQSPED})

				QRYTQ->(DbSkip())
			EndDo

			For nI := 1 To Len(aTanques)
				If nI == Len(aTanques)
					cTq += "'" + aTanques[nI][1] + "'"
				Else
					cTq += "'" + aTanques[nI][1] + "',"
				Endif
			Next nI

			If Select("QRYBICO") > 0
				QRYBICO->(dbCloseArea())
			Endif

			cQry := "SELECT MIC_CODBIC, MIC_NLOGIC, MIC_CODTAN, MIC_CODBOM"
			cQry += " FROM "+RetSqlName("MIC")+""
			cQry += " WHERE D_E_L_E_T_ 	<> '*'"
			cQry += " AND MIC_FILIAL	= '"+xFilial("MIC")+"'"
			cQry += " AND MIC_CODTAN	IN ("+iif(empty(cTq),"''",cTq)+")"
			cQry += " AND ((MIC_STATUS = '1' AND MIC_XDTATI <= '"+cData+"') OR (MIC_STATUS = '2' AND MIC_XDTDES >= '"+cData+"'))"
			cQry += " ORDER BY 1"

			cQry := ChangeQuery(cQry)
			//MemoWrite("c:\temp\QRYBICO.txt",cQry)
			TcQuery cQry NEW Alias "QRYBICO"

			While QRYBICO->(!EOF())

				AAdd(aBicos,{QRYBICO->MIC_CODBIC,QRYBICO->MIC_NLOGIC,QRYBICO->MIC_CODTAN,QRYBICO->MIC_CODBOM})

				QRYBICO->(DbSkip())
			EndDo

			If Select("QRYTQ") > 0
				QRYTQ->(dbCloseArea())
			Endif

			If Select("QRYBICO") > 0
				QRYBICO->(dbCloseArea())
			Endif

			For nI := 1 to Len(aTanques)

				cAbert 	:= "MIE->MIE_ESTI" + aTanques[nI][1]
				cFech	:= "MIE->MIE_VTAQ" + aTanques[nI][1]
				nEnt	:= RetEnt(cProd,cData,aTanques[nI][1])

				oLMC:SetTanques({aTanques[nI][1]})
				nVen	:= oLMC:RetVen()

				nPerda	:= 0
				nGanho	:= 0

				If &cFech - (&cAbert + (nEnt - nVen)) > 0
					nGanho := &cFech - (&cAbert + (nEnt - nVen))
				ElseIf &cFech - (&cAbert + (nEnt - nVen)) < 0
					nPerda := (&cAbert + (nEnt - nVen)) - &cFech
				Endif

				&cAbert	:= Round(&cAbert,3)
				&cFech	:= Round(&cFech,3)
				nEnt	:= Round(nEnt,3)
				nVen	:= Round(nVen,3)
				nGanho	:= Round(nGanho,3)
				nPerda	:= Round(nPerda,3)

				AAdd(aReg1310, {nReg1300,; 										//00 - RELACAO
				"1310",;														//01 - REG - Texto fixo contendo "1310"
				AllTrim(aTanques[nI][2]),; 										//02 - NUM_TANQUE - Tanque que armazena o combustível.
				StrTran(Str(&cAbert),".",","),;									//03 - ESTQ_ABERT - Estoque no inicio do dia, em litros
				StrTran(Str(nEnt),".",","),;									//04 - VOL_ENTR - Volume Recebido no dia (em litros)
				StrTran(Str(nEnt + &cAbert),".",","),;							//05 - VOL_DISP - Volume Disponível (03 + 04), em litros
				StrTran(Str(nVen),".",","),;									//06 - VOL_SAIDAS - Volume Total das Saídas, em litros
				StrTran(Str(nEnt + &cAbert - nVen),".",","),;					//07 - ESTQ_ESCR - Estoque Escritural(05 – 06), litros
				StrTran(Str(nPerda),".",","),;									//08 - VAL_AJ_PERDA - Valor da Perda, em litros
				StrTran(Str(nGanho),".",","),;									//09 - VAL_AJ_GANHO - Valor do ganho, em litros
				StrTran(Str(&cFech),".",","),;									//10 - FECH_FISICO - Volume aferido no tanque, em litros. Estoque de fechamento físico do tanque.
				Substr(cData,7,2) + Substr(cData,5,2) + Substr(cData,1,4)})

				//A soma dos valores apresentados no campo 10 do registro 1310 deve ser igual ao valor apresentado no campo 11 do registro 1300.

				nReg1310 := Len(aReg1310)

				//////////////////////////////////////
				// Registro 1320 - VOLUME DE VENDAS //
				//////////////////////////////////////

				For nJ := 1 To Len(aBicos)
					If aBicos[nJ][3] == aTanques[nI][1]
						SPED1320(cAlias,cData,@aReg1320,nReg1310,MIE->MIE_CODPRO,aTanques[nI][1],aBicos[nJ][1],aBicos[nJ][2],aBicos[nJ][4])
					Endif
				Next nJ
			Next nI

			MIE->(DbSkip())
		EndDo
	Endif

	QRYMIE->(DbSkip())
EndDo

MIE->(DbCloseArea())

If Select("QRYMIE") > 0
	QRYMIE->(dbCloseArea())
Endif

For nX := 1 to Len(aReg1310)
	aSize(aReg1310[nX],11)
Next nX

For nX := 1 to Len(aReg1320)
	aSize(aReg1320[nX],12)
Next nX

//Caso as variáveis cProdNv e cDataNv estejam vazias se trata de execução única, caso contrário, a execução é compartilhada com o
//fonte UPIPEI01
If Empty(cProdNv) .And. Empty(cDataNv)
	SPEDRegs(cAlias,{aReg1300,aReg1310,aReg1320})
Endif

Return()

//////////////////////////////////////
// Registro 1320 - VOLUME DE VENDAS //
//////////////////////////////////////

Static Function SPED1320(cAlias,cData,aReg1320,nReg1310,cProd,nRecTan,nRecBicC,nRecBicN,cBomba)

Local nPos			:= 0

Local nVlrAbert		:= 0
Local nVlrFecha		:= 0

Local cQry := ""

Local oLMC := TLmcLib():New(cProd, STOD(cData))
Local aDados
Local dDtManut := CtoD("")
Local aRetMnut := {CtoD(""),0}
Local nEncMant := 0

DbSelectArea("MID") //Abastecimentos
MID->(DbOrderNickName("MID_004")) //MID_FILIAL+DTOS(MID_DATACO)+MID_XPROD+MID_CODBIC+MID_CODTAN

//Abastecimentos
MID->(DbGoTop())

//Se tem abastecimento no dia para esse bico e tanque
If MID->(DbSeek(xFilial("MID")+cData+cProd+nRecBicC+nRecTan))

	//retorna dados de vendas
	oLMC:SetTRetVen(2) //1=Vlr Total Vendas; 2=Array Dados; 3=Qtd Registros
	oLMC:SetDRetVen({"_FECH", "_ABERT", "_AFERIC", "_VDBICO"})
	oLMC:SetTanques({nRecTan})
	oLMC:SetBico(nRecBicC)
	aDados := oLMC:RetVen()

	for nPos:=1 to len(aDados)

		AAdd(aReg1320, {nReg1310,;	 								//00 - RELACAO
		"1320",;  													//01 - REG - Texto fixo contendo "1320"
		nRecBicC,;													//02 - NUM_BICO - Bico Ligado à Bomba
		Nil,;														//03 - NR_INTERV - Número da intervenção
		Nil,;														//04 - MOT_INTERV - Motivo da Intervenção
		Nil,;														//05 - NOM_INTERV - Nome do Interventor
		Nil,;														//06 - CNPJ_INTERV - CNPJ da empresa responsável pela intervenção
		Nil,;														//07 - CPF_INTERV - CPF do técnico responsável pela intervenção
		StrTran(Str(aDados[nPos][1]),".",","),;						//08 - VAL_FECHA - Valor da leitura final do contador, no fechamento do bico.
		StrTran(Str(aDados[nPos][2]),".",","),;						//09 - VAL_ABERT - Valor da leitura inicial do contador, na abertura do bico.
		StrTran(Str(aDados[nPos][3]),".",","),;						//10 - VOL_AFERI - Aferições da Bomba, em litros
		StrTran(Str(aDados[nPos][4]),".",","),;						//11 - VOL_VENDAS - Vendas (08 – (09 + 10) do bico , em litros
		Substr(cData,7,2) + Substr(cData,5,2) + Substr(cData,1,4)})
		
	next nPos

	//Guarda os bicos que houveram movimentação
	If aScan(aAuxBicos,{|x| x == nRecBicN}) == 0
		AAdd(aAuxBicos,nRecBicN)
	Endif

Else

	If Select("QRYABERT") > 0
		QRYABERT->(dbCloseArea())
	Endif

	//Considera a manutenção de encerrante
	DbSelectArea("MIC") //Bicos
	MIC->(DbSetOrder(3)) //MIC_FILIAL+MIC_CODBIC+MIC_CODTAN
	MIC->(DbSeek(xFilial("MIC")+nRecBicC+nRecTan))

	aRetMnut := RetDtUltMant(MIC->MIC_CODBOM,nRecBicC,StoD(cData))
	dDtManut := aRetMnut[1]
	nEncMant := aRetMnut[2]

	cQry := "SELECT MAX(MID_ENCFIN) AS ABERT"
	cQry += " FROM "+RetSqlName("MID")+""
	cQry += " WHERE D_E_L_E_T_ <> '*'"
	cQry += " AND MID_FILIAL	= '"+xFilial("MID")+"'"
	cQry += " AND MID_XPROD		= '"+cProd+"'"
	cQry += " AND MID_DATACO	< '"+cData+"'"
	cQry += " AND MID_CODTAN	= '"+nRecTan+"'"
	cQry += " AND MID_CODBIC	= '"+nRecBicC+"'"
	If !Empty(dDtManut)
		cQry += " AND MID_DATACO > '"+DtoS(dDtManut)+"'"
	EndIf

	cQry := ChangeQuery(cQry)
	//MemoWrite("c:\temp\RPOS011.txt",cQry)
	TcQuery cQry NEW Alias "QRYABERT"

	If QRYABERT->(!EOF())
		If QRYABERT->ABERT > 0
			nVlrAbert := QRYABERT->ABERT
			nVlrFecha := QRYABERT->ABERT
		Else
			nVlrFecha := 0
			nVlrAbert := 0
		Endif
	Else
		If nEncMant > 0
			nVlrAbert := nEncMant
			nVlrFecha := nEncMant
		Else
			nVlrFecha := 0
			nVlrAbert := 0
		Endif
	EndIf

	AAdd(aReg1320, {nReg1310,;	 								//00 - RELACAO
	"1320",;  													//01 - REG - Texto fixo contendo "1320"
	nRecBicC,;													//02 - NUM_BICO - Bico Ligado à Bomba
	Nil,;									   					//03 - NR_INTERV - Número da intervenção
	Nil,;														//04 - MOT_INTERV - Motivo da Intervenção
	Nil,;														//05 - NOM_INTERV - Nome do Interventor
	Nil,;														//06 - CNPJ_INTERV - CNPJ da empresa responsável pela intervenção
	Nil,;														//07 - CPF_INTERV - CPF do técnico responsável pela intervenção
	StrTran(Str(Round(nVlrFecha, 3)),".",","),;					//08 - VAL_FECHA - Valor da leitura final do contador, no fechamento do bico.
	StrTran(Str(Round(nVlrAbert, 3)),".",","),;					//09 - VAL_ABERT - Valor da leitura inicial do contador, na abertura do bico.
	0,;															//10 - VOL_AFERI - Aferições da Bomba, em litros
	StrTran(Str(Round(nVlrFecha - nVlrAbert + 0, 3)),".",","),;	//11 - VOL_VENDAS - Vendas (08 – (09 + 10) do bico , em litros
	Substr(cData,7,2) + Substr(cData,5,2) + Substr(cData,1,4)})
Endif

MID->(DbGoTop())

MID->(DbCloseArea())

If Select("QRYABERT") > 0
	QRYABERT->(dbCloseArea())
Endif

Return

////////////////////////////
// Registro 1350 - BOMBAS //
////////////////////////////

/******************************************************************/
Static Function Reg1350P(cAlias,dDataDe,dDataAte,aReg0200,aReg0190)
/******************************************************************/

Local nPos			:= 0
Local cFabric		:= ""

Local aReg1350		:= {}
Local aReg1360		:= {}
Local aReg1370		:= {}

Local nRegPai		:= 0

Local nCont			:= 0

Local cBombaArla	:= SuperGetMv("MV_XBOMBAR",,"")
Local lBicMov 		:= SuperGetMv("MV_XBICMOV",,.T.) //Lista bicos apenas com movimentos nos registros 1350 - BOMBAS (default .T.)

Local cFilConc := iif(SuperGetMv("MV_COFLSPD",,.T.),cFilAnt,"")

Local cQry			:= ""
Local cQry2			:= ""
Local cQry3			:= ""

DbSelectArea("MHY") //Bombas
MHY->(DbSetOrder(1)) //MHY_FILIAL+MHY_CODBOM+MHY_CODCON

DbSelectArea("MIB") //Lacres de Bombas
MIB->(DbSetOrder(3)) //MIB_FILIAL+MIB_CODBOM+MIB_NROLAC

DbSelectArea("MIC") //Bicos
MIC->(DbSetOrder(2)) //MIC_FILIAL+MIC_CODBOM+MIC_CODBIC

DbSelectArea("MHZ") //Tanques
MHZ->(DbSetOrder(1)) //MHZ_FILIAL+MHZ_CODTAN

DbSelectArea("SB1")
SB1->(DbSetOrder(1)) //B1_FILIAL+B1_COD

MHY->(DbSeek(xFilial("MHY")))

While MHY->(!EOF()) .And. MHY->MHY_FILIAL == xFilial("MHY")

	//Bombas de Arla não deve ser informada no SPED Fiscal
	If MHY->MHY_CODBOM $ cBombaArla .OR. MHY->MHY_ENSPED == "2" //nao envia para sped
		MHY->(DbSkip())
		Loop
	Endif

	aReg1350 := {}
	aReg1360 := {}
	aReg1370 := {}

	If MHY->MHY_STATUS == "1" //Ativa
		cFabric		:= Alltrim(Posicione("MIA",1,xFilial("MIA")+MHY->MHY_FABBOM+'03',"MIA_DESCRI"))

		AAdd(aReg1350, {"1350",;	//01 - REG - Texto fixo contendo "1350"
		Alltrim(MHY->MHY_SERIE),;	//02 - SERIE - Número de Série da Bomba
		Alltrim(cFabric),;			//03 - FABRICANTE - Nome do Fabricante da Bomba
		Alltrim(MHY->MHY_MODBOM),;	//04 - MODELO - Modelo da Bomba
		MHY->MHY_TIPMED})			//05 - TIPO_MEDICAO - Identificador de medição: 0 - analógico; 1 – digital

		nRegPai:= Len(aReg1350)

		/////////////////////////////////////
		// Registro 1360 - LACRES DA BOMBA //
		/////////////////////////////////////

		// Houve atualização da tabela MIB no período do SPED e se trata da última atualização para aquela Bomba
		If Select("QRYLACATU") > 0
			QRYLACATU->(dbCloseArea())
		Endif

		cQry := "SELECT MIB_NROLAC,"
		cQry += " MIB_DATA"
		cQry += " FROM "+RetSqlName("MIB")+""
		cQry += " WHERE D_E_L_E_T_	<> '*'"
		cQry += " AND MIB_FILIAL 	= '"+xFilial("MIB")+"'"
		cQry += " AND MIB_CODBOM 	= '"+MHY->MHY_CODBOM+"'"
		cQry += " AND MIB_DATA 		BETWEEN '"+DToS(dDataDe)+"' AND '"+DToS(dDataAte)+"'"
		cQry += " AND MIB_DTINAT 	= ' '" //que nao esteja inativo
		cQry += " AND MIB_CODMAN = ' ' " //retiro registros de manutenção, pois no PE TRETM027 gravo separado a MIB de lacres da bomba

		cQry := ChangeQuery(cQry)
		//MemoWrite("c:\temp\TRETP012.txt",cQry)
		TcQuery cQry NEW Alias "QRYLACATU"

		If QRYLACATU->(!EOF())
			While QRYLACATU->(!EOF())

				/*nRegPai,;*/																								//00 - RELACAO
				AAdd(aReg1360, {"1360",;																					//01 - REG - Texto fixo contendo "1360"
				QRYLACATU->MIB_NROLAC,;																						//02 - NUM_LACRE - Número do Lacre associado na Bomba
				Substr(QRYLACATU->MIB_DATA,7,2) + Substr(QRYLACATU->MIB_DATA,5,2) + Substr(QRYLACATU->MIB_DATA,1,4)})		//03 - DT_APLICACAO - Data de aplicação do Lacre, formato “ddmmaaaa”

				QRYLACATU->(dbSkip())
			EndDo
		Else // Houve atualização da tabela MIB no período do SPED e NÃO se trata da última atualização para aquela Bomba

			If Select("QRYLACEXC") > 0
				QRYLACEXC->(dbCloseArea())
			Endif

			cQry2 := "SELECT MAX(R_E_C_N_O_),
			cQry2 += " MIB_NROLAC,"
			cQry2 += " MIB_DATA"
			cQry2 += " FROM "+RetSqlName("MIB")+""
			cQry2 += " WHERE D_E_L_E_T_	= '*'" // Buca registros deletados
			cQry2 += " AND MIB_FILIAL 	= '"+xFilial("MIB")+"'"
			cQry2 += " AND MIB_CODBOM 	= '"+MHY->MHY_CODBOM+"'"
			cQry2 += " AND MIB_DATA 	BETWEEN '"+DToS(dDataDe)+"' AND '"+DToS(dDataAte)+"'"
			cQry2 += " AND MIB_CODMAN = ' ' " //retiro registros de manutenção, pois no PE TRETM027 gravo separado a MIB de lacres da bomba
			cQry2 += " GROUP BY MIB_NROLAC, MIB_DATA"

			cQry2 := ChangeQuery(cQry2)
			//MemoWrite("c:\temp\TRETP012.txt",cQry)
			TcQuery cQry2 NEW Alias "QRYLACEXC"

			If QRYLACEXC->(!EOF())

				While QRYLACEXC->(!EOF())

					/*nRegPai,;*/																							//00 - RELACAO
					AAdd(aReg1360, {"1360",;																				//01 - REG - Texto fixo contendo "1360"
					QRYLACEXC->MIB_NROLAC,;																					//02 - NUM_LACRE - Número do Lacre associado na Bomba
					Substr(QRYLACEXC->MIB_DATA,7,2) + Substr(QRYLACEXC->MIB_DATA,5,2) + Substr(QRYLACEXC->MIB_DATA,1,4)})	//03 - DT_APLICACAO - Data de aplicação do Lacre, formato “ddmmaaaa”

					QRYLACEXC->(dbSkip())
				EndDo

			Else //Não houve atualização da tabela MIB no período do SPED

				If Select("QRYLACANT") > 0
					QRYLACANT->(dbCloseArea())
				Endif

				cQry3 := "SELECT MIB_NROLAC,"
				cQry3 += " MIB_DATA"
				cQry3 += " FROM "+RetSqlName("MIB")+""
				cQry3 += " WHERE D_E_L_E_T_	<> '*'" 
				cQry3 += " AND MIB_FILIAL 	= '"+xFilial("MIB")+"'"
				cQry3 += " AND MIB_CODBOM 	= '"+MHY->MHY_CODBOM+"'"
				cQry3 += " AND MIB_DATA 	< '"+DToS(dDataDe)+"'"
				cQry3 += " AND MIB_DTINAT 	= ' '" //que nao esteja inativo
				cQry3 += " AND MIB_CODMAN 	= ' ' " //retiro registros de manutenção, pois no PE TRETM027 gravo separado a MIB de lacres da bomba

				cQry3 := ChangeQuery(cQry3)
				//MemoWrite("c:\temp\TRETP012.txt",cQry)
				TcQuery cQry3 NEW Alias "QRYLACANT"

				If QRYLACANT->(!EOF())

					While QRYLACANT->(!EOF())

						/*nRegPai,;*/																							//00 - RELACAO
						AAdd(aReg1360, {"1360",;																				//01 - REG - Texto fixo contendo "1360"
						QRYLACANT->MIB_NROLAC,;																					//02 - NUM_LACRE - Número do Lacre associado na Bomba
						Substr(QRYLACANT->MIB_DATA,7,2) + Substr(QRYLACANT->MIB_DATA,5,2) + Substr(QRYLACANT->MIB_DATA,1,4)})	//03 - DT_APLICACAO - Data de aplicação do Lacre, formato “ddmmaaaa”

						QRYLACANT->(dbSkip())
					EndDo
				EndIf
			EndIf
		Endif

		////////////////////////////////////
		// Registro 1370 - BICOS DA BOMBA //
		////////////////////////////////////
		MIC->(DbSetOrder(2)) //MIC_FILIAL+MIC_CODBOM+MIC_CODBIC
		If MIC->(DbSeek(xFilial("MIC")+MHY->MHY_CODBOM))

			While MIC->(!EOF()) .And. MIC->MIC_FILIAL == xFilial("MIC") .And. MIC->MIC_CODBOM == MHY->MHY_CODBOM

				//If MIC->MIC_STATUS == "1" //Ativo
				If ((MIC->MIC_STATUS = '1' .AND. MIC->MIC_XDTATI <= dDataDe) .OR. (MIC->MIC_STATUS = '2' .AND. MIC->MIC_XDTDES >= dDataDe))

					If MHZ->(DbSeek(xFilial("MHZ")+MIC->MIC_CODTAN))

						If !lBicMov .or. PossuiMov(MIC->MIC_NLOGIC)

							/*nRegPai,;*/							//00 - RELACAO
							AAdd(aReg1370, {"1370",;				//01 - REG - Texto fixo contendo "1370"
							MIC->MIC_CODBIC,;						//02 - NUM_BICO - Número sequencial do bico ligado a bomba
							MHZ->MHZ_CODPRO + cFilConc,;			//03 - COD_ITEM - Código do Produto, constante do registro 0200
							MHZ->MHZ_TQSPED})						//04 - NUM_TANQUE - Tanque que armazena o combustível
						Endif
					Endif
				Endif

				MIC->(DbSkip())
			EndDo
		Endif
	Endif

	nCont++

	GrvRegTrS (cAlias,nCont,aReg1350)
	GrvRegTrS (cAlias,nCont,aReg1360)
	GrvRegTrS (cAlias,nCont,aReg1370)

	MHY->(DbSkip())
EndDo

MHY->(DbCloseArea())
MIB->(DbCloseArea())
MIC->(DbCloseArea())
MHZ->(DbCloseArea())
SB1->(DbCloseArea())

If Select("QRYLACATU") > 0
	QRYLACATU->(dbCloseArea())
Endif

If Select("QRYLACEXC") > 0
	QRYLACEXC->(dbCloseArea())
Endif

If Select("QRYLACANT") > 0
	QRYLACANT->(dbCloseArea())
Endif

Return

/**************************************/
Static Function RetEnt(cProd,cData,cTq)
/**************************************/

Local nRet 	:= 0
Local cQry	:= ""

If Select("QRYENT") > 0
	QRYENT->(dbCloseArea())
Endif

cQry := "SELECT SUM(SD1.D1_QUANT) AS QTD"
cQry += " FROM "+RetSqlName("SF1")+" SF1, "+RetSqlName("SD1")+" SD1, "+RetSqlName("SF4")+" SF4"
cQry += " WHERE SF1.D_E_L_E_T_ 	<> '*'"
cQry += " AND SD1.D_E_L_E_T_ 	<> '*'"
cQry += " AND SF4.D_E_L_E_T_ 	<> '*'"
cQry += " AND SF1.F1_FILIAL		= '"+xFilial("SF1")+"'"
cQry += " AND SD1.D1_FILIAL		= '"+xFilial("SD1")+"'"
cQry += " AND SF4.F4_FILIAL		= '"+xFilial("SF4")+"'"
cQry += " AND SF1.F1_DOC		= SD1.D1_DOC"
cQry += " AND SF1.F1_SERIE		= SD1.D1_SERIE"
cQry += " AND SF1.F1_FORNECE	= SD1.D1_FORNECE"
cQry += " AND SF1.F1_LOJA		= SD1.D1_LOJA"
cQry += " AND SD1.D1_TES		= SF4.F4_CODIGO"
cQry += " AND (SD1.D1_TIPO		= 'N' OR SD1.D1_TIPO = 'D')" //Tipo Normal ou Devolução
cQry += " AND SF1.F1_XLMC		= 'S'" //Considera LMC
cQry += " AND SD1.D1_COD		= '"+cProd+"'"
cQry += " AND SF1.F1_DTDIGIT	= '"+cData+"'"
cQry += " AND SD1.D1_LOCAL		= '"+cTq+"'"
cQry += " AND SF4.F4_ESTOQUE	= 'S'" //Movimenta estoque

cQry := ChangeQuery(cQry)
//MemoWrite("c:\temp\RPOS011.txt",cQry)
TcQuery cQry NEW Alias "QRYENT"

If QRYENT->(!EOF())
	nRet := QRYENT->QTD
Endif

If Select("QRYENT") > 0
	QRYENT->(dbCloseArea())
Endif

Return nRet

/*******************************/
Static Function PossuiMov(cBico)
/*******************************/

Local lPossui := .F.

If aScan(aAuxBicos,{|x| x == cBico}) > 0
	lPossui := .T.
Endif

Return lPossui

/*/{Protheus.doc} RetDtUltMant
Retorna a ultima data e encerrante inicial da manutenção da bomba/bico

@type function
@version 12.1.33
@author Pablo Nunes
@since 20/06/2022
@param cBomba, character, código da bomba
@param cBico, character, código do bico
@param dData, date, data a ser considerado
@return date, data da ultima manutenção de bomba
/*/
Static Function RetDtUltMant(cBomba,cBico,dData)

	Local dDtManut := CtoD("")
	Local nNewValE := 0
	Local cQry 	:= ""

	If Select("QRYU00") > 0
		QRYU00->(DbCloseArea())
	EndIf

	cQry := "SELECT U00.U00_DTINT, U02.U02_ENCATU "
	cQry += " FROM " + RetSqlName("U00") +" U00 "
	cQry += " INNER JOIN " + RetSqlName("U02") +" U02"
	cQry += " ON (U00.D_E_L_E_T_ = ' ' AND U00.U00_FILIAL = U02.U02_FILIAL AND U00.U00_NUMSEQ = U02.U02_NUMSEQ)"
	cQry += " WHERE U00.D_E_L_E_T_ = ' '"
	cQry += " AND U00.U00_FILIAL = '"+xFilial("U00")+"'"
	cQry += " AND U00.U00_BOMBA = '"+cBomba+"'"
	cQry += " AND U02.U02_BICO = '"+cBico+"'"
	cQry += " AND U00.U00_DTINT < '"+DTOS(dData)+"'"
	cQry += " ORDER BY 1 DESC" //ordeno pela data da manutenção (decrescente)

	cQry := ChangeQuery(cQry)
	TcQuery cQry New Alias "QRYU00"

	If QRYU00->(!EOF())
		dDtManut := StoD(QRYU00->U00_DTINT)
		nNewValE := QRYU00->U02_ENCATU
	EndIf

	QRYU00->(DbCloseArea())

Return {dDtManut,nNewValE}

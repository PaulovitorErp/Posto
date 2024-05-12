#include "protheus.ch"
#include "topconn.ch"

/*/{Protheus.doc} TRETR005
Relatório do Livro de Movimentação de Combustível - LMC
@author Maiki Perin
@since 03/11/2018
@version 1.0
@return Nil
@param dData, date, descricao
@param cProd, characters, descricao
@type function
/*/
User Function TRETR005(dData,cProd,cCodUB4)

	Local aDados			:= {} //Produto;Data;NroLivro
	Local lMenuRel

	Private oFont6			:= TFont():New("Arial",,6,.T.,.F.,5,.T.,5,.T.,.F.) 			//Fonte 6 Normal
	Private oFont6N 		:= TFont():New("Arial",,6,,.T.,,,,.T.,.F.) 					//Fonte 6 Negrito
	Private oFont8			:= TFont():New('Arial',,8,,.F.,,,,.F.,.F.) 					//Fonte 8 Normal
	Private oFont8N			:= TFont():New('Arial',,8,,.T.,,,,.F.,.F.) 				 	//Fonte 8 Negrito
	Private oFont9			:= TFont():New('Arial',,9,,.F.,,,,.F.,.F.) 					//Fonte 9 Normal
	Private oFont9N			:= TFont():New('Arial',,9,,.T.,,,,.F.,.F.) 				 	//Fonte 9 Negrito
	Private oFont8NI		:= TFont():New('Times New Roman',,8,,.T.,,,,.F.,.F.,.T.) 	//Fonte 8 Negrito e Itálico
	Private oFont10			:= TFont():New('Arial',,10,,.F.,,,,.F.,.F.) 				//Fonte 10 Normal
	Private oFont10N		:= TFont():New('Arial',,10,,.T.,,,,.F.,.F.) 				//Fonte 10 Negrito
	Private oFont12			:= TFont():New('Arial',,12,,.F.,,,,.F.,.F.) 				//Fonte 12 Normal
	Private oFont12N		:= TFont():New('Arial',,12,,.T.,,,,.F.,.F.) 			 	//Fonte 12 Negrito
	Private oFont13N		:= TFont():New('Arial',,13,,.T.,,,,.F.,.F.) 				//Fonte 13 Negrito
	Private oFont14			:= TFont():New('Arial',,14,,.F.,,,,.F.,.F.) 				//Fonte 14 Normal
	Private oFont14N		:= TFont():New('Arial',,14,,.T.,,,,.F.,.F.) 				//Fonte 14 Negrito
	Private oFont14NI		:= TFont():New('Times New Roman',,14,,.T.,,,,.F.,.F.,.T.) 	//Fonte 14 Negrito e Itálico
	Private oFont16N		:= TFont():New('Arial',,16,,.T.,,,,.F.,.F.) 				//Fonte 16 Negrito
	Private oFont16NI		:= TFont():New('Times New Roman',,16,,.T.,,,,.F.,.F.,.T.) 	//Fonte 16 Negrito e Itálico
	Private oFont18			:= TFont():New("Arial",,18,,.F.,,,,,.F.,.F.)				//Fonte 18 Negrito
	Private oFont18N		:= TFont():New("Arial",,18,,.T.,,,,,.F.,.F.)				//Fonte 18 Negrito
	Private oFont22			:= TFont():New("Arial",,22,,.F.,,,,,.F.,.F.)				//Fonte 26 Normal

	Private oBrush			:= TBrush():New(,CLR_HGRAY)

	Private cPerg			:= "TRETR005"

	Private nLin 			:= 60
	Private oRel			:= TmsPrinter():New("")

	Private aTq				:= {}

	Private lSeqPag			:= .F.
	Private nSeqpag

	Private dPriDia			:= CToD("")
	Private dUltDia			:= CToD("")

	If ValType(dData) == "U"
		If !ValidPerg()
			Return
		Endif
	Endif

	oRel:setPaperSize(DMPAPER_A4)

	oRel:SetPortrait()///Define a orientacao da impressao como retrato
	//oRel:SetLandscape() ///Define a orientacao da impressao como paisagem
	//oRel:Setup()

	If ValType(dData) == "U"
		aDados 		:= BuscaDados()
		lMenuRel 	:= .T.
	Else
		aDados 		:= {{cProd,DToS(dData),cCodUB4}}
		lMenuRel 	:= .F.
	Endif

	FWMsgRun(,{|| ProcImp(aDados) },"Aguarde","Imprimindo...")

	oRel:Preview()

Return

Static Function ProcImp(aDados)

	Local nX

	For nX := 1 To Len(aDados)
		//FWMsgRun(,{|| ImpLmc(aDados[nX][1],aDados[nX][2],aDados[nX][3])},"Aguarde","Imprimindo...")
		ImpLmc(aDados[nX][1],aDados[nX][2],aDados[nX][3])

		// Incluído tempo entre as impressões quando for impressão do livro
		//If ValType(dData) == "U"
		//	Sleep(5000)
		//EndIf
	Next

Return

/*/{Protheus.doc} BuscaDados
Busca os dados do relatorio
@author thebr
@since 30/11/2018
@version 1.0
@return Nil
@type function
/*/
Static Function BuscaDados()

	Local aRet 	:= {}

	Local cQry	:= ""

	If Select("QRYLMC") > 0
		QRYLMC->(DbCloseArea())
	Endif

	cQry := "SELECT DISTINCT MIE.MIE_DATA, MIE.MIE_CODPRO, UB4.UB4_COMPET, MIE.MIE_NRLIVR"
	cQry += " FROM "+RetSqlName("MIE")+" MIE, "+RetSqlName("UB4")+" UB4"
	cQry += " WHERE MIE.D_E_L_E_T_ = ' '"
	cQry += " AND UB4.D_E_L_E_T_  = ' '"
	cQry += " AND MIE.MIE_FILIAL = '"+xFilial("MIE")+"'"
	cQry += " AND UB4.UB4_FILIAL = '"+xFilial("UB4")+"'"
	cQry += " AND MIE.MIE_NRLIVR = UB4.UB4_CODIGO"
	cQry += " AND MIE.MIE_CODPRO = UB4.UB4_PROD"
	cQry += " AND UB4.UB4_PROD = '"+MV_PAR01+"'"
	cQry += " AND UB4.UB4_NUMERO >= '"+MV_PAR02+"'"
	cQry += " AND UB4.UB4_NUMERO <= '"+MV_PAR03+"'"
	cQry += " AND UB4.UB4_COMPET >= '"+MV_PAR04+"'"
	cQry += " AND UB4.UB4_COMPET <= '"+MV_PAR05+"'"
	cQry += " ORDER BY 1,2,3,4"

	cQry := ChangeQuery(cQry)
	//MemoWrite("c:\temp\TRETR005.txt",cQry)
	TcQuery cQry NEW Alias "QRYLMC"

	While QRYLMC->(!EOF())

		AAdd(aRet,{QRYLMC->MIE_CODPRO,QRYLMC->MIE_DATA,QRYLMC->MIE_NRLIVR})

		If Empty(dPriDia)
			dPriDia := SToD(SubStr(QRYLMC->UB4_COMPET,3,4) + SubStr(QRYLMC->UB4_COMPET,1,2) + "01")
			dUltDia	:= LastDay(dPriDia) //Último dia do mês em Pauta
		ElseIf LastDay(SToD(SubStr(QRYLMC->UB4_COMPET,3,4) + SubStr(QRYLMC->UB4_COMPET,1,2) + "01")) > dUltDia
			dUltDia := LastDay(SToD(SubStr(QRYLMC->UB4_COMPET,3,4) + SubStr(QRYLMC->UB4_COMPET,1,2) + "01"))
		Endif

		QRYLMC->(DbSkip())
	EndDo

Return aRet

/*/{Protheus.doc} ImpLmc
Faz impressao LMC
@author thebr
@since 30/11/2018
@version 1.0
@return Nil
@param cProd, characters, descricao
@param cData, characters, descricao
@param cCodUB4, characters, descricao
@type function
/*/
Static Function ImpLmc(cProd,cData,cCodUB4)

	Local aRec			:= {}
	Local aVen			:= {}

	Local nPag			:= 1

	Local cQry			:= ""

	Local nContTq 		:= 0
	Local nTotAbert		:= 0
	Local nTotRec		:= 0
	Local nTotVen		:= 0
	Local nAcum			:= 0
	Local nTotFech		:= 0
	Local nTotTqFech	:= 0
	Local nPerGan		:= 0

	Local nIniRec		:= 1
	Local nFinRec		:= 15
	Local nIniVen		:= 1
	Local nFinVen		:= 20

	Local aAux			:= {}
	Local nAux			:= 0
	Local nX,nY,nZ

	Local lNPag			:= .F. //Identifica se há mais de um página
	Local lUltPag		:= .F. //Identifica se a impressão é da última página

	Local cPriDia		:= cValToChar(Year(SToD(cData))) + StrZero(Month(SToD(cData)),2) + "01"

	Local cAbert		:= ""
	Local cFech			:= ""
	Local nI
	Local lQObs			:= .F.
	Local lMObs			:= .F.

	Local oLMC
	Local lLmcTqSped 	:= SuperGetMV("MV_XLMCTQS",,.F.) //Usa campo MHZ_TQSPED tanque sped para impressao LMC?
	Local aTqSped		:= {}
	Local aSM0

	//verifica se há divergências do gravado com a leitura atual
	if ChkFile("U0I")
		U_TRETE039(SToD(cData),cProd)
	endif

	//dbSelectArea("SM0")
	//SM0->(dbSeek(cEmpAnt+cFilAnt))
	If Empty(Select("SM0"))
		OpenSM0(cEmpAnt)
	EndIf
	aSM0 := FWSM0Util():GetSM0Data()

	DbSelectArea("MIE")
	MIE->(DbSetOrder(1)) //MIE_FILIAL+MIE_CODPRO+DTOS(MIE_DATA)+MIE_CODTAN+MIE_CODBIC

	//Localiza os recebimentos e verifica se haverá necessidade de mais de uma página para comportar os dados
	aRec := RetRec(cProd,cData)

	If Len(aRec) > 15
		If (Len(aRec) / 15) - Int((Len(aRec) / 15)) > 0
			nPag := Int(Len(aRec) / 15) + 1
		Else
			nPag := Len(aRec) / 15
		Endif
	Endif

	If Select("QRYTQ") > 0
		QRYTQ->(DbCloseArea())
	Endif

	cQry := "SELECT MHZ_CODTAN, MHZ_TQSPED"
	cQry += " FROM "+RetSqlName("MHZ")+""
	cQry += " WHERE D_E_L_E_T_ 	= ' '"
	cQry += " AND MHZ_FILIAL	= '"+xFilial("MHZ")+"'"
	cQry += " AND MHZ_CODPRO	= '"+cProd+"'"
	cQry += " AND ((MHZ_STATUS = '1' AND MHZ_DTATIV <= '"+cData+"') OR (MHZ_STATUS = '2' AND MHZ_DTDESA >= '"+cData+"'))"
	cQry += " ORDER BY 1"

	cQry := ChangeQuery(cQry)
	//MemoWrite("c:\temp\TRETR005.txt",cQry)
	TcQuery cQry NEW Alias "QRYTQ"

	While QRYTQ->(!EOF())

		AAdd(aTq,QRYTQ->MHZ_CODTAN)
		AAdd(aTqSped, {QRYTQ->MHZ_CODTAN, QRYTQ->MHZ_TQSPED})

		QRYTQ->(DbSkip())
	EndDo

	If Select("QRYTQ") > 0
		QRYTQ->(DbCloseArea())
	Endif

	//retorna dados de vendas
	oLMC := TLmcLib():New(cProd, STOD(cData))
	oLMC:SetTanques(aTq)
	oLMC:SetTRetVen(2) //1=Vlr Total Vendas; 2=Array Dados; 3=Qtd Registros
	oLMC:SetDRetVen({"_TANQUE", "_BICO", "_FECH", "_ABERT", "_AFERIC", "_VDBICO"})
	aVen := oLMC:RetVen()

	//Localiza as vendas e verifica se haverá necessidade de mais de uma página para comportar os dados
	If Len(aVen) > 20

		If (Len(aVen) / 20) - Int((Len(aVen) / 20)) > 0
			nAux := Int(Len(aVen) / 20) + 1
		Else
			nAux := Len(aVen) / 20
		Endif

		If nAux > nPag
			nPag := nAux
		Endif
	Endif

	//Controle de impressão com mais de uma página
	If nPag > 1
		lNPag := .T.
	Endif

	For nI := 1 To nPag

		oRel:StartPage() //Inicia uma nova página

		nLin 		:= 60

		nContTq 	:= 0
		nTotAbert	:= 0
		nAcum		:= 0
		nTotTqFech	:= 0

		lQObs 		:= .F.
		lMObs 		:= .F.

		If lNPag
			If nI == nPag
				lUltPag := .T.
			Endif
		Endif

		If nI == 1 //Página 1
			nIniRec	:= 1

			If Len(aRec) > 15
				nFinRec := 15
			Else
				nFinRec := Len(aRec)
			Endif

			nIniVen	:= 1

			If Len(aVen) > 20
				nFinVen := 20
			Else
				nFinVen := Len(aVen)
			Endif

		ElseIf nI == 2 //Página 2

			nIniRec	:= 16

			If Len(aRec) > 30
				nFinRec := 30
			Else
				nFinRec := Len(aRec)
			Endif

			nIniVen		:= 21

			If Len(aVen) > 40
				nFinVen := 40
			Else
				nFinVen := Len(aVen)
			Endif

		ElseIf nI == 3 //Página 3

			nIniRec	:= 31
			nFinRec := Len(aRec)

			nIniVen	:= 41
			nFinVen := Len(aVen)
		Endif

		//Título e página
		oRel:Say(nLin,0500,"Livro de Movimentação de Combustíveis (LMC)",oFont14N)

		DbSelectArea("UB4")
		UB4->(DbSetOrder(1)) //UB4_FILIAL+UB4_CODIGO
		If UB4->(DbSeek(xFilial("UB4")+cCodUB4)) .and. (UB4->UB4_PROD == cProd)
			If UB4->UB4_PAGINA == "R" //Repetido
				oRel:Say(nLin,2120,StrZero(Val(SubStr(cData,7,2)) + 1,3),oFont12)
			ElseIf UB4->UB4_PAGINA == "S" //Sequencial
				If lSeqPag
					nSeqPag++
					oRel:Say(nLin,2120,StrZero(nSeqPag,3),oFont12)
				Else
					lSeqPag := .T.
					nSeqPag := Val(SubStr(cData,7,2)) + 1
					oRel:Say(nLin,2120,StrZero(nSeqPag,3),oFont12)
				Endif
			Endif
		Else
			oRel:Say(nLin,2120,StrZero(Val(SubStr(cData,7,2)) + 1,3),oFont12)
		Endif

		nLin += 70 //130

		//Boxs moldura
		//Externo
		oRel:Box(nLin + 005,0120,3266,2378)
		//Parte cima
		oRel:Box(nLin + 013,0128,2277,2370)
		//Parte baixo
		oRel:Box(nLin + 2157,0128,3258,2370)

		//Cabeçalho
		//1
		oRel:Box(nLin + 013,0128,0200,0184)
		oRel:Say(nLin + 023,0145,"1",oFont9)
		oRel:Say(nLin + 023,0213,"Produto:",oFont9)
		oRel:Say(nLin + 023,0350,Posicione("SB1",1,xFilial("SB1")+cProd,"B1_DESC"),oFont9)

		//2
		oRel:Box(nLin + 013,1799,0200,1855)
		oRel:Say(nLin + 023,1816,"2",oFont9)
		oRel:Say(nLin + 023,1888,"Data:",oFont9)
		oRel:Say(nLin + 023,2030,DToC(SToD(cData)),oFont9)

		nLin += 70 //200

		//3
		oRel:Box(nLin,0128,0257,2370)
		oRel:Box(nLin,0128,0257,0184)
		oRel:Say(nLin + 10,0145,"3",oFont9)
		oRel:Say(nLin + 10,0213,"Estoque de Abertura (Medição física no início do dia)",oFont9)
		//Tanques
		oRel:Box(nLin + 057,0128,0314,2370)
		oRel:Box(nLin + 057,0128,0314,0198)
		oRel:Say(nLin + 067,0140,"TQ",oFont9)
		oRel:Box(nLin + 057,0428,0314,0498)
		oRel:Say(nLin + 067,0440,"TQ",oFont9)
		oRel:Box(nLin + 057,0728,0314,0798)
		oRel:Say(nLin + 067,0740,"TQ",oFont9)
		oRel:Box(nLin + 057,1028,0314,1098)
		oRel:Say(nLin + 067,1040,"TQ",oFont9)
		oRel:Box(nLin + 057,1328,0314,1398)
		oRel:Say(nLin + 067,1340,"TQ",oFont9)
		oRel:Box(nLin + 057,1628,0314,1698)
		oRel:Say(nLin + 067,1640,"TQ",oFont9)

		If Select("QRYTQABERT") > 0
			QRYTQABERT->(dbCloseArea())
		Endif

		cQry := "SELECT MHZ_CODTAN, MHZ_TQSPED"
		cQry += " FROM "+RetSqlName("MHZ")+""
		cQry += " WHERE D_E_L_E_T_ 	= ' '"
		cQry += " AND MHZ_FILIAL	= '"+xFilial("MHZ")+"'"
		cQry += " AND MHZ_CODPRO	= '"+cProd+"'"
		cQry += " AND ((MHZ_STATUS = '1' AND MHZ_DTATIV <= '"+cData+"') OR (MHZ_STATUS = '2' AND MHZ_DTDESA >= '"+cData+"'))"
		cQry += " ORDER BY 1"

		cQry := ChangeQuery(cQry)
		//MemoWrite("c:\temp\TRETR005.txt",cQry)
		TcQuery cQry NEW Alias "QRYTQABERT"

		While QRYTQABERT->(!EOF())

			Do Case
			Case nContTq == 0
				nAux := 270

			Case nContTq == 1
				nAux := 570

			Case nContTq == 2
				nAux := 870

			Case nContTq == 3
				nAux := 1170

			Case nContTq == 4
				nAux := 1470

			Case nContTq == 5
				nAux := 1770
			EndCase

			if lLmcTqSped
				oRel:Say(nLin + 067,nAux,QRYTQABERT->MHZ_TQSPED,oFont9)
			else
				oRel:Say(nLin + 067,nAux,QRYTQABERT->MHZ_CODTAN,oFont9)
			endif

			If MIE->(DbSeek(xFilial("MIE")+cProd+cData))

				cAbert := "MIE->MIE_ESTI" + QRYTQABERT->MHZ_CODTAN

				oRel:Say(nLin + 124,nAux - 150,Transform(&cAbert,"@E 99,999,999,999,999.999"),oFont9)

				nTotAbert += &cAbert
			Endif

			nContTq++

			If nContTq == 6
				Exit
			Endif

			QRYTQABERT->(DbSkip())
		EndDo

		//3.1
		oRel:Box(nLin + 057,1928,0314,1998)
		oRel:Say(nLin + 067,1940,"3.1",oFont9)
		oRel:Say(nLin + 067,2030,"Estoque Abertura",oFont9)
		oRel:Box(nLin + 114,0128,0371,0428)
		oRel:Box(nLin + 114,0428,0371,0728)
		oRel:Box(nLin + 114,0728,0371,1028)
		oRel:Box(nLin + 114,1028,0371,1328)
		oRel:Box(nLin + 114,1328,0371,1628)
		oRel:Box(nLin + 114,1628,0371,1928)
		oRel:Box(nLin + 114,1928,0371,2370)
		oRel:Say(nLin + 124,2250,Transform(nTotAbert,"@E 99,999,999,999,999.999"),oFont9,,,,1)

		nLin += 171 //371

		//4
		oRel:Box(nLin,0128,0428,2370)
		oRel:Box(nLin,0128,0428,0184)
		oRel:Say(nLin + 010,0145,"4",oFont9)
		oRel:Say(nLin + 010,0213,"Volume Recebido no dia (em litros)",oFont9)
		//4.1
		oRel:Box(nLin,1535,0428,1595)
		oRel:Say(nLin + 010,1544,"4.1",oFont9)
		oRel:Say(nLin + 010,1620,"Nr. TQ Descarga",oFont9)
		//4.2
		oRel:Box(nLin,1928,0428,1998)
		oRel:Say(nLin + 010,1940,"4.2",oFont9)
		oRel:Say(nLin + 010,2030,"Volume Recebido",oFont9)

		nLin += 57 //428

		For nX := 1 To 15
			oRel:Box(nLin,0128,nLin + 47,2370)
			oRel:Box(nLin,1535,nLin + 47,1928)
			nLin += 47
		Next nX

		If Len(aRec) > 0

			nLin := 428

			DbSelectArea("MHZ")
			MHZ->(DbSetOrder(3)) //MHZ_FILIAL+MHZ_CODPRO+MHZ_LOCAL

			For nX := nIniRec To nFinRec
				//DT. Digit + Doc + Fornecedor
				oRel:Say(nLin + 7,0180,DToC(SToD(aRec[nX][1])),oFont9)
				oRel:Say(nLin + 7,0400,aRec[nX][2],oFont9)
				oRel:Say(nLin + 7,0600,aRec[nX][3],oFont9)

				If MHZ->(DbSeek(xFilial("MHZ")+cProd+aRec[nX][4]))
					While MHZ->(!Eof()) .AND. MHZ->MHZ_FILIAL + MHZ->MHZ_CODPRO + MHZ->MHZ_LOCAL == xFilial("MHZ")+cProd+aRec[nX][4]
						//If MHZ->MHZ_STATUS == "1" //Ativo
						if ((MHZ->MHZ_STATUS == '1' .AND. MHZ->MHZ_DTATIV <= SToD(cData)) .OR. (MHZ->MHZ_STATUS == '2' .AND. MHZ->MHZ_DTDESA >= SToD(cData)))
							if lLmcTqSped
								oRel:Say(nLin + 005,1680,MHZ->MHZ_TQSPED,oFont9) //Nr. TQ Descarga
							else
								oRel:Say(nLin + 005,1680,MHZ->MHZ_CODTAN,oFont9) //Nr. TQ Descarga
							endif
							EXIT
						Endif
						MHZ->(DbSkip())
					EndDo
				Endif

				oRel:Say(nLin + 005,2250,Transform(aRec[nX][5],"@E 99,999,999,999,999.999"),oFont9,,,,1) //Volume Recebido

				nTotRec += aRec[nX][5]

				nLin += 47
			Next nX

			nLin := 1133
		Endif

		//nLin igual a 1133

		//4.3
		oRel:Box(nLin,0128,nLin + 57,2370)
		oRel:Box(nLin,1535,nLin + 57,1928)
		oRel:Box(nLin,1535,nLin + 57,1595)
		oRel:Say(nLin + 010,1544,"4.3",oFont9)
		oRel:Say(nLin + 010,1620,"Total Recebido",oFont9)
		If lNPag
			If lUltPag
				oRel:Say(nLin + 020,2250,Transform(nTotRec,"@E 99,999,999,999,999.999"),oFont9,,,,1)
			Else
				oRel:Say(nLin + 020,2100,"***********",oFont9)
			Endif
		Else
			oRel:Say(nLin + 020,2250,Transform(nTotRec,"@E 99,999,999,999,999.999"),oFont9,,,,1)
		Endif

		nLin += 57 //1190

		//5
		oRel:Box(nLin,0128,nLin + 90,2370)
		oRel:Box(nLin,0128,nLin + 90,0198)
		oRel:Say(nLin + 028,0140,"5",oFont9)
		oRel:Say(nLin + 028,0213,"Volume Vendido no dia (em litros)",oFont10)
		//4.4
		oRel:Box(nLin,1535,nLin + 90,1928)
		oRel:Box(nLin,1535,nLin + 90,1595)
		oRel:Say(nLin + 028,1544,"4.4",oFont9)
		oRel:Say(nLin + 005,1610,"Volume Disponível",oFont10)
		oRel:Say(nLin + 045,1665,"(3.1 + 4.3)",oFont9)
		If lNPag
			If lUltPag
				oRel:Say(nLin + 030,2250,Transform(nTotAbert + nTotRec,"@E 99,999,999,999,999.999"),oFont9,,,,1)
			Else
				oRel:Say(nLin + 030,2100,"***********",oFont9)
			Endif
		Else
			oRel:Say(nLin + 030,2250,Transform(nTotAbert + nTotRec,"@E 99,999,999,999,999.999"),oFont9,,,,1)
		Endif

		nLin += 90 //1280

		//5.1
		oRel:Box(nLin,0128,nLin + 57,2370)
		oRel:Box(nLin,0128,nLin + 57,0198)
		oRel:Say(nLin + 10,0145,"5.1",oFont9)
		oRel:Say(nLin + 10,0245,"TQ",oFont9)
		//5.2
		oRel:Box(nLin,0340,nLin + 57,0410)
		oRel:Say(nLin + 10,0352,"5.2",oFont9)
		oRel:Say(nLin + 10,0517,"Bico",oFont9)
		//5.3
		oRel:Box(nLin,0735,nLin + 57,0805)
		oRel:Say(nLin + 10,0747,"5.3",oFont9)
		oRel:Say(nLin + 10,0853,"+ Fechamento",oFont9)
		//5.4
		oRel:Box(nLin,1125,nLin + 57,1195)
		oRel:Say(nLin + 10,1137,"5.4",oFont9)
		oRel:Say(nLin + 10,1265,"- Abertura",oFont9)
		//5.5
		oRel:Box(nLin,1535,nLin + 57,1595)
		oRel:Say(nLin + 10,1544,"5.5",oFont9)
		oRel:Say(nLin + 10,1655,"- Aferições",oFont9)
		//5.6
		oRel:Box(nLin,1928,nLin + 57,1998)
		oRel:Say(nLin + 10,1940,"5.6",oFont9)
		oRel:Say(nLin + 10,2030,"= Vendas no Bico",oFont9)

		nLin += 57 //1337

		For nY := 1 To 20
			oRel:Box(nLin,0128,nLin + 47,2370)
			oRel:Box(nLin,0340,nLin + 47,0735)
			oRel:Box(nLin,0735,nLin + 47,1125)
			oRel:Box(nLin,1125,nLin + 47,1535)
			oRel:Box(nLin,1535,nLin + 47,1928)

			nLin += 47
		Next nY

		If Len(aVen) > 0

			nLin := 1337

			For nY := nIniVen To nFinVen
				if lLmcTqSped .AND. aScan(aTqSped, {|x| x[1] == aVen[nY][1] })
					oRel:Say(nLin + 7,0200,aTqSped[aScan(aTqSped, {|x| x[1] == aVen[nY][1] })][2],oFont9) //TQ
				else
					oRel:Say(nLin + 7,0200,aVen[nY][1],oFont9) //TQ
				endif
				oRel:Say(nLin + 7,0490,aVen[nY][2],oFont9) //Bico
				oRel:Say(nLin + 7,0760,Transform(aVen[nY][3],"@E 99,999,999,999,999.999"),oFont9) //+ Fechamento
				oRel:Say(nLin + 7,1140,Transform(aVen[nY][4],"@E 99,999,999,999,999.999"),oFont9) //- Abertura
				oRel:Say(nLin + 7,1530,Transform(aVen[nY][5],"@E 99,999,999,999,999.999"),oFont9) //- Aferições
				oRel:Say(nLin + 7,2250,Transform(aVen[nY][6],"@E 99,999,999,999,999.999"),oFont9,,,,1) //= Vendas no Bico

				nTotVen += aVen[nY][6]

				nLin += 47
			Next nY

			nLin := 2277
		Endif

		//nLin igual a 2277
		nLin += 10 //2287

		//10
		oRel:Box(nLin,0128,nLin + 710,1400)
		//oRel:Box(nLin,1400,nLin + 710,2370)

		oRel:Box(nLin,0128,nLin + 57,0735)
		oRel:Say(nLin + 10,0145,"10 - Valor das Vendas  (R$)",oFont9)
		oRel:Box(nLin,1400,nLin + 57,1470)
		oRel:Say(nLin + 10,1412,"5.7",oFont10)
		oRel:Box(nLin,1470,nLin + 57,1928)
		oRel:Say(nLin + 10,1550,"Vendas no dia",oFont10)
		oRel:Box(nLin,1928,nLin + 57,2370)
		If lNPag
			If lUltPag
				oRel:Say(nLin + 15,2250,Transform(nTotVen,"@E 99,999,999,999,999.999"),oFont9,,,,1)
			Else
				oRel:Say(nLin + 15,2100,"***********",oFont9) //= Vendas no Bico
			Endif
		Else
			oRel:Say(nLin + 15,2250,Transform(nTotVen,"@E 99,999,999,999,999.999"),oFont9,,,,1)
		Endif

		nLin += 57 //2344

		//10.1
		oRel:Box(nLin,0128,nLin + 90,0198)
		oRel:Say(nLin + 28,0130,"10.1",oFont9)
		oRel:Say(nLin + 5,0223,"Valor das Vendas do dia",oFont9)
		oRel:Say(nLin + 45,0239,"(5.7 X Preço Bomba)",oFont9)
		oRel:Box(nLin + 8,0735,nLin + 82,1300)

		If MIE->(dbSeek(xFilial("MIE")+cProd+cData))
			If lNPag
				If lUltPag
					oRel:Say(nLin + 25,0980,Transform(MIE->MIE_VLRITE,"@E 999,999,999.99"),oFont9)
				Else
					oRel:Say(nLin + 25,0980,"***********",oFont9)
				Endif
			Else
				oRel:Say(nLin + 25,0980,Transform(MIE->MIE_VLRITE,"@E 999,999,999.99"),oFont9)
			Endif
		Endif

		oRel:Box(nLin,1400,nLin + 90,1470)
		oRel:Say(nLin + 28,1412,"6",oFont10)
		oRel:Box(nLin,1470,nLin + 90,1928)
		oRel:Say(nLin + 5,1520,"Estoque Escritural",oFont10)
		oRel:Say(nLin + 45,1575,"(4.4 - 5.7)",oFont10)
		oRel:Box(nLin,1928,nLin + 90,2370)
		If lNPag
			If lUltPag
				oRel:Say(nLin + 25,2250,Transform((nTotAbert + nTotRec) - nTotVen,"@E 99,999,999,999,999.999"),oFont9,,,,1)
			Else
				oRel:Say(nLin + 25,2100,"***********",oFont9)
			Endif
		Else
			oRel:Say(nLin + 25,2250,Transform((nTotAbert + nTotRec) - nTotVen,"@E 99,999,999,999,999.999"),oFont9,,,,1)
		Endif

		nLin += 90 //2434

		//10.2
		oRel:Box(nLin,0128,nLin + 90,2370)
		oRel:Box(nLin,0128,nLin + 90,0198)
		oRel:Say(nLin + 28,0130,"10.2",oFont9)
		oRel:Say(nLin + 28,0223,"Valor Acumulado no mês",oFont10)
		oRel:Box(nLin + 8,0735,nLin + 82,1300)

		If Select("QRYACUM") > 0
			QRYACUM->(DbCloseArea())
		Endif

		cQry := "SELECT SUM(MIE_VLRITE) AS VLR"
		cQry += " FROM "+RetSqlName("MIE")+""
		cQry += " WHERE D_E_L_E_T_ 	= ' '"
		cQry += " AND MIE_FILIAL	= '"+xFilial("MIE")+"'"
		cQry += " AND MIE_CODPRO	= '"+cProd+"'"
		cQry += " AND MIE_DATA		BETWEEN '"+cPriDia+"'  AND '"+cData+"'

		cQry := ChangeQuery(cQry)
		//MemoWrite("c:\temp\TRETR005.txt",cQry)
		TcQuery cQry NEW Alias "QRYACUM"

		If QRYACUM->(!EOF())
			nAcum += QRYACUM->VLR
		Endif

		If lNPag
			If lUltPag
				oRel:Say(nLin + 25,0980,Transform(nAcum,"@E 999,999,999.99"),oFont9)
			Else
				oRel:Say(nLin + 25,0980,"***********",oFont9)
			Endif
		Else
			oRel:Say(nLin + 25,0980,Transform(nAcum,"@E 999,999,999.99"),oFont9)
		Endif
		oRel:Box(nLin,1400,nLin + 90,1470)
		oRel:Say(nLin + 28,1412,"7",oFont10)
		oRel:Box(nLin,1470,nLin + 90,1928)
		oRel:Say(nLin + 5,1510,"Estoque de Fechamento",oFont10)
		oRel:Say(nLin + 45,1630,"(9.1)",oFont10)
		oRel:Box(nLin,1928,nLin + 90,2370)

		If Select("QRYESTFECH") > 0
			QRYESTFECH->(DbCloseArea())
		Endif

		cQry := "SELECT SUM(MIE_ESTFEC) AS QTD"
		cQry += " FROM "+RetSqlName("MIE")+""
		cQry += " WHERE D_E_L_E_T_ 	= ' '"
		cQry += " AND MIE_FILIAL	= '"+xFilial("MIE")+"'"
		cQry += " AND MIE_CODPRO	= '"+cProd+"'"
		cQry += " AND MIE_DATA		= '"+cData+"'"
		cQry += " ORDER BY 1"

		cQry := ChangeQuery(cQry)
		//MemoWrite("c:\temp\RPOS011.txt",cQry)
		TcQuery cQry NEW Alias "QRYESTFECH"

		If QRYESTFECH->(!EOF())
			nTotFech := QRYESTFECH->QTD
		Endif

		If lNPag
			If lUltPag
				oRel:Say(nLin + 25,2250,Transform(nTotFech,"@E 99,999,999,999,999.999"),oFont9,,,,1)
			Else
				oRel:Say(nLin + 25,2100,"***********",oFont9)
			Endif
		Else
			oRel:Say(nLin + 25,2250,Transform(nTotFech,"@E 99,999,999,999,999.999"),oFont9,,,,1)
		Endif

		nLin += 90 //2524

		//11
		oRel:Box(nLin,0128,nLin + 160,1400)
		oRel:Say(nLin + 5,0145,"11 - Para uso do Revendedor",oFont10)
		oRel:Box(nLin,1400,nLin + 80,1928)
		oRel:Box(nLin,1400,nLin + 80,1470)
		oRel:Say(nLin + 28,1412,"8",oFont10)
		oRel:Say(nLin + 5,1590,"- Perdas",oFont9)
		oRel:Say(nLin + 45,1590,"+ Ganhos(*)",oFont9)
		oRel:Box(nLin,1928,nLin + 80,2370)

		If Select("QRYPERGAN") > 0
			QRYPERGAN->(DbCloseArea())
		Endif

		cQry := "SELECT MIE_GANHOS - MIE_PERDA AS QTD"
		cQry += " FROM "+RetSqlName("MIE")+""
		cQry += " WHERE D_E_L_E_T_ 	= ' '"
		cQry += " AND MIE_FILIAL	= '"+xFilial("MIE")+"'"
		cQry += " AND MIE_CODPRO	= '"+cProd+"'"
		cQry += " AND MIE_DATA		= '"+cData+"'"
		cQry += " ORDER BY 1"

		cQry := ChangeQuery(cQry)
		//MemoWrite("c:\temp\RPOS011.txt",cQry)
		TcQuery cQry NEW Alias "QRYPERGAN"

		If QRYPERGAN->(!EOF())
			nPerGan := QTD
		Endif

		If lNPag
			If lUltPag
				oRel:Say(nLin + 25,2250,Transform(nPerGan,"@E 99,999,999,999,999.999"),oFont9,,,,1)
			Else
				oRel:Say(nLin + 25,2100,"***********",oFont9)
			Endif
		Else
			oRel:Say(nLin + 25,2250,Transform(nPerGan,"@E 99,999,999,999,999.999"),oFont9,,,,1)
		Endif

		nLin += 80 //2604

		oRel:Box(nLin,1400,nLin + 60,2320)
		oRel:Say(nLin + 10,1412,"12 - Destinado a Fiscalização			ANP",oFont9)

		nLin += 80 //2684

		//13
		oRel:Box(nLin,0128,nLin + 57,0500)
		oRel:Say(nLin + 10,0145,"13 - Observações",oFont9)

		//Só imprime as inf. de filtros e bicos no primeiro e último dia
		If cData == DToS(dPriDia) .Or. cData == DToS(dUltDia)
			lPriUltPag := .T.
		Else
			lPriUltPag := .F.
		Endif

		If lPriUltPag

			//Informações de Tanques e respectivos Bicos
			If Select("QRYOBSTQ") > 0
				QRYOBSTQ->(DbCloseArea())
			Endif

			cQry := "SELECT MHZ_CODTAN, MHZ_TQSPED, SUM(MHZ_CAPNOM) AS CAPNOM"
			cQry += " FROM "+RetSqlName("MHZ")+""
			cQry += " WHERE D_E_L_E_T_ 	= ' '"
			cQry += " AND MHZ_FILIAL	= '"+xFilial("MHZ")+"'"
			cQry += " AND MHZ_CODPRO	= '"+cProd+"'"
			cQry += " AND ((MHZ_STATUS = '1' AND MHZ_DTATIV <= '"+cData+"') OR (MHZ_STATUS = '2' AND MHZ_DTDESA >= '"+cData+"'))"
			cQry += " GROUP BY MHZ_CODTAN, MHZ_TQSPED"
			cQry += " ORDER BY 1"

			cQry := ChangeQuery(cQry)
			//MemoWrite("c:\temp\TRETR005.txt",cQry)
			TcQuery cQry NEW Alias "QRYOBSTQ"

			While QRYOBSTQ->(!EOF())

				If nLin >= 2850 .OR. lQObs

					If !lQObs
						nLin := 2624
					Endif

					if lLmcTqSped
						oRel:Say(nLin + 70,0780,"TANQUE: " + AllTrim(QRYOBSTQ->MHZ_TQSPED) + " - Capacidade: " + Transform(QRYOBSTQ->CAPNOM,"@E 999,999"),oFont9)
					else
						oRel:Say(nLin + 70,0780,"TANQUE: " + AllTrim(QRYOBSTQ->MHZ_CODTAN) + " - Capacidade: " + Transform(QRYOBSTQ->CAPNOM,"@E 999,999"),oFont9)
					endif
					nLin += 45
					cBicos := RetBicos(QRYOBSTQ->MHZ_CODTAN, cData)

					If Len(cBicos) > 35
						oRel:Say(nLin + 70,0780,"Bico(s): " + SubStr(cBicos,1,35),oFont9)
						nLin += 45
						oRel:Say(nLin + 70,0780,SubStr(cBicos,36,Len(cBicos)),oFont9)
					Else
						oRel:Say(nLin + 70,0780,"Bico(s): " + cBicos,oFont9)
					Endif

					nLin += 50

					lQObs := .T.
				Else
					if lLmcTqSped
						oRel:Say(nLin + 70,0150,"TANQUE: " + AllTrim(QRYOBSTQ->MHZ_TQSPED) + " - Capacidade: " + Transform(QRYOBSTQ->CAPNOM,"@E 999,999"),oFont9)
					else
						oRel:Say(nLin + 70,0150,"TANQUE: " + AllTrim(QRYOBSTQ->MHZ_CODTAN) + " - Capacidade: " + Transform(QRYOBSTQ->CAPNOM,"@E 999,999"),oFont9)
					endif
					nLin += 45

					cBicos := RetBicos(QRYOBSTQ->MHZ_CODTAN, cData)
					If Len(cBicos) > 35
						oRel:Say(nLin + 70,0150,"Bico(s): " + SubStr(cBicos,1,35),oFont9)
						nLin += 45
						oRel:Say(nLin + 70,0150,SubStr(cBicos,36,Len(cBicos)),oFont9)
					Else
						oRel:Say(nLin + 70,0150,"Bico(s): " + cBicos,oFont9)
					Endif
					nLin += 50
				Endif

				QRYOBSTQ->(DbSkip())
			EndDo
		Endif

		aAux := PclPontObs(cData)

		If Len(aAux) > 0

			If !lQObs
				If lPriUltPag
					nLin := 2624
				Else
					nLin := 2684
				Endif
			Endif

			For nZ := 1 To Len(aAux)

				If !Empty(aAux[nZ]) .And. !lMObs
					lMObs := .T.
				Endif

				If !Empty(aAux[nZ])
					If lPriUltPag
						oRel:Say(nLin + 70,0780,aAux[nZ],oFont9)
					Else
						oRel:Say(nLin + 70,0150,aAux[nZ],oFont9)
					Endif
					nLin += 50
				Endif
			Next nZ
		Endif

		//Observação na página do LMC
		If MIE->(DbSeek(xFilial("MIE")+cProd+cData))

			If !Empty(MIE->MIE_OBS)

				If !lQObs .And. !lMObs
					If lPriUltPag
						nLin := 2624
					Else
						nLin := 2684
					Endif
				Endif

				aAux := U_UQuebTxt(MIE->MIE_OBS,30)

				For nZ := 1 To Len(aAux)
					If lPriUltPag
						oRel:Say(nLin + 70,0780,aAux[nZ],oFont9)
					Else
						oRel:Say(nLin + 70,0150,aAux[nZ],oFont9)
					Endif
					nLin += 50
				Next nZ
			Endif
		Endif

		nLin := 2684

		nLin += 153 //2837

		oRel:Box(nLin,1400,nLin + 160,2370)
		oRel:Say(nLin + 10,1412,"OUTROS ÓRGÃOS FISCAIS",oFont10)

		nLin += 160 //2997

		oRel:Box(nLin,0128,nLin + 57,2370)
		oRel:Say(nLin + 10,1020,"Conciliação dos Estoques",oFont10N)

		nLin += 57 //3054

		oRel:Box(nLin,0128,nLin + 57,2370)
		oRel:Box(nLin,0380,nLin + 57,0440)
		oRel:Say(nLin + 10,0388,"TQ",oFont9)
		oRel:Box(nLin,0650,nLin + 57,0710)
		oRel:Say(nLin + 10,0658,"TQ",oFont9)
		oRel:Box(nLin,0920,nLin + 57,0980)
		oRel:Say(nLin + 10,0928,"TQ",oFont9)
		oRel:Box(nLin,1190,nLin + 57,1250)
		oRel:Say(nLin + 10,1198,"TQ",oFont9)
		oRel:Box(nLin,1460,nLin + 57,1520)
		oRel:Say(nLin + 10,1468,"TQ",oFont9)
		oRel:Box(nLin,1730,nLin + 57,1790)
		oRel:Say(nLin + 10,1738,"TQ",oFont9)
		oRel:Box(nLin,2000,nLin + 57,2370)
		oRel:Say(nLin + 10,2115,"TOTAL",oFont9)

		If Select("QRYTQFECH") > 0
			QRYTQFECH->(dbCloseArea())
		Endif

		cQry := "SELECT MHZ_CODTAN, MHZ_TQSPED"
		cQry += " FROM "+RetSqlName("MHZ")+""
		cQry += " WHERE D_E_L_E_T_ 	= ' '"
		cQry += " AND MHZ_FILIAL	= '"+xFilial("MHZ")+"'"
		cQry += " AND MHZ_CODPRO	= '"+cProd+"'"
		cQry += " AND ((MHZ_STATUS = '1' AND MHZ_DTATIV <= '"+cData+"') OR (MHZ_STATUS = '2' AND MHZ_DTDESA >= '"+cData+"'))"
		cQry += " ORDER BY 1"

		cQry := ChangeQuery(cQry)
		//MemoWrite("c:\temp\TRETR005.txt",cQry)
		TcQuery cQry NEW Alias "QRYTQFECH"

		nContTq := 0

		While QRYTQFECH->(!EOF())

			Do Case
			Case nContTq == 0
				nAux := 510

			Case nContTq == 1
				nAux := 780

			Case nContTq == 2
				nAux := 1050

			Case nContTq == 3
				nAux := 1320

			Case nContTq == 4
				nAux := 1590

			Case nContTq == 5
				nAux := 1860
			EndCase

			if lLmcTqSped
				oRel:Say(nLin + 010,nAux,QRYTQFECH->MHZ_TQSPED,oFont9)
			else
				oRel:Say(nLin + 010,nAux,QRYTQFECH->MHZ_CODTAN,oFont9)
			endif

			If MIE->(DbSeek(xFilial("MIE")+cProd+cData))

				cFech := "MIE->MIE_VTAQ" + QRYTQFECH->MHZ_CODTAN

				If lNPag
					If lUltPag
						oRel:Say(nLin + 082,nAux - 150,Transform(&cFech,"@E 99,999,999,999,999.999"),oFont9)
					Else
						oRel:Say(nLin + 082,nAux - 20,"***********",oFont9)
					Endif
				Else
					oRel:Say(nLin + 082,nAux - 150,Transform(&cFech,"@E 99,999,999,999,999.999"),oFont9)
				Endif
			Endif

			nTotTqFech += &cFech

			nContTq++

			If nContTq == 6
				Exit
			Endif

			QRYTQFECH->(dbSkip())
		EndDo

		nLin += 57 //3111

		//9
		oRel:Box(nLin,0128,nLin + 90,2370)
		oRel:Box(nLin,0128,nLin + 90,0380)
		oRel:Box(nLin + 30,0128,nLin + 90,0188)
		oRel:Say(nLin + 40,0140,"9",oFont9)
		oRel:Say(nLin + 5,0195,"Fechamento",oFont9)
		oRel:Say(nLin + 45,0230,"Físico",oFont9)
		oRel:Box(nLin,0380,nLin + 90,0650)
		oRel:Box(nLin,0650,nLin + 90,0920)
		oRel:Box(nLin,0920,nLin + 90,1190)
		oRel:Box(nLin,1190,nLin + 90,1460)
		oRel:Box(nLin,1460,nLin + 90,1730)
		oRel:Box(nLin,1730,nLin + 90,2000)
		oRel:Box(nLin + 30,2000,nLin + 90,2060)
		oRel:Say(nLin + 40,2008,"9.1",oFont9)
		If lNPag
			If lUltPag
				oRel:Say(nLin + 025,2040,Transform(nTotTqFech,"@E 99,999,999,999,999.999"),oFont9)
			Else
				oRel:Say(nLin + 025,2100,"***********",oFont9)
			Endif
		Else
			oRel:Say(nLin + 025,2040,Transform(nTotTqFech,"@E 99,999,999,999,999.999"),oFont9)
		Endif

		nLin += 90 //3201

		oRel:Box(nLin,0128,nLin + 57,2370)
		oRel:Say(nLin + 10,0255,"(*) ATENÇÃO SE O RESULTADO FOR NEGATIVO, PODE ESTAR HAVENDO VAZAMENTO DO PRODUTO PARA O MEIO AMBIENTE",oFont9)

		//Rodapé
		nLin := 3280

		oRel:Say(nLin,0120,"Razao Social:",oFont10,,0)
		nAux := aScan(aSM0, {|x| alltrim(x[1]) == "M0_NOMECOM" })
		oRel:Say(nLin,0370,AllTrim(aSM0[nAux][2]),oFont10,,0) //SM0->M0_NOMECOM

		oRel:Say(nLin,1155,"CNPJ:",oFont10,,0)
		nAux := aScan(aSM0, {|x| alltrim(x[1]) == "M0_CGC" })
		oRel:Say(nLin,1260,Transform(aSM0[nAux][2],"@R 99.999.999/9999-99"),oFont10,,0) //SM0->M0_CGC

		oRel:Say(nLin,1800,"I.E.:",oFont10,,0)
		nAux := aScan(aSM0, {|x| alltrim(x[1]) == "M0_INSC" })
		oRel:Say(nLin,1900,AllTrim(aSM0[nAux][2]),oFont10,,0) //SM0->M0_INSC

		oRel:EndPage() //Finaliza página

	Next nI

	If Select("QRYTQABERT") > 0
		QRYTQABERT->(DbCloseArea())
	Endif

	If Select("QRYACUM") > 0
		QRYACUM->(DbCloseArea())
	Endif

	If Select("QRYESTFECH") > 0
		QRYESTFECH->(DbCloseArea())
	Endif

	If Select("QRYPERGAN") > 0
		QRYPERGAN->(DbCloseArea())
	Endif

	If Select("QRYOBSTQ") > 0
		QRYOBSTQ->(DbCloseArea())
	Endif

	If Select("QRYTQFECH") > 0
		QRYTQFECH->(DbCloseArea())
	Endif

Return

/*/{Protheus.doc} RetRec
Retorna Qtd
@author thebr
@since 30/11/2018
@version 1.0
@return Nil
@param cProd, characters, descricao
@param cData, characters, descricao
@type function
/*/
Static Function RetRec(cProd,cData)

	Local aRet 	:= {}

	Local cQry	:= ""

	If Select("QRYREC") > 0
		QRYREC->(dbCloseArea())
	Endif

	cQry := "SELECT SF1.F1_EMISSAO, SF1.F1_DOC, SA2.A2_NOME, SD1.D1_LOCAL, SUM(SD1.D1_QUANT) AS QTD, SF1.F1_TIPO, SF1.F1_FORNECE, SF1.F1_LOJA"

	cQry += " FROM "+RetSqlName("SF1")+" SF1 INNER JOIN "+RetSqlName("SD1")+" SD1 ON SF1.F1_DOC			= SD1.D1_DOC"
	cQry += " 																		AND SF1.F1_SERIE	= SD1.D1_SERIE"
	cQry += " 																		AND SF1.F1_FORNECE	= SD1.D1_FORNECE"
	cQry += " 																		AND SF1.F1_LOJA		= SD1.D1_LOJA"
	cQry += " 																		AND SD1.D1_COD		= '"+cProd+"'"
	cQry += " 																		AND SD1.D1_FILIAL	= '"+xFilial("SD1")+"'"
	cQry += " 																		AND SD1.D_E_L_E_T_ 	= ' '"

	cQry += " 								LEFT JOIN "+RetSqlName("SA2")+" SA2 ON 	SF1.F1_FORNECE		= SA2.A2_COD"
	cQry += " 																		AND SF1.F1_LOJA		= SA2.A2_LOJA"
	cQry += " 																		AND SA2.D_E_L_E_T_ 	= ' '"
	cQry += " 																		AND SA2.A2_FILIAL	= '"+xFilial("SA2")+"'"

	cQry += "								INNER JOIN "+RetSqlName("SF4")+" SF4 ON SD1.D1_TES			= SF4.F4_CODIGO"
	cQry += " 																		AND SF4.D_E_L_E_T_ 	= ' '"
	cQry += " 																		AND SF4.F4_FILIAL	= '"+xFilial("SF4")+"'"
	cQry += " 																		AND SF4.F4_ESTOQUE	= 'S'" //Movimenta estoque

	cQry += " WHERE SF1.D_E_L_E_T_ 	= ' '"
	cQry += " AND SF1.F1_FILIAL		= '"+xFilial("SF1")+"'"
	cQry += " AND SF1.F1_DTDIGIT	= '"+cData+"'"
	cQry += " AND SF1.F1_TIPO		IN ('N','D')" //Diferente de Complementos e Beneficiamento
	cQry += " AND SF1.F1_XLMC		= 'S'" //Considera LMC
	cQry += " GROUP BY SF1.F1_EMISSAO, SF1.F1_DOC, SA2.A2_NOME, SD1.D1_LOCAL, SF1.F1_TIPO, SF1.F1_FORNECE, SF1.F1_LOJA"
	cQry += " ORDER BY 1,2"

	cQry := ChangeQuery(cQry)
	//MemoWrite("c:\temp\RPOS011.txt",cQry)
	TcQuery cQry NEW Alias "QRYREC"

	While QRYREC->(!EOF())

		aAdd(aRet,{cData,QRYREC->F1_DOC,IIF(QRYREC->F1_TIPO <> "D",QRYREC->A2_NOME,;
			Posicione("SA1",1,xFilial("SA1")+QRYREC->F1_FORNECE+QRYREC->F1_LOJA,"A1_NOME")),QRYREC->D1_LOCAL,QRYREC->QTD})

		QRYREC->(dbSkip())
	EndDo

	If Select("QRYREC") > 0
		QRYREC->(dbCloseArea())
	Endif

Return aRet

/*/{Protheus.doc} RetBicos
Retorna Bicos
@author thebr
@since 30/11/2018
@version 1.0
@return Nil
@param cTq, characters, descricao
@type function
/*/
Static Function RetBicos(cTq, cData)

	Local cRet 	:= ""
	Local cQry	:= ""

	If Select("QRYBICOS") > 0
		QRYBICOS->(DbCloseArea())
	Endif

	cQry := "SELECT MIC_CODBIC"
	cQry += " FROM "+RetSqlName("MIC")+" MIC"
	cQry += " WHERE D_E_L_E_T_	= ' '"
	cQry += " AND MIC_FILIAL 	= '"+xFilial("MIC")+"'"
	cQry += " AND MIC_CODTAN 	= '"+cTq+"'"
	//cQry += " AND MIC_STATUS	= '1'" //Ativo
	cQry += " AND ((MIC_STATUS = '1' AND MIC_XDTATI <= '"+cData+"') OR (MIC_STATUS = '2' AND MIC_XDTDES >= '"+cData+"'))"
	cQry += " ORDER BY 1"

	cQry := ChangeQuery(cQry)
	//MemoWrite("c:\temp\TRETR005.txt",cQry)
	TcQuery cQry NEW Alias "QRYBICOS"

	While QRYBICOS->(!EOF())
		cRet += cValToChar(Val(QRYBICOS->MIC_CODBIC)) + "; "

		QRYBICOS->(DbSkip())
	EndDo

	If Select("QRYBICOS") > 0
		QRYBICOS->(DbCloseArea())
	Endif

Return cRet

/*/{Protheus.doc} PclPontObs
Retorna Dados
@author thebr
@since 30/11/2018
@version 1.0
@return Nil
@param cData, characters, descricao
@type function
/*/
Static Function PclPontObs(cData)

	Local aRet := Array(5)
	Local xRetorno
	Local nX := 0

	If FindFunction("U_TRETE015")

		xRetorno := U_TRETE015(cData,aTq)

		If ValType(xRetorno) == "C"

			For nX := 1 to 5
				If Len(xRetorno) > 37
					aRet[nX] := SubStr(xRetorno, 1, 37)
					xRetorno := SubStr(xRetorno, 38, Len(xRetorno))
				Else
					aRet[nX] := Padr(xRetorno, 37)
					xRetorno := ""
				EndIf
			Next nX
		Else
			For nX := 1  To 5
				aRet[nX] := Space(37)
			Next nX
		EndIf
	Else
		For nX := 1  To 5
			aRet[nX] := Space(37)
		Next nX
	EndIf

Return(aRet)

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

	U_uAjusSx1(cPerg,"01",OemToAnsi("Produto ?"),"","","mv_ch1","C",15,0,0,"G","","SB1","","","mv_par01","","","","","","","","","","","","","","","","",aHelpPor,{},{})
	U_uAjusSx1(cPerg,"02",OemToAnsi("Nro. Livro De ?"),"","","mv_ch2","C",06,0,0,"G","","UB4","","","mv_par02","","","","","","","","","","","","","","","","",aHelpPor,{},{})
	U_uAjusSx1(cPerg,"03",OemToAnsi("Nro. Livro Ate ?"),"","","mv_ch3","C",06,0,0,"G","","UB4","","","mv_par03","","","","ZZZZZZ","","","","","","","","","","","","",aHelpPor,{},{})
	U_uAjusSx1(cPerg,"04",OemToAnsi("Competencia De (MM/AAAA) ?"),"","","mv_ch4","C",06,0,0,"G","","","","","mv_par04","","","","","","","","","","","","","","","","",aHelpPor,{},{},"","@R 99/9999")
	U_uAjusSx1(cPerg,"05",OemToAnsi("Competencia Ate (MM/AAAA) ?"),"","","mv_ch5","C",06,0,0,"G","","","","","mv_par05","","","","999999","","","","","","","","","","","","",aHelpPor,{},{},"","@R 99/9999")

Return Pergunte(cPerg,.T.)

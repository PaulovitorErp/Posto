#include "protheus.ch"
#include "topconn.ch"

/*/{Protheus.doc} TRETE009
Rotina para geração de página do Livro de Movimentação de Combustivel
@author Totvs TBC
@since 01/11/2018
@version 1.0
@param dData, date, data
@param cProd, characters, codigo do produto
@param cNrLivro, characters, codigo do livro LMC
@type function
/*/

/*****************************************************/
User Function TRETE009(dData,cProd,cNrLivro,oModelMIE)
/*****************************************************/

Local nX := 0

Private nQTQLMC := SuperGetMv("MV_XQTQLMC",,20) //Quantidade de tanques para apuração LMC
Private nAbert    	:= 0
Private cEntTQ    	:= ""
Private cVenTQ    	:= ""

//criando variaveis private
For nX := 1 to nQTQLMC
	Private &("cEntTQ"+StrZero(nX,2)) := 0
	Private &("cVenTQ"+StrZero(nX,2)) := 0
next nX

Private _cNrLivro	:= cNrLivro

Private nEstMed		:= 0

Public __aEstFec	:= {}

GeraPag(dData,cProd,oModelMIE)

Return

//-----------------------------------------------
Static Function GeraPag(dData, cProd, oModelMIE)

Local aPag	:= {}

aPag := AcumDados(dData,cProd)

If Len(aPag) > 0
	IncluiMIE(aPag,oModelMIE)
Else
	Help( ,, 'Help - GeraLMC',, 'Dados não encontrados para o produto '+AllTrim(cProd)+', favor verificar o saldo inicial deste produto.', 1, 0 )
Endif

Return

/*************************************/
Static Function AcumDados(dData,cProd)
/*************************************/

Local aPag 		:= {}
Local aEstIni	:= {}
Local aEstFin	:= {}
Local cQry
Local nX		:= 0
Local cI		:= ""

Local cTanque	:= ""

Local oLMC := TLmcLib():New(cProd, dData)

oLMC:SetTRetVen(1) //1=Vlr Total Vendas; 2=Array Dados; 3=Qtd Registros

DbSelectArea("MIE")
MIE->(DbSetOrder(1)) //MIE_FILIAL+MIE_CODPRO+DTOS(MIE_DATA)+MIE_CODTAN+MIE_CODBIC

DbSelectArea("SF1")
SF1->(DbSetOrder(1)) //F1_FILIAL+F1_DOC+F1_SERIE+F1_FORNECE+F1_LOJA+F1_TIPO

DbSelectArea("SD1")
SD1->(DbSetOrder(6)) //D1_FILIAL+DTOS(D1_DTDIGIT)+D1_NUMSEQ

DbSelectArea("SF4")
SF4->(DbSetOrder(1)) //F4_FILIAL+F4_CODIGO

DbSelectArea("MHZ")
MHZ->(DbSetOrder(3)) //MHZ_FILIAL+MHZ_CODPRO+MHZ_LOCAL

nAbert 	:= 0
cVenTQ	:= ""
cEstTQ	:= ""

For nX:= 1 to nQTQLMC
	aadd(aEstIni, 0)
	aadd(aEstFin, 0)

	cI	:=	"cEntTQ" + StrZero(nX,2)
	&cI	:=	0

	cI	:=	"cVenTQ" + StrZero(nX,2)
	&cI	:=	0
Next nX

//Verifica se existe lançamento com data do dia anterior
If MIE->(DbSeek(xFilial("MIE")+cProd+DToS(dData-1)))

	For nX:= 1 to nQTQLMC
		aEstIni[nX] := MIE->&("MIE_VTAQ"+StrZero(nX,2))
	next nX

	//Grava aDados de acordo com o MIE em D-1
	aAdd(aPag,{dData,;				//1 - Data
				Space(3),;			//2 - Bico
				Space(3),;			//3 - Grp. tanque
				cProd,;				//4 - Produto
				MIE->MIE_ESTFEC,;	//5 - Estoque abertura
				0,;					//6 - Vendas do dia
				0,;					//7 - Estoque escritural
				0,;					//8 - Estoque fechamento
				0,;					//9 - Volume disponível
				0,;					//10 - Aferição
				0,;					//11 - Perdas
				0,;					//12 - Ganhos
				0,;					//13 - Encerrante inicial
				0,;					//14 - Encerrante final
				0,;					//15 - Entrada
				"",;				//16 - Tanque descarga
				0,;					//17 - Valor Acumulado no mês
				aEstIni,; 			//18 - Array Estoques inicial TQ
				Nil,; 				//19 - Array Estoques final TQ
				0,;					//20 - Vendas no dia R$
				0,;					//21 - Saldo Kardex
				.T.})				//22 - Flag achou

Else
	dbSelectArea("SB9")
	SB9->(dbSetOrder(1)) //B9_FILIAL+B9_COD+B9_LOCAL+DTOS(B9_DATA)

	If SB9->(dbSeek(xFilial("SB9")+cProd))

		While SB9->(!EOF()) .And. xFilial("SB9") + cProd == SB9->B9_FILIAL + SB9->B9_COD

			//Tanque relacionado
			If MHZ->(DbSeek(xFilial("MHZ")+SB9->B9_COD+SB9->B9_LOCAL))
				While MHZ->(!Eof()) .AND. MHZ->MHZ_FILIAL + MHZ->MHZ_CODPRO + MHZ->MHZ_LOCAL == xFilial("MHZ")+SB9->B9_COD+SB9->B9_LOCAL
					//If MHZ->MHZ_STATUS == "1" //Ativo
					If ((MHZ->MHZ_STATUS == '1' .AND. MHZ->MHZ_DTATIV <= dData) .OR. (MHZ->MHZ_STATUS == '2' .AND. MHZ->MHZ_DTDESA >= dData))
						cTanque := MHZ->MHZ_CODTAN

						//Estoque de Abertura Total
						nAbert  += SB9->B9_QINI

						//Estoque de Abertura por Tanque
						aEstIni[Val(cTanque)] := SB9->B9_QINI

						EXIT //sai laço MHZ
					Endif

					MHZ->(DbSkip())
				enddo
			Endif

			SB9->(dbSkip())
		EndDo

		aAdd(aPag,{dData,;		   		//1 - Data
					Space(3),;			//2 - Bico
					Space(3),;			//3 - Grp. tanque
					cProd,;				//4 - Produto
					nAbert,;			//5 - Estoque abertura
					0,;					//6 - Vendas do dia
					0,;					//7 - Estoque escritural
					0,;					//8 - Estoque fechamento
					0,;					//9 - Volume disponível
					0,;					//10 - Aferição
					0,;					//11 - Perdas
					0,;					//12 - Ganhos
					0,;					//13 - Encerrante inicial
					0,;					//14 - Encerrante final
					0,;					//15 - Entrada
					"",;				//16 - Tanque descarga
					0,;					//17 - Valor Acumulado no mês
					aEstIni,; 			//18 - Array Estoques inicial TQ
					Nil,; 				//19 - Array Estoques final TQ
					0,;					//20 - Vendas no dia R$
					0,;					//21 - Saldo Kardex
					.F.})				//22 - Flag achou
	Endif
EndIf

If Len(aPag) > 0

	//Notas de Entrada
	If SD1->(DbSeek(xFilial("SD1")+DToS(dData)))

		While SD1->(!EOF()) .And. SD1->D1_FILIAL+DToS(SD1->D1_DTDIGIT) == xFilial("SD1")+DToS(dData)

			If SD1->D1_TIPO $ "N/D" //Diferente de Complementos e Beneficiamento

				If SF1->(DbSeek(xFilial("SF1")+SD1->D1_DOC+SD1->D1_SERIE+SD1->D1_FORNECE+SD1->D1_LOJA))

					If SF1->F1_XLMC == "S" //Considera LMC

						If SF4->(DbSeek(xFilial("SF4")+SD1->D1_TES))

							If SF4->F4_ESTOQUE == "S" //Movimenta estoque

								If SD1->D1_COD == cProd
									aPag[Len(aPag)][15] += SD1->D1_QUANT //Entrada

									//Tanque relacionado
									If MHZ->(DbSeek(xFilial("MHZ")+SD1->D1_COD+SD1->D1_LOCAL))
										While MHZ->(!Eof()) .AND. MHZ->MHZ_FILIAL + MHZ->MHZ_CODPRO + MHZ->MHZ_LOCAL == xFilial("MHZ")+SD1->D1_COD+SD1->D1_LOCAL
											//If MHZ->MHZ_STATUS == "1" //Ativo
											If ((MHZ->MHZ_STATUS == '1' .AND. MHZ->MHZ_DTATIV <= dData) .OR. (MHZ->MHZ_STATUS == '2' .AND. MHZ->MHZ_DTDESA >= dData))
												cTanque := MHZ->MHZ_CODTAN

												//Entrada de Combustível por Tanque
												cEntTQ  := "cEntTQ" + cTanque
												&cEntTQ	+= SD1->D1_QUANT
												EXIT //sai laço MHZ
											Endif
											MHZ->(DbSkip())
										Enddo
									EndIf
								Endif
							Endif
						Endif
					Endif
				Endif
			Endif

			SD1->(DbSkip())
		EndDo
	EndIf

	//Vendas
	MHZ->(DbSetOrder(3)) //MHZ_FILIAL+MHZ_CODPRO+MHZ_LOCAL
	If MHZ->(DbSeek(xFilial("MHZ")+cProd))

    	While MHZ->(!EOF()) .And. xFilial("MHZ") == MHZ->MHZ_FILIAL .And. MHZ->MHZ_CODPRO == cProd
			If ((MHZ->MHZ_STATUS == '1' .AND. MHZ->MHZ_DTATIV <= dData) .OR. (MHZ->MHZ_STATUS == '2' .AND. MHZ->MHZ_DTDESA >= dData))
				oLMC:SetTanques({MHZ->MHZ_CODTAN})

				cVenTQ   := "cVenTQ" + MHZ->MHZ_CODTAN
				&cVenTQ  += oLMC:RetVen(.T.)

				//pego o saldo para kardex
				if GetSx3Cache('MIE_XKARDE',"X3_TIPO")=="N"
					aPag[Len(aPag)][21] += U_TRETE09B(cProd, dData, MHZ->MHZ_LOCAL)
				endif
			endif
    		MHZ->(DbSkip())
    	EndDo
	Endif

	//Aferição
    cQry := " SELECT SUM(MID_LITABA) TOTAFER"
    cQry += " FROM "+RetSqlName("MID")+""
    cQry += " WHERE D_E_L_E_T_ <> '*'"
    cQry += " AND MID_FILIAL	= '"+xFilial("MID")+"'"
    cQry += " AND MID_XPROD		= '"+cProd+"'"
    cQry += " AND MID_DATACO	= '"+DTOS(dData)+"'"
    cQry += " AND MID_AFERIR	= 'S'" //Aferição

	cQry := ChangeQuery(cQry)
	
	If Select("QRYAFER") > 0
		QRYAFER->(dbCloseArea())
	Endif

	//MemoWrite("c:\temp\RPOS011.txt",cQry)
	TcQuery cQry NEW Alias "QRYAFER"

	If QRYAFER->(!EOF())
		aPag[Len(aPag)][10] := QRYAFER->TOTAFER
	Endif

	QRYAFER->(dbCloseArea())
	
	//limpo tanques, para pesquisar todos
	oLMC:SetTanques({})

  	aPag[Len(aPag)][6]	:= oLMC:RetVen(.T.)
  	aPag[Len(aPag)][20]	:= aPag[Len(aPag)][6] * MedPrecoVend(dData, cProd) //U_URetPrec(cProd,,.F.)

	//Estoques: inicial e fechamento
	For nX := 1 To nQTQLMC

		cI := StrZero(nX,2)

		cVenTQ	:= "cVenTQ" + cI
		cEntTQ	:= "cEntTQ" + cI

		aEstFin[nX] := aEstIni[nX] - &cVenTQ + &cEntTQ
		
	Next nX

	//aPag[Len(aPag)][nX + 17] := IIf(aPag[Len(aPag)][59],aPag[Len(aPag)][nX + 17],aPag[Len(aPag)][nX + 17] + &cVenTQ - &cEntTQ)
	//aPag[Len(aPag)][nX + 17] := aPag[Len(aPag)][nX + 17]
	//aPag[Len(aPag)][nX + 37] := aPag[Len(aPag)][nX + 17] - &cVenTQ + &cEntTQ
	aPag[Len(aPag)][19] := aEstFin

Endif

Return aPag

/******************************************/
Static Function IncluiMIE(aDados,oModelMIE)
/******************************************/

Local nX			:= 0
Local cI			:= ""

Local cQry			:= ""

Local nAcum			:= 0

Local cPriDia		:= cValToChar(Year(aDados[Len(aDados)][1])) + StrZero(Month(aDados[Len(aDados)][1]),2) + "01"

Local lMed			:= .F.
Local lAuxMed		:= .F.

Local nSobras		:= 0
Local nPerdas		:= 0

Local lConsMed		:= SuperGetMv("MV_XCONSME",.F.,.F.)

//Local oModel		:= FWLoadModel("TRETA010")
//Local oModelMIE

Public __aDados		:= aDados //Guarda os dados originais para serem apresentados em Detalhar Rec./Vend. >> Est. Fechamento X Medições

//oModelMIE:LoadValue('MIE_FILIAL',xFilial("MIE"))
oModelMIE:LoadValue('MIE_DATA',aDados[Len(aDados)][1])
oModelMIE:LoadValue('MIE_CODPRO',aDados[1][4])
oModelMIE:LoadValue('MIE_XDESCR',SubStr(Posicione("SB1",1,xFilial("SB1")+aDados[Len(aDados)][4],"B1_DESC"),1,TamSx3("MIE_XDESCR")[1]))

//Estoque de Abertura Total
//oModelMIE:LoadValue('MIE_ABERT',IIf(aDados[Len(aDados)][59],aDados[Len(aDados)][5],aDados[Len(aDados)][5] + aDados[Len(aDados)][6] - aDados[Len(aDados)][15]))
oModelMIE:LoadValue('MIE_ABERT',aDados[Len(aDados)][5])

//Afericao
oModelMIE:LoadValue('MIE_AFERIC',aDados[Len(aDados)][10])

//Vendas
oModelMIE:LoadValue('MIE_VENDAS',aDados[Len(aDados)][6])
oModelMIE:LoadValue('MIE_VLRITE',aDados[Len(aDados)][20])

//Notas Fiscais
oModelMIE:LoadValue('MIE_ENTRAD',aDados[Len(aDados)][15])

//Estoque Escritural e Fechamento
oModelMIE:LoadValue('MIE_ESTESC',oModelMIE:GetValue("MIE_ABERT") + (oModelMIE:GetValue("MIE_ENTRAD") - oModelMIE:GetValue("MIE_VENDAS")))
oModelMIE:LoadValue('MIE_ESTFEC',oModelMIE:GetValue("MIE_ABERT") + (oModelMIE:GetValue("MIE_ENTRAD") - oModelMIE:GetValue("MIE_VENDAS")))

//Volume Disponivel
oModelMIE:LoadValue('MIE_VOLDIS',oModelMIE:GetValue("MIE_ABERT") + oModelMIE:GetValue("MIE_ENTRAD"))

//Acumulador Mensal
If Select("QRYACUM") > 0
	QRYACUM->(dbCloseArea())
Endif

cQry := "SELECT SUM(MIE_VLRITE) AS VLR"
cQry += " FROM "+RetSqlName("MIE")+""
cQry += " WHERE D_E_L_E_T_ 	<> '*'"
cQry += " AND MIE_FILIAL	= '"+xFilial("MIE")+"'"
cQry += " AND MIE_CODPRO	= '"+aDados[Len(aDados)][4]+"'"
cQry += " AND MIE_DATA		BETWEEN '"+cPriDia+"'  AND '"+DToS(aDados[Len(aDados)][1] - 1)+"'

cQry := ChangeQuery(cQry)
//MemoWrite("c:\temp\RPOS011.txt",cQry)
TcQuery cQry NEW Alias "QRYACUM"

If QRYACUM->(!EOF())
	nAcum := QRYACUM->VLR
Endif

If Select("QRYACUM") > 0
	QRYACUM->(dbCloseArea())
Endif

oModelMIE:LoadValue('MIE_ACUMUL',IIf(Day(aDados[Len(aDados)][1]) == 1,oModelMIE:GetValue("MIE_VLRITE"),nAcum + oModelMIE:GetValue("MIE_VLRITE")))

//oModelMIE:LoadValue('MIE_NOTA',"XXXXXXXXX")
//oModelMIE:LoadValue('MIE_NOTA02',"XXXXXXXXX")
//oModelMIE:LoadValue('MIE_NOTA03',"XXXXXXXXX")
//oModelMIE:LoadValue('MIE_NOTA04',"XXXXXXXXX")
//oModelMIE:LoadValue('MIE_NOTA05',"XXXXXXXXX")

//Estoques: inicial e fechamento
For nX := 1 To nQTQLMC

	cI := StrZero(nX,2)

	if MIE->(FieldPos( 'MIE_ESTI'+cI ))>0
		oModelMIE:LoadValue("MIE_ESTI" + cI, aDados[Len(aDados)][18][nX] )
	endif

	//Verifica se há medição realizada
	nEstMed := 0
	if MIE->(FieldPos( 'MIE_VTAQ'+cI ))>0

		If lConsMed

			lMed := VerifMed(StrZero(nX,2),aDados[Len(aDados)][1],aDados[Len(aDados)][4])

			If lMed

				//If nEstMed >= aDados[Len(aDados)][nX + 37]
				If nEstMed >= aDados[Len(aDados)][19][nX]
					nSobras += nEstMed - aDados[Len(aDados)][19][nX]
				Else
					nPerdas += aDados[Len(aDados)][19][nX] - nEstMed
				Endif

				oModelMIE:LoadValue("MIE_VTAQ" + cI,nEstMed)

				lAuxMed	:=  .T.
			Else
				oModelMIE:LoadValue("MIE_VTAQ" + cI,aDados[Len(aDados)][19][nX])
			Endif
		Else
			oModelMIE:LoadValue("MIE_VTAQ" + cI,aDados[Len(aDados)][19][nX])
		Endif

		aAdd(__aEstFec,{oModelMIE:GetValue('MIE_VTAQ' + cI),aDados[Len(aDados)][19][nX],nEstMed})
	
	endif

Next nX

If lAuxMed

	//Help( ,, 'Help - GeraLMC',, 'Foram consideradas medições para cálculo do Estoque de Fechamento e Estoque Escritural.', 1, 0 )
	MsgInfo('Foram consideradas medições para cálculo do Estoque de Fechamento e Estoque Escritural.',"Apuração LMC")

	oModelMIE:LoadValue('MIE_ESTFEC',oModelMIE:GetValue("MIE_ESTFEC") + nSobras - nPerdas)

	If nSobras > nPerdas
		oModelMIE:LoadValue('MIE_GANHOS',nSobras - nPerdas)
	Else
		oModelMIE:LoadValue('MIE_PERDA',nPerdas - nSobras)
	Endif

	If MIE->(FieldPos("MIE_XPERGP")) > 0
		oModelMIE:SetValue('MIE_XPERGP',Abs(((oModelMIE:GetValue("MIE_ESTFEC") - oModelMIE:GetValue("MIE_ESTESC")) / oModelMIE:GetValue("MIE_ESTESC")) * 100))
	Endif
Endif

oModelMIE:LoadValue('MIE_NRLIVR',_cNrLivro)
oModelMIE:LoadValue('MIE_NROPAG', StrZero(Val(SubStr(DTOS(aDados[Len(aDados)][1]),7,2)) + 1,3) )

if GetSx3Cache('MIE_XKARDE',"X3_TIPO")=="N"
	oModelMIE:LoadValue('MIE_XKARDE', aDados[Len(aDados)][21] )
endif

Return

/********************************************/
Static Function VerifMed(cEstLMC,dData,cProd)
/********************************************/

Local lRet		:= .F.
Local cQry		:= ""
Local cTq 		:= ""

DbSelectArea("MHZ")
MHZ->(DbSetOrder(3)) //MHZ_FILIAL+MHZ_CODPRO+MHZ_LOCAL

If MHZ->(DbSeek(xFilial("MHZ")+cProd))

	While MHZ->(!EOF()) .And. MHZ->MHZ_FILIAL == xFilial("MHZ") .And. MHZ->MHZ_CODPRO == cProd
		If ((MHZ->MHZ_STATUS == '1' .AND. MHZ->MHZ_DTATIV <= dData) .OR. (MHZ->MHZ_STATUS == '2' .AND. MHZ->MHZ_DTDESA >= dData))
			If MHZ->MHZ_CODTAN == cEstLMC
				cTq := MHZ->MHZ_CODTAN
				Exit
			Endif
		Endif
		MHZ->(DbSkip())
	EndDo
Endif

If !Empty(cTq)

	If Select("QRYMED") > 0
		QRYMED->(DbCloseArea())
	Endif

	cQry := "SELECT TQK_TANQUE, SUM(TQK_QTDEST) AS ESTMED"
	cQry += " FROM "+RetSqlName("TQK")+""
	cQry += " WHERE D_E_L_E_T_ = ' '"
	cQry += " AND TQK_FILIAL	= '"+xFilial("TQK")+"'"
	cQry += " AND TQK_DTMEDI	= '"+DToS(dData)+"'"
	cQry += " AND TQK_TANQUE	= '"+cTq+"'"
	cQry += " AND TQK_PRODUT	= '"+cProd+"'"
	cQry += " AND TQK_TANQUE + TQK_TQFISC + TQK_HRMEDI IN ("
	cQry += " 		SELECT TQK_TANQUE + TQK_TQFISC + MAX(TQK_HRMEDI)"
	cQry += " 		FROM "+RetSqlName("TQK")+""
	cQry += " 		WHERE D_E_L_E_T_	= ' '"
	cQry += " 		AND TQK_FILIAL		= '"+xFilial("TQK")+"'"
	cQry += " 		AND TQK_DTMEDI		= '"+DToS(dData)+"'"
	cQry += " 		AND TQK_TANQUE		= '"+cTq+"'"
	cQry += " 		AND TQK_PRODUT		= '"+cProd+"'"
	cQry += " 		GROUP BY TQK_TANQUE, TQK_TQFISC "
	cQry += " )"
	cQry += " GROUP BY TQK_TANQUE"

	cQry := ChangeQuery(cQry)
	TcQuery cQry NEW Alias "QRYMED"

	While QRYMED->(!EOF())
		lRet 	:= .T.
		nEstMed += QRYMED->ESTMED

		QRYMED->(DbSkip())
	EndDo

	If Select("QRYMED") > 0
		QRYMED->(DbCloseArea())
	Endif
Endif

Return lRet

//Calcula o saldo do(s) tanque(s) pelo Kardex
User Function TRETE09A()
	
	Local nKardex := 0
	
	MHZ->(DbSetOrder(3)) //MHZ_FILIAL+MHZ_CODPRO+MHZ_LOCAL
	If MHZ->(DbSeek(xFilial("MHZ")+MIE->MIE_CODPRO ))
		While MHZ->(!EOF()) .And. xFilial("MHZ") == MHZ->MHZ_FILIAL .And. MHZ->MHZ_CODPRO == MIE->MIE_CODPRO
			If ((MHZ->MHZ_STATUS == '1' .AND. MHZ->MHZ_DTATIV <= MIE->MIE_DATA) .OR. (MHZ->MHZ_STATUS == '2' .AND. MHZ->MHZ_DTDESA >= MIE->MIE_DATA))
				//pego o saldo para kardex
				nKardex += U_TRETE09B(MIE->MIE_CODPRO, MIE->MIE_DATA, MHZ->MHZ_LOCAL)
			Endif
			MHZ->(DbSkip())
		EndDo
	Endif

Return nKardex

//Calcula o saldo do tanque pelo Kardex
User Function TRETE09B(cProduto, dData, cLocal)

	Local aSaldo
	Local nSaldo := 0

	dData := dData + 1

	aSaldo := CalcEst(cProduto, cLocal, dData )
	nSaldo := aSaldo[1]

Return nSaldo


Static Function MedPrecoVend(dData, cProd, cFilPes)

    Local nPrcVen := U_URetPrec(cProd,,.F.)

    Default cFilPes := xFilial("MID")

    //média preço de venda
    If Select("QRYAVG") > 0
        QRYAVG->(dbCloseArea())
    Endif

    //cQry := "SELECT AVG(ISNULL(MID_PREPLI, 0)) AS VLR"
    cQry := "SELECT (SUM(MID_LITABA * MID_PREPLI) / SUM(MID_LITABA)) AS VLR" //média ponderada
    cQry += CRLF + " FROM "+RetSqlName("MID")+""
    cQry += CRLF + " WHERE D_E_L_E_T_ = ' '"
    cQry += CRLF + " AND MID_FILIAL	= '"+cFilPes+"'"
    cQry += CRLF + " AND MID_XPROD	= '"+cProd+"'"
    cQry += CRLF + " AND MID_DATACO	= '"+DTOS(dData)+"'"
    cQry += CRLF + "GROUP BY MID_FILIAL, MID_XPROD, MID_DATACO"

    cQry := ChangeQuery(cQry)
    TcQuery cQry NEW Alias "QRYAVG"

    If QRYAVG->(!EOF())
        nPrcVen := Round(QRYAVG->VLR,TamSX3("MID_PREPLI")[2])
    Endif

    If Select("QRYAVG") > 0
        QRYAVG->(dbCloseArea())
    Endif

Return nPrcVen

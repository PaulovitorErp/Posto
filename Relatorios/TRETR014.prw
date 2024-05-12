#include "protheus.ch"
#include "topconn.ch"

/*/{Protheus.doc} TRETR014
Relatório de Relação de Títulos - Faturamento Manual
@author Henrique Botelho Gomes
@since 16/04/2015
@version P11
@param aReg -> vetor contendo todos os valores contidos na GRID de Títulos em Fatura Manual
@return nulo
/*/

/***************************/
User Function TRETR014(aReg)
/***************************/

Local oReport 
Private _aReg := aReg

oReport := ReportDef()
oReport:PrintDialog()

Return

/**************************/
Static Function ReportDef()
/**************************/

Local oReport

Local oSection1

Local cTitle    := "Relação de Títulos - Faturamento Manual"

oReport:= TReport():New("Faturamento Manual",cTitle,"Faturamento Manual",{|oReport| PrintReport(oReport)},"FATURAMENTO MANUAL.")
oReport:SetLandscape()	//Define a orientação do relatório como paisagem(Lanscape) 
oReport:HideParamPage()

oSection1 := TRSection():New(oReport,"FatManual",{"aReg"})
oSection1:SetHeaderPage(.F.)
oSection1:SetHeaderSection(.T.)

TRCell():New(oSection1,"col1",,	"FILIAL"	,,)
if len(cFilAnt) <> len(AlltriM(xFilial("SE1")))
	TRCell():New(oSection1,"col2",,	"FIL.ORIGEM",,)
endif
TRCell():New(oSection1,"col3",, "TIPO"		,,)
TRCell():New(oSection1,"col4",, "ORIGEM FAT",,)
TRCell():New(oSection1,"col5",, "DESCRIÇÃO"	,,20)
TRCell():New(oSection1,"col6",, "PREFIXO"	,,)
TRCell():New(oSection1,"col7",,	"NUMERO"	,,9)
TRCell():New(oSection1,"col8",,	"PARCELA"	,,)
TRCell():New(oSection1,"col9",,	"NATUREZA"	,,)
TRCell():New(oSection1,"col10",,"PORTADOR"	,,)
TRCell():New(oSection1,"col11",,"DEPOSITARIA",,)
TRCell():New(oSection1,"col12",,"Nº CONTA"	,,)
TRCell():New(oSection1,"col13",,"NOME BANCO",,)
TRCell():New(oSection1,"col14",,"PLACA"		,,8)
TRCell():New(oSection1,"col15",,"CLIENTE"	,,)
TRCell():New(oSection1,"col16",,"LOJA"		,,)
TRCell():New(oSection1,"col17",,"NOME"		,,20)	//ultimo paramentro define o tamanho do campo
TRCell():New(oSection1,"col18",,"CLASSE"	,,15)
TRCell():New(oSection1,"col19",,"COND. PAGTO.",,)
TRCell():New(oSection1,"col20",,"DT. EMISSÃO",,)  
TRCell():New(oSection1,"col21",,"DT. VENCTO",,)
TRCell():New(oSection1,"col22",,"EMAIL ENV.?",,)
TRCell():New(oSection1,"col23",,"VALOR"		,,8)
TRCell():New(oSection1,"col24",,"SALDO"		,,8)

oSection2 := TRSection():New(oReport,"FatManual",{"aReg"})
oSection3 := TRSection():New(oReport,"FatManual",{"aReg"})

oSection1:SetPageBreak(.T.)

Return(oReport)                                                               

/***********************************/
Static Function PrintReport(oReport)
/***********************************/

Local SumValor := 0
Local nI, nJ
Local oSection1	:= oReport:Section(1)
Local oSection2 := oReport:Section(2)
Local oSection3 := oReport:Section(3)

Local nCont		:= Len(_aReg)

oSection1:Init()
oReport:SetMeter(nCont)

for nI := 1 to Len(_aReg)	
	
	oReport:IncMeter()

	If oReport:Cancel()
		Exit
	Endif   
	 
	nJ := 3
	oSection1:Cell("col1"):SetValue(_aReg[nI][U_TRE017CP(5, "nPosFilial")])
	nJ++
	if len(cFilAnt) <> len(AlltriM(xFilial("SE1")))
		oSection1:Cell("col2"):SetValue(_aReg[nI][U_TRE017CP(5, "nPosFilOri")])
		nJ++
	endif
	oSection1:Cell("col3"):SetValue(_aReg[nI][U_TRE017CP(5, "nPosTipo")])
	nJ++
	oSection1:Cell("col4"):SetValue(_aReg[nI][U_TRE017CP(5, "nPosOriFat")])
	nJ++
	oSection1:Cell("col5"):SetValue(_aReg[nI][U_TRE017CP(5, "nPosDescri")])
	nJ++
	oSection1:Cell("col6"):SetValue(_aReg[1][U_TRE017CP(5, "nPosPrefixo")])
	nJ++
	oSection1:Cell("col7"):SetValue(_aReg[nI][U_TRE017CP(5, "nPosNumero")])
	nJ++
	oSection1:Cell("col8"):SetValue(_aReg[nI][U_TRE017CP(5, "nPosParcela")])
	nJ++
	oSection1:Cell("col9"):SetValue(_aReg[nI][U_TRE017CP(5, "nPosNaturez")])
	nJ++
	oSection1:Cell("col10"):SetValue(_aReg[nI][U_TRE017CP(5, "nPosPortado")])
	nJ++
	oSection1:Cell("col11"):SetValue(_aReg[nI][U_TRE017CP(5, "nPosDeposit")])
	nJ++
	oSection1:Cell("col12"):SetValue(_aReg[nI][U_TRE017CP(5, "nPosNConta")])
	nJ++
	oSection1:Cell("col13"):SetValue(_aReg[nI][U_TRE017CP(5, "nPosBanco")])
	nJ++
	oSection1:Cell("col14"):SetValue(_aReg[nI][U_TRE017CP(5, "nPosPlaca")])
	nJ++                
	oSection1:Cell("col15"):SetValue(_aReg[nI][U_TRE017CP(5, "nPosCliente")])
	nJ++
	oSection1:Cell("col16"):SetValue(_aReg[nI][U_TRE017CP(5, "nPosLoja")])
	nJ++
	oSection1:Cell("col17"):SetValue(_aReg[nI][U_TRE017CP(5, "nPosNome")])
	nJ++
	oSection1:Cell("col18"):SetValue(_aReg[nI][U_TRE017CP(5, "nPosClasse")])
	nJ++
	oSection1:Cell("col19"):SetValue(_aReg[nI][U_TRE017CP(5, "nPosCondPg")])
	nJ++
	oSection1:Cell("col20"):SetValue(_aReg[nI][U_TRE017CP(5, "nPosEmissao")])
	nJ++
	oSection1:Cell("col21"):SetValue(_aReg[nI][U_TRE017CP(5, "nPosVencto")])
	nJ++
	oSection1:Cell("col22"):SetValue(_aReg[nI][U_TRE017CP(5, "nPosMailFat")])
	nJ++
	oSection1:Cell("col23"):SetValue(AllTrim(_aReg[nI][U_TRE017CP(5, "nPosValor")]))
	SumValor += Val(StrTran(StrTran(AllTrim(_aReg[nI][U_TRE017CP(5, "nPosValor")]),".",""),",","." )) //Somatório do Valor Total 
	nJ++
	oSection1:Cell("col24"):SetValue(AllTrim(_aReg[nI][U_TRE017CP(5, "nPosSaldo")]))
	nJ++

	oSection1:PrintLine()
	oReport:IncMeter()
Next

oSection1:Finish()
oReport:ThinLine() //imprime uma linha

oSection2:Init()
TRCell():New(oSection2,"col25",, "Total de Registros:",,)
TRCell():New(oSection2,"col26",, cValToChar(nI-1) ,,)
oSection2:PrintLine()
oSection2:Finish()

oSection3:Init()
TRCell():New(oSection3,"col27",, "Valor Total:",,)
TRCell():New(oSection3,"col28",, Transform(SumValor,"@E 9,999,999,999,999.99") ,,)
oSection3:Printline()
oSection3:Finish()


Return

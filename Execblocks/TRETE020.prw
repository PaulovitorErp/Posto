#include "rwmake.ch"
#include "colors.ch"
#include "font.ch"
#include "topconn.ch"
#include "protheus.ch"
#include "fileio.ch"
#include "rptdef.ch"
#include "fwprintsetup.ch"
#Include "Shell.ch"

#define DMPAPER_A4 9 // A4 210 x 297 mm

Static lFatConv 	:= SuperGetMv("MV_XFTCONV",,.F.) //define se abrira modo faturamento conveniencia

/*/{Protheus.doc} TRETE020 (ImpFatur)
Impressão de Fatura
@author Maiki Perin
@since 28/03/2019
@version P12
@param Filial, Fatura, Arq. PDF, Impressão física, Fat. automático, Dados arq. PDF
@return nulo
/*/

/*******************************************************************/
User Function TRETE020(oSay,_cFil,aFat,lArqPdf,lImp,lFatAut,aArqPDF,cObs)
/*******************************************************************/

Local nI				:= 0
Local aArea 			:= GetArea()
Local aAreaSM0 			:= SM0->(GetArea())
Local lRet				:= .T.
Local nCont
Local cDirFat			:= SuperGetMv("MV_XTMPFAT",.F.,"faturamento_automatico\faturas\")
Local cDirDes  			:= SuperGetMv("MV_XDIRFAT",.F.,"arquivos_mo\faturas\") //destino dos arquivos (arquivos_mo\faturas\)
Local cDirSystem		:= SuperGetMv("MV_XDIRSYS",.F.,"C:\TOTVS\Protheus11\Data\Protheus_Data_Ofc\system\")

Local cDirSrv			:= ""

Local aImp				:= {}
Local _cImp				:= ""

Local cNomeCli			:= ""
Local cNomeArq			:= ""
Local cMask := "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-_"
Local aFatAux			:= {}

Private oFont6			:= TFont():New("Arial",,6,.T.,.F.,5,.T.,5,.T.,.F.) 			//Fonte 6 Normal
Private oFont6N 		:= TFont():New("Arial",,6,,.T.,,,,.T.,.F.) 					//Fonte 6 Negrito
Private oFont8			:= TFont():New('Arial',,8,,.F.,,,,.F.,.F.) 					//Fonte 8 Normal
Private oFont8N			:= TFont():New('Arial',,8,,.T.,,,,.F.,.F.) 				 	//Fonte 8 Negrito
Private oFont8NI		:= TFont():New('Times New Roman',,8,,.T.,,,,.F.,.F.,.T.) 	//Fonte 8 Negrito e Itálico
Private oFont10			:= TFont():New('Arial',,10,,.F.,,,,.F.,.F.) 				//Fonte 10 Normal
Private oFont10N		:= TFont():New('Arial',,10,,.T.,,,,.F.,.F.) 				//Fonte 10 Negrito
Private oFont12			:= TFont():New('Arial',,12,,.F.,,,,.F.,.F.) 				//Fonte 12 Normal
Private oFont12N		:= TFont():New('Arial',,12,,.T.,,,,.F.,.F.) 			 	//Fonte 12 Negrito
Private oFont12NS		:= TFont():New('Arial',,12,,.T.,,,,.T.,.F.) 			 	//Fonte 12 Negrito e Sublinhado
Private oFont14			:= TFont():New('Arial',,14,,.F.,,,,.F.,.F.) 				//Fonte 14 Normal
Private oFont13N		:= TFont():New('Arial',,13,,.T.,,,,.F.,.F.) 				//Fonte 13 Negrito
Private oFont14N		:= TFont():New('Arial',,14,,.T.,,,,.F.,.F.) 				//Fonte 14 Negrito
Private oFont14NI		:= TFont():New('Times New Roman',,14,,.T.,,,,.F.,.F.,.T.) 	//Fonte 14 Negrito e Itálico
Private oFont16N		:= TFont():New('Arial',,16,,.T.,,,,.F.,.F.) 				//Fonte 16 Negrito
Private oFont16NI		:= TFont():New('Times New Roman',,16,,.T.,,,,.F.,.F.,.T.) 	//Fonte 16 Negrito e Itálico
Private oFont18			:= TFont():New("Arial",,18,,.F.,,,,,.F.,.F.)				//Fonte 18 Negrito
Private oFont18N		:= TFont():New("Arial",,18,,.T.,,,,,.F.,.F.)				//Fonte 18 Negrito

Private oBrush			:= TBrush():New(,CLR_HGRAY)

Private cStartPath
Private nLin 			:= 80
Private oRel
Private nPag			:= 1

Private	nTotQtd 		:= 0
Private	nTotVlr			:= 0

Private cFilFat			:= _cFil
Private cFatCorr		:= ""

Private cFil			:= ""
Private cFatSol			:= ""
Private cSubAgrup		:= ""
Private cClasse			:= ""
Private nVlrAcres		:= 0
Private nVlrDecres		:= 0
Private lDuplSD2 		:= .F.
Private lDanfe			:= .F.

Private cTmpUser		:= IIF(!IsBlind(),GetTempPath(),"")
Private lFatParc		:= .F.
Private nQtdParc		:= 0

Default lArqPdf			:= .F.
Default lImp			:= .F.
Default lFatAut			:= .F.
Default cObs			:= ""

_lArqPdf				:= lArqPdf
_lImp					:= lImp
_lFatAut				:= lFatAut

if len(aFat) > 1 
	//ordeno o array de faturas por cliente + numero + parcela
    ASort(aFat,,,{|x,y| x[2] + x[3] + x[1] + x[5] < y[2] + y[3] + y[1] + y[5] })
	
	cFatCorr := ""
	for nI := 1 to len(aFat)
		
		if aFat[nI][1] <> cFatCorr
			aadd(aFatAux, {})
		endif

		cFatCorr := aFat[nI][1]
		aadd(aFatAux[len(aFatAux)], aFat[nI] )
	next nX
else
	aFatAux := {aFat}
endif

cStartPath := GetPvProfString(GetEnvServer(),"StartPath","ERROR",GetAdv97())
cStartPath += If(Right(cStartPath, 1) <> "\", "\", "")

If !IsBlind()

	cDirSrv := cStartPath + cDirDes

Else //IsBlind() -> JOB

	cDirSrv := cDirSystem + cDirDes

Endif

//Excluir arquivos .rel e ._pd
//ExcRelPd(aFat[1][1],cDirSrv,cDirFat,cDirFatRel)

If !IsBlind() .And. !_lArqPdf .And. !_lImp //Visualiza em Tela

	oRel := TmsPrinter():New("")
	oRel:SetPortrait()
	oRel:SetPaperSize(9) //A4

Else //PDF ou Impressão na Porta ou Faturamento Automático

	//FWMsPrinter(): New ( < cFilePrintert >, [ nDevice], [ lAdjustToLegacy], [ cPathInServer], [ lDisabeSetup ], [ lTReport], [ @oPrintSetup],
	//[ cPrinter], [ lServer], [ lPDFAsPNG], [ lRaw], [ lViewPDF], [ nQtdCopy] ) --> oPrinter

	If !_lArqPdf

		If !_lFatAut //Impressão na porta

			oRel := TmsPrinter():New("")
			oRel:SetPortrait()
			oRel:SetPaperSize(9) //A4

		Else  //Faturamento automático

			cNomeCli 	:= Posicione("SA1",1,xFilial("SA1")+aFat[1][2]+aFat[1][3],"A1_NOME")
			cNomeArq	:= _cFil + "_" + aFat[1][1] + "_" + aFat[1][2] + aFat[1][3] + "_" + Upper(AllTrim(cNomeCli)) + "_" + SubStr(DToS(dDataBase),7,2) +;
							SubStr(DToS(dDataBase),5,2) + SubStr(DToS(dDataBase),1,4)

			//Exclui arquivo caso exista
			If FErase(cTmpUser + cNomeArq + ".pdf") == 0
				Conout(" >> Excluido arquivo <"+ cTmpUser + cNomeArq + ".pdf" +">")
			Endif

			If FErase("system\" + cDirDes + cNomeArq + ".pdf") == 0
				Conout(" >> Excluido arquivo <"+ "system\" + cDirDes + cNomeArq + ".pdf" +">")
			Endif

			oRel := FWMsPrinter():New(cNomeArq,,.T.,,.T.,.T.,,,.T.,.F.,,,)

			oRel:SetResolution(76)
		 	oRel:SetPortrait()
		 	oRel:SetPaperSize(9) //A4
		 	oRel:SetMargin(0,0,0,0)

			aImp := GetImpWindows(.F.) //Busca a relacao de impressoras do client, onde a primeira da lista e a padrao
			_cImp := aImp[1]

		 	oRel:cPrinter := _cImp
		 	oRel:SetDevice(IMP_SPOOL)

		 	_lArqPdf := .T.
		 Endif
 	Else

		cNomeCli 	:= Posicione("SA1",1,xFilial("SA1")+aFat[1][2]+aFat[1][3],"A1_NREDUZ")
		cNomeArq	:= "FATURA_" + Alltrim(xFilial("SE1",_cFil)) + "_" + Alltrim(aFat[1][1]) + "_" + Alltrim(aFat[1][2]) + Alltrim(aFat[1][3]) + "_" + Upper(AllTrim(cNomeCli)) + "_" +;
						SubStr(DToS(dDataBase),7,2) + SubStr(DToS(dDataBase),5,2) + SubStr(DToS(dDataBase),1,4)
		
		//trato nome arquivo 
		cNomeArq := StrTran(cNomeArq," ","_")
		cNomeArq := U_MYNOCHAR(cNomeArq, cMask)

		//Exclui arquivo caso exista
		If FErase(cTmpUser + cNomeArq + ".pdf") == 0
			Conout(" >> Excluido arquivo <"+ cTmpUser + cNomeArq + ".pdf" +">")
		Endif

		If FErase("system\" + cDirDes + cNomeArq + ".pdf") == 0
			Conout(" >> Excluido arquivo <"+ "system\" + cDirDes + cNomeArq + ".pdf" +">")
		Endif

		oRel := FWMsPrinter():New(cNomeArq,,.T.,"\system\"+cDirFat,.T.,.T.,,,.T.,.F.,,,)

		//Anexo a ser enviado por e-mail
		If Type("aArqPDF") <> "U"
			Conout("Anexo fatura: " + "\system\" + cDirDes + cNomeArq)
			AAdd(aArqPDF,"\system\" + cDirDes + cNomeArq)
		Endif

		If Type("__aArqPDF") <> "U"
			Conout("Anexo fatura: " + "\system\" + cDirDes + cNomeArq)
			AAdd(__aArqPDF,"\system\" + cDirDes + cNomeArq)
		Endif

		oRel:SetResolution(76)
	 	oRel:SetPortrait()
	 	oRel:SetPaperSize(9) //A4
	 	oRel:SetMargin(0,0,0,0)

	 	If IsBlind()
		 	U_TRETE20A("\system\"+cDirFat)
	 		oRel:cPathPDF	:= "\system\"+cDirFat
			oRel:lInJob		:= .T. //Determina se o relatório está sendo executado via Job.
	 	Else
	 		oRel:cPathPDF	:= cTmpUser
		 	oRel:cPrinter	:= "PDF"
	 	Endif

	 	oRel:SetViewPDF(.F.)
	 	oRel:SetDevice(IMP_PDF)
 	Endif
Endif

For nI := 1 to len(aFatAux)

	if Len(aFatAux[nI]) == 1

		cFatCorr 	:= aFatAux[nI][1][1]
		lDanfe		:= RetDanfe(aFatAux[nI][1])

		Cabec(aFatAux[nI][1])
		Itens(aFatAux[nI][1])
		CompItens(aFatAux[nI][1])
		DadosFil(aFatAux[nI][1], cObs)
		Resumo(aFatAux[nI][1])
		Rod()

	else

		lFatParc := .T.
		nQtdParc := len(aFatAux[nI])

		for nCont := 1 to nQtdParc

			If !IsBlind() .And. oSay <> Nil
				oSay:cCaption := "Imprimindo parcela "+cValToChar(nCont)+" de "+cValToChar(nQtdParc)+""
				ProcessMessages()
			Endif
			
			cFatCorr 	:= aFatAux[nI][nCont][1]
			lDanfe		:= RetDanfe(aFatAux[nI][nCont])

			Cabec(aFatAux[nI][nCont])
			Itens(aFatAux[nI][nCont])
			CompItens(aFatAux[nI][nCont])
			DadosFil(aFatAux[nI][nCont], cObs)
			Resumo(aFatAux[nI][nCont])
			Rod()

		next nCont
	endif

Next nI

If _lFatAut  //Compatibiliza a variável
	_lArqPdf := lArqPdf
Endif

If IsBlind() .Or. _lArqPdf .Or. _lImp .Or. _lFatAut //Via Job ou PDF ou Impressão na porta ou Faturamento Automático

	oRel:Print()

	If !IsBlind() .And. _lArqPdf

		If CpyT2S(cTmpUser + cNomeArq + ".pdf",cDirSrv,.T.)
			Conout(" >> Copiado arquivo <"+cTmpUser + _cFil + aFat[1][1] + ".pdf"+"> para o Servidor: "+cDirSrv)
		Endif

		If FErase(cTmpUser + cNomeArq + ".pdf") == 0
			Conout(" >> Excluido arquivo <"+cTmpUser + _cFil + aFat[1][1] + ".pdf"+">")
		Endif
	Endif

Else
	oRel:Preview()
Endif

RestArea(aAreaSM0)
RestArea(aArea)

Return lRet

/***************************/
Static Function Cabec(_aFat)
/***************************/

Local cQry 			:= ""

Local cNome 		:= ""
Local cEnd 			:= ""
Local cComp 		:= ""
Local cBairro		:= ""
Local cMun 			:= ""
Local cCep 			:= ""
Local cEst 			:= ""
Local cInscr 		:= ""
Local cCgc			:= ""
Local cTel			:= ""
Local cCli			:= ""
Local cLoja			:= ""
Local cEmis			:= ""
Local cVencto		:= ""

Local aFil			:= {}
Local nI

If !_lArqPdf .Or. _lFatAut
	nLin := 80
Else
	nLin := 20
Endif

If Select("QRYCABEC") > 0
	QRYCABEC->(DbCloseArea())
Endif

cQry := "SELECT SA1.A1_NOME, ISNULL(U88.U88_END,'') AS U88_END, U88.U88_COMPLE, U88.U88_BAIRRO, U88.U88_MUN, U88.U88_CEP, U88.U88_EST, U88.U88_INSCR, U88.U88_CGC,"
cQry += CRLF + " U88.U88_TEL, U88.U88_FATCOR, SA1.A1_END, SA1.A1_COMPLEM, SA1.A1_BAIRRO, SA1.A1_MUN, SA1.A1_CEP, SA1.A1_EST, SA1.A1_INSCR, SA1.A1_CGC, SA1.A1_PESSOA,"
cQry += CRLF + " SA1.A1_TEL, SE1.E1_CLIENTE, SE1.E1_LOJA, SE1.E1_FILIAL, SE1.E1_EMISSAO, SE1.E1_VENCTO, SE1.E1_VENCREA, SA1.A1_XQFAT, 

If !lFatConv // Diferente de conveniência
	cQry += CRLF + " UF6.UF6_DESC,"
EndIf
cQry += CRLF + " SE1.E1_ACRESC, SE1.E1_DECRESC"

cQry += CRLF + " FROM "+RetSqlName("SE1")+" SE1 	INNER JOIN "+RetSqlName("SA1")+" SA1 ON SE1.E1_CLIENTE 		= SA1.A1_COD"
cQry += CRLF + " 																			AND SE1.E1_LOJA		= SA1.A1_LOJA"
cQry += CRLF + " 																			AND SA1.D_E_L_E_T_ = ' '"

cQry += CRLF + "									LEFT JOIN "+RetSqlName("U88")+" U88  ON SE1.E1_CLIENTE 		= U88.U88_CLIENT"
cQry += CRLF + " 																			AND SE1.E1_LOJA		= U88.U88_LOJA"
cQry += CRLF + " 																			AND SE1.E1_TIPO		= LEFT(U88.U88_FORMAP,3)"
cQry += CRLF + " 																			AND U88.D_E_L_E_T_ = ' '"
cQry += CRLF + " 																			AND U88.U88_FILIAL	= '"+xFilial("U88",cFilFat)+"'"

If !lFatConv // Diferente de conveniência
	cQry += CRLF + " 									LEFT JOIN "+RetSqlName("UF6")+" UF6		ON SA1.A1_XCLASSE	= UF6.UF6_CODIGO"
	cQry += CRLF + " 																			AND UF6.D_E_L_E_T_ = ' '"
	cQry += CRLF + " 																			AND UF6.UF6_FILIAL	= '"+xFilial("UF6")+"'"
EndIf

cQry += CRLF + " WHERE SE1.D_E_L_E_T_	= ' '"
cQry += CRLF + " AND SE1.E1_FILIAL		= '"+xFilial("SE1",cFilFat)+"'"
cQry += CRLF + " AND SE1.E1_NUM			= '"+_aFat[1]+"'"
cQry += CRLF + " AND SE1.E1_CLIENTE		= '"+_aFat[2]+"'"
cQry += CRLF + " AND SE1.E1_LOJA		= '"+_aFat[3]+"'"

If Len(_aFat) > 3
	cQry += CRLF + " AND SE1.E1_PREFIXO	= '"+_aFat[4]+"'"
	cQry += CRLF + " AND SE1.E1_PARCELA	= '"+_aFat[5]+"'"
	cQry += CRLF + " AND SE1.E1_TIPO	= '"+_aFat[6]+"'"
Endif

cQry := ChangeQuery(cQry)
//MemoWrite("c:\temp\RFATE013_cabec.txt",cQry)
TcQuery cQry NEW Alias "QRYCABEC"

If QRYCABEC->(!EOF())

	cNome := QRYCABEC->A1_NOME
	cFatSol		:= IIF(QRYCABEC->U88_FATCOR == "S","Não","Sim")

	If !Empty(QRYCABEC->U88_END)
		cEnd 		:= QRYCABEC->U88_END
		cComp 		:= QRYCABEC->U88_COMPLE
		cBairro		:= QRYCABEC->U88_BAIRRO
		cMun 		:= QRYCABEC->U88_MUN
		cCep 		:= Transform(QRYCABEC->U88_CEP,"@R 99999-999")
		cEst 		:= QRYCABEC->U88_EST
		cInscr 		:= QRYCABEC->U88_INSCR
		cCgc		:= Subs(Transform(QRYCABEC->U88_CGC,PicPes(RetPessoa(QRYCABEC->U88_CGC))),1,At("%",Transform(QRYCABEC->U88_CGC,PicPes(RetPessoa(QRYCABEC->U88_CGC))))-1)
		cTel		:= QRYCABEC->U88_TEL
	Else
		cEnd 		:= QRYCABEC->A1_END
		cComp 		:= QRYCABEC->A1_COMPLEM
		cBairro		:= QRYCABEC->A1_BAIRRO
		cMun 		:= QRYCABEC->A1_MUN
		cCep 		:= Transform(QRYCABEC->A1_CEP,"@R 99999-999")
		cEst 		:= QRYCABEC->A1_EST
		cInscr 		:= QRYCABEC->A1_INSCR
		cCgc		:= Subs(Transform(QRYCABEC->A1_CGC,PicPes(RetPessoa(QRYCABEC->A1_CGC))),1,At("%",Transform(QRYCABEC->A1_CGC,PicPes(RetPessoa(QRYCABEC->A1_CGC))))-1)
		cTel		:= QRYCABEC->A1_TEL
	Endif

	cCli		:= QRYCABEC->E1_CLIENTE
	cLoja		:= QRYCABEC->E1_LOJA
	cFil		:= QRYCABEC->E1_FILIAL
	cEmis		:= DToC(SToD(QRYCABEC->E1_EMISSAO))
	cVencto		:= DToC(SToD(QRYCABEC->E1_VENCREA)) //E1_VENCTO
	cSubAgrup	:= QRYCABEC->A1_XQFAT

	If !lFatConv // Diferente de conveniência
		cClasse		:= QRYCABEC->UF6_DESC
	EndIf
	
	nVlrAcres	:= QRYCABEC->E1_ACRESC
	nVlrDecres	:= QRYCABEC->E1_DECRESC
Else
	If IsBlind()
		Conout("Dados não localizados!")
	Else
		MsgAlert("Dados não localizados!","Alerta")
	Endif

	Return
Endif

If Select("QRYCABEC") > 0
	QRYCABEC->(dbCloseArea())
Endif

oRel:StartPage() //Inicia uma nova pagina

//Box geral
oRel:Box(nLin,0056,0550,2340)

//Box sacado
oRel:Box(nLin,1950,0305,2135)

oRel:SayBitMap(nLin + 25,1500,cStartPath + "lgrlfat.png",0400,0100)

oRel:Say(nLin + 45,1985,"Sacado",oFont8)
oRel:Say(nLin + 135,1965,AllTrim(cCli) + "/" + cLoja,oFont8N)

oRel:Say(nLin + 25,2195,"Fatura",oFont8)
if lFatParc
	oRel:Say(nLin + 75,2165,_aFat[1],oFont8N)
	oRel:Say(nLin + 130,2195,"Parcela",oFont8)
	oRel:Say(nLin + 170,2195,_aFat[5]+"/"+StrZero(nQtdParc,len(_aFat[5])),oFont8N)
else
	oRel:Say(nLin + 95,2165,_aFat[1],oFont8N)
endif
nLin += 50 //130

oRel:Say(nLin + 15,0110,cNome,oFont10N)

nLin += 100 //230

oRel:Say(nLin + 15,0110,"Endereço:",oFont8)
oRel:Say(nLin + 15,0295,cEnd,oFont8N)

nLin += 50 //280

oRel:Say(nLin + 25,0110,"Compl.:",oFont8)
oRel:Say(nLin + 25,0295,cComp,oFont8N)

oRel:Say(nLin + 25,1500,"I.E.:",oFont8)
oRel:Say(nLin + 25,1620,cInscr,oFont8N)

if lFatParc
	oRel:Say(nLin + 30,2185,"Emissão",oFont8)
	oRel:Say(nLin + 80,2165,cEmis,oFont8N)
else
	oRel:Say(nLin - 25,2185,"Emissão",oFont8)
	oRel:Say(nLin + 40,2165,cEmis,oFont8N)
endif
//Box filial
oRel:Box(nLin + 25,1950,0550,2135)
oRel:FillRect({nLin + 27,1952,0549,2133},oBrush)

DbSelectArea("SM0")
SM0->(DbSetOrder(1))
SM0->(DbSeek(cEmpAnt+cFil))
if SM0->(Eof())
	SM0->(DbSeek(cEmpAnt+cFilAnt))
endif

aFil := U_UQuebTxt(SM0->M0_FILIAL,13)

For nI := 1 To Len(aFil)
	oRel:Say(nLin + 70,1960,aFil[nI],oFont6N,,CLR_WHITE)
	nLin += 50
Next

nLin := 330 //330

oRel:Say(nLin + 35,0110,"Bairro:",oFont8)
oRel:Say(nLin + 35,0295,cBairro,oFont8N)

nLin += 50 //380

oRel:Say(nLin + 45,0110,"Cidade:",oFont8)
oRel:Say(nLin + 45,0295,cMun,oFont8N)

oRel:Say(nLin + 45,0945,"U.F.:",oFont8)
oRel:Say(nLin + 45,1065,cEst,oFont8N)

oRel:Say(nLin + 15,1500,"CNPJ:",oFont8)
oRel:Say(nLin + 15,1620,cCgc,oFont8N)

if lFatParc
	oRel:Say(nLin + 40,2160,"Vencimento",oFont8)
	oRel:Say(nLin + 95,2165,cVencto,oFont8N)
else
	oRel:Say(nLin + 20,2160,"Vencimento",oFont8)
	oRel:Say(nLin + 85,2165,cVencto,oFont8N)
endif

nLin += 100 //480

oRel:Say(nLin + 5,0110,"CEP:",oFont8)
oRel:Say(nLin + 5,0295,cCep,oFont8N)

oRel:Say(nLin + 5,1500,"Fone:",oFont8)
oRel:Say(nLin + 5,1620,cTel,oFont8N)

Return

/***************************/
Static Function Itens(_aFat)
/***************************/

Local cQry			:= ""

Local nLinAux		:= 0
Local nBkpLin		:= 0
Local nBkpLinAux 	:= 0

Local cFPg			:= ""
Local cMotSaq		:= ""

Local lDifFpg 		:= .F.
Local lDifMotSaq	:= .F.

Local aItens		:= {}
Local nSubVlr		:= 0
Local nI

Local lQbrPag		:= .F.

Local cLogFatur		:= ""
Local cDirLogs		:= "\autocom\faturas\"+cEmpAnt+cFilAnt+"\"+PadL(Month(dDatabase),2,"0")+cValToChar(Year(dDatabase))+"\"
Local lLogFat		:= SuperGetMV("MV_XLOGFAT",,.T.) //habilita gravacao de log ao gerar faturas

Local aRecSD2 := {}

nTotQtd := 0
nSubVlr := 0
nTotVlr := 0

nLin += 150 //630

//Tipo de subagrupamento dos itens
If !lFatConv // Diferente de conveniência
	Do Case
		Case cSubAgrup == "F"
			oRel:Say(nLin,0080,"Subagrupado por: Tipo de Pagamento",oFont8)
		Case cSubAgrup == "M"
			oRel:Say(nLin,0080,"Subagrupado por: Motivo de Saque",oFont8)
	EndCase
EndIf

nLin += 50 //680
nBkpLinAux	:= nLin
nLinAux 	:= nLin
nLin += 50 //730

If Select("QRYITENS") > 0
	QRYITENS->(dbCloseArea())
Endif

If !lFatConv // Diferente de conveniência
	cQry := "SELECT SE1.E1_FILORIG, SE1.E1_TIPO, SE1.E1_NUM, SE1.E1_NUMCART, SE1.E1_PARCELA, SE1.E1_EMISSAO, SE1.E1_XPLACA, SUM(SD2.D2_QUANT) AS QTD,"
	cQry += CRLF + " SL1.L1_ODOMETR, SL1.L1_NOMMOTO, " + Iif(SL1->(FieldPos("L1_CGCMOTO"))>0,"SL1.L1_CGCMOTO","SL1.L1_CGCCLI") + " as L1_CGCCLI, U57.U57_MOTIVO, SE1.E1_VALOR, SE1.E1_VLRREAL, SE1.E1_PREFIXO, SE1.E1_CLIENTE, SE1.E1_LOJA, UIC.UIC_PLACA,"
	cQry += CRLF + " UIC.UIC_MOTORI, SA1.A1_NREDUZ, SA1.A1_EST, SA1.A1_MUN, SE1.E1_XMOTOR"
Else
	cQry := "SELECT SE1.E1_FILORIG, SE1.E1_TIPO, SE1.E1_NUM, SE1.E1_PARCELA, SE1.E1_EMISSAO, SUM(SD2.D2_QUANT) AS QTD,"
	cQry += " SE1.E1_VALOR, SE1.E1_VLRREAL, SE1.E1_PREFIXO, SE1.E1_CLIENTE, SE1.E1_LOJA,"
	cQry += " SA1.A1_NREDUZ, SA1.A1_EST, SA1.A1_MUN, SE1.E1_XMOTOR"
EndIf 

cQry += CRLF + " FROM "+RetSqlName("SE1")+" SE1 LEFT JOIN "+RetSqlName("SF2")+" SF2"
cQry += CRLF + " ON SF2.D_E_L_E_T_ = ' '"
cQry += CRLF + " AND SF2.F2_FILIAL		= SE1.E1_FILORIG"
cQry += CRLF + " AND SE1.E1_NUM		= SF2.F2_DOC"
cQry += CRLF + " AND SE1.E1_PREFIXO	= SF2.F2_SERIE"
//cQry += CRLF + " AND SE1.E1_CLIENTE	= SF2.F2_CLIENTE"
//cQry += CRLF + " AND SE1.E1_LOJA		= SF2.F2_LOJA"

cQry += CRLF + " LEFT JOIN "+RetSqlName("SA1")+" SA1"
cQry += CRLF + " ON SA1.D_E_L_E_T_ = ' '"
cQry += CRLF + " AND SA1.A1_FILIAL		= '"+xFilial("SA1")+"'"
cQry += CRLF + " AND SA1.A1_COD		= SE1.E1_CLIENTE"
cQry += CRLF + " AND SA1.A1_LOJA		= SE1.E1_LOJA"

cQry += CRLF + " LEFT JOIN "+RetSqlName("SD2")+" SD2"
cQry += CRLF + " ON SD2.D_E_L_E_T_ = ' '"
cQry += CRLF + " AND SD2.D2_FILIAL		= SF2.F2_FILIAL "
cQry += CRLF + " AND SF2.F2_DOC		= SD2.D2_DOC"
cQry += CRLF + " AND SF2.F2_SERIE		= SD2.D2_SERIE"
cQry += CRLF + " AND SF2.F2_CLIENTE	= SD2.D2_CLIENTE"
cQry += CRLF + " AND SF2.F2_LOJA		= SD2.D2_LOJA"

If !lFatConv // Diferente de conveniência
	cQry += CRLF + " LEFT JOIN "+RetSqlName("UIC")+" UIC"
	cQry += CRLF + " ON UIC.D_E_L_E_T_ = ' '"
	cQry += CRLF + " AND UIC.UIC_FILIAL	= '"+xFilial("UIC")+"'" //Compartilhado
	cQry += CRLF + " AND SE1.E1_FILIAL || SE1.E1_PREFIXO || SE1.E1_NUM	= UIC_FILIAL || UIC_AMB || UIC_CODIGO"
EndIf

cQry += CRLF + " INNER JOIN "+RetSqlName("FI7")+" FI7	ON SE1.E1_PREFIXO = FI7.FI7_PRFORI"
cQry += CRLF + " AND SE1.E1_NUM 		= FI7.FI7_NUMORI"
cQry += CRLF + " AND SE1.E1_PARCELA 	= FI7.FI7_PARORI"
cQry += CRLF + " AND SE1.E1_TIPO 		= FI7.FI7_TIPORI"
cQry += CRLF + " AND SE1.E1_CLIENTE 	= FI7.FI7_CLIORI"
cQry += CRLF + " AND SE1.E1_LOJA 		= FI7.FI7_LOJORI"
cQry += CRLF + " AND FI7.FI7_PRFDES	= '"+_aFat[4]+"'"
cQry += CRLF + " AND FI7.FI7_NUMDES	= '"+_aFat[1]+"'"
cQry += CRLF + " AND FI7.FI7_PARDES	= '"+_aFat[5]+"'"
cQry += CRLF + " AND FI7.FI7_TIPDES	= '"+_aFat[6]+"'"
cQry += CRLF + " AND FI7.FI7_CLIDES	= '"+_aFat[2]+"'"
cQry += CRLF + " AND FI7.FI7_LOJDES	= '"+_aFat[3]+"'"
cQry += CRLF + " AND FI7.D_E_L_E_T_ = ' '"
cQry += CRLF + " AND FI7.FI7_FILIAL	= '"+xFilial("FI7")+"'"

If !lFatConv // Diferente de conveniência

	cQry += CRLF + " LEFT JOIN "+RetSqlName("U57")+" U57" 	
	cQry += CRLF + " ON SE1.E1_XCODBAR		= U57.U57_PREFIX+U57.U57_CODIGO+U57.U57_PARCEL"
	cQry += CRLF + " AND U57.D_E_L_E_T_ = ' '"
	cQry += CRLF + " AND U57.U57_FILIAL	= '"+xFilial("U57")+"'"

	cQry += CRLF + " LEFT JOIN "+RetSqlName("SL1")+" SL1 	ON SE1.E1_PREFIXO	= SL1.L1_SERIE"
	cQry += CRLF + " AND SE1.E1_NUM 	= SL1.L1_DOC"
	cQry += CRLF + " AND SE1.E1_CLIENTE = SL1.L1_CLIENTE"
	cQry += CRLF + " AND SE1.E1_LOJA 	= SL1.L1_LOJA"
	cQry += CRLF + " AND SL1.L1_SITUA 	= 'OK'"
	cQry += CRLF + " AND SL1.D_E_L_E_T_ = ' '"
	cQry += CRLF + " AND SL1.L1_FILIAL	= SE1.E1_FILORIG "
EndIf

cQry += CRLF + " WHERE SE1.D_E_L_E_T_ = ' '"
cQry += CRLF + " AND SE1.E1_FILIAL		= '"+xFilial("SE1",cFilFat)+"'"

If !lFatConv // Diferente de conveniência
	cQry += CRLF + " GROUP BY SE1.E1_FILORIG, SE1.E1_TIPO, SE1.E1_NUM, SE1.E1_NUMCART, SE1.E1_PARCELA, SE1.E1_EMISSAO, SE1.E1_XPLACA, SL1.L1_ODOMETR, SL1.L1_NOMMOTO, " + Iif(SL1->(FieldPos("L1_CGCMOTO"))>0,"SL1.L1_CGCMOTO","SL1.L1_CGCCLI") + ","
	cQry += CRLF + " U57.U57_MOTIVO, SE1.E1_VALOR, SE1.E1_VLRREAL, SE1.E1_PREFIXO, SE1.E1_CLIENTE, SE1.E1_LOJA, UIC.UIC_PLACA, UIC.UIC_MOTORI, "
	cQry += CRLF + " SA1.A1_NREDUZ, SA1.A1_EST, SA1.A1_MUN, SE1.E1_XMOTOR"
Else
	cQry += " GROUP BY SE1.E1_FILORIG, SE1.E1_TIPO, SE1.E1_NUM,SE1.E1_PARCELA, SE1.E1_EMISSAO, "
	cQry += " SE1.E1_VALOR, SE1.E1_VLRREAL, SE1.E1_PREFIXO, SE1.E1_CLIENTE, SE1.E1_LOJA, "
	cQry += " SA1.A1_NREDUZ, SA1.A1_EST, SA1.A1_MUN, SE1.E1_XMOTOR "
EndIf

If !lFatConv // Diferente de conveniência

	DbSelectArea("SA1")
	SA1->(DbSetOrder(1)) //A1_FILIAL+A1_COD+A1_LOJA

	If SA1->(DbSeek(xFilial("SA1")+_aFat[2]+_aFat[3]))
		If SA1->A1_XORDFAT == "P"//Ordenação por placa
			cQry += CRLF + " ORDER BY 6,5,2"
		Else //Ordenação por data emissao
			cQry += CRLF + " ORDER BY 5,6,2"
		Endif
	Else
		cQry += CRLF + " ORDER BY 5"
	Endif
Else
	cQry += CRLF + " ORDER BY 4"
EndIf

cQry := ChangeQuery(cQry)
//MemoWrite("c:\temp\TRETE020_itens.txt",cQry)
TcQuery cQry NEW Alias "QRYITENS"

/*
Será gerado um LOG com nome "fat_filial+prefixo+numero+parcela_erro_qry.txt" na pasta "\autocom\faturas\", informando que a query de itens que compoem a fatura foi retornado vazio.
No log ira conter a query de busca executada.
*/
If _lFatAut .and. lLogFat .and. QRYITENS->(EOF())
	U_TRETE20A(cDirLogs) //cria pasta para logs
	cLogFatur += "TRETE020 - INICIO " + DTOC(date()) + " " + Time() +CRLF
	cLogFatur += "FILIAL / PREFIXO / FATURA / PARCELA: "+cFilAnt+" / "+_aFat[4]+" / "+_aFat[1]+" / "+_aFat[5]+CRLF
	cLogFatur += "Query sem retorno: " + FunName()+CRLF
	cLogFatur += cQry
	cLogFatur += "TRETE020 - FIM " + DTOC(date()) + " " + Time() +CRLF
	MemoWrite(cDirLogs+"fat_"+cFilAnt+_aFat[4]+_aFat[1]+_aFat[5]+"_erro_qry.txt", cLogFatur)
	cLogFatur := ""
EndIf

//Verfica se há formas de pagamento OU motivos de saque distintos entre os itens
While QRYITENS->(!EOF())

	If !lFatConv // Diferente de conveniência

		If Empty(cFpg)

			cFpg :=  QRYITENS->E1_TIPO
		Else
			If cFpg <> QRYITENS->E1_TIPO

				lDifFpg := .T.
			Endif
		Endif

		If Empty(cMotSaq)

			cMotSaq :=  QRYITENS->U57_MOTIVO
		Else
			If cMotSaq <> QRYITENS->U57_MOTIVO

				lDifMotSaq := .T.
			Endif
		Endif

		If QRYITENS->E1_TIPO == "VLS" //Vale serviço

			AAdd(aItens,{QRYITENS->E1_NUM,;		//1
						QRYITENS->E1_PARCELA,;	//2
						QRYITENS->E1_EMISSAO,;	//3
						QRYITENS->UIC_PLACA,;	//4
						Posicione("DA4",1,xFilial("DA4")+QRYITENS->UIC_MOTORI,"DA4_NOME"),;	//5
						QRYITENS->QTD,;			//6
						QRYITENS->L1_ODOMETR,;	//7
						"",;	//8  QRYITENS->U67_REQUIS
						"",;					//9
						"",;					//10
						QRYITENS->U57_MOTIVO,;	//11
						IIF(QRYITENS->E1_VLRREAL > 0 .And. QRYITENS->E1_VLRREAL <> QRYITENS->E1_VALOR,QRYITENS->E1_VLRREAL,QRYITENS->E1_VALOR),;	//12
						QRYITENS->E1_TIPO,;		//13
						QRYITENS->E1_NUMCART,; //14
						QRYITENS->A1_NREDUZ,; //15
						QRYITENS->A1_EST,; //16
						QRYITENS->A1_MUN,; //17
						QRYITENS->E1_FILORIG,; //18
						QRYITENS->E1_PREFIXO}) //19

		ElseIf Alltrim(QRYITENS->E1_TIPO) == "RP" .And. QRYITENS->E1_PREFIXO == "RPS" //Requisição pós-paga

			AAdd(aItens,{QRYITENS->E1_NUM,;		//1
						QRYITENS->E1_PARCELA,;	//2
						QRYITENS->E1_EMISSAO,;	//3
						QRYITENS->E1_XPLACA,;	//4
						Posicione("DA4",3,xFilial("DA4")+QRYITENS->E1_XMOTOR,"DA4_NOME"),;	//5
						QRYITENS->QTD,;			//6
						0,;						//7
						"",;					//8  QRYITENS->U67_REQUIS
						"",;					//9
						"",;					//10
						QRYITENS->U57_MOTIVO,;	//11
						IIF(QRYITENS->E1_VLRREAL > 0 .And. QRYITENS->E1_VLRREAL <> QRYITENS->E1_VALOR,QRYITENS->E1_VLRREAL,QRYITENS->E1_VALOR),;	//12
						QRYITENS->E1_TIPO,;		//13
						QRYITENS->E1_NUMCART,; //14
						QRYITENS->A1_NREDUZ,; //15
						QRYITENS->A1_EST,; //16
						QRYITENS->A1_MUN,; //17
						QRYITENS->E1_FILORIG,; //18
						QRYITENS->E1_PREFIXO}) //19

		Else //Vendas

			//preenche o nome do motorista, somente quando for CPF e quando for diferente do cliente
			cNomMot := "" 
			Do Case
				Case !Empty(QRYITENS->L1_NOMMOTO) .and. AllTrim(QRYITENS->L1_NOMMOTO) <> AllTrim(SA1->A1_NOME)
					cNomMot := QRYITENS->L1_NOMMOTO
				Case ChkFile("U07") .and. !Empty(QRYITENS->L1_CGCCLI) .and. (QRYITENS->L1_CGCCLI <> SA1->A1_CGC .or. Len(AllTrim(SA1->A1_CGC)) <= 11)
					cNomMot := Posicione("U07",1,xFilial("U07")+QRYITENS->L1_CGCCLI,"U07_NOME")
			EndCase

			AAdd(aItens,{QRYITENS->E1_NUM,;		//1
						QRYITENS->E1_PARCELA,;	//2
						QRYITENS->E1_EMISSAO,;	//3
						QRYITENS->E1_XPLACA,;	//4
						cNomMot,;	//5
						QRYITENS->QTD,;			//6
						QRYITENS->L1_ODOMETR,;	//7
						"",;	//8  QRYITENS->U67_REQUIS
						"",;					//9
						"",;					//10
						QRYITENS->U57_MOTIVO,;	//11
						QRYITENS->E1_VALOR,;	//12
						QRYITENS->E1_TIPO,;		//13
						QRYITENS->E1_NUMCART,; //14
						QRYITENS->A1_NREDUZ,; //15
						QRYITENS->A1_EST,; //16
						QRYITENS->A1_MUN,; //17
						QRYITENS->E1_FILORIG,; //18
						QRYITENS->E1_PREFIXO}) //19
		Endif
	Else

		AAdd(aItens,{QRYITENS->E1_NUM,;		//1
						QRYITENS->E1_PARCELA,;	//2
						QRYITENS->E1_EMISSAO,;	//3
						"",;					//4
						"",;					//5
						QRYITENS->QTD,;			//6
						"",;					//7
						"",;					//8
						"",;					//9
						"",;					//10
						"",;					//11
						QRYITENS->E1_VALOR,;	//12
						QRYITENS->E1_TIPO,;		//13
						"",;					//14
						QRYITENS->A1_NREDUZ,; //15
						QRYITENS->A1_EST,; //16
						QRYITENS->A1_MUN,; //17
						QRYITENS->E1_FILORIG,; //18
						QRYITENS->E1_PREFIXO}) //19
	EndIf

    QRYITENS->(dbSkip())
EndDo

If !lFatConv // Diferente de conveniência

	//Ordena conforme subagrupamento
	If cSubAgrup == "F" .And. lDifFpg
		ASort(aItens,,,{|x,y| x[13] > y[13]})
	Endif

	If cSubAgrup == "M" .And. lDifMotSaq
		ASort(aItens,,,{|x,y| x[11] > y[11]})
	Endif
EndIf

DbSelectArea("SX5")
SX5->(DbSetOrder(1)) //X5_FILIAL+X5_TABELA+X5_CHAVE

cFpg 	:= ""
cMotSaq	:= ""

nLin += 30 //760

For nI := 1 To Len(aItens)

	//Final de pagina
	If nLin > 2800

		If nBkpLin == 0
			nBkpLin := nLin
		Endif

		If !_lArqPdf

			//Box geral
			oRel:Box(nLinAux,0053,nLin,2340)
			oRel:FillRect({nLinAux + 3,0054,nLinAux + 60,2340},oBrush)

			//Box horizontal - cima p/ baixo
			oRel:Box(nLinAux,0053,nLinAux + 60,2340)

			//Box 1 - esquerda p/ direita
			oRel:Box(nLinAux,0217,nLin,0400)

			If !lFatConv // Diferente de conveniência

				//Box 2 - esquerda p/ direita
				oRel:Box(nLinAux,0400,nLin,0570)

				//Box 3 - esquerda p/ direita
				oRel:Box(nLinAux,0570,nLin,780)
			EndIf

			//Box 4 - esquerda p/ direita
			oRel:Box(nLinAux,780,nLin,980)

			If !lFatConv // Diferente de conveniência

				//Box 5 - esquerda p/ direita
				oRel:Box(nLinAux,980,nLin,1150)

				//Box 6 - esquerda p/ direita
				oRel:Box(nLinAux,1150,nLin,1360)

				//Box 7 - esquerda p/ direita
				oRel:Box(nLinAux,1360,nLin,1570)

				//Box 8 - esquerda p/ direita
				oRel:Box(nLinAux,1570,nLin,1850)

				//Box 9 - esquerda p/ direita
				oRel:Box(nLinAux,1850,nLin,2060)
			EndIf

		    oRel:Box(nLinAux,2060,nLin,2060)
		Endif

		nPag++
		lQbrPag := .T.

		If !_lFatAut .And. !_lArqPdf

			oRel:Say(nLinAux + 18,0100,"Título",oFont8)
			oRel:Say(nLinAux + 18,0255,"Emissão",oFont8)

			If !lFatConv // Diferente de conveniência
				oRel:Say(nLinAux + 18,0450,"Placa",oFont8)
				oRel:Say(nLinAux + 18,0610,"Motorista",oFont8)
			EndIf

			oRel:Say(nLinAux + 18,805,"Quantidade",oFont8)

			If !lFatConv // Diferente de conveniência
				oRel:Say(nLinAux + 18,1035,"KM",oFont8)
				oRel:Say(nLinAux + 18,1220,"Req.",oFont8)
				oRel:Say(nLinAux + 18,1390,"C. Convênio",oFont8)
				oRel:Say(nLinAux + 18,1660,"RFID",oFont8)
				oRel:Say(nLinAux + 18,1865,"Motivo Saque",oFont8)
			EndIf

			oRel:Say(nLinAux + 18,2150,"Valor",oFont8)

			Rod()
			Cabec(_aFat)
		Endif

		nLinAux := nLin + 140
		nLin += 205
	Endif

	If !_lArqPdf

		If AllTrim(aItens[nI][13]) == "CF" .and. !Empty(aItens[nI][14]) //Carta Frete
			oRel:Say(nLin,0064,AllTrim(aItens[nI][14]),oFont8)
		ElseIf AllTrim(aItens[nI][13]) == "RP" //Requisição
			oRel:Say(nLin + 4,0062,AllTrim(aItens[nI][1]) + "/" + aItens[nI][2],oFont6)
		Else
			oRel:Say(nLin,0064,AllTrim(aItens[nI][1]) + "/" + aItens[nI][2],oFont6)
		Endif

		oRel:Say(nLin,0235,DToC(SToD(aItens[nI][3])),oFont8)

		If !lFatConv // Diferente de conveniência
			oRel:Say(nLin,0420,Transform(aItens[nI][4],"@!R NNN-9N99"),oFont8)
			oRel:Say(nLin,0590,SubStr(aItens[nI][5],1,8),oFont8)
		EndIf

		oRel:Say(nLin,0790,Alltrim(Transform(aItens[nI][6],"@E 99999999.99"))+iif(aScan(aRecSD2, aItens[nI][18]+aItens[nI][19]+aItens[nI][1])==0,""," *"),oFont8)
		
		If !lFatConv // Diferente de conveniência
			oRel:Say(nLin,0937,Transform(aItens[nI][7],"@E 99,999,999,999"),oFont8)
			oRel:Say(nLin,1170,aItens[nI][8],oFont8)
			oRel:Say(nLin,1385,aItens[nI][9],oFont8)
			oRel:Say(nLin,1590,aItens[nI][10],oFont8)
			oRel:Say(nLin,1870,SubStr(Posicione("SX5",1,xFilial("SX5")+"UX"+aItens[nI][11],"X5_DESCRI"),1,9),oFont8)
		EndIf
		oRel:Say(nLin,2000,Transform(aItens[nI][12],"@E 9,999,999,999,999.99"),oFont8)

		if aScan(aRecSD2, aItens[nI][18]+aItens[nI][19]+aItens[nI][1] ) == 0 //se recno do SD2 ainda nao somou
			nTotQtd += aItens[nI][6]
			aadd(aRecSD2, aItens[nI][18]+aItens[nI][19]+aItens[nI][1])
		else
			lDuplSD2 := .T.
		endif

		nSubVlr	+= aItens[nI][12]
		nTotVlr	+= aItens[nI][12]

		If cSubAgrup == "F" .Or. cSubAgrup == "M"

			If cSubAgrup == "F" .And. lDifFpg

				If Empty(cFpg)

					cFpg := aItens[nI][13]
				Else
					If nI + 1 <= Len(aItens)

						If cFpg <> aItens[nI + 1][13]

							nLin += 50
							oRel:Line(nLin,2060,nLin,2220)
							oRel:Say(nLin,2000,Transform(nSubVlr,"@E 9,999,999,999,999.99"),oFont8N)
							nLin += 50
							nSubVlr := 0
							cFpg := aItens[nI + 1][13]
						Endif
					Endif
				Endif

			ElseIf cSubAgrup == "M" .And. lDifMotSaq

				If Empty(cMotSaq)

					cMotSaq := aItens[nI][11]
				Else
					If nI + 1 <= Len(aItens)

						If cMotSaq <> aItens[nI + 1][11]

							nLin += 50
							oRel:Line(nLin,2060,nLin,2220)
							oRel:Say(nLin,2000,Transform(nSubVlr,"@E 9,999,999,999,999.99"),oFont8N)
							nLin += 50
							nSubVlr := 0
							cMotSaq := aItens[nI + 1][11]
						Endif
					Endif
				Endif
			Endif

			If lDifFpg .Or. lDifMotSaq

				If nI == Len(aItens)
					nLin += 50
					oRel:Line(nLin,2058,nLin,2220)
					oRel:Say(nLin,2000,Transform(nSubVlr,"@E 9,999,999,999,999.99"),oFont8N)
				Endif
			Endif
		Endif
	Endif

	nLin += 50
Next

If !_lArqPdf

	If !lQbrPag

		//Box geral
		oRel:Box(nLinAux,0053,nLin,2340)
		oRel:FillRect({nLinAux + 3,0054,nLinAux + 60,2340},oBrush)

		//Box horizontal - cima p/ baixo
		oRel:Box(nLinAux,0053,nLinAux + 60,2340)

		//Box 1 - esquerda p/ direita
		oRel:Box(nLinAux,0217,nLin,0400)

		If !lFatConv // Diferente de conveniência

			//Box 2 - esquerda p/ direita
			oRel:Box(nLinAux,0400,nLin,0570)

			//Box 3 - esquerda p/ direita
			oRel:Box(nLinAux,0570,nLin,780)
		EndIf

		//Box 4 - esquerda p/ direita
		oRel:Box(nLinAux,780,nLin,980)

		If !lFatConv // Diferente de conveniência

			//Box 5 - esquerda p/ direita
			oRel:Box(nLinAux,980,nLin,1150)

			//Box 6 - esquerda p/ direita
			oRel:Box(nLinAux,1150,nLin,1360)

			//Box 7 - esquerda p/ direita
			oRel:Box(nLinAux,1360,nLin,1570)

			//Box 8 - esquerda p/ direita
			oRel:Box(nLinAux,1570,nLin,1850)

			//Box 9 - esquerda p/ direita
			oRel:Box(nLinAux,1850,nLin,2060)
		EndIf

		oRel:Box(nLinAux,2060,nLin,2060)

		oRel:Say(nLinAux + 18,0100,"Título",oFont8)
		oRel:Say(nLinAux + 18,0255,"Emissão",oFont8)

		If !lFatConv // Diferente de conveniência
			oRel:Say(nLinAux + 18,0450,"Placa",oFont8)
			oRel:Say(nLinAux + 18,0610,"Motorista",oFont8)
		EndIf

		oRel:Say(nLinAux + 18,805,"Quantidade",oFont8)

		If !lFatConv // Diferente de conveniência
			oRel:Say(nLinAux + 18,1035,"KM",oFont8)
			oRel:Say(nLinAux + 18,1220,"Req.",oFont8)
			oRel:Say(nLinAux + 18,1390,"C. Convênio",oFont8)
			oRel:Say(nLinAux + 18,1660,"RFID",oFont8)
			oRel:Say(nLinAux + 18,1865,"Motivo Saque",oFont8)
		EndIf

		oRel:Say(nLinAux + 18,2150,"Valor",oFont8)
	Else
		//Box geral
		oRel:Box(nLinAux,0053,nLin,2340)

		//Box 1 - esquerda p/ direita
		oRel:Box(nLinAux,0217,nLin,0400)

		If !lFatConv // Diferente de conveniência

			//Box 2 - esquerda p/ direita
			oRel:Box(nLinAux,0400,nLin,0570)

			//Box 3 - esquerda p/ direita
			oRel:Box(nLinAux,0570,nLin,780)
		EndIf

		//Box 4 - esquerda p/ direita
		oRel:Box(nLinAux,780,nLin,980)

		If !lFatConv // Diferente de conveniência

			//Box 5 - esquerda p/ direita
			oRel:Box(nLinAux,980,nLin,1150)

			//Box 6 - esquerda p/ direita
			oRel:Box(nLinAux,1150,nLin,1360)

			//Box 7 - esquerda p/ direita
			oRel:Box(nLinAux,1360,nLin,1570)

			//Box 8 - esquerda p/ direita
			oRel:Box(nLinAux,1570,nLin,1850)

			//Box 9 - esquerda p/ direita
			oRel:Box(nLinAux,1850,nLin,2060)
		EndIf

		oRel:Box(nLinAux,2060,nLin,2060)
	Endif
Else
	If !lQbrPag

		//Box geral
		oRel:Box(nLinAux,0053,nLin,2340)

		//Box horizontal - cima p/ baixo
		oRel:Box(nLinAux,0053,nLinAux + 60,2340)

		//Box 1 - esquerda p/ direita
		oRel:Box(nLinAux + 60,0217,nLin,0400)

		If !lFatConv // Diferente de conveniência

			//Box 2 - esquerda p/ direita
			oRel:Box(nLinAux + 60,0400,nLin,0570)

			//Box 3 - esquerda p/ direita
			oRel:Box(nLinAux + 60,0570,nLin,0780)
		EndIf

		//Box 4 - esquerda p/ direita
		oRel:Box(nLinAux + 60,0775,nLin,0980)

		If !lFatConv // Diferente de conveniência

			//Box 5 - esquerda p/ direita
			oRel:Box(nLinAux + 60,0980,nLin,1150)

			//Box 6 - esquerda p/ direita
			oRel:Box(nLinAux + 60,1150,nLin,1360)

			//Box 7 - esquerda p/ direita
			oRel:Box(nLinAux + 60,1360,nLin,1570)

			//Box 8 - esquerda p/ direita
			oRel:Box(nLinAux + 60,1565,nLin,1850)

			//Box 9 - esquerda p/ direita
			oRel:Box(nLinAux + 60,1850,nLin,2060)
		EndIf

		oRel:Box(nLinAux + 60,2060,nLin,2060)

		oRel:FillRect({nLinAux + 1,0054,nLinAux + 60,2340},oBrush)

		oRel:Say(nLinAux + 18,0100,"Título",oFont8)
		oRel:Say(nLinAux + 18,0255,"Emissão",oFont8)

		If !lFatConv // Diferente de conveniência
			oRel:Say(nLinAux + 18,0450,"Placa",oFont8)
			oRel:Say(nLinAux + 18,0610,"Motorista",oFont8)
		EndIf
		
		oRel:Say(nLinAux + 18,805,"Quantidade",oFont8)
		
		If !lFatConv // Diferente de conveniência
			oRel:Say(nLinAux + 18,1035,"KM",oFont8)
			oRel:Say(nLinAux + 18,1220,"Req.",oFont8)
			oRel:Say(nLinAux + 18,1390,"C. Convênio",oFont8)
			oRel:Say(nLinAux + 18,1660,"RFID",oFont8)
			oRel:Say(nLinAux + 18,1865,"Motivo Saque",oFont8)
		EndIf

		oRel:Say(nLinAux + 18,2150,"Valor",oFont8)

		nLin := 760

		For nI := 1 To Len(aItens)

			If nLin > 2800
				Rod()
				nPag++
				Cabec(_aFat)
				nLinAux := nLin + 140
				nLin += 205
			Endif

			If AllTrim(aItens[nI][13]) == "CF" .and. !Empty(aItens[nI][14]) //Carta Frete
				oRel:Say(nLin,0064,AllTrim(aItens[nI][14]),oFont8)
			ElseIf AllTrim(aItens[nI][13]) == "RP" //Requisição
				oRel:Say(nLin + 4,0062,AllTrim(aItens[nI][1]) + "/" + aItens[nI][2],oFont6)
			Else
				oRel:Say(nLin,0064,AllTrim(aItens[nI][1]) + "/" + aItens[nI][2],oFont6)
			Endif

			oRel:Say(nLin,0235,DToC(SToD(aItens[nI][3])),oFont8)

			If !lFatConv // Diferente de conveniência
				oRel:Say(nLin,0420,Transform(aItens[nI][4],"@!R NNN-9N99"),oFont8)
				oRel:Say(nLin,0590,SubStr(aItens[nI][5],1,8),oFont8)
			EndIf

			oRel:Say(nLin,0790,Alltrim(Transform(aItens[nI][6],"@E 99999999.99"))+iif(aScan(aRecSD2, aItens[nI][18]+aItens[nI][19]+aItens[nI][1])==0,""," *"),oFont8)

			If !lFatConv // Diferente de conveniência
				oRel:Say(nLin,0937,Transform(aItens[nI][7],"@E 99,999,999,999"),oFont8)
				oRel:Say(nLin,1170,aItens[nI][8],oFont8)
				oRel:Say(nLin,1385,aItens[nI][9],oFont8)
				oRel:Say(nLin,1590,aItens[nI][10],oFont8)
				oRel:Say(nLin,1870,SubStr(Posicione("SX5",1,xFilial("SX5")+"UX"+aItens[nI][11],"X5_DESCRI"),1,9),oFont8)
			EndIf

			oRel:Say(nLin,2000,Transform(aItens[nI][12],"@E 9,999,999,999,999.99"),oFont8)

			if aScan(aRecSD2, aItens[nI][18]+aItens[nI][19]+aItens[nI][1] ) == 0 //se recno do SD2 ainda nao somou
				nTotQtd += aItens[nI][6]
				aadd(aRecSD2, aItens[nI][18]+aItens[nI][19]+aItens[nI][1])
			else
				lDuplSD2 := .T.
			endif
			nSubVlr	+= aItens[nI][12]
			nTotVlr	+= aItens[nI][12]

			If cSubAgrup == "F" .Or. cSubAgrup == "M"

				If cSubAgrup == "F" .And. lDifFpg

					If Empty(cFpg)

						cFpg := aItens[nI][13]
					Else
						If nI + 1 <= Len(aItens)

							If cFpg <> aItens[nI + 1][13]

								nLin += 50
								oRel:Line(nLin,2060,nLin,2220)
								oRel:Say(nLin,2000,Transform(nSubVlr,"@E 9,999,999,999,999.99"),oFont8N)
								nLin += 50
								nSubVlr := 0
								cFpg := aItens[nI + 1][13]
							Endif
						Endif
					Endif

				ElseIf cSubAgrup == "M" .And. lDifMotSaq

					If Empty(cMotSaq)

						cMotSaq := aItens[nI][11]
					Else
						If nI + 1 <= Len(aItens)

							If cMotSaq <> aItens[nI + 1][11]

								nLin += 50
								oRel:Line(nLin,2060,nLin,2220)
								oRel:Say(nLin,2000,Transform(nSubVlr,"@E 9,999,999,999,999.99"),oFont8N)
								nLin += 50
								nSubVlr := 0
								cMotSaq := aItens[nI + 1][11]
							Endif
						Endif
					Endif
				Endif

				If lDifFpg .Or. lDifMotSaq

					If nI == Len(aItens)
						nLin += 50
						oRel:Line(nLin,2058,nLin,2220)
						oRel:Say(nLin,2000,Transform(nSubVlr,"@E 9,999,999,999,999.99"),oFont8N)
					Endif
				Endif
			Endif

			nLin += 50
		Next
	Else
		If !_lFatAut .And. !_lArqPdf
			//Box geral
			oRel:Box(nLinAux,0053,nLin,2340)

			//Box 1 - esquerda p/ direita
			oRel:Box(nLinAux + 60,0217,nLin,0400)

			If !lFatConv // Diferente de conveniência

				//Box 2 - esquerda p/ direita
				oRel:Box(nLinAux + 60,0400,nLin,0570)

				//Box 3 - esquerda p/ direita
				oRel:Box(nLinAux + 60,0570,nLin,0780)
			EndIf

			//Box 4 - esquerda p/ direita
			oRel:Box(nLinAux + 60,0775,nLin,0980)

			If !lFatConv // Diferente de conveniência

				//Box 5 - esquerda p/ direita
				oRel:Box(nLinAux + 60,0980,nLin,1150)

				//Box 6 - esquerda p/ direita
				oRel:Box(nLinAux + 60,1150,nLin,1360)

				//Box 7 - esquerda p/ direita
				oRel:Box(nLinAux + 60,1360,nLin,1570)

				//Box 8 - esquerda p/ direita
				oRel:Box(nLinAux + 60,1565,nLin,1850)
			EndIf

			//Box 9 - esquerda p/ direita
			oRel:Box(nLinAux + 60,1850,nLin,2060)
		Else

			//Box geral
			oRel:Box(nBkpLinAux,0053,nBkpLin,2340)

			//Box horizontal - cima p/ baixo
			oRel:Box(nBkpLinAux,0053,nBkpLinAux + 60,2340)

			//Box 1 - esquerda p/ direita
			oRel:Box(nBkpLinAux,0217,nBkpLin,0400)

			If !lFatConv // Diferente de conveniência

				//Box 2 - esquerda p/ direita
				oRel:Box(nBkpLinAux,0400,nBkpLin,0570)

				//Box 3 - esquerda p/ direita
				oRel:Box(nBkpLinAux,0570,nBkpLin,0780)
			EndIf

			//Box 4 - esquerda p/ direita
			oRel:Box(nBkpLinAux,0780,nBkpLin,0980)

			If !lFatConv // Diferente de conveniência

				//Box 5 - esquerda p/ direita
				oRel:Box(nBkpLinAux,0980,nBkpLin,1150)

				//Box 6 - esquerda p/ direita
				oRel:Box(nBkpLinAux,1150,nBkpLin,1360)

				//Box 7 - esquerda p/ direita
				oRel:Box(nBkpLinAux,1360,nBkpLin,1570)

				//Box 8 - esquerda p/ direita
				oRel:Box(nBkpLinAux,1570,nBkpLin,1850)

				//Box 9 - esquerda p/ direita
				oRel:Box(nBkpLinAux,1850,nBkpLin,2060)
			EndIf

			oRel:Box(nBkpLinAux,2060,nBkpLin,2060)

			oRel:FillRect({nBkpLinAux + 3,0054,nBkpLinAux + 60,2340},oBrush)

			oRel:Say(nBkpLinAux + 18,0100,"Título",oFont8)
			oRel:Say(nBkpLinAux + 18,0255,"Emissão",oFont8)

			If !lFatConv // Diferente de conveniência
				oRel:Say(nBkpLinAux + 18,0450,"Placa",oFont8)
				oRel:Say(nBkpLinAux + 18,0610,"Motorista",oFont8)
			EndIf

			oRel:Say(nBkpLinAux + 18,805,"Quantidade",oFont8)
			
			If !lFatConv // Diferente de conveniência
				oRel:Say(nBkpLinAux + 18,1035,"KM",oFont8)
				oRel:Say(nBkpLinAux + 18,1220,"Req.",oFont8)
				oRel:Say(nBkpLinAux + 18,1390,"C. Convênio",oFont8)
				oRel:Say(nBkpLinAux + 18,1660,"RFID",oFont8)
				oRel:Say(nBkpLinAux + 18,1865,"Motivo Saque",oFont8)
			EndIf

			oRel:Say(nBkpLinAux + 18,2150,"Valor",oFont8)
		Endif

		nLin := 760

		For nI := 1 To Len(aItens)

			If nLin > 2800
				Rod()
				nPag++
				Cabec(_aFat)
				nLinAux := nLin + 140
				nLin += 205

				If _lFatAut .Or. _lArqPdf

					nBkpLin := (Len(aItens) - nI) * 160

					//Box geral
					oRel:Box(nLinAux,0053,nBkpLin,2340)

					//Box 1 - esquerda p/ direita
					oRel:Box(nLinAux,0217,nBkpLin,0400)

					//Box 2 - esquerda p/ direita
					oRel:Box(nLinAux,0400,nBkpLin,0570)

					//Box 3 - esquerda p/ direita
					oRel:Box(nLinAux,0570,nBkpLin,780)

					//Box 4 - esquerda p/ direita
					oRel:Box(nLinAux,780,nBkpLin,980)

					//Box 5 - esquerda p/ direita
					oRel:Box(nLinAux,980,nBkpLin,1150)

					//Box 6 - esquerda p/ direita
					oRel:Box(nLinAux,1150,nBkpLin,1360)

					//Box 7 - esquerda p/ direita
					oRel:Box(nLinAux,1360,nBkpLin,1570)

					//Box 8 - esquerda p/ direita
					oRel:Box(nLinAux,1570,nBkpLin,1850)

					//Box 9 - esquerda p/ direita
					oRel:Box(nLinAux,1850,nBkpLin,2060)
					oRel:Box(nLinAux,2060,nBkpLin,2060)
				Endif
			Endif

			If AllTrim(aItens[nI][13]) == "CF" .and. !Empty(aItens[nI][14]) //Carta Frete
				oRel:Say(nLin,0064,AllTrim(aItens[nI][14]),oFont8)
			ElseIf AllTrim(aItens[nI][13]) == "RP" //Requisição
				oRel:Say(nLin + 4,0062,AllTrim(aItens[nI][1]) + "/" + aItens[nI][2],oFont6)
			Else
				oRel:Say(nLin,0064,AllTrim(aItens[nI][1]) + "/" + aItens[nI][2],oFont6)
			Endif

			oRel:Say(nLin,0235,DToC(SToD(aItens[nI][3])),oFont8)

			If !lFatConv // Diferente de conveniência
				oRel:Say(nLin,0420,Transform(aItens[nI][4],"@!R NNN-9N99"),oFont8)
				oRel:Say(nLin,0590,SubStr(aItens[nI][5],1,8),oFont8)
			EndIf
			
			oRel:Say(nLin,0790,Alltrim(Transform(aItens[nI][6],"@E 99999999.99"))+iif(aScan(aRecSD2, aItens[nI][18]+aItens[nI][19]+aItens[nI][1])==0,""," *"),oFont8)
			
			If !lFatConv // Diferente de conveniência
				oRel:Say(nLin,0937,Transform(aItens[nI][7],"@E 99,999,999,999"),oFont8)
				oRel:Say(nLin,1170,aItens[nI][8],oFont8)
				oRel:Say(nLin,1385,aItens[nI][9],oFont8)
				oRel:Say(nLin,1590,aItens[nI][10],oFont8)
				oRel:Say(nLin,1870,SubStr(Posicione("SX5",1,xFilial("SX5")+"UX"+aItens[nI][11],"X5_DESCRI"),1,9),oFont8)
			EndIf

			oRel:Say(nLin,2000,Transform(aItens[nI][12],"@E 9,999,999,999,999.99"),oFont8)

			if aScan(aRecSD2, aItens[nI][18]+aItens[nI][19]+aItens[nI][1] ) == 0 //se recno do SD2 ainda nao somou
				nTotQtd += aItens[nI][6]
				aadd(aRecSD2, aItens[nI][18]+aItens[nI][19]+aItens[nI][1])
			else
				lDuplSD2 := .T.
			endif
			nSubVlr	+= aItens[nI][12]
			nTotVlr	+= aItens[nI][12]

			If !lFatConv // Diferente de conveniência

				If cSubAgrup == "F" .Or. cSubAgrup == "M"

					If cSubAgrup == "F" .And. lDifFpg

						If Empty(cFpg)

							cFpg := aItens[nI][13]
						Else
							If nI + 1 <= Len(aItens)

								If cFpg <> aItens[nI + 1][13]

									nLin += 50
									oRel:Line(nLin,2060,nLin,2220)
									oRel:Say(nLin,2000,Transform(nSubVlr,"@E 9,999,999,999,999.99"),oFont8N)
									nLin += 50
									nSubVlr := 0
									cFpg := aItens[nI + 1][13]
								Endif
							Endif
						Endif

					ElseIf cSubAgrup == "M" .And. lDifMotSaq

						If Empty(cMotSaq)

							cMotSaq := aItens[nI][11]
						Else
							If nI + 1 <= Len(aItens)

								If cMotSaq <> aItens[nI + 1][11]

									nLin += 50
									oRel:Line(nLin,2060,nLin,2220)
									oRel:Say(nLin,2000,Transform(nSubVlr,"@E 9,999,999,999,999.99"),oFont8N)
									nLin += 50
									nSubVlr := 0
									cMotSaq := aItens[nI + 1][11]
								Endif
							Endif
						Endif
					Endif

					If lDifFpg .Or. lDifMotSaq

						If nI == Len(aItens)
							nLin += 50
							oRel:Line(nLin,2058,nLin,2220)
							oRel:Say(nLin,2000,Transform(nSubVlr,"@E 9,999,999,999,999.99"),oFont8N)
						Endif
					Endif
				Endif
			EndIf

			nLin += 50
		Next
	Endif
Endif

If Select("QRYITENS") > 0
	QRYITENS->(dbCloseArea())
Endif

Return

/*******************************/
Static Function CompItens(_aFat)
/*******************************/

Local aVlr := {}
Local nLinAux
Local nI

//Final de pagina
If nLin > 2400
	Rod()
	nPag++
	Cabec(_aFat)
	nLin += 100
Endif

oRel:Box(nLin,0053,nLin + 641,2340)

nLin += 25

oRel:Say(nLin,0110,"Sequencia fatura",oFont8)

If !lFatConv // Diferente de conveniência
	oRel:Say(nLin,0515,"Total Litros:",oFont10N)
Else
	oRel:Say(nLin,0515,"Quant. Total:",oFont10N)
EndIf
oRel:Say(nLin,0730,Transform(nTotQtd,"@E 99999999.99"),oFont10N)

if lDuplSD2
	oRel:Say(nLin,0960,"* Quantidade já listada em outro titulo, por pertercer a mesma venda.",oFont6)
	oRel:Say(nLin+25,0960,"   Portanto não será somada na quantidade total.",oFont6)
endif

oRel:Say(nLin,1755,"Total Faturado:",oFont10N)
oRel:Say(nLin,1952,Transform(nTotVlr,"@E 9,999,999,999,999.99"),oFont10N)

//Fatura Flexível
If nVlrAcres > 0 .Or. nVlrDecres > 0

	If nVlrAcres > 0

		oRel:Say(nLin + 50,1755,"Acréscimo:",oFont10N)
		oRel:Say(nLin + 50,1952,Transform(nVlrAcres,"@E 9,999,999,999,999.99"),oFont10N)

		If nVlrDecres > 0

			oRel:Say(nLin + 100,1755,"Desconto:",oFont10N)
			oRel:Say(nLin + 100,1952,Transform(nVlrDecres,"@E 9,999,999,999,999.99"),oFont10N)
		Endif
	Else
		If nVlrDecres > 0

			oRel:Say(nLin + 50,1755,"Desconto:",oFont10N)
			oRel:Say(nLin + 50,1952,Transform(nVlrDecres,"@E 9,999,999,999,999.99"),oFont10N)
		Endif
	Endif
Endif

nLin += 50

oRel:Say(nLin,0110,cFil + _aFat[1],oFont8)
If nLin < 1000

	If !_lArqPdf
		MSBAR3("CODE128"/*cTypeBar*/,NoRound(nLin / 110,1)/*nRow*/,0.9/*nCol*/,cFil + _aFat[1]/*cCode*/,oRel/*oPrint*/,/*lCheck*/,/*Color*/,/*lHorz*/,0.025/*nWidth*/,1.3/*nHeigth*/,.F./*lBanner*/,oFont8/*cFont*/,/*cMode*/,.F./*lPrint*/,/*nPFWidth*/,/*nPFHeigth*/,/*lCmtr2Pix*/)
	Else
		If !_lFatAut
			MSBAR3("CODE128"/*cTypeBar*/,NoRound(nLin / 110,1)/*nRow*/,0.9/*nCol*/,cFil + _aFat[1]/*cCode*/,oRel/*oPrint*/,/*lCheck*/,/*Color*/,/*lHorz*/,0.025/*nWidth*/,1.3/*nHeigth*/,.F./*lBanner*/,oFont10/*cFont*/,/*cMode*/,.F./*lPrint*/,/*nPFWidth*/,/*nPFHeigth*/,/*lCmtr2Pix*/)
		Else
			If nLin < 850
				oRel:FwMsBar("CODE128"/*cTypeBar*/,NoRound((nLin + 1500) / 124,1)/*nRow*/,2.40/*nCol*/,cFil + _aFat[1]/*cCode*/,oRel/*oPrint*/,.F./*lCheck*/,/*Color*/,/*lHorz*/,0.025/*nWidth*/,1.3/*nHeigth*/, , , ,.F.)
			Else
				oRel:FwMsBar("CODE128"/*cTypeBar*/,NoRound((nLin + 1500) / 105,1)/*nRow*/,2.40/*nCol*/,cFil + _aFat[1]/*cCode*/,oRel/*oPrint*/,.F./*lCheck*/,/*Color*/,/*lHorz*/,0.025/*nWidth*/,1.3/*nHeigth*/, , , ,.F.)
			Endif
		Endif
	Endif

ElseIf nLin > 1000 .And. nLin < 2000

	If !_lArqPdf
		MSBAR3("CODE128"/*cTypeBar*/,NoRound(nLin / 113,1)/*nRow*/,0.9/*nCol*/,cFil + _aFat[1]/*cCode*/,oRel/*oPrint*/,/*lCheck*/,/*Color*/,/*lHorz*/,0.025/*nWidth*/,1.3/*nHeigth*/,.F./*lBanner*/,oFont8/*cFont*/,/*cMode*/,.F./*lPrint*/,/*nPFWidth*/,/*nPFHeigth*/,/*lCmtr2Pix*/)
	Else
		If !_lFatAut
			MSBAR3("CODE128"/*cTypeBar*/,NoRound(nLin / 113,1)/*nRow*/,0.9/*nCol*/,cFil + _aFat[1]/*cCode*/,oRel/*oPrint*/,/*lCheck*/,/*Color*/,/*lHorz*/,0.025/*nWidth*/,1.3/*nHeigth*/,.F./*lBanner*/,oFont10/*cFont*/,/*cMode*/,.F./*lPrint*/,/*nPFWidth*/,/*nPFHeigth*/,/*lCmtr2Pix*/)
		Else
			If nLin < 1100
				oRel:FwMsBar("CODE128"/*cTypeBar*/,NoRound((nLin + 1500) / 099,1)/*nRow*/,2.40/*nCol*/,cFil + _aFat[1]/*cCode*/,oRel/*oPrint*/,.F./*lCheck*/,/*Color*/,/*lHorz*/,0.025/*nWidth*/,1.3/*nHeigth*/, , , ,.F.)
			ElseIf nLin > 1100 .And. nLin < 1200
				oRel:FwMsBar("CODE128"/*cTypeBar*/,NoRound((nLin + 1500) / 092,1)/*nRow*/,2.40/*nCol*/,cFil + _aFat[1]/*cCode*/,oRel/*oPrint*/,.F./*lCheck*/,/*Color*/,/*lHorz*/,0.025/*nWidth*/,1.3/*nHeigth*/, , , ,.F.)
			ElseIf nLin > 1200 .And. nLin < 1300
				oRel:FwMsBar("CODE128"/*cTypeBar*/,NoRound((nLin + 1500) / 088,1)/*nRow*/,2.40/*nCol*/,cFil + _aFat[1]/*cCode*/,oRel/*oPrint*/,.F./*lCheck*/,/*Color*/,/*lHorz*/,0.025/*nWidth*/,1.3/*nHeigth*/, , , ,.F.)
			ElseIf nLin > 1300 .And. nLin < 1400
				oRel:FwMsBar("CODE128"/*cTypeBar*/,NoRound((nLin + 1500) / 086,1)/*nRow*/,2.40/*nCol*/,cFil + _aFat[1]/*cCode*/,oRel/*oPrint*/,.F./*lCheck*/,/*Color*/,/*lHorz*/,0.025/*nWidth*/,1.3/*nHeigth*/, , , ,.F.)
			ElseIf nLin > 1400 .And. nLin < 1500
				oRel:FwMsBar("CODE128"/*cTypeBar*/,NoRound((nLin + 1500) / 082,1)/*nRow*/,2.40/*nCol*/,cFil + _aFat[1]/*cCode*/,oRel/*oPrint*/,.F./*lCheck*/,/*Color*/,/*lHorz*/,0.025/*nWidth*/,1.3/*nHeigth*/, , , ,.F.)
			ElseIf nLin > 1500 .And. nLin < 1700
				oRel:FwMsBar("CODE128"/*cTypeBar*/,NoRound((nLin + 1500) / 079,1)/*nRow*/,2.40/*nCol*/,cFil + _aFat[1]/*cCode*/,oRel/*oPrint*/,.F./*lCheck*/,/*Color*/,/*lHorz*/,0.025/*nWidth*/,1.3/*nHeigth*/, , , ,.F.)
			Else
				oRel:FwMsBar("CODE128"/*cTypeBar*/,NoRound((nLin + 1500) / 076,1)/*nRow*/,2.40/*nCol*/,cFil + _aFat[1]/*cCode*/,oRel/*oPrint*/,.F./*lCheck*/,/*Color*/,/*lHorz*/,0.025/*nWidth*/,1.3/*nHeigth*/, , , ,.F.)
			Endif
		Endif
	Endif
Else
	If !_lArqPdf
		MSBAR3("CODE128"/*cTypeBar*/,NoRound(nLin / 115,1)/*nRow*/,0.9/*nCol*/,cFil + _aFat[1]/*cCode*/,oRel/*oPrint*/,/*lCheck*/,/*Color*/,/*lHorz*/,0.025/*nWidth*/,1.3/*nHeigth*/,.F./*lBanner*/,oFont8/*cFont*/,/*cMode*/,.F./*lPrint*/,/*nPFWidth*/,/*nPFHeigth*/,/*lCmtr2Pix*/)
	Else
		If !_lFatAut
			MSBAR3("CODE128"/*cTypeBar*/,NoRound(nLin / 115,1)/*nRow*/,0.9/*nCol*/,cFil + _aFat[1]/*cCode*/,oRel/*oPrint*/,/*lCheck*/,/*Color*/,/*lHorz*/,0.025/*nWidth*/,1.3/*nHeigth*/,.F./*lBanner*/,oFont10/*cFont*/,/*cMode*/,.F./*lPrint*/,/*nPFWidth*/,/*nPFHeigth*/,/*lCmtr2Pix*/)
		Else
			If nLin < 2200
				oRel:FwMsBar("CODE128"/*cTypeBar*/,NoRound((nLin + 1500) / 071,1)/*nRow*/,2.40/*nCol*/,cFil + _aFat[1]/*cCode*/,oRel/*oPrint*/,.F./*lCheck*/,/*Color*/,/*lHorz*/,0.025/*nWidth*/,1.3/*nHeigth*/, , , ,.F.)
			Else
				oRel:FwMsBar("CODE128"/*cTypeBar*/,NoRound((nLin + 1500) / 068,1)/*nRow*/,2.40/*nCol*/,cFil + _aFat[1]/*cCode*/,oRel/*oPrint*/,.F./*lCheck*/,/*Color*/,/*lHorz*/,0.025/*nWidth*/,1.3/*nHeigth*/, , , ,.F.)
			Endif
		Endif
	Endif
Endif

nLin += 270

oRel:Say(nLin,0110,"Valor por extenso",oFont8)

nLin += 80
nLinAux := nLin

aVlr := U_UQuebTxt(Extenso(nTotVlr + nVlrAcres - nVlrDecres),80)

For nI := 1 To Len(aVlr)
	oRel:Say(nLin,0110,aVlr[nI] + Space(1) + Replicate("#",70 - Len(aVlr[nI])),oFont8N)
	nLin += 50
Next

oRel:Say(nLinAux + 100,1740,"Total a Pagar:",oFont12N)
oRel:Say(nLinAux + 100,1915,Transform(nTotVlr + nVlrAcres - nVlrDecres,"@E 9,999,999,999,999.99"),oFont12N)

Return

/******************************/
Static Function DadosFil(_aFat, cObsManual)
/******************************/

Local cGerente 	:= ""
Local aEmails	:= StrTokArr(SuperGetMv("MV_XMAILFT",.F.,"COBRANCA@XXXXXXXX.COM.BR/FATURAMENTO@XXXXXXXX.COM.BR"),"/")
Local cObs		:= SuperGetMv("MV_XOBSFAT",.F.,"") + Space(1) + AllTrim(cObsManual)

Local nI
Local aEndCob	:= {}

nLin += 88

//Final de pagina
If nLin > 2450
	Rod()
	nPag++
	Cabec(_aFat)
	nLin += 100

	oRel:Box(nLin,0053,nLin + 550,2340)
Else
	If _lFatAut .Or. _lArqPdf
		oRel:Box(nLin,0053,nLin + 550,2340)
	Else
		oRel:Box(nLin + 78,0053,nLin + 550,2340)
	Endif
Endif

nLin += 100

dbSelectArea("SM0")
SM0->(dbSetOrder(1))
SM0->(dbSeek(cEmpAnt+cFil))
if SM0->(Eof())
	SM0->(DbSeek(cEmpAnt+cFilAnt))
endif

oRel:Say(nLin + 5,0110,"Razão Social:",oFont8)
oRel:Say(nLin + 5,0570,SM0->M0_NOMECOM,oFont8N)

oRel:Say(nLin + 65,0110,"Cidade:",oFont8)
oRel:Say(nLin + 65,0570,SM0->M0_CIDCOB,oFont8N)

oRel:Say(nLin + 125,0110,"CNPJ:",oFont8)
oRel:Say(nLin + 125,0570,Transform(SM0->M0_CGC,"@R 99.999.999/9999-99"),oFont8N)

oRel:Say(nLin + 185,0110,"Fone Escritório Central:",oFont8)
oRel:Say(nLin + 185,0570,SM0->M0_TEL,oFont8)

oRel:Say(nLin + 245,0110,"Fone / Fax Posto:",oFont8)
oRel:Say(nLin + 245,0570,SM0->M0_TEL,oFont8N)

DbSelectArea("SA1")
SA1->(DbSetOrder(1)) //A1_FILIAL+A1_COD+A1_LOJA
SA1->(DbSeek(xFilial("SA1")+_aFat[2]+_aFat[3]))
cGerente := Posicione("SU7",1,xFilial("SU7")+SA1->A1_XOPCOBR,"U7_NOME")
If !Empty(cGerente)
	oRel:Say(nLin + 305,0110,"Gerente Recebimento:",oFont8)
	oRel:Say(nLin + 305,0570,Upper(cGerente),oFont8N)
Endif

If !Empty(cObs)
	oRel:Say(nLin + 365,0110,Upper(cObs),oFont10N)
Endif

oRel:Say(nLin + 5,1350,"Endereço:",oFont8)
aEndCob := U_UQuebTxt(SM0->M0_ENDCOB,40)

oRel:Say(nLin,1600,aEndCob[1],oFont8N)
If Len(aEndCob) > 1
	nLin += 50
	oRel:Say(nLin,1600,aEndCob[2],oFont8N)
Endif

oRel:Say(nLin + 65,1350,"CEP:",oFont8)
oRel:Say(nLin + 65,1600,Transform(SM0->M0_CEPCOB,"@R 99999-999"),oFont8N)

oRel:Say(nLin + 125,1350,"Insc. Est.:",oFont8)
oRel:Say(nLin + 125,1600,SM0->M0_INSC,oFont8N)

oRel:Say(nLin + 185,1350,"E-mail:",oFont8)
For nI := 1 To Len(aEmails)
	oRel:Say(nLin + 185,1600,aEmails[nI],oFont8N)
	nLin += 50
Next

Return

/****************************/
Static Function Resumo(_aFat)
/****************************/

Local cQry 		:= ""
Local nRecSD2	:= 0
Local lQbrPag	:= .F.

Local nLinAux	:= 0
Local nLinBkp	:= 0

nLin += 400

//Final de pagina
If nLin > 2550
	Rod()
	nPag++
	Cabec(_aFat)
	nLin += 100
Endif

oRel:Say(nLin,0110,"Resumo",oFont10N)

nLin += 50
nLinAux := nLin
nLin += 80

nLinBkp := nLin

If Select("QRYRES") > 0
	QRYRES->(dbCloseArea())
Endif

cQry := "SELECT SB1.B1_COD, SB1.B1_DESC, SD2.D2_PRCVEN AS VLR, SD2.D2_QUANT AS QTD,  SD2.D2_TOTAL AS TOTAL, SD2.R_E_C_N_O_ RECSD2"
cQry += CRLF + " FROM "+RetSqlName("SE1")+" SE1 INNER JOIN "+RetSqlName("SF2")+" SF2 ON SE1.E1_NUM	= SF2.F2_DOC
cQry += CRLF + " AND SE1.E1_PREFIXO	= SF2.F2_SERIE"
//cQry += CRLF + " AND SE1.E1_CLIENTE	= SF2.F2_CLIENTE"
//cQry += CRLF + " AND SE1.E1_LOJA		= SF2.F2_LOJA"
cQry += CRLF + " AND SF2.F2_FILIAL		= SE1.E1_FILORIG"
cQry += CRLF + " AND SF2.D_E_L_E_T_ 	= ' '"

cQry += CRLF + " INNER JOIN "+RetSqlName("SD2")+" SD2 ON SF2.F2_DOC = SD2.D2_DOC"
cQry += CRLF + " AND SF2.F2_SERIE		= SD2.D2_SERIE"
cQry += CRLF + " AND SF2.F2_CLIENTE		= SD2.D2_CLIENTE"
cQry += CRLF + " AND SF2.F2_LOJA		= SD2.D2_LOJA"
cQry += CRLF + " AND SD2.D_E_L_E_T_ 	= ' '"
cQry += CRLF + " AND SD2.D2_FILIAL		= SF2.F2_FILIAL"

cQry += CRLF + " INNER JOIN "+RetSqlName("SB1")+" SB1 ON SD2.D2_COD = SB1.B1_COD"
cQry += CRLF + " AND SB1.D_E_L_E_T_ = ' '"
cQry += CRLF + " AND SB1.B1_FILIAL		= '"+xFilial("SB1",cFilFat)+"'"

cQry += CRLF + " INNER JOIN "+RetSqlName("FI7")+" FI7	ON SE1.E1_PREFIXO = FI7.FI7_PRFORI"
cQry += CRLF + " AND SE1.E1_NUM 		= FI7.FI7_NUMORI"
cQry += CRLF + " AND SE1.E1_PARCELA 	= FI7.FI7_PARORI"
cQry += CRLF + " AND SE1.E1_TIPO 		= FI7.FI7_TIPORI"
cQry += CRLF + " AND SE1.E1_CLIENTE 	= FI7.FI7_CLIORI"
cQry += CRLF + " AND SE1.E1_LOJA 		= FI7.FI7_LOJORI"
cQry += CRLF + " AND FI7.FI7_PRFDES		= '"+_aFat[4]+"'"
cQry += CRLF + " AND FI7.FI7_NUMDES		= '"+_aFat[1]+"'"
cQry += CRLF + " AND FI7.FI7_PARDES		= '"+_aFat[5]+"'"
cQry += CRLF + " AND FI7.FI7_TIPDES		= '"+_aFat[6]+"'"
cQry += CRLF + " AND FI7.FI7_CLIDES		= '"+_aFat[2]+"'"
cQry += CRLF + " AND FI7.FI7_LOJDES		= '"+_aFat[3]+"'"
cQry += CRLF + " AND FI7.D_E_L_E_T_ 	= ' '"
cQry += CRLF + " AND FI7.FI7_FILIAL		= '"+xFilial("FI7",cFilFat)+"'"

cQry += CRLF + " WHERE SE1.D_E_L_E_T_ = ' '"
cQry += CRLF + " AND SE1.E1_FILIAL		= '"+xFilial("SE1",cFilFat)+"'"
//cQry += CRLF + " GROUP BY SB1.B1_COD, SB1.B1_DESC, SD2.D2_PRCVEN"
cQry += CRLF + " ORDER BY SB1.B1_COD, SB1.B1_DESC, SD2.D2_PRCVEN, SD2.R_E_C_N_O_"

cQry := ChangeQuery(cQry)
//MemoWrite("c:\temp\RFATE013.txt",cQry)
TcQuery cQry NEW Alias "QRYRES"

While QRYRES->(!EOF())

	if nRecSD2 == QRYRES->RECSD2
		QRYRES->(DbSkip())
		LOOP
	endif

	//Final de pagina
	If nLin > 3100

		If !_lArqPdf

			//Box geral
			oRel:Box(nLinAux,0053,nLin,2340)
			oRel:FillRect({nLinAux + 3,0054,nLinAux + 60,2340},oBrush)

			//Box horizontal - cima p/ baixo
			oRel:Box(nLinAux,0053,nLinAux + 60,2340)

			//Box 1 - esquerda p/ direita
			oRel:Box(nLinAux,0053,nLin,1001)

			//Box 2 - esquerda p/ direita
			oRel:Box(nLinAux,1001,nLin,1512)

			//Box 3 - esquerda p/ direita
			oRel:Box(nLinAux,1512,nLin,1948)

			//Box 4 - esquerda p/ direita
			oRel:Box(nLinAux,1948,nLin,2340)

			oRel:Say(nLinAux + 10,0478,"Item",oFont8)
			oRel:Say(nLinAux + 10,1211,"Qtd.",oFont8)
			oRel:Say(nLinAux + 10,1621,"R$ Unitario",oFont8)
			oRel:Say(nLinAux + 10,2062,"R$ Total",oFont8)

			lQbrPag := .T.

			Rod()
			nPag++
			Cabec(_aFat)
			nLinAux := nLin + 140
			nLin += 180
		Endif
	Endif

	If !_lArqPdf
		oRel:Say(nLin,0100,QRYRES->B1_DESC,oFont8)
		oRel:Say(nLin,1140,Transform(QRYRES->QTD,"@E 99999999.99"),oFont8)
		oRel:Say(nLin,1570,Transform(QRYRES->TOTAL / QRYRES->QTD,"@E 999,999,999.999"),oFont8)
		oRel:Say(nLin,2000,Transform(QRYRES->TOTAL,"@E 999,999,999.99"),oFont8)
	Endif

	nLin += 50
	nRecSD2 := QRYRES->RECSD2

	QRYRES->(DbSkip())
EndDo

If !_lArqPdf

	If !lQbrPag

		//Box geral
		oRel:Box(nLinAux,0053,nLin,2340)
		oRel:FillRect({nLinAux + 3,0054,nLinAux + 60,2340},oBrush)

		//Box horizontal - cima p/ baixo
		oRel:Box(nLinAux,0053,nLinAux + 60,2340)

		//Box 1 - esquerda p/ direita
		oRel:Box(nLinAux,0053,nLin,1001)

		//Box 2 - esquerda p/ direita
		oRel:Box(nLinAux,1001,nLin,1512)

		//Box 3 - esquerda p/ direita
		oRel:Box(nLinAux,1512,nLin,1948)

		//Box 4 - esquerda p/ direita
		oRel:Box(nLinAux,1948,nLin,2340)

		oRel:Say(nLinAux + 10,0478,"Item",oFont8)
		oRel:Say(nLinAux + 10,1211,"Qtd.",oFont8)
		oRel:Say(nLinAux + 10,1621,"R$ Unitario",oFont8)
		oRel:Say(nLinAux + 10,2062,"R$ Total",oFont8)
	Else
		//Box geral
		oRel:Box(nLinAux,0053,nLin,2340)

		//Box 1 - esquerda p/ direita
		oRel:Box(nLinAux,0053,nLin,1001)

		//Box 2 - esquerda p/ direita
		oRel:Box(nLinAux,1001,nLin,1512)

		//Box 3 - esquerda p/ direita
		oRel:Box(nLinAux,1512,nLin,1948)

		//Box 4 - esquerda p/ direita
		oRel:Box(nLinAux,1948,nLin,2340)
	Endif
Else
	If !lQbrPag

		//Box geral
		oRel:Box(nLinAux,0053,nLin,2340)

		//Box horizontal - cima p/ baixo
		oRel:Box(nLinAux,0053,nLinAux + 60,2340)

		//Box 1 - esquerda p/ direita
		oRel:Box(nLinAux + 60,0053,nLin,1001)

		//Box 2 - esquerda p/ direita
		oRel:Box(nLinAux + 60,1001,nLin,1512)

		//Box 3 - esquerda p/ direita
		oRel:Box(nLinAux + 60,1512,nLin,1948)

		//Box 4 - esquerda p/ direita
		//oRel:Box(nLinAux,1948,nLin,2340)

		oRel:FillRect({nLinAux + 3,0054,nLinAux + 60,2340},oBrush)

		oRel:Say(nLinAux + 10,0478,"Item",oFont8)
		oRel:Say(nLinAux + 10,1211,"Qtd.",oFont8)
		oRel:Say(nLinAux + 10,1621,"R$ Unitario",oFont8)
		oRel:Say(nLinAux + 10,2062,"R$ Total",oFont8)

		nLin := nLinBkp

		QRYRES->(DbGoTop())
		nRecSD2 := 0
		While QRYRES->(!EOF())

			if nRecSD2 == QRYRES->RECSD2
				QRYRES->(DbSkip())
				LOOP
			endif

			//Final de pagina
			If nLin > 3100
				Rod()
				nPag++
				Cabec(_aFat)
				nLinAux := nLin + 140
				nLin += 180
			Endif

			oRel:Say(nLin,0100,QRYRES->B1_DESC,oFont8)
			oRel:Say(nLin,1140,Transform(QRYRES->QTD,"@E 99999999.99"),oFont8)
			oRel:Say(nLin,1570,Transform(QRYRES->TOTAL / QRYRES->QTD,"@E 999,999,999.999"),oFont8)
			oRel:Say(nLin,2000,Transform(QRYRES->TOTAL,"@E 999,999,999.99"),oFont8)

			nLin += 50
			nRecSD2 := QRYRES->RECSD2

			QRYRES->(DbSkip())
		EndDo
	Else
		//Box geral
		oRel:Box(nLinAux,0053,nLin,2340)

		//Box 1 - esquerda p/ direita
		oRel:Box(nLinAux + 60,0053,nLin,1001)

		//Box 2 - esquerda p/ direita
		oRel:Box(nLinAux + 60,1001,nLin,1512)

		//Box 3 - esquerda p/ direita
		oRel:Box(nLinAux + 60,1512,nLin,1948)

		//Box 4 - esquerda p/ direita
		//oRel:Box(nLinAux,1948,nLin,2340)

		nLin := nLinBkp

		QRYRES->(DbGoTop())
		nRecSD2 := 0
		While QRYRES->(!EOF())

			if nRecSD2 == QRYRES->RECSD2
				QRYRES->(DbSkip())
				LOOP
			endif

			//Final de pagina
			If nLin > 3100
				Rod()
				nPag++
				Cabec(_aFat)
				nLinAux := nLin + 140
				nLin += 180
			Endif

			oRel:Say(nLin,0100,QRYRES->B1_DESC,oFont8)
			oRel:Say(nLin,1140,Transform(QRYRES->QTD,"@E 99999999.99"),oFont8)
			oRel:Say(nLin,1570,Transform(QRYRES->TOTAL / QRYRES->QTD,"@E 999,999,999.999"),oFont8)
			oRel:Say(nLin,2000,Transform(QRYRES->TOTAL,"@E 999,999,999.99"),oFont8)

			nLin += 50
			nRecSD2 := QRYRES->RECSD2

			QRYRES->(DbSkip())
		EndDo
	Endif
Endif

Return

/********************/
Static Function Rod()
/********************/

Local cNomEmp := Alltrim(SuperGetMv("MV_XNOMEMP",.F.,SM0->M0_NOMECOM))

If !_lArqPdf
	oRel:Line(3220,0053,3220,2340)
	oRel:Say(3250,0110,"Cliente optante por fatura solidária:",oFont8)
	oRel:Say(3250,0560,IIF(!Empty(cFatSol),cFatSol,"Indefinido"),oFont8)
	oRel:Say(3250,1772, cNomEmp + " - Pág. " + cValToChar(nPag),oFont8)
	oRel:Say(3300,1772,"Protheus - TOTVS Goiás",oFont8)
	oRel:Say(3300,0110,"Classe:",oFont8)
	oRel:Say(3300,0560,cClasse,oFont8)
	oRel:Say(3350,0110,"Possui DANFE relacionada:",oFont8)
	oRel:Say(3350,0560,IIF(lDanfe,"Sim","Não"),oFont8)
Else
	oRel:Line(2820,0053,2820,2340)
	oRel:Say(2850,0110,"Cliente optante por fatura solidária:",oFont8)
	oRel:Say(2850,0560,IIF(!Empty(cFatSol),cFatSol,"Indefinido"),oFont8)
	oRel:Say(2850,1772,cNomEmp + " - Pág. " + cValToChar(nPag),oFont8)
	oRel:Say(2900,1772,"Protheus - TOTVS Goiás",oFont8)
	oRel:Say(2900,0110,"Classe:",oFont8)
	oRel:Say(2900,0560,cClasse,oFont8)
	oRel:Say(2950,0110,"Possui DANFE relacionada:",oFont8)
	oRel:Say(2950,0560,IIF(lDanfe,"Sim","Não"),oFont8)
Endif

oRel:EndPage()

Return

/******************************/
Static Function RetDanfe(_aFat)
/******************************/

Local lRet := .F.
Local cQry := ""

If Select("QRYNFCF") > 0
	QRYNFCF->(dbCloseArea())
Endif

cQry := "SELECT SF2.F2_NFCUPOM"
cQry += CRLF + " FROM "+RetSqlName("SE1")+" SE1 INNER JOIN "+RetSqlName("SF2")+" SF2 ON SE1.E1_NUM	= SF2.F2_DOC"
cQry += CRLF + " AND SE1.E1_PREFIXO	= SF2.F2_SERIE"
cQry += CRLF + " AND SE1.E1_CLIENTE	= SF2.F2_CLIENTE"
cQry += CRLF + " AND SE1.E1_LOJA		= SF2.F2_LOJA"
cQry += CRLF + " AND SF2.D_E_L_E_T_ = ' '"
cQry += CRLF + " AND SF2.F2_FILIAL 	= SE1.E1_FILORIG"

cQry += CRLF + " INNER JOIN "+RetSqlName("FI7")+" FI7	ON SE1.E1_PREFIXO = FI7.FI7_PRFORI"
cQry += CRLF + " AND SE1.E1_NUM 		= FI7.FI7_NUMORI"
cQry += CRLF + " AND SE1.E1_PARCELA 	= FI7.FI7_PARORI"
cQry += CRLF + " AND SE1.E1_TIPO 		= FI7.FI7_TIPORI"
cQry += CRLF + " AND SE1.E1_CLIENTE 	= FI7.FI7_CLIORI"
cQry += CRLF + " AND SE1.E1_LOJA 		= FI7.FI7_LOJORI"
cQry += CRLF + " AND FI7.FI7_PRFDES	= '"+_aFat[4]+"'"
cQry += CRLF + " AND FI7.FI7_NUMDES	= '"+_aFat[1]+"'"
cQry += CRLF + " AND FI7.FI7_PARDES	= '"+_aFat[5]+"'"
cQry += CRLF + " AND FI7.FI7_TIPDES	= '"+_aFat[6]+"'"
cQry += CRLF + " AND FI7.FI7_CLIDES	= '"+_aFat[2]+"'"
cQry += CRLF + " AND FI7.FI7_LOJDES	= '"+_aFat[3]+"'"
cQry += CRLF + " AND FI7.D_E_L_E_T_ = ' '"
cQry += CRLF + " AND FI7.FI7_FILIAL 	= '"+xFilial("FI7",cFilFat)+"'"
cQry += CRLF + " WHERE SE1.D_E_L_E_T_ = ' '"
cQry += CRLF + " AND SE1.E1_FILIAL 	= '"+xFilial("SE1",cFilFat)+"'"

cQry += CRLF + " ORDER BY 1"

cQry := ChangeQuery(cQry)
//MemoWrite("c:\temp\RFATE006.txt",cQry)
TcQuery cQry NEW Alias "QRYNFCF"

While QRYNFCF->(!EOF())

	If !Empty(QRYNFCF->F2_NFCUPOM)
		lRet := .T.
		Exit
	Endif

	QRYNFCF->(DbSkip())
EndDo

If Select("QRYNFCF") > 0
	QRYNFCF->(dbCloseArea())
Endif

Return lRet

/***********************************************************/
Static Function ExcRelPd(cFatura,cDirSrv,cDirFat,cDirFatRel)
/***********************************************************/

//Apaga .rel e .pd_, se houverem
//.pd_
If File(cTmpUser + cFilFat + cFatura + ".pd_")
	Conout("Arquivo " + cTmpUser + cFilFat + cFatura + ".pd_" + " localizado.")
	If FErase(cTmpUser + cFilFat + cFatura + ".pd_") == 0
		Conout("Arquivo " + cTmpUser + cFilFat + cFatura + ".pd_" + " apagado.")
	Endif
Endif
If File("spool\" + cFilFat + cFatura+".pd_")
	Conout("Arquivo " + "spool\" + cFilFat + cFatura + ".pd_" + " localizado.")
	If FErase("spool\" + cFilFat + cFatura+".pd_") == 0
		Conout("Arquivo " + "spool\" + cFilFat + cFatura + ".pd_" + " apagado.")
	Endif
Endif
If File(cDirSrv + cFilFat + cFatura + ".pd_")
	Conout("Arquivo " + cDirSrv + cFilFat + cFatura + ".pd_" + " localizado.")
	If FErase(cDirSrv + cFilFat + cFatura + ".pd_") == 0
		Conout("Arquivo " + cDirSrv + cFilFat + cFatura + ".pd_" + " apagado.")
	Endif
Endif
If File("C:\TOTVS\Protheus11\Data\Protheus_Data_Ofc\system\" + cDirFat + cFilFat + cFatura + ".pd_")
	Conout("Arquivo " + "C:\TOTVS\Protheus11\Data\Protheus_Data_Ofc\system\" + cDirFat + cFilFat + cFatura + ".pd_" + " localizado.")
	If FErase("C:\TOTVS\Protheus11\Data\Protheus_Data_Ofc\system\" + cDirFat + cFilFat + cFatura + ".pd_") == 0
		Conout("Arquivo " + "C:\TOTVS\Protheus11\Data\Protheus_Data_Ofc\system\" + cDirFat + cFilFat + cFatura + ".pd_" + " apagado.")
	Endif
Endif
If File("C:\TOTVS 12\Microsiga\data\data_oficial\system\" + cDirFat + cFilFat + cFatura + ".pd_")
	Conout("Arquivo " + "C:\TOTVS 12\Microsiga\data\data_oficial\system\" + cDirFat + cFilFat + cFatura + ".pd_" + " localizado.")
	If FErase("C:\TOTVS 12\Microsiga\data\data_oficial\system\" + cDirFat + cFilFat + cFatura + ".pd_") == 0
		Conout("Arquivo " + "C:\TOTVS 12\Microsiga\data\data_oficial\system\" + cDirFat + cFilFat + cFatura + ".pd_" + " apagado.")
	Endif
Endif
If File(cDirFatRel + cFilFat + cFatura + ".pd_")
	Conout("Arquivo " + cDirFatRel + cFilFat + cFatura + ".pd_" + " localizado.")
	If FErase(cDirFatRel + cFilFat + cFatura + ".pd_") == 0
		Conout("Arquivo " + cDirFatRel + cFilFat + cFatura + ".pd_" + " apagado.")
	Endif
Endif

//.rel
If File(cTmpUser + cFilFat + cFatura + ".rel")
	Conout("Arquivo " + cTmpUser + cFilFat + cFatura + ".rel" + " localizado.")
	If FErase(cTmpUser + cFilFat + cFatura + ".rel") == 0
		Conout("Arquivo " + cTmpUser + cFilFat + cFatura + ".rel" + " apagado.")
	Endif
Endif
If File("spool\" + cFilFat + cFatura + ".rel")
	Conout("Arquivo " + "spool\" + cFilFat + cFatura + ".rel" + " localizado.")
	If FErase("spool\" + cFilFat + cFatura + ".rel") == 0
		Conout("Arquivo " + "spool\" + cFilFat + cFatura + ".rel" + " apagado.")
	Endif
Endif
If File(cDirSrv + cFilFat + cFatura + ".rel")
	Conout("Arquivo " + cDirSrv + cFilFat + cFatura + ".rel" + " localizado.")
	If FErase(cDirSrv + cFilFat + cFatura + ".rel") == 0
		Conout("Arquivo " + cDirSrv + cFilFat + cFatura + ".rel" + " apagado.")
	Endif
Endif
If File("C:\TOTVS\Protheus11\Data\Protheus_Data_Ofc\system\" + cDirFat + cFilFat + cFatura + ".rel")
	Conout("Arquivo " + "C:\TOTVS\Protheus11\Data\Protheus_Data_Ofc\system\" + cDirFat + cFilFat + cFatura + ".rel" + " localizado.")
	If FErase("C:\TOTVS\Protheus11\Data\Protheus_Data_Ofc\system\" + cDirFat + cFilFat + cFatura + ".rel") == 0
		Conout("Arquivo " + "C:\TOTVS\Protheus11\Data\Protheus_Data_Ofc\system\" + cDirFat + cFilFat + cFatura + ".rel" + " apagado.")
	Endif
Endif
If File("C:\TOTVS 12\Microsiga\data\data_oficial\system\" + cDirFat + cFilFat + cFatura + ".rel")
	Conout("Arquivo " + "C:\TOTVS 12\Microsiga\data\data_oficial\system\" + cDirFat + cFilFat + cFatura + ".rel" + " localizado.")
	If FErase("C:\TOTVS 12\Microsiga\data\data_oficial\system\" + cDirFat + cFilFat + cFatura+".rel") == 0
		Conout("Arquivo " + "C:\TOTVS 12\Microsiga\data\data_oficial\system\" + cDirFat + cFilFat + cFatura + ".rel" + " apagado.")
	Endif
Endif
If File(cDirFatRel + cFilFat + cFatura + ".rel")
	Conout("Arquivo " + cDirFatRel + cFilFat + cFatura + ".rel" + " localizado.")
	If FErase(cDirFatRel + cFilFat + cFatura + ".rel") == 0
		Conout("Arquivo " + cDirFatRel + cFilFat + cFatura + ".rel" + " apagado.")
	Endif
Endif

Return

//Valida a existencia de pasta, e tenta criar os diretórios e subdiretórios
User Function TRETE20A(cPasta)

Local nH
Local lExistDir	:= .T.
Local aFoldes := STRTOKARR(cPasta,"\")
Local cDiretorio := iif(Len(aFoldes)>0,aFoldes[1],"")
	
	For nH:=2 to Len(aFoldes)
		cDiretorio := cDiretorio + "\" + aFoldes[nH]
		If !ExistDir(cDiretorio) //Verifica se existe a pasta.
			nRet := MakeDir(cDiretorio)	//Cria a pasta.
			If nRet != 0 //Verifica se a pasta foi criada.
				lExistDir := .F.
				If IsBlind()
					//Executa Rotina pelo Schedule (prepare environment)
					ConOut( "Não foi possível criar o diretório " + cDiretorio + ". FERROR: " + cValToChar( FError() ) )
				Else
					//Executa Rotina pelo Menu, sem prepare environment.
					MsgStop( "Não foi possível criar o diretório " + cDiretorio + ". FERROR: " + cValToChar( FError() ) )
				EndIf
				Exit //sai fo For nH
			EndIf
		EndIf
	Next nH

Return lExistDir

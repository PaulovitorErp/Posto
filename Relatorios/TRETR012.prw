#include "totvs.ch"
#include "topconn.ch"

/*/{Protheus.doc} TRETR012
Imprime Contrato de Renegocia��o
@author TOTVS
@since 03/05/2019
@version P12
@param _aReg
@return cFatura
/*/

/****************************/
User Function TRETR012(_aReg)
/****************************/

Private oFont8			:= TFont():New('Courier new',,8,,.F.,,,,.F.,.F.) 			//Fonte 8 Normal
Private oFont8N			:= TFont():New('Courier new',,8,,.T.,,,,.F.,.F.) 			//Fonte 8 Negrito
Private oFont10			:= TFont():New('Courier new',,10,,.F.,,,,.F.,.F.) 			//Fonte 10 Normal
Private oFont10N		:= TFont():New('Courier new',,10,,.T.,,,,.F.,.F.) 			//Fonte 10 Negrito
Private oFont10NS		:= TFont():New('Courier new',,10,,.T.,,,,,.T.,.F.) 			//Fonte 10 Negrito e Sublinhado
Private oFont13N		:= TFont():New('Arial',,13,,.T.,,,,.F.,.F.) 				//Fonte 13 Negrito
Private oFont14			:= TFont():New('Arial',,14,,.F.,,,,.F.,.F.) 				//Fonte 14 Normal
Private oFont14N		:= TFont():New('Arial',,14,,.T.,,,,.F.,.F.) 				//Fonte 14 Negrito
Private oFont14NI		:= TFont():New('Times New Roman',,14,,.T.,,,,.F.,.F.,.T.) 	//Fonte 14 Negrito e It�lico
Private oFont16			:= TFont():New('Arial',,16,,.F.,,,,.F.,.F.) 				//Fonte 16 
Private oFont16N		:= TFont():New('Arial',,16,,.T.,,,,.F.,.F.) 				//Fonte 16 Negrito
Private oFont16NI		:= TFont():New('Times New Roman',,16,,.T.,,,,.F.,.F.,.T.) 	//Fonte 16 Negrito e It�lico
Private oFont18			:= TFont():New("Arial",,18,,.F.,,,,,.F.,.F.)				//Fonte 18 Negrito
Private oFont18N		:= TFont():New("Arial",,18,,.T.,,,,,.F.,.F.)				//Fonte 18 Negrito

Private oBrush			:= TBrush():New(,CLR_HGRAY)

Private cStartPath
Private nLin 			
Private oRel			:= TmsPrinter():New("")
Private nPag			:= 0      

Private cNomeCli		:= ""
Private cCnpj			:= ""
Private aPessoas 		:= {}

oRel:setPaperSize(DMPAPER_A4)

oRel:SetPortrait()///Define a orientacao da impressao como retrato
//oRel:SetLandscape() ///Define a orientacao da impressao como paisagem

//oRel:Setup()

NovaPag()
Parte1(_aReg)
Processa({||Titulos(_aReg)},"Aguarde")
Parte2()
Rod()

oRel:Preview()

Return      

/************************/
Static Function NovaPag()
/************************/

nLin := 200
nPag++
oRel:StartPage() //Inicia uma nova pagina

Return

/****************************/
Static Function Parte1(_aReg)
/****************************/

Local cText 	:= ""
Local nLinAux	:= 0
Local nI   
Local nTot		:= 0

oRel:Say(nLin,0450,"INSTRUMENTO PARTICULAR DE RECONHECIMENTO DE D�BITO E AJUSTE PARA PAGAMENTO",oFont10NS)
oRel:Say(nLin + 050,1150,"PARCELADO",oFont10NS)

nLin := 350

DbSelectArea("SM0")   //Filial
SM0->(DbSeek(cEmpAnt+_aReg[1][3])) //Empresa+Filial

cTexto := "CREDOR(A): " + AllTrim(cNomeCli) + Space(1) + AllTrim(SM0->M0_FILIAL) + Space(1) + "(" + AllTrim(SM0->M0_NOMECOM) + "),"
ImpLin(1,nLin,cTexto)
cTexto := "pessoa jur�dica de direito privado, inscrita no CNPJ "+Transform(SM0->M0_CGC,"@R 99.999.999/9999-99")+","
ImpLin(2,nLin + 050,cTexto)
cTexto := "sediada na "+AllTrim(SM0->M0_ENDCOB)+", "+AllTrim(SM0->M0_COMPCOB)+", "+AllTrim(SM0->M0_BAIRCOB)+", CEP "+Transform(SM0->M0_CEPCOB,"@R 99999-999")+","
ImpLin(2,nLin + 100,cTexto)
oRel:Say(nLin + 150,0200,AllTrim(SM0->M0_CIDCOB)+" - "+AllTrim(SM0->M0_ESTCOB)+";",oFont10)

nLin := 600

cCnpj 		:= Posicione("SA1",1,xFilial("SA1")+_aReg[1][15]+_aReg[1][16],"A1_CGC")
cEnd		:= Posicione("SA1",1,xFilial("SA1")+_aReg[1][15]+_aReg[1][16],"A1_END")
cComplem	:= Posicione("SA1",1,xFilial("SA1")+_aReg[1][15]+_aReg[1][16],"A1_COMPLEM")        
cBairro		:= Posicione("SA1",1,xFilial("SA1")+_aReg[1][15]+_aReg[1][16],"A1_BAIRRO")        
cMun		:= Posicione("SA1",1,xFilial("SA1")+_aReg[1][15]+_aReg[1][16],"A1_MUN")        
cEst		:= Posicione("SA1",1,xFilial("SA1")+_aReg[1][15]+_aReg[1][16],"A1_EST")        
cCep		:= Posicione("SA1",1,xFilial("SA1")+_aReg[1][15]+_aReg[1][16],"A1_CEP")  

cNomeCli 	:= _aReg[1][17]  

DbSelectArea("UF7")                                
UF7->(DbSetOrder(1)) //UF7_FILIAL+UF7_CLIENT+UF7_LOJA+UF7_ITEM

If UF7->(DbSeek(xFilial("UF7")+_aReg[1][15]+_aReg[1][16]))

	While UF7->(!EOF()) .And. UF7->UF7_FILIAL == xFilial("UF7") .And. UF7->UF7_CLIENT == _aReg[1][15] .And. UF7->UF7_LOJA == _aReg[1][16]
	    
        AAdd(aPessoas,{AllTrim(UF7->UF7_SOCIO),UF7->UF7_CPF,AllTrim(UF7->UF7_END),AllTrim(UF7->UF7_COMPLE),AllTrim(UF7->UF7_BAIRRO),;
        				AllTrim(UF7->UF7_MUN),UF7->UF7_EST,UF7->UF7_CEP,UF7->UF7_TIPO})
		
		UF7->(DbSkip())
	EndDo
Endif

cTexto := "CONFITENTE/DEVEDOR(A): "+AllTrim(cNomeCli)+", CNPJ "+Transform(cCnpj,"@R 99.999.999/9999-99")+","
ImpLin(1,nLin,cTexto)     
cTexto := ""+AllTrim(cEnd)+", "+IIF(!Empty(cComplem),AllTrim(cComplem)+", ","")+" "+AllTrim(cBairro)+", "+AllTrim(cMun)+" - "+cEst+","
ImpLin(2,nLin + 050,cTexto)
cTexto := "CEP "+Transform(cCep,"@R 99999-999")+", neste ato representada pelo s�cio administrador"
ImpLin(2,nLin + 100,cTexto)

If Len(aPessoas) > 0 
	cTexto := ""+aPessoas[1][1]+", CPF "+Transform(aPessoas[1][2],"@R 999.999.999-99")+", residente e domiciliado na"
	ImpLin(2,nLin + 150,cTexto)  	
	cTexto := ""+aPessoas[1][3]+", "+IIF(!Empty(aPessoas[1][4]),aPessoas[1][4]+", ","")+""+aPessoas[1][5]+", "+aPessoas[1][6]+" - "+aPessoas[1][7]+", CEP "+Transform(aPessoas[1][8],"@R 99999-999")+""
	ImpLin(2,nLin + 200,cTexto)
	If Len(aPessoas) > 1   
		nLinAux := 800
		For nI := 2 To Len(aPessoas)
			If aPessoas[nI][9] == "O" .Or. aPessoas[nI][9] == "A" //S�cio ou Ambos (S�cio e Fiador)
				cTexto := ", e "+aPessoas[nI][1]+", CPF "+Transform(aPessoas[nI][2],"@R 999.999.999-99")+", "+aPessoas[nI][3]+","
				ImpLin(2,nLinAux + 50,cTexto)
				cTexto := ""+IIF(!Empty(aPessoas[nI][4]),aPessoas[nI][4]+",","")+""+aPessoas[nI][5]+", "+aPessoas[nI][6]+" - "+aPessoas[nI][7]+", CEP "+Transform(aPessoas[nI][8],"@R 99999-999")+""
				ImpLin(2,nLinAux + 100,cTexto)
				nLinAux += 100
			Endif
		Next
		nLin += (nLinAux - nLin) + 100
	Else
		nLin += 350
	Endif
Else
	nLin += 200
Endif

nLinAux := 0
 
If Len(aPessoas) > 0
	cTexto := "FIADOR(ES): "+aPessoas[1][1]+", domiciliado na "+aPessoas[1][3]+","
	ImpLin(1,nLin,cTexto)
	cTexto := ""+IIF(!Empty(aPessoas[1][4]),aPessoas[1][4]+", ","")+""+aPessoas[1][5]+", "+aPessoas[1][6]+" - "+aPessoas[1][7]+", CEP "+Transform(aPessoas[1][8],"@R 99999-999")+""
	ImpLin(2,nLin + 050,cTexto)
	If Len(aPessoas) > 1   
		nLinAux := nLin + 50
		For nI := 2 To Len(aPessoas)
			If aPessoas[nI][9] == "F" .Or. aPessoas[nI][9] == "A" //Fiador ou Ambos (S�cio e Fiador)
				cTexto := ", e "+aPessoas[nI][1]+", CPF "+Transform(aPessoas[nI][2],"@R 999.999.999-99")+", "+aPessoas[nI][3]+","
				ImpLin(2,nLinAux + 50,cTexto)
				cTexto := ""+IIF(!Empty(aPessoas[nI][4]),aPessoas[nI][4]+", ","")+""+aPessoas[nI][5]+", "+aPessoas[nI][6]+" - "+aPessoas[nI][7]+", CEP "+Transform(aPessoas[nI][8],"@R 99999-999")+""
				ImpLin(2,nLinAux + 100,cTexto)
				nLinAux += 100
			Endif
		Next
		nLin += (nLinAux - nLin) + 100
	Else
		nLin += 200
	Endif
Endif

cTexto := "Por via do presente instrumento particular, as partes supra nominados t�m entre si,"
ImpLin(1,nLin,cTexto)
cTexto := "de maneira justa e acordada, o presente CONTRATO DE RECONHECIMENTO DE D�BITO E AJUSTE"
ImpLin(2,nLin + 050,cTexto)
cTexto := "PARA PAGAMENTO PARCELADO, que se reger� pelas cl�usulas e condi��es a seguir firmadas."
ImpLin(2,nLin + 100,cTexto)

nLin += 200

oRel:Say(nLin,0400,"I - DO RECONHECIMENTO E CONFISS�O DE D�VIDA",oFont10NS)
cTexto := "CL�USULA PRIMEIRA: Pelo presente instrumento, o(a) CONFITENTE/DEVEDOR(A)"
ImpLin(1,nLin + 50,cTexto)
cTexto := "reconhece e confessa dever, ao(�)s CREDORE(A)S, a quantia l�quida, certa e exig�vel de"
ImpLin(2,nLin + 100,cTexto)       
For nI := 1 To Len(_aReg)
	If _aReg[nI][1] //Selecionado
		If ValType(_aReg[nI][23]) == "C"
			nTot += Val(StrTran(StrTran(cValToChar(_aReg[nI][23]),".",""),",",".")) //Saldo
		Else
			nTot += _aReg[nI][23] //Saldo
		Endif
	Endif
Next
cTexto := "R$ "+AllTrim(Transform(nTot,"@E 9,999,999,999,999.99"))+" ("+Extenso(nTot)+")"
ImpLin(2,nLin + 150,cTexto)
cTexto := "oriunda de transa��o comercial (fornecimento de combust�vel � frota do Confitente/Devedor)"
ImpLin(2,nLin + 200,cTexto)
oRel:Say(nLin + 250,0200,"mantida entre as partes contratantes, conforme planilha abaixo:",oFont10)

Return

/*****************************/
Static Function Titulos(_aReg)
/*****************************/

Local cQry		:= ""
Local cQry2		:= ""
Local nI  
Local nTot 		:= 0   

Local cNf 		:= ""
Local nAux		:= 0 
Local nBkpnLin 	:= 0

nLin += 350

oRel:Box(nLin,200,nLin + 60,450)   
oRel:Say(nLin + 10,210,"Prefixo",oFont10)
oRel:Box(nLin,450,nLin + 60,700)   
oRel:Say(nLin + 10,460,"N�mero",oFont10)
oRel:Box(nLin,700,nLin + 60,950)   
oRel:Say(nLin + 10,710,"Parcela",oFont10)
oRel:Box(nLin,950,nLin + 60,1200)   
oRel:Say(nLin + 10,960,"Tipo",oFont10)
oRel:Box(nLin,1200,nLin + 60,1450)   
oRel:Say(nLin + 10,1210,"Emiss�o",oFont10)
oRel:Box(nLin,1450,nLin + 60,1700)   
oRel:Say(nLin + 10,1460,"Vencimento",oFont10)
oRel:Box(nLin,1700,nLin + 60,1950)   
oRel:Say(nLin + 10,1710,"N. Fiscal",oFont10)  
oRel:Box(nLin,1950,nLin + 60,2200)   
oRel:Say(nLin + 10,1960,"Saldo",oFont10)  

nLin += 60

For nI := 1 To Len(_aReg) 

	If nLin >= 3000
		Rod()
		NovaPag()
	Endif

	If _aReg[nI][1]   
	
		nAux 		:= 0
		nBkpnLin 	:= 0
		
		oRel:Say(nLin + 10,210,_aReg[nI][7],oFont10) //Prefixo
		oRel:Say(nLin + 10,460,_aReg[nI][8],oFont10) //N�mero
		oRel:Say(nLin + 10,710,_aReg[nI][9],oFont10) //Parcela
		oRel:Say(nLin + 10,960,_aReg[nI][4],oFont10) //Tipo
		oRel:Say(nLin + 10,1210,_aReg[nI][21],oFont10) //Emiss�o
		oRel:Say(nLin + 10,1460,_aReg[nI][22],oFont10) //Vencimento

		//Saldo
		If ValType(_aReg[nI][23]) == "C"
			oRel:Say(nLin + 10,1960,AllTrim(_aReg[nI][23]),oFont10)
			nTot += Val(StrTran(StrTran(cValToChar(_aReg[nI][23]),".",""),",","."))
		Else
			oRel:Say(nLin + 10,1960,AllTrim(cValToChar(_aReg[nI][23])),oFont10)
			nTot += _aReg[nI][23]
		Endif
		      
		nBkpnLin := nLin
		
		//N. Fiscal
		If AllTrim(_aReg[nI][7]) == "FAT" //Fatura
		
			If Select("QRYNF") > 0
				QRYNF->(DbCloseArea())
			Endif                                              
			
			cQry := "SELECT DISTINCT SF2.F2_NFCUPOM, SF2.F2_DOC, SF2.F2_SERIE"
			cQry += " FROM "+RetSqlName("SF2")+" SF2 	INNER JOIN "+RetSqlName("SE1")+" SE1	ON SE1.E1_NUM		= SF2.F2_DOC"
			cQry += " 																			AND SE1.E1_PREFIXO	= SF2.F2_SERIE"
			cQry += " 																			AND SE1.E1_CLIENTE	= SF2.F2_CLIENTE"
			cQry += " 																			AND SE1.E1_LOJA		= SF2.F2_LOJA"
			cQry += " 																			AND SE1.D_E_L_E_T_	<> '*'"
			cQry += " 																			AND SE1.E1_FILIAL	= '"+xFilial("SE1")+"'"
			cQry += " 									INNER JOIN "+RetSqlName("FI7")+" FI7	ON SE1.E1_PREFIXO 	= FI7.FI7_PRFORI"
			cQry += " 																			AND SE1.E1_NUM 		= FI7.FI7_NUMORI"
			cQry += " 																			AND SE1.E1_PARCELA 	= FI7.FI7_PARORI"
			cQry += " 																			AND SE1.E1_TIPO 	= FI7.FI7_TIPORI"
			cQry += " 																			AND SE1.E1_CLIENTE 	= FI7.FI7_CLIORI"
			cQry += " 																			AND SE1.E1_LOJA 	= FI7.FI7_LOJORI"
			cQry += " 																			AND FI7.FI7_PRFDES	= '"+_aReg[nI][7]+"'"
			cQry += " 																			AND FI7.FI7_NUMDES	= '"+_aReg[nI][8]+"'"
			cQry += " 																			AND FI7.FI7_PARDES	= '"+_aReg[nI][9]+"'"
			cQry += " 																			AND FI7.FI7_TIPDES	= '"+_aReg[nI][4]+"'"
			cQry += " 																			AND FI7.FI7_CLIDES	= '"+_aReg[nI][16]+"'"
			cQry += " 																			AND FI7.FI7_LOJDES	= '"+_aReg[nI][17]+"'"
			cQry += " 																			AND FI7.D_E_L_E_T_	<> '*'"
			cQry += " 																			AND FI7.FI7_FILIAL	= '"+xFilial("FI7")+"'"
			cQry += " WHERE SF2.D_E_L_E_T_ 	<> '*'"
			cQry += " AND SF2.F2_FILIAL 	= '"+xFilial("SF2")+"'"
			cQry += " AND ((SF2.F2_NFCUPOM	<> ' ' AND SF2.F2_NFCUPOM <> 'MDL-RECORDED') OR (SF2.F2_ESPECIE IN('SPED') AND SF2.F2_NFCUPOM = ''))" //Haja NF s/ CF/NFC-e Ou NF-e PDV
			cQry += " ORDER BY 1"
			
			cQry := ChangeQuery(cQry) 
			//MemoWrite("c:\temp\IMPCONTR.txt",cQry)
			TcQuery cQry NEW Alias "QRYNF"

			If QRYNF->(!EOF())

				While QRYNF->(!EOF())
			
					If Select("QRYNFCF") > 0
						QRYNFCF->(DbCloseArea())
					Endif
			
					cQry2 := "SELECT SF2.F2_FILIAL,"
					cQry2 += " SF2.F2_DOC,"
					cQry2 += " SF2.F2_SERIE,"
					cQry2 += " SF2.F2_EMISSAO"
					cQry2 += " FROM "+RetSqlName("SF2")+" SF2"
					cQry2 += " WHERE SF2.D_E_L_E_T_	<> '*'"
					cQry2 += " AND SF2.F2_FILIAL	= '"+xFilial("SF2")+"'"
			        cQry2 += " AND SF2.F2_DOC		= '"+IIF(!Empty(QRYNF->F2_NFCUPOM),SubStr(QRYNF->F2_NFCUPOM,4,9),QRYNF->F2_DOC)+"'"
			        cQry2 += " AND SF2.F2_SERIE		= '"+IIF(!Empty(QRYNF->F2_NFCUPOM),SubStr(QRYNF->F2_NFCUPOM,1,3),QRYNF->F2_SERIE)+"'"
			        cQry2 += " ORDER BY 1,2,3"
			
					cQry2 := ChangeQuery(cQry2)
					//MemoWrite("c:\temp\QRYNFCF.txt",cQry2)
					TcQuery cQry2 NEW Alias "QRYNFCF"
			
					If QRYNFCF->(!EOF())

						//Controle de linhas dos itens conforme o n�mero de NFs relacionadas
						If !Empty(QRYNFCF->F2_DOC)
							nAux++
						Endif
					
						oRel:Say(nLin + 10,1710,QRYNFCF->F2_SERIE + Space(1) + QRYNFCF->F2_DOC,oFont10)
		
						If QRYNF->(!EOF())
							nLin += 60				
						Endif
					EndIf

					QRYNF->(DbSkip())
				EndDo
			EndIf
		Endif

		If nAux > 0
		
			oRel:Box(nBkpnLin,200,nBkpnLin + (60 * nAux),450)   
			oRel:Box(nBkpnLin,450,nBkpnLin + (60 * nAux),700)   
			oRel:Box(nBkpnLin,700,nBkpnLin + (60 * nAux),950)   
			oRel:Box(nBkpnLin,950,nBkpnLin + (60 * nAux),1200)   
			oRel:Box(nBkpnLin,1200,nBkpnLin + (60 * nAux),1450)   
			oRel:Box(nBkpnLin,1450,nBkpnLin + (60 * nAux),1700)   
			oRel:Box(nBkpnLin,1700,nBkpnLin + (60 * nAux),1950)
			oRel:Box(nBkpnLin,1950,nBkpnLin + (60 * nAux),2200)   
		Else
			oRel:Box(nLin,200,nLin + 60,450)   
			oRel:Box(nLin,450,nLin + 60,700)   
			oRel:Box(nLin,700,nLin + 60,950)   
			oRel:Box(nLin,950,nLin + 60,1200)   
			oRel:Box(nLin,1200,nLin + 60,1450)   
			oRel:Box(nLin,1450,nLin + 60,1700)   
			oRel:Box(nLin,1700,nLin + 60,1950)
			oRel:Box(nLin,1950,nLin + 60,2200)   
		Endif

		nLin += 60
	Endif
Next

oRel:Box(nLin,200,nLin + 60,1950)   
oRel:Say(nLin + 10,1700,"TOTAL",oFont10)
oRel:Box(nLin,1950,nLin + 60,2200)   
oRel:Say(nLin + 10,1960,AllTrim(Transform(nTot,"@E 9,999,999,999,999.99")),oFont10)

If Select("QRYNFCF") > 0
	QRYNFCF->(DbCloseArea())
Endif

If Select("QRYNF") > 0
	QRYNF->(dbCloseArea())
Endif                                              

Return

/***********************/
Static Function Parte2()
/***********************/   

Local nAux := 1     
Local nI    

nLin += 150

If nLin >= 3000
	Rod()
	NovaPag()
Endif

oRel:Say(nLin,0400,"II - ACORDO DE PARCELAMENTO DE D�VIDA VENCIDA",oFont10NS)
cTexto := "CL�USULA SEGUNDA: A d�vida acima reconhecida e confessada ser� paga pelo(a)"
ImpLin(1,nLin + 100,cTexto)
oRel:Say(nLin + 150,0200,"DEVEDOR(A) ao(�)s CREDORE(A)S, nos prazos e valores abaixo descritos:",oFont10)
oRel:Say(nLin + 200,0200,"a) ____________________________________________________ no dia ______________; e,",oFont10)
oRel:Say(nLin + 250,0200,"b) ____________________________________________________ no dia ______________; e,",oFont10)
oRel:Say(nLin + 300,0200,"c) ____________________________________________________ no dia ______________.",oFont10)

nLin += 400 

If nLin >= 3000
	Rod()
	NovaPag()
Endif

cTexto := "Par�grafo primeiro: Os pagamentos ser�o efetuados por via de dep�sito em"
ImpLin(1,nLin,cTexto)
cTexto := "dinheiro ou transfer�ncia banc�ria � conta n� 610-6, vinculada � ag�ncia n� 3684-6, do Banco"
ImpLin(2,nLin + 050,cTexto)
cTexto := "Bradesco SA, pertencente � CREDORA Rede de Postos Maraj� Aparecida de Goi�nia Ltda."
ImpLin(2,nLin + 100,cTexto)
oRel:Say(nLin + 200,0200,"Boleto",oFont10)
oRel:Say(nLin + 300,0200,"Caixa posto",oFont10)

nLin += 400

If nLin >= 3000
	Rod()
	NovaPag()
Endif

cTexto := "Par�grafo segundo: O comprovante de dep�sito ou TED servir� como recibo,"
ImpLin(1,nLin,cTexto)
cTexto := "contudo, para efetiva quita��o ser� imprescind�vel o envio imediato de c�pia do comprovante para"
ImpLin(2,nLin + 050,cTexto)
cTexto := "o e-mail para as CREDORAS, indicando-se, desde j�, o e-mail "+SuperGetMV("TP_MAILJUR",,"jur�dico@xxxxxx.com.br")+" para"
oRel:Say(nLin + 100,0200,"tanto.",oFont10)

nLin += 200

If nLin >= 3000
	Rod()
	NovaPag()
Endif

cTexto := "CL�USULA TERCEIRA: Por este instrumento e na melhor forma de direito, o(a)s"
ImpLin(1,nLin,cTexto)
cTexto := "CONFITENTE(S)/DEVEDOR(A)S reconhece e confessa expressamente e sem nenhuma m�cula,"
ImpLin(2,nLin + 050,cTexto)
cTexto := "v�cio ou qualquer outro impedimento, o seu d�bito (Cl�usula Primeira) junto ao grupo econ�mico"
ImpLin(2,nLin + 100,cTexto)
cTexto := "REDE DE POSTOS MARAJ� - REDE DE POSTOS MARAJ� TOCANTINS LTDA., REDE DE POSTOS"
ImpLin(2,nLin + 150,cTexto)
cTexto := "MARAJ� APARECIDA DE GOI�NIA LTDA, e VAZ, OLIVEIRA E CRUZ LTDA, ora designado(a)s como"
ImpLin(2,nLin + 200,cTexto)
cTexto := "credore(a)s, obrigando-se a pag�-lo no prazo e sob as condi��es consignadas na cl�usula segunda"
ImpLin(2,nLin + 250,cTexto)
oRel:Say(nLin + 300,0200,"deste pacto.",oFont10)

nLin += 400  

If nLin >= 3000
	Rod()
	NovaPag()
Endif

cTexto := "CL�USULA QUARTA: A falta do pagamento de qualquer das parcelas referidas neste"
ImpLin(1,nLin,cTexto)
cTexto := "instrumento nos seus respectivos vencimentos, parafraseando aqui, se for o caso, o"
ImpLin(2,nLin + 050,cTexto)
cTexto := "inadimplemento tempestivo de qualquer boleto ou t�tulo decorrente deste ajuste, por qualquer"
ImpLin(2,nLin + 100,cTexto)
cTexto := "motivo, importar� no vencimento antecipado de todas as presta��es e t�tulos subsequentes,"
ImpLin(2,nLin + 150,cTexto)
cTexto := "independentemente de pr�via comunica��o, notifica��o ou interpela��o judicial ou extrajudicial,"
ImpLin(2,nLin + 200,cTexto)
cTexto := "oportunizando ao(�)s CREDORE(A)S o direito de prosseguir ou propor as a��es"
ImpLin(2,nLin + 250,cTexto)
oRel:Say(nLin + 300,0200,"judiciais/execu��es, se assim entender devido.",oFont10)    

nLin += 400 

If nLin >= 3000
	Rod()
	NovaPag()
Endif

cTexto := "Par�grafo primeiro: A eventual toler�ncia do(a)s CREDORE(A)S, por atraso de" 
ImpLin(1,nLin,cTexto)
cTexto := "algum dos pagamentos, ou quanto ao descumprimento de qualquer disposi��o deste contrato, bem" 
ImpLin(2,nLin + 050,cTexto)
cTexto := "como a negocia��o, transa��o ou composi��o formal de qualquer das condi��es aqui apostas, n�o"
ImpLin(2,nLin + 100,cTexto)
cTexto := "implicar� em ren�ncia de direito, nem constituir�, em hip�tese alguma, nova��o, e, nem mesmo"
ImpLin(2,nLin + 150,cTexto)
cTexto := "prejudicar� o aqui pactuado, por ser ato de mera liberalidade e/ou de interesse comum das partes."
ImpLin(2,nLin + 200,cTexto)       

nLin += 300 

If nLin >= 3000
	Rod()
	NovaPag()
Endif

cTexto := "Par�grafo segundo: O inadimplemento de qualquer uma das parcelas acima"
ImpLin(1,nLin,cTexto)
cTexto := "referidas, em seus respectivos vencimentos, acarretar�, quando de sua efetiva liquida��o (extra ou"
ImpLin(2,nLin + 050,cTexto)
cTexto := "judicial), a obriga��o do(a) CONFITENTE/DEVEDOR(A) e do(s) respectivo(s) FIADOR(ES) de pagar"
ImpLin(2,nLin + 100,cTexto)
cTexto := "ao(�)s CREDORE(A)S, multa contratual de 10% (dez por cento), juros morat�rios de 1% (um por"
ImpLin(2,nLin + 150,cTexto)
cTexto := "cento) ao m�s e corre��o monet�ria pelo INPC, bem como honor�rios advocat�cios, neste ato,"
ImpLin(2,nLin + 200,cTexto)
cTexto := "devidamente ajustados em 20% (vinte por cento), tudo incidente sobre o valor total do d�bito e"
ImpLin(2,nLin + 250,cTexto)
cTexto := "independentemente da interven��o se dar na via administrativa ou judicial, desde que seja efetiva."
ImpLin(2,nLin + 300,cTexto)

nLin += 400

If nLin >= 3000
	Rod()
	NovaPag()
Endif

cTexto := "CLAUSULA QUINTA: O(A) CONFITENTE/DEVEDOR(A) e o(s) respectivo(s)"
ImpLin(1,nLin,cTexto)
cTexto := "FIADOR(ES) declara(m) ter ci�ncia de que o(a)s CREDORE(A)S, em caso do descumprimento de"
ImpLin(2,nLin + 050,cTexto)
cTexto := "qualquer obriga��o deste contrato, mormente de inadimplemento de qualquer parcela ajustada,"
ImpLin(2,nLin + 100,cTexto)
cTexto := "poder�(o) efetuar a inser��o de seu(s) CPF(s) ou CNPJ(s) nos sistemas restritivos de cr�dito (SPC,"
ImpLin(2,nLin + 150,cTexto)
oRel:Say(nLin + 200,0200,"SERASA, CHECK-CHECK, ETC.), bem como o protesto dos boletos, se for o caso.",oFont10)

nLin += 300

If nLin >= 3000
	Rod()
	NovaPag()
Endif

cTexto := "Par�grafo �nico: As CREDORAS efetuar�o a exclus�o das restri��es ao(s) nome(s)"
ImpLin(1,nLin,cTexto)
cTexto := "do(a)s CONFITENTE/DEVEDOR(A) no prazo de at� 10 (dez) dias, contados da efetiva entrega deste"
ImpLin(2,nLin + 050,cTexto)
oRel:Say(nLin + 100,0200,"acordo no escrit�rio corporativo da(s) CREDORA(S).",oFont10)

nLin += 200

If nLin >= 3000
	Rod()
	NovaPag()
Endif

cTexto := "CL�USULA SEXTA: Com ren�ncia expressa ao disposto nos artigos 827, 835 e 838 do"
ImpLin(1,nLin,cTexto)
cTexto := "Novo C�digo Civil Brasileiro, a(s) pessoa(s) indicada(s) abaixo, no presente instrumento"
ImpLin(2,nLin + 050,cTexto)
cTexto := "declara(m)-se e constitui(em)-se FIADOR(ES) e principal(is) pagador(es), solidariamente"
ImpLin(2,nLin + 100,cTexto)
cTexto := "respons�vel(is) pelo pagamento integral de todo e qualquer d�bito resultante de rela��es"
ImpLin(2,nLin + 150,cTexto)
oRel:Say(nLin + 200,0200,"existentes entre o(a) DEVEDOR(A) e o(a)s CREDORE(A)S.",oFont10)

nLin += 300

If nLin >= 3000
	Rod()
	NovaPag()
Endif

cTexto := "Par�grafo primeiro: O(AS) FIADOR(ES) declara(m) que a presente fian�a � dada"
ImpLin(1,nLin,cTexto)
cTexto := "independentemente da composi��o societ�ria do(a) DEVEDOR(A), reconhecendo ainda o presente"
ImpLin(2,nLin + 050,cTexto)
cTexto := "instrumento como t�tulo executivo extrajudicial, nos termos do artigo 585 do C�digo de Processo"
ImpLin(2,nLin + 100,cTexto)
oRel:Say(nLin + 150,0200,"Civil.",oFont10)

nLin += 250

If nLin >= 3000
	Rod()
	NovaPag()
Endif

cTexto := "Par�grafo segundo: O(AS) FIADOR(ES) declara(m) ainda, que a presente fian�a"
ImpLin(1,nLin,cTexto)
cTexto := "permanecer� v�lida at� o efetivo pagamento de todos os d�bitos porventura contra�dos pelo(a)"
ImpLin(2,nLin + 050,cTexto)
oRel:Say(nLin + 100,0200,"DEVEDOR(A) perante o(a)s CREDORE(A)S.",oFont10)

nLin += 200

If nLin >= 3000
	Rod()
	NovaPag()
Endif

cTexto := "CL�USULA S�TIMA: O(A) CONFITENTE/DEVEDOR(A) declara expressamente, neste"
ImpLin(1,nLin,cTexto)
cTexto := "ato, que tem plena ci�ncia do teor do presente instrumento, sendo que o mesmo tem validade"
ImpLin(2,nLin + 050,cTexto)
oRel:Say(nLin + 100,0200,"como confiss�o de d�vida, nos termos do artigo 585 do C�digo de Processo Civil.",oFont10)

nLin += 200

If nLin >= 3000
	Rod()
	NovaPag()
Endif

oRel:Say(nLin,0850,"III - DISPOSI��ES FINAIS E FORO",oFont10)

nLin += 100

If nLin >= 3000
	Rod()
	NovaPag()
Endif

cTexto := "CL�USULA OITAVA: O presente ajuste vincula as partes signat�rias, herdeiros e/ou"
ImpLin(1,nLin,cTexto)
cTexto := "sucessores a qualquer t�tulo, ficando eleito o foro da cidade e comarca de Aparecida de Goi�nia -"
ImpLin(2,nLin + 050,cTexto)
cTexto := "Goi�s, como o �nico competente para dirimir qualquer quest�o que possa resultar, renunciando a"
ImpLin(2,nLin + 100,cTexto)
oRel:Say(nLin + 150,0200,"qualquer outro, por mais privilegiado que seja.",oFont10)

nLin += 250

If nLin >= 3000
	Rod()
	NovaPag()
Endif

cTexto := "CL�USULA NONA: O(A)S CREDORE(A)S s�o reconhecidas, neste ato, de forma"
ImpLin(1,nLin,cTexto)
cTexto := "irretrat�vel, irrevog�vel e inexor�vel, sem nenhuma m�cula ou v�cio, pelo(s)"
ImpLin(2,nLin + 050,cTexto)
cTexto := "CONFITENTE/DEVEDOR(A), como solidariamente detentoras do direito credit�cio ora tratado,"
ImpLin(2,nLin + 100,cTexto)
cTexto := "podendo exigir ou reclamar, em conjunto ou separadamente, o cumprimento ou a execu��o do"
ImpLin(2,nLin + 150,cTexto)
oRel:Say(nLin + 200,0200,"presente instrumento.",oFont10)

nLin += 300

If nLin >= 3000
	Rod()
	NovaPag()
Endif

cTexto := "CL�USULA D�CIMA: O presente instrumento tem for�a de t�tulo executivo"
ImpLin(1,nLin,cTexto)
cTexto := "extrajudicial, nos termos do artigo 585, II, do C�digo de Processo Civil, sendo celebrado em car�ter"
ImpLin(2,nLin + 050,cTexto)
oRel:Say(nLin + 100,0200,"irrevog�vel e irretrat�vel.",oFont10)

nLin += 200

If nLin >= 3000
	Rod()
	NovaPag()
Endif

cTexto := "CL�USULA D�CIMA PRIMEIRA: O(A) CONFITENTE/DEVEDOR(A) se"
ImpLin(1,nLin,cTexto)
cTexto := "compromete(m) entregar pessoalmente ou encaminhar pelos Correios, no prazo de at� 5 (cinco)"
ImpLin(2,nLin + 050,cTexto)
cTexto := "dias, contados do recebimento deste acordo por e-mail, �(s) CREDORA(S) uma via do original do"
ImpLin(2,nLin + 100,cTexto)
cTexto := "presente acordo devidamente assinada pelo(a)s CONFITENTE(S)/DEVEDOR(A)S, bem como pelo(s)"
ImpLin(2,nLin + 150,cTexto)
cTexto := "FIADOR(ES), com as firmas devidamente reconhecidas em cart�rio, para o endere�o do escrit�rio"
ImpLin(2,nLin + 200,cTexto)
cTexto := "corporativo da(s) CREDORA(S) situado na Rua Teresina, 380, Evidence Office, Maraj� Rede de"
ImpLin(2,nLin + 250,cTexto)
oRel:Say(nLin + 300,0200,"Servi�os S/A, 5� andar, Bairro Alto da Gl�ria, Goi�nia-Goi�s, CEP 74.815-715.",oFont10)

nLin += 400

If nLin >= 3000
	Rod()
	NovaPag()
Endif

cTexto := "E por estarem justas e aven�adas, assinam o presente instrumento, feito em 03 (tr�s)"
ImpLin(1,nLin,cTexto)
oRel:Say(nLin + 050,0200,"vias de um s� teor e forma, na presen�a das testemunhas abaixo.",oFont10)
 
nLin += 150

If nLin >= 3000
	Rod()
	NovaPag()
Endif

oRel:Say(nLin,0400,"Aparecida de Goi�nia - Goi�s, "+StrZero(Day(dDataBase),2)+" de "+RetMes()+" de "+StrZero(Year(dDataBase),4)+"",oFont10)

nLin += 200

If nLin >= 3000
	Rod()
	NovaPag()
Endif

oRel:Line(nLin,200,nLin,1150)
oRel:Line(nLin,1250,nLin,2200)

//Assinatura cliente
oRel:Say(nLin,0400,AllTrim(cNomeCli),oFont10)
oRel:Say(nLin + 050,0400,"CNPJ "+Transform(cCnpj,"@R 99.999.999/9999-99"),oFont10)
oRel:Say(nLin + 100,0400,"CONFITENTE/DEVEDOR(A)",oFont10)

//Assinatura Maraj�
oRel:Say(nLin,1350,"REDE DE POSTOS MARAJ� TOCANTINS LTDA",oFont10)
oRel:Say(nLin + 050,1350,"CNPJ 26.638.338/0001-67 e 26.638.338/0002-49",oFont10)
oRel:Say(nLin + 100,1350,"REDE DE POSTOS MARAJ� APARECIDA DE GOI�NIA",oFont10)
oRel:Say(nLin + 150,1350,"(VAZ E CRUZ LTDA)",oFont10)
oRel:Say(nLin + 200,1350,"CNPJ 05.443.159/0001-02",oFont10)
oRel:Say(nLin + 250,1350,"VAZ, OLIVEIRA E CRUZ LTDA",oFont10)
oRel:Say(nLin + 300,1350,"CNPJ 10.505.190/0001-52",oFont10)

nLin += 400

If nLin >= 3000
	Rod()
	NovaPag()
Endif

//Fiadores
oRel:Say(nLin,0200,"FIADOR(ES):",oFont10)

If Len(aPessoas) > 1   
	nLinAux := nLin + 50
	For nI := 2 To Len(aPessoas)
		If aPessoas[nI][9] == "F" .Or. aPessoas[nI][9] == "A" //Fiador ou Ambos (S�cio e Fiador)
			oRel:Say(nLinAux + 50,0200,""+cValToChar(nAux)+")_____________________________________________________",oFont10)
			oRel:Say(nLinAux + 100,0200,AllTrim(aPessoas[nI][1]),oFont10)
			oRel:Say(nLinAux + 150,0200,"CPF "+Transform(aPessoas[nI][2],"@R 999.999.999-99"),oFont10)
			nLinAux += 150                               
			nAux++
		Endif
	Next
	nLin += (nLinAux - nLin) + 100
Endif                        

If nLin >= 3000
	Rod()
	NovaPag()
Endif

//Testemunhas
oRel:Say(nLin,0200,"TESTEMUNHAS:",oFont10)

oRel:Say(nLin + 100,0200,"1)_____________________________________________________",oFont10)
oRel:Say(nLin + 150,0200,"CPF: ________.________.________-________",oFont10)

oRel:Say(nLin + 200,0200,"2)_____________________________________________________",oFont10)
oRel:Say(nLin + 250,0200,"CPF: ________.________.________-________",oFont10)

Return

/********************/
Static Function Rod()
/********************/
Local cNomEmp 	:= SuperGetMv("MV_XNOMEMP",.F.,"MV_XNOMEMP")

nLin := 3350
oRel:Say(nLin + 020,0200,"____________________________________",oFont8N,,/*CLR_HGRAY*/)
oRel:Say(nLin + 020,0200,"INSTRUMENTO PARTICULAR DE RECONHECIMENTO DE D�VIDA - "+Alltrim(cNomEmp)+" X "+AllTrim(cNomeCli)+"",oFont8,,/*CLR_HGRAY*/)
oRel:Say(nLin + 020,2250,cValToChar(nPag),oFont10N,,/*CLR_HGRAY*/)
oRel:EndPage()

Return            

/*****************************************/
Static Function ImpLin(_nTp,_nLin,_cTexto)
/*****************************************/

If _nTp == 1 //Par�grafo
	oRel:Say(_nLin,0400,Justif(_cTexto + (Space(086 - Len(_cTexto)))),oFont10)
ElseIf _nTp == 2 //Texto
	oRel:Say(_nLin,0200,Justif(_cTexto + (Space(095 - Len(_cTexto)))),oFont10)
Else //Par�grafo parcial
	oRel:Say(_nLin,0820,Justif(_cTexto + (Space(067 - Len(_cTexto)))),oFont10)
Endif

Return

/******************************/
Static Function Justif(cString)
/******************************/

Local cRetorno
Local nTam
Local cSpacs
Local nWinter 
Local nCont
Local cJustString

nTam   	:= Len(AllTrim(cString))
cSpacs	:= Len(cString) - nTam

If cSpacs <= 0
   Return cString
Endif

cString	:= AllTrim(cString)
nWinter	:= 0
nCont  	:= Len(cString)

Do While nCont > 0

   	If SubStr(cString,nCont,1) = Space(1)

      	nWinter++

      	Do While SubStr(cString,nCont,1) = Space(1) .And. nCont > 0
          	--nCont
      	EndDo
   	Else
      	nCont--
	Endif
EndDo

If nWinter = 0
	Return cString
Endif

Do While cSpacs > 0

   	cRetorno	:= ""
   	nCont   	:= Len(cString)

   	Do While nCont>0

      	If SubStr(cString,nCont,1) = Space(1)
         	If cSpacs > 0
            	cRetorno += SPACE(1)
            	--cSpacs
         	Endif
      	Endif

      	cRetorno += SubStr(cString,nCont,1) 
      	nCont--
   	EndDo

   	cString:=""

	For nCont = Len(cRetorno) To 1 Step -1
		cString += SubStr(cRetorno,nCont,1)
   	Next
EndDo

cJustString:=""

For nCont = Len(cRetorno) To 1 Step -1
	cJustString += SubStr(cRetorno,nCont,1)
Next

Return cJustString

/***********************/
Static Function RetMes()
/***********************/

Local aMes  := Array(12)

aMes[01] := "janeiro"
aMes[02] := "fevereiro"
aMes[03] := "marco"
aMes[04] := "abril"
aMes[05] := "maio"
aMes[06] := "junho"
aMes[07] := "julho"
aMes[08] := "agosto"
aMes[09] := "setembro"
aMes[10] := "outubro"
aMes[11] := "novembro"
aMes[12] := "dezembro"

Return aMes[Month(dDataBase)]

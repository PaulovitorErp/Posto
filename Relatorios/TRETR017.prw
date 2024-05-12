#INCLUDE "rwmake.ch"
#INCLUDE "topconn.ch"
#INCLUDE "Protheus.ch"


/*/{Protheus.doc} TRETR017
Registro de Anแlise da Qualidade da Amostra-Testemunha
Impressใo de ticket
@author Ricardo Quintais
@since 24/04/2014
@version 1.0
@return nulo

@type define
/*/

#DEFINE TAMLINCABEC 55

User Function TRETR017()

    ///////////////////////////////////////////////////////////////////////
    ///Variaveis de fontes                                             ////
    ///////////////////////////////////////////////////////////////////////
	Private oFont6		:= TFONT():New("ARIAL",7,6,.T.,.F.,5,.T.,5,.T.,.F.) ///Fonte 6 Normal
	Private oFont6N 	:= TFONT():New("ARIAL",7,6,,.T.,,,,.T.,.F.) ///Fonte 6 Negrito
	Private oFont8		:= TFONT():New("ARIAL",9,8,.T.,.F.,5,.T.,5,.T.,.F.) ///Fonte 8 Normal
	Private oFont8N 	:= TFONT():New("ARIAL",8,8,,.T.,,,,.T.,.F.) ///Fonte 8 Negrito
	Private oFont10 	:= TFONT():New("ARIAL",9,10,.T.,.F.,5,.T.,5,.T.,.F.) ///Fonte 10 Normal
	Private oFont10S	:= TFONT():New("ARIAL",9,10,.T.,.F.,5,.T.,5,.T.,.T.) ///Fonte 10 Sublinhando
	Private oFont10N 	:= TFONT():New("ARIAL",9,10,,.T.,,,,.T.,.F.) ///Fonte 10 Negrito
	Private oFont11		:= TFONT():New("ARIAL",11,11,,.F.,,,,.T.,.F.) ///Fonte 11 Normal
	Private oFont11NS	:= TFONT():New("ARIAL",11,11,,.T.,,,,.T.,.T.) ///Fonte 11 Negrito e Sublinhado
	Private oFont11N	:= TFONT():New("ARIAL",11,11,,.T.,,,,.T.,.F.) ///Fonte 11 Negrito
	Private oFont12		:= TFONT():New("ARIAL",12,12,,.F.,,,,.T.,.F.) ///Fonte 12 Normal
	Private oFont12NS	:= TFONT():New("ARIAL",12,12,,.T.,,,,.T.,.T.) ///Fonte 12 Negrito e Sublinhado
	Private oFont12N	:= TFONT():New("ARIAL",12,12,,.T.,,,,.T.,.F.) ///Fonte 12 Negrito
	Private oFont13		:= TFONT():New("ARIAL",13,13,,.F.,,,,.T.,.F.) ///Fonte 13 Normal
	Private oFont13NS	:= TFONT():New("ARIAL",13,13,,.T.,,,,.T.,.T.) ///Fonte 13 Negrito e Sublinhado
	Private oFont13N	:= TFONT():New("ARIAL",13,13,,.T.,,,,.T.,.F.) ///Fonte 13 Negrito
	Private oFont16 	:= TFONT():New("ARIAL",16,16,,.F.,,,,.T.,.F.) ///Fonte 16 Normal
	Private oFont16N	:= TFONT():New("ARIAL",16,16,,.T.,,,,.T.,.F.) ///Fonte 16 Negrito
	Private oFont16NS	:= TFONT():New("ARIAL",16,16,,.T.,,,,.T.,.T.) ///Fonte 16 Negrito e Sublinhado
	Private oFont20N	:= TFONT():New("ARIAL",20,20,,.T.,,,,.T.,.F.) ///Fonte 20 Negrito
	Private oFont22N	:= TFONT():New("ARIAL",22,22,,.T.,,,,.T.,.F.) ///Fonte 22 Negrito
    
    ///////////////////////////////////////////////////////////////////////
    ///Variaveis Impressao                                             ////
    ///////////////////////////////////////////////////////////////////////
	Private cStartPath
	Private nLin 	:= 100
	Private oPrint	:= TMSPRINTER():New("Registro de Anแlise da Qualidade da Amostra-Testemunha")
	Private nPag	:= 1
	Private oBrush1 := TBrush():New( , CLR_GRAY)
    
    ////////////////////////////////////////////////////////////////////////
    ///Outras Variaveis
    ////////////////////////////////////////////////////////////////////////
	Private cPerg   := "TRETR017"
	Private cFilZE5 := xFilial("ZE5")  //Tabela de amostra de combustivel
    
    //Particular
	Private _cNMent := ''
	Private _cCNPJCli := ''
	Private cNumDe:=''

	oPrint:SetPaperSize(9)
	oPrint:SetPortrait()///Define a orientacao da impressao como retrato

	ValidPerg()
	If !Pergunte(cPerg,.t.)
		Return
	Endif
	cNumDe:= mv_par01

	cQry:="SELECT * FROM "+RetSqlName("ZE5")+" ZE5 WHERE ZE5.D_E_L_E_T_ <> '*' AND ZE5_FILIAL = '"+cFilZE5+"' AND ZE5_PEDIDO='"+cNumDe+"'"

	If SELECT("TRB") > 0
		TRB->(DBCLOSEAREA())
	Endif
	cQry := ChangeQuery(cQry)
	TcQuery cQry New Alias "TRB" // Cria uma nova area com o resultado do query
	dbSelectArea("TRB")
	TRB->(dbGoTop())

	While !TRB->(Eof())
	
		DbSelectArea("ZE3")
		dbseek(xFilial('ZE3')+TRB->ZE5_CRC)
		fCabecalho()
		nLin+=150
	
		oPrint:Box(nLin,140,nLin+100,2300)
		oPrint:Say(nLin+40, 160, AllTrim("Razใo Social do Posto Revendedor: "+AllTrim(SM0->M0_NOME)), oFont13N)
		nLin+=100
		oPrint:Box(nLin,140,nLin+100,2300)
		oPrint:Say(nLin+40, 160, AllTrim("Cnpj do Posto Revendedor: "+SM0->M0_CGC), oFont13N)
		nLin+=100
		oPrint:Box(nLin,140,nLin+100,2300)
		oPrint:Say(nLin+40, 160, AllTrim("Endere็o do Posto Revendedor: "+SM0->M0_ENDCOB), oFont13N)
		nLin+=100
		oPrint:Box(nLin,140,nLin+100,2300)
		oPrint:Say(nLin+40, 160, AllTrim("Bairro: "+AllTrim(SM0->M0_BAIRCOB)+"/Cidade: "+AllTrim(SM0->M0_CIDCOB)+"/Estado: "+AllTrim(SM0->M0_ESTCOB)), oFont13N)
		nLin+=100
		oPrint:Box(nLin,140,nLin+100,2300)
		oPrint:Say(nLin+20,800,AllTrim('Dados do Recebimento'), oFont20N)
		nLin+=100


		oPrint:Box(nLin,140,nLin+100,2300)
		oPrint:Say(nLin+40, 160, AllTrim("Produto: "), oFont13N)
		impCol(1)
		nLin+=100
		oPrint:Box(nLin,140,nLin+100,2300)
		oPrint:Say(nLin+40, 160, AllTrim("Vol. Receb.(Litros):"), oFont13N)
		impCol(2)
		nLin+=100
		oPrint:Box(nLin,140,nLin+100,2300)
		oPrint:Say(nLin+40, 160, AllTrim("Data coleta: "), oFont13N)
		impCol(3)
		nLin+=100
		oPrint:Box(nLin,140,nLin+100,2300)
		oPrint:Say(nLin+40, 160, AllTrim("Distribuidor: "), oFont13N)
		impCol(4)
		nLin+=100
		oPrint:Box(nLin,140,nLin+100,2300)
		oPrint:Say(nLin+40, 160, AllTrim("Cnpj do Distribuidor: "), oFont13N)
		impCol(5)
		nLin+=100
		oPrint:Box(nLin,140,nLin+100,2300)
		oPrint:Say(nLin+40, 160, AllTrim("Transportador: "), oFont13N)
		impCol(6)
		nLin+=100
		oPrint:Box(nLin,140,nLin+100,2300)
		oPrint:Say(nLin+40, 160, AllTrim("Cnpj Transportador: "), oFont13N)
		impCol(7)
		nLin+=100
		oPrint:Box(nLin,140,nLin+100,2300)
		oPrint:Say(nLin+40, 160, AllTrim("N.F. do Produto:"), oFont13N)
		impCol(8)
		nLin+=100
		oPrint:Box(nLin,140,nLin+100,2300)
		oPrint:Say(nLin+40, 160, AllTrim("Placa Caminh./Reboq."), oFont13N)
		impCol(9)
		nLin+=100
		oPrint:Box(nLin,140,nLin+100,2300)
		oPrint:Say(nLin+40, 160, AllTrim("Nome do motorista: "), oFont13N)
		impCol(10)
		nLin+=100
		oPrint:Box(nLin,140,nLin+100,2300)
		oPrint:Say(nLin+40, 160, AllTrim("CPF do Motorista: "), oFont13N)
		impCol(11)
		nLin+=100
		oPrint:Box(nLin,140,nLin+100,2300)
		oPrint:Say(nLin+40, 160, AllTrim("Nome do analista: "), oFont13N)
		impCol(12)
		nLin+=100
		oPrint:Box(nLin,140,nLin+100,2300)
		oPrint:Say(nLin+20,800,AllTrim('Resultados da Anแlise'), oFont20N)
		nLin+=100
		
        
        oPrint:Box(nLin,140,nLin+100,2300)
		oPrint:Say(nLin+40, 160, AllTrim("Aspecto: "), oFont13N)
		impCol1(1,'ZE5_ASPECT')
		nLin+=100
		oPrint:Box(nLin,140,nLin+100,2300)
		oPrint:Say(nLin+40, 160, AllTrim("Cor: "), oFont13N)
		impCol1(2,'ZE5_COR')
		nLin+=100
		oPrint:Box(nLin,140,nLin+100,2300)
		oPrint:Say(nLin+40, 160, AllTrim("Massa Especํf.a 20: "), oFont13N)
		impCol1(3,'ZE5_MASSA')
		nLin+=100
		oPrint:Box(nLin,140,nLin+100,2300)
		oPrint:Say(nLin+40, 160, AllTrim("Teor Alcool na Gas.: "), oFont13N)
		impCol1(4,'ZE5_TEOR')
		nLin+=100
		oPrint:Box(nLin,140,nLin+100,2300)
		oPrint:Say(nLin+40, 160, AllTrim("Teor Alc. no AEHC: "), oFont13N)
		impCol1(5,'ZE5_TEORE')
	
		nLin+=300
		oPrint:Say(nLin+40, 160, AllTrim("Responsแvel pelo Preenchimento   ________________________________________:"), oFont16N)
		nlin+=100
		oPrint:Say(nLin+40, 160, AllTrim("Assinatura   ____________________________________: "), oFont16N)
	
		fRodape()
	
		TRB->(DbSkip())
	EndDO

	TRB->(DbCloseArea())

	oPrint:Preview()

Return

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  ณfCabecalho บAutor ณTotvs               บ Data ณ  13/08/2012 บฑฑ
ฑฑฬออออออออออุออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDesc.     ณ Funcao que monta o cabe็alho da rotina                     บฑฑ
ฑฑบ          ณ                                                            บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณ RCRC003                                                   บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
*/
Static Function fCabecalho()

    Local nTamTit        := 0

	oPrint:StartPage() // Inicia uma nova pagina
	cStartPath := GetPvProfString(GetEnvServer(),"StartPath","ERROR",GetAdv97())
	cStartPath += If(Right(cStartPath, 1) <> "\", "\", "")
	nLin := 147


	SM0->(DbSetOrder(1))
	SM0->(DbSeek(cempant+cfilant)) //cempant EMPRESA QUE ESTม LOGADA E cfilant ษ A FILIAL QUE ESTA LOGADA
	_cCNPJCli := SM0->M0_CGC
	_cNMent   := SM0->M0_NOMECOM
	_cEndent  := SM0->M0_ENDENT
	_cBaiEnt  := SM0->M0_BAIRENT
	_cCidEnt  := SM0->M0_CIDENT
	_cEstEnt  := SM0->M0_ESTENT
	_cCepEnt  := SM0->M0_CEPENT
	_cInscri  := SM0->M0_INSC

	oPrint:Box(nLin,145,nLin+285,540)
	oPrint:SayBitmap(nLin+30, 165, cStartPath + iif(FindFunction('U_URETLGRL'),U_URETLGRL(),"lgrl01.bmp"), 342, 109)///Impressao da Logo

	oPrint:Box(nLin,540,nLin+120,1850)
	cTodaStr := "Registro das Anแlises de Qualidade"
	nTamTit  := Len(cTodaStr)
// 1095 ้ o meio da celula, iniciando a impressใo do meio menos a metade do tamanho da string
	oPrint:Say(nLin+30, 1195, cTodaStr, oFont12n,,,,2)//1120 - ((nTamTit/2)*20)

	oPrint:Box(nLin,1850,nLin+120,2300)
	oPrint:Say(nLin+15, 2075, "Emissใo:", oFont11N,,,,2) //1985
	oPrint:Say(nLin+60, 2075, DtoC(date()), oFont11,,,,2) //1985

	nLin+=120
	oPrint:Box(nLin,540,nLin+165,2300)

	cTodaStr := AllTrim(SM0->M0_NOMECOM)
	nTamTit  := Len(cTodaStr)
// 1095 ้ o meio da celula, iniciando a impressใo do meio menos a metade do tamanho da string
	oPrint:Say(nLin+10, 1400, cTodaStr, oFont12n,,,,2) //1420 - ((nTamTit/2)*20)

	cTodaStr := AllTrim(SM0->M0_ENDENT)+", "+AllTrim(SM0->M0_BAIRENT)+", "+AllTrim(SM0->M0_CIDENT)+" - "+AllTrim(SM0->M0_ESTENT)
	nTamTit  := Len(cTodaStr)
// 1095 ้ o meio da celula, iniciando a impressใo do meio menos a metade do tamanho da string
	oPrint:Say(nLin+50, 1400, cTodaStr, oFont10n,,,,2)//1480 - ((nTamTit/2)*20)

	cTodaStr := "CEP: "+AllTrim(Transform(SM0->M0_CEPENT,"@R 99.999-999")) +" / "+"FONE: "+AllTrim(Transform(SM0->M0_TEL,"@R (99) 999999999"))
	nTamTit  := Len(cTodaStr)
// 1095 ้ o meio da celula, iniciando a impressใo do meio menos a metade do tamanho da string
	oPrint:Say(nLin+90, 1400, cTodaStr, oFont12n,,,,2) //1440 - ((nTamTit/2)*20)

	nLin+=250

Return NIL


/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  ณfRodape   บAutor  ณTotvs               บ Data ณ  13/08/2012 บฑฑ
ฑฑฬออออออออออุออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDesc.     ณ funcao que monta o rodape						          บฑฑ
ฑฑบ          ณ                                                            บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณ AP                                                         บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
*/

Static Function fRodape()

	oPrint:EndPage()

return NIL

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  ณRCRC003   บAutor  ณMicrosiga           บ Data ณ  04/30/14   บฑฑ
ฑฑฬออออออออออุออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDesc.     ณImprime as colunas dos itens da nota fiscal                 บฑฑ
ฑฑบ          ณLayout oficial/legal possui 5 colunas somente               บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณ AP                                                         บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
*/

Static Function ImpCol(_nCampo)

	Local _aARea:=GetArea()
    Local _x
     
	//TODO fazer altera็ใ para vir de forma distinta as amostras, quando hแ divisใo do abastecimento nos tanques
	cQry:="SELECT * FROM "+RetSqlName("ZE5")+" ZE5 WHERE ZE5.D_E_L_E_T_ <> '*' AND ZE5_FILIAL = '"+cFilZE5+"' AND ZE5_PEDIDO='"+TRB->ZE5_PEDIDO+"'"
	If SELECT("TRB1") > 0
		TRB1->(DBCLOSEAREA())
	Endif
	cQry := ChangeQuery(cQry)
	TcQuery cQry New Alias "TRB1" // Cria uma nova area com o resultado do query

	Do case
	case _nCampo==1
		_cCpo:='ZE5_PRODUT'
	case _nCampo==2
		_cCpo:='ZE5_VOLUME'
	case _nCampo==3
		_cCpo:='ZE5_DATA'
	case _nCampo==4
		_cCpo:='ZE5_FORNEC'
	case _nCampo==5 //CNPJ DISTRIBUIDOR
		_cCpo:=''
	case _nCampo==6 //TRANSPORTADOR  (ZE3)
		_cCpo:=''
	case _nCampo==7   //CNPJ TRANSPORTADOR   (ZE3)
		_cCpo:=''
	case _nCampo==8
		_cCpo:='ZE5_DOC'
	case _nCampo==9//PLACA CAMINHAO (ZE3)
		_cCpo:=''
	case _nCampo==10 //NOME MOTORISTA
		_cCpo:=''
	case _nCampo==11 //RG DO MOTORISTA
		_cCpo:=''
	case _nCampo==12
		_cCpo:='ZE5_ANALIS'
	EndCase

	_nCol:=320
	ncol:=520
	ncol1:=350
 	
	For _x:=1 to 5
		ncol:=nCol+_nCol
		oPrint:Box(nLin,(ncol-180),nLin+100,2300)
	
		While TRB1->(!Eof())
        	   
			If !(Empty(_cCpo))
				if _cCpo=='ZE5_PRODUT'
					oPrint:Say(nLin+40,nCol1+_ncol,SubStr(Posicione('SB1',1,xFilial('SB1')+TRB1->&_cCpo,'B1_DESC'),1,15),oFont8N)
				elseif _cCpo=='ZE5_DATA'
					_cData:=AllTrim(TRB1->&_cCpo)
					_cData:=Dtoc(Stod(_cData))
					oPrint:Say(nLin+40,nCol1+_ncol, ((AllTrim(_cData))),oFont10N)
				else
					if valtype(TRB1->&_cCpo) == "N"
						oPrint:Say(nLin+40,nCol1+_ncol, cValToChar(TRB1->&_cCpo),oFont10N)
					else
						oPrint:Say(nLin+40,nCol1+_ncol, AllTrim(TRB1->&_cCpo),oFont10N)
					endif
				Endif
			Else
				Do Case
				case _nCampo==5 //CNPJ DISTRIBUIDOR
					oPrint:Say(nLin+40,nCol1+_ncol, AllTrim(Posicione("SA2",1,xFilial("SA2")+ZE5->ZE5_FORNEC,"A2_CGC")),oFont10N)
				case _nCampo==6 //TRANSPORTADOR  (ZE3)
					oPrint:Say(nLin+40,nCol1+_ncol, AllTrim(Posicione("SA4",1,xFilial("SA4")+ZE3->ZE3_TRANSP,"A4_NOME")),oFont10N)
				case _nCampo==7 //CNPJ TRANSPORTADOR   (ZE3)
					oPrint:Say(nLin+40,nCol1+_ncol, AllTrim(Posicione("SA4",1,xFilial("SA4")+ZE3->ZE3_TRANSP,"A4_CGC")),oFont10N)
				case _nCampo==9 //PLACA CAMINHAO (ZE3)
					oPrint:Say(nLin+40,nCol1+_ncol, AllTrim(ZE3->ZE3_VEICUL),oFont10N)
				case _nCampo==10 //NOME MOTORISTA
					oPrint:Say(nLin+40,nCol1+_ncol, AllTrim(Posicione("DA4",3,xFilial("DA4")+ZE3->ZE3_MOTORI,"DA4_NOME")),oFont8N)
				case _nCampo==11 //RG DO MOTORISTA
					oPrint:Say(nLin+40,nCol1+_ncol, AllTrim(Posicione("DA4",3,xFilial("DA4")+ZE3->ZE3_MOTORI,"DA4_CGC")),oFont10N)
				EndCase
			Endif
		
			TRB1->(DbSkip())
			ncol1+=325 //ncol1+_ncol
		Enddo
	Next

	RestArea(_aArea)

Return


Static Function ImpCol1(_nCampo,_ccpo)

	local _aArea	:=	GetArea()
    Local _x

	//TODO fazer altera็ใ para vir de forma distinta as amostras, quando hแ divisใo do abastecimento nos tanques
	cQry:="SELECT * FROM "+RetSqlName("ZE5")+" ZE5 WHERE ZE5.D_E_L_E_T_ <> '*' AND ZE5_FILIAL = '"+cFilZE5+"' AND ZE5_PEDIDO='"+TRB->ZE5_PEDIDO+"'"
	If SELECT("TRB1") > 0
		TRB1->(DBCLOSEAREA())
	Endif
	cQry := ChangeQuery(cQry)
	TcQuery cQry New Alias "TRB1" // Cria uma nova area com o resultado do query

    /*_nCol:=296 
    ncol:=520                             
    ncol1:=520*/

	_nCol:=320
	ncol:=520
	ncol1:=350

	For _x:=1 to 5
		ncol:=nCol+_nCol
		oPrint:Box(nLin,(ncol-180),nLin+100,2300)
	
		While TRB1->(!Eof())
			//ncol:=ncol1+_ncol
		
			Do Case
			case _nCampo == 1 //ASPECTO
				oPrint:Say(nLin+40,nCol1+_ncol, AllTrim(iif(TRB1->ZE5_ASPECT=='1','Limpido','Turvo')),oFont11N)
			case _nCampo == 2 //COR
				oPrint:Say(nLin+40,nCol1+_ncol, AllTrim(Posicione("SX5",1,xFilial("SX5")+'70'+TRB1->ZE5_COR,'X5_DESCRI')),oFont11N)
			case _nCampo == 3 //MASSA
				oPrint:Say(nLin+40,nCol1+_ncol, cValToChar(TRB1->ZE5_MASSA),oFont11N)
			case _nCampo == 4 //TEOR ALCOOL NA GASOLINA
				oPrint:Say(nLin+40,nCol1+_ncol, AllTrim(TRB1->ZE5_TEOR),oFont11N)
			case _nCampo == 5 //TEOR ALCOOL AEHC
				oPrint:Say(nLin+40,nCol1+_ncol, AllTrim(TRB1->ZE5_TEORE),oFont11N)
			EndCase
		
			TRB1->(DbSkip())
			ncol1+=325 //ncol1+_ncol
		Enddo
	Next
	RestArea(_aArea)

Return

/*ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑฺฤฤฤฤฤฤฤฤฤฤฤยฤฤฤฤฤฤฤฤฤฤฤฤยฤฤฤฤฤฤฤยฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤยฤฤฤฤฤฤยฤฤฤฤฤฤฤฤฤฤฟฑฑ
ฑฑณPrograma   ณ ValidPerg  ณ Autor ณ TOTVS                     ณ Data ณ13/08/2012ณฑฑ
ฑฑรฤฤฤฤฤฤฤฤฤฤฤลฤฤฤฤฤฤฤฤฤฤฤฤมฤฤฤฤฤฤฤมฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤมฤฤฤฤฤฤมฤฤฤฤฤฤฤฤฤฤดฑฑ
ฑฑณDescricao  ณ Cria perguntas no SX1	                                         ณฑฑ
ฑฑรฤฤฤฤฤฤฤฤฤฤฤลฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤดฑฑ
ฑฑณObservacao ณ Sugestao de Claudio Ferreira                                     ณฑฑ
ฑฑณ           ณ                                                                  ณฑฑ
ฑฑภฤฤฤฤฤฤฤฤฤฤฤมฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤูฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿*/

Static Function ValidPerg()

	dbSelectArea("SX1")
	dbSetOrder(1)
	cPerg 	:=	PADR(cPerg,10)
	U_uAjusSx1( cPerg,"01","Numero P.C. :","."     ,"."       ,"mv_CH1","C",06,0,0,"G","","SC7ZE5","","","MV_PAR01","","","","","","","","","","","","","","","","")
    //U_uAjusSx1( cPerg,"02","Ate Numero         ?","."     ,"."       ,"mv_CH2","C",06,0,0,"G","","SC7ZE5","","","MV_PAR02","","","","","","","","","","","","","","","","")

Return

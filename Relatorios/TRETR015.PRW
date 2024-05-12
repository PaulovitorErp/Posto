#INCLUDE "RWMAKE.CH"
#INCLUDE "TOPCONN.CH"     
#INCLUDE "PROTHEUS.CH"

#DEFINE DMPAPER_A4 9    // A4 210 x 297 mm

/*/{Protheus.doc} User Function TRETR015
Relatorio de recibo de pagamento

@type  Function
@author Gabriel
@since 26/02/2020
@version version
@param param_name, param_type, param_descr
/*/
User Function TRETR015(_Exec)

//------------------------------------------------------
// Define Variaveis 
//------------------------------------------------------
Private cPerg   :="TRETR015"
Private oFont, oPrn
Private cCGCPict
Private lPrimPag :=.t.
Private lEnc     := .f.
Private _MsExec	 := .f.
Default _Exec := {}

//------------------------------------------------------
// Verifica as perguntas selecionadas                          
//------------------------------------------------------
//Variaveis utilizadas para parametros 
//mv_par01	     	  Do Prefixo       
//mv_par02	     	  Do Titulo	      
//mv_par03              Da Parcela  	 
//mv_par04	     	  Do Tipo	       
//mv_par05	     	  Ate Prefixo  		
//mv_par06              Ate Titulo	       
//mv_par07              Ate Parcela      	
//mv_par08              Ate Tipo   	          
//mv_par09              De Dt. Emissao   		
//mv_par10              Ate Dt. Emisao        
//mv_par11              Duas Vias?      	
//mv_par12              De Cliente   	    
//mv_par13              De Loja        		
//mv_par14              Ate Cliente   	    
//mv_par15              Ate Loja        	
//------------------------------------------------------

_MsExec	:= len(_Exec) > 0 .and. ValType(_Exec) == "A"
ValidPerg()
if !_MsExec .AND. !Pergunte(cPerg, !_MsExec)
	Return
ElseIf Len(_Exec) <> 15 .and. _MsExec
	Aviso("ERRO","Informar ao Dept. T.I. diferença nos parametros vindo do Faturamento, a Duplicata poderá ser impressa pela opção Relatorios ->Específicos -> Impressao de Duplicatas",{"OK"})
	Return
ElseIf _MsExec
	MV_PAR01 := _Exec[01]	// Prefixo
	MV_PAR02 := _Exec[02]	// Nr. 
	MV_PAR03 := _Exec[03]	// Parcela
	MV_PAR04 := _Exec[04]	// Tipo
	MV_PAR05 := _Exec[05]
	MV_PAR06 := _Exec[06]
	MV_PAR07 := _Exec[07]
	MV_PAR08 := _Exec[08]	
	MV_PAR09 := _Exec[09]	// Emissïao
	MV_PAR10 := _Exec[10]	
	MV_PAR11 := _Exec[11]
	MV_PAR12 := _Exec[12]
	MV_PAR13 := _Exec[13]
	MV_PAR14 := _Exec[14]
	MV_PAR15 := _Exec[15]
EndIf

RptStatus({|| R150Imp()})

Return

/*/{Protheus.doc} Static Function R150Imp
Faz a busca dos dados e a impressao do relatorio

@type  Function
@author Gabriel
@since 26/02/2020
@version version
@param param_name, param_type, param_descr
/*/
Static Function R150Imp()

	Local _cQry := ""
	Local _cFat := ""
	Local li := 0
	Local nX := 0
	Local aDados := {}
	Local aDadosAux := {}

	//------------------------------------------------------
	// Definir as pictures
	//------------------------------------------------------
	cCGCPict:=PesqPict("SA1","A1_CGC")

	oFont1 := TFont():New( "Arial",,16,,.t.,,,,,.f. )
	oFont2 := TFont():New( "Arial",,16,,.f.,,,,,.f. )
	oFont3 := TFont():New( "Arial",,10,,.t.,,,,,.f. )
	oFont4 := TFont():New( "Arial",,10,,.f.,,,,,.f. )
	oFont5 := TFont():New( "Arial",,06,,.t.,,,,,.f. )
	oFont6 := TFont():New( "Arial",,08,,.f.,,,,,.f. )
	oFont7 := TFont():New( "Arial",,14,,.t.,,,,,.f. )
	oFont8 := TFont():New( "Arial",,14,,.f.,,,,,.f. )
	oFont9 := TFont():New( "Arial",,12,,.t.,,,,,.f. )
	oFont10:= TFont():New( "Arial",,12,,.f.,,,,,.f. )
	oFont20:= TFont():New( "Arial",,20,,.f.,,,,,.f. )

	oFont1c := TFont():New( "Courier New",,16,,.t.,,,,,.f. )
	oFont2c := TFont():New( "Courier New",,16,,.f.,,,,,.f. )
	oFont3c := TFont():New( "Courier New",,10,,.t.,,,,,.f. )
	oFont4c := TFont():New( "Courier New",,10,,.f.,,,,,.f. )
	oFont5c := TFont():New( "Courier New",,09,,.t.,,,,,.f. )
	oFont6c := TFont():New( "Courier New",,09,,.T.,,,,,.f. )
	oFont7c := TFont():New( "Courier New",,14,,.t.,,,,,.f. )
	oFont8c := TFont():New( "Courier New",,14,,.f.,,,,,.f. )
	oFont9c := TFont():New( "Courier New",,12,,.t.,,,,,.f. )
	oFont10c:= TFont():New( "Courier New",,12,,.f.,,,,,.f. )

	//------------------------------------------------------
	//Pesquisa Numero da Cotacao
	//------------------------------------------------------
	//dbSelectArea("SE1")
	//dbSetOrder(1)
	//dbSeek(xFilial("SE1")+mv_par01+mv_par02+mv_par03+mv_par04)

	SetRegua(RecCount())

	_cQry := ""
	_cQry += " SELECT "
	_cQry += " E1_PREFIXO "
	_cQry += " ,E1_NUM "
	_cQry += " ,E1_PARCELA "
	_cQry += " ,E1_TIPO "
	_cQry += " ,E1_CLIENTE "
	_cQry += " ,E1_LOJA "
	_cQry += " ,E1_EMISSAO "
	_cQry += " ,E1_VENCTO "
	_cQry += " ,E1_VALOR "
	_cQry += " ,E1_DESCONT "
	_cQry += " FROM "+RetSqlName("SE1")
	_cQry += " WHERE D_E_L_E_T_ <> '*' "
	_cQry += " AND E1_FILIAL = '" + xFilial("SE1") + "' "
	_cQry += " AND E1_PREFIXO BETWEEN '" + MV_PAR01 + "' AND '" + MV_PAR05 + "' "
	_cQry += " AND E1_NUM BETWEEN '" + MV_PAR02 + "' AND '" + MV_PAR06 + "' "
	_cQry += " AND E1_PARCELA BETWEEN '" + MV_PAR03 + "' AND '" + MV_PAR07 + "' "
	_cQry += " AND E1_TIPO BETWEEN '" + MV_PAR04 + "' AND '" + MV_PAR08 + "' "
	_cQry += " AND E1_EMISSAO BETWEEN '" + DtoS(MV_PAR09) + "' AND '" + DtoS(MV_PAR10) + "' "
	_cQry += " AND E1_CLIENTE BETWEEN '" + MV_PAR12 + "' AND '" + MV_PAR14 + "' "
	_cQry += " AND E1_LOJA BETWEEN '" + MV_PAR13 + "' AND '" + MV_PAR15 + "' "
	_cQry += " ORDER BY E1_PREFIXO, E1_NUM, E1_PARCELA, E1_TIPO, E1_EMISSAO "

	_cQry := ChangeQuery(_cQry)

	TcQuery _cQry New Alias "ZSE1"
		
	dbSelectArea("ZSE1") 
	ZSE1->(dbGoTop())

	While !ZSE1->(Eof())
		IncRegua()
		
		_cFat   := ALLTRIM(ZSE1->E1_PREFIXO)+"/"+ALLTRIM(ZSE1->E1_NUM)

		SE5->(DbSetOrder(7)) //E5_FILIAL+E5_PREFIXO+E5_NUMERO+E5_PARCELA+E5_TIPO+E5_CLIFOR+E5_LOJA+E5_SEQ
		if SE5->(DbSeek(xFilial('SE5')+ZSE1->E1_PREFIXO+ZSE1->E1_NUM+ZSE1->E1_PARCELA+ZSE1->E1_TIPO+ZSE1->E1_CLIENTE+ZSE1->E1_LOJA ))
			
			aDadosAux := {}
			While SE5->(!Eof()) .AND. SE5->(E5_FILIAL+E5_PREFIXO+E5_NUMERO+E5_PARCELA+E5_TIPO+E5_CLIFOR+E5_LOJA) == xFilial('SE5')+ZSE1->E1_PREFIXO+ZSE1->E1_NUM+ZSE1->E1_PARCELA+ZSE1->E1_TIPO+ZSE1->E1_CLIENTE+ZSE1->E1_LOJA
				if !SE5->(TemBxCanc()) //verifica se SE5 posicionado tem estorno/cancelamento
					aadd(aDadosAux, { "LBOK" , SE5->E5_DATA , SE5->E5_VALOR, .F. } )
				endif

				SE5->(DbSkip())
			enddo

			if !_MsExec .AND. len(aDadosAux) > 1
				EscolheSE5(aDadosAux)		
			endif

			_cA1Cod := ALLTRIM(ZSE1->E1_CLIENTE)+"/"+ALLTRIM(ZSE1->E1_LOJA)

			if _MsExec //quando execauto (chamado ponto de entrada)
				aadd(aDados, { nil , _cFat, ZSE1->E1_VALOR, ZSE1->E1_PARCELA, StoD(ZSE1->E1_EMISSAO), ;
							StoD(ZSE1->E1_VENCTO), ZSE1->E1_DESCONT, SA1->A1_NOME, _cA1Cod, SA1->A1_END, ;
							SA1->A1_MUN, SA1->A1_EST, SA1->A1_CEP, SA1->A1_ENDCOB, SA1->A1_CGC, SA1->A1_INSCR, ;
							aDadosAux[len(aDadosAux)][3], aDadosAux[len(aDadosAux)][2] })
			else
				for nX := 1 to len(aDadosAux)
					if aDadosAux[nX][1] == "LBOK"
						aadd(aDados, { nil , _cFat, ZSE1->E1_VALOR, ZSE1->E1_PARCELA, StoD(ZSE1->E1_EMISSAO), ;
								StoD(ZSE1->E1_VENCTO), ZSE1->E1_DESCONT, SA1->A1_NOME, _cA1Cod, SA1->A1_END, ;
								SA1->A1_MUN, SA1->A1_EST, SA1->A1_CEP, SA1->A1_ENDCOB, SA1->A1_CGC, SA1->A1_INSCR, ;
								aDadosAux[nX][3], aDadosAux[nX][2] })
					endif
				next nX
			endif

		endif

		ZSE1->(dbSkip())
	EndDo

	For nX := 1 to len(aDados)
		
		If MV_PAR11 == 1
			li := 0
		else
			if MOD(nX, 2) > 0
				li := 0
			else
				li := 1600
			endif
		endif

		//imprime a primeira duplicata da folha
		ImpRec(li, aDados[nX][2], aDados[nX][3], aDados[nX][4], aDados[nX][5], aDados[nX][6], ;
			aDados[nX][7], aDados[nX][8], aDados[nX][9], aDados[nX][10], aDados[nX][11], ;
			aDados[nX][12], aDados[nX][13], aDados[nX][14], aDados[nX][15], aDados[nX][16], ;
			aDados[nX][17], aDados[nX][18])
		
		//imprime a segunda duplicata (espelho) na mesma folha
		If MV_PAR11 == 1
			li := 1600
			ImpRec(li, aDados[nX][2], aDados[nX][3], aDados[nX][4], aDados[nX][5], aDados[nX][6], ;
				aDados[nX][7], aDados[nX][8], aDados[nX][9], aDados[nX][10], aDados[nX][11], ;
				aDados[nX][12], aDados[nX][13], aDados[nX][14], aDados[nX][15], aDados[nX][16], ;
				aDados[nX][17], aDados[nX][18])
		EndIf

	next nX

	//para finalizar ultima pagina, caso qtd impressao for impar
	If li == 0
		oPrn:EndPage()
	EndIf

	//------------------------------------------------------
	//Se em disco, desvia para Spool
	//------------------------------------------------------
	If lEnc
		oPrn:Preview()
		MS_FLUSH()
	EndIf

	ZSE1->(dbCloseArea())
	//fErase(_cQry + ".DBF")
	//fErase(_cQry + ordBagExt())

Return


/*/{Protheus.doc} Static Function ImpRec
Faz a impressao do relatorio

@type  Function
@author Gabriel
@since 26/02/2020
@version version
@param param_name, param_type, param_descr
/*/
Static Function ImpRec(li, cFatura, nValor, cOrdem, dEmissao, dVencimento, nDesconto, cNome, cCod, cEnd, cMun, cEst, cCep, cEndC, cCgc, cInsc, nValorPago, dDatPag)

If lPrimPag
	lPrimPag	:= .f.
	lEnc    	:= .t.
	oPrn  		:= TMSPrinter():New()
	oPrn:Setup()
EndIF

If li == 0
	oPrn:StartPage()
Endif	

oPrn:Say( li, 0020, " ",oFont,100 ) // startando a impressora

//Cabecalho (Enderecos da Empresa e Fornecedor) 
oPrn:Box( 0050 + li, 0050, 1500 + li,2400) // Box Total
oPrn:Box( 0050 + li, 0050, 0409 + li,2400) // Box Divisao Cabecalho
oPrn:Box( 0050 + li, 0050, 0409 + li,1175) // Box do Logo Tipo
oPrn:Box( 0409 + li, 0050, 1500 + li,0400) // Box Assinatura do Emitente

oPrn:Box( 0409 + li, 0400, 0585 + li,1813) // Box Dados Duplicata 1

oPrn:Box( 0409 + li, 0400, 0585 + li,0683) // Box Dados FATURA32 !
oPrn:Box( 0409 + li, 0400, 0491 + li,0683) // Box Dados FATURA 2
oPrn:Say( 0412 + li, 0460, "FATURA NUM.",oFont6,100 )
oPrn:Say( 0456 + li, 0410, "PREFIXO / N.TITULO",oFont6,100 )

oPrn:Box( 0409 + li, 0683, 0585 + li,1175) // Box Dados VALOR TOTAL FATURA
oPrn:Box( 0409 + li, 0683, 0491 + li,1175) // Box Dados VALOR TOTAL FATURA 2
oPrn:Say( 0412 + li, 0822, "VALOR TOTAL",oFont6,100 )
oPrn:Say( 0456 + li, 0822, "DA FATURA R$",oFont6,100 )

oPrn:Box( 0409 + li, 1175, 0585 + li,1404) // Box Dados VALOR PAGO
oPrn:Box( 0409 + li, 1175, 0491 + li,1404) // Box Dados VALOR PAGO  2

oPrn:Say( 0412 + li, 1253, "VALOR",oFont6,100 )
oPrn:Say( 0456 + li, 1251, "PAGO R$",oFont6,100 )

oPrn:Box( 0409 + li, 1404, 0585 + li,1813) // Box Dados VENCIMENTO
oPrn:Box( 0409 + li, 1404, 0491 + li,1813) // Box Dados VENCIMENTO 2

oPrn:Box( 0409 + li, 1813, 0491 + li,2400) // Box Dados forma de pagamento
oPrn:Box( 0409 + li, 1813, 0585 + li,2400)	// Box Dados forma de pagamento

oPrn:Say( 0435 + li, 1532, "VENCIMENTO",oFont6,100 )
oPrn:Say( 0435 + li, 1980, "FORMA DE PAGAMENTO",oFont6,100 )

//oPrn:Say( 0412 + li, 1823, "PARA USO DA INST.FINANCEIRA",oFont5,100 )
oPrn:Say( 0412 + li, 0060, "PARA USO DA INST.FINANCEIRA",oFont5,100 )

oPrn:Box( 0585 + li, 0400, 0807 + li,2400) // Box Dados Duplicata

oPrn:Box( 0807 + li, 0400, 1050 + li,2400) // Box Dados Cliente

oPrn:Box( 1050 + li, 0400, 1250 + li,2400) // Box Valor Extenso

//oPrn:Say( 0596 + li, 0424, "DESCONTO DE",oFont6,100 ) //retirar
oPrn:Say( 0656 + li, 1100, "RECIBO DE PAGAMENTO",oFont20,100 )
oPrn:Say( 0819 + li, 0424, "CLIENTE:",oFont6,100 )
oPrn:Say( 0819 + li, 1755, "CODIGO/LOJA:",oFont6,100 )
oPrn:Say( 0865 + li, 0424, "ENDERECO:",oFont6,100 )
oPrn:Say( 0911 + li, 0424, "MUNICIPIO:",oFont6,100 )
oPrn:Say( 0911 + li, 1755, "ESTADO:",oFont6,100 )
oPrn:Say( 0911 + li, 2106, "CEP:",oFont6,100 )      
//oPrn:Say( 0957 + li, 0424, "Pï¿½A. PAGATO:",oFont6,100 )
oPrn:Say( 1003 + li, 0424, "CNPJ N.:",oFont6,100 )
oPrn:Say( 1003 + li, 1755, "INSC.ESTADUAL:",oFont6,100 )

oPrn:Say( 1070 + li, 0424, "VALOR",oFont6,100 )
oPrn:Say( 1140 + li, 0424, "POR",oFont6,100 )
oPrn:Say( 1210 + li, 0424, "EXTENSO",oFont6,100 )

oPrn:Say( 1270 + li, 0424, "RECONHECEMOS O RECEBIMENTO DESTA FATURA NA IMPORTANCIA ACIMA DESCRITA.",oFont6,100 )
oPrn:Say( 1310 + li, 0424, "POR SER VERDADE, FIRMO O PRESENTE.",oFont6,100 )

//oPrn:Say( 1430 + li, 0424, "______/_____/_______",oFont6,100 ) //ALTERAR A DATA
//oPrn:Say( 1460 + li, 0424, "   DATA DO ACEITE   ",oFont6,100 )

oPrn:Say( 1430 + li, 1755, "_____________________________",oFont6,100 )
oPrn:Say( 1460 + li, 1755, "     ASSINATURA DO EMISSOR",oFont6,100 )

//			li   	  col   li  	  col
//logo da empresa
//oPrn:SayBitmap( 0070 + li,0200,"logo_inf.bmp",0800,0300)
cStartPath := GetPvProfString(GetEnvServer(),"StartPath","ERROR",GetAdv97())
oPrn:SayBitmap( 0070 + li, 0200, cStartPath + iif(FindFunction('U_URETLGRL'),U_URETLGRL(),"lgrl01.bmp"), 0800, 0300)
//campo de assinatura
//oPrn:SayBitmap( 0526 + li, 0070, cStartPath + "assinfor.bmp", 0300, 0800) //retirar

/*
oPrn:EndPage()
oPrn:SetLandscape() //vertical
oPrn:StartPage()
oPrn:Say( 0526 + li, 0070, "_______________________________________________________",oFont6,100 )
oPrn:Say( 0556 + li, 0070, "       "+SM0->M0_NOMECOM,oFont6,100 )
oPrn:EndPage()
oPrn:StartPage()
oPrn:SetPortrait() //horizontal
*/

oPrn:Say( 0070 + li, 1213, SM0->M0_NOMECOM,oFont9,100 )
oPrn:Say( 0150 + li, 1213, UPPER(ALLTRIM(SM0->M0_ENDCOB)) + ", " + UPPER(ALLTRIM(SM0->M0_COMPCOB))+" - "+ UPPER(ALLTRIM(SM0->M0_BAIRCOB)) ,oFont6,100 )
oPrn:Say( 0180 + li, 1213, "CEP: " + AllTrim(Transform(SM0->M0_CEPCOB,"@R 99.999-999"))+" - "+UPPER(ALLTRIM(SM0->M0_CIDCOB))+" - "+ UPPER(AllTrim(SM0->M0_ESTCOB)),oFont6,100 )
oPrn:Say( 0210 + li, 1213, "FONE: " + SM0->M0_TEL ,oFont6,100 )
oPrn:Say( 0210 + li, 1823, "FAX: " + SM0->M0_FAX ,oFont6,100 )
                                                                              
oPrn:Say( 0270 + li, 1213, "CNPJ N.: "+ Transform(SM0->M0_CGC,cCgcPict) ,oFont6,100 )
oPrn:Say( 0300 + li, 1213, "INSCRICAO ESTADUAL N.: " + InscrEst() ,oFont6,100 )

oPrn:Say( 0370 + li, 1213, "DATA DA EMISSAO: " + DtoC(dEmissao) ,oFont6,100 )

oPrn:Say( 0526 + li, 0424, cFatura, oFont3c,100 ) //0468
//oPrn:Say( 0526 + li, 1205, cOrdem, oFont3c,100 ) //cFatura + If(!Empty(cOrdem),'/',' ') + cOrdem //retirar

//oPrn:Say( 0526 + li, 0819, TransForm(nValor, "@EZ 999,999,999.99"), oFont3c,100 )
oPrn:Say( 0526 + li, 1155, TransForm(nValor, "@EZ 999,999,999.99"), oFont3c,100,,,1 )//valor total
oPrn:Say( 0526 + li, 1375, TransForm(nValorPago, "@EZ 999,999,999.99"), oFont3c,100,,,1 )//valor pago

//nValorPago
oPrn:Say( 0526 + li, 1521, DtoC(dVencimento), oFont3c, 100 )
//oPrn:Say( 0596 + li, 0702, TransForm(nDesconto, "@EZ 999,999,999.99"), oFont3c, 100 ) //retirar

oPrn:Say( 0819 + li, 0737, cNome, oFont3c, 100 )
oPrn:Say( 0819 + li, 2187, cCod, oFont3c, 100 )
oPrn:Say( 0865 + li, 0737, cEnd, oFont3c, 100 )
oPrn:Say( 0911 + li, 0737, cMun, oFont3c, 100 )
oPrn:Say( 0911 + li, 1907, cEst, oFont3c, 100 )
oPrn:Say( 0911 + li, 2187, Left(cCep,5)+"-"+Right(cCep,3), oFont3c, 100 )
//oPrn:Say( 0957 + li, 0737, cEndC, oFont3c, 100 )	//Pï¿½A. PAGATO //retirar
oPrn:Say( 1003 + li, 0737, Transform(cCgc,cCgcPict), oFont3c, 100 )
oPrn:Say( 1003 + li, 2012, cInsc, oFont3c, 100 )

cTexto := "(" + Extenso(nValorPago) +" "+ Replicate("*",220)
_cTexto1 := SubStr(cTexto,1,070)
_cTexto2 := SubStr(cTexto,071,070)
_cTexto3 := SubStr(cTexto,141,068) + " )"


oPrn:Say( 1445 + li, 0424,UPPER(ALLTRIM(SM0->M0_CIDCOB)) + ", " + UPPER(AllTrim(SM0->M0_ESTCOB)) + ", " +cValToChar(Day(dDatPag)) + " DE " + UPPER(MesExtenso(Month(dDatPag))) + " DE " + cValToChar(Year(dDatPag)),oFont6,100)
//UPPER(ALLTRIM(SM0->M0_CIDCOB)) + ", " + UPPER(AllTrim(SM0->M0_ESTCOB)) + ", " +Day(date()) + " DE " + UPPER(MesExtenso(Month(date()))) + " DE " Year(date())

oPrn:Say( 1070 + li, 0585, _cTexto1, oFont3c, 100 )
oPrn:Say( 1140 + li, 0585, _cTexto2, oFont3c, 100 )
oPrn:Say( 1210 + li, 0585, _cTexto3, oFont3c, 100 )

If li > 0
	oPrn:EndPage()
EndIf

dbSelectArea("SX3")
dbSetOrder(2)
dbSeek("A2_CGC")
cCGC := Alltrim(X3TITULO())
nOrden = IndexOrd()

dbSelectArea("SA2")
dbSetOrder(nOrden)

Return


/*/{Protheus.doc} Static Function EscolheSE5
Tela de escolha das SE5 para impressao

@type  Function
@author Gabriel
@since 26/02/2020
@version version
@param param_name, param_type, param_descr
/*/
Static Function EscolheSE5(aDadosAux)	

	Local aCampos := {"MARK", "E5_DATA", "E5_VALOR"}
	Local aHeaderEx := {}
	Local oPnlDet
	Local bMarcaTodos := {|x| iif(x[1]=="LBNO", x[1]:="LBOK", x[1]:="LBNO")  }
	Private lMARKALL := .F.
	Private oGridDet
	Private oDlgDet

	DEFINE MSDIALOG oDlgDet TITLE "Baixas do titulo" STYLE DS_MODALFRAME FROM 000, 000  TO 400, 800 COLORS 0, 16777215 PIXEL

	oPnlDet := TScrollBox():New(oDlgDet,05,05,172,390,.F.,.T.,.T.)

	@ 005, 005 SAY ("Prefixo: " + ZSE1->E1_PREFIXO) SIZE 200, 007 OF oPnlDet COLORS 0, 16777215 PIXEL
	@ 005, 055 SAY ("Numero: " + ZSE1->E1_NUM) SIZE 200, 007 OF oPnlDet COLORS 0, 16777215 PIXEL
	@ 005, 125 SAY ("Parcela: " + ZSE1->E1_PARCELA) SIZE 200, 007 OF oPnlDet COLORS 0, 16777215 PIXEL
	@ 005, 175 SAY ("Tipo: " + ZSE1->E1_TIPO) SIZE 200, 007 OF oPnlDet COLORS 0, 16777215 PIXEL

	@ 015, 005 SAY ("Cliente: " + ALLTRIM(ZSE1->E1_CLIENTE)+"/"+ALLTRIM(ZSE1->E1_LOJA) + " - " + Posicione("SA1",1,xFilial("SA1")+ZSE1->E1_CLIENTE+ZSE1->E1_LOJA,"A1_NOME")) SIZE 200, 007 OF oPnlDet COLORS 0, 16777215 PIXEL

	@ 030, 005 SAY "Selecione as baixas para impressão:" SIZE 200, 007 OF oPnlDet COLORS 0, 16777215 PIXEL
	@ 033, 002 SAY Replicate("_",384) SIZE 384, 007 OF oPnlDet COLORS 0, 16777215 PIXEL

	aHeaderEx := MontaHeader(aCampos, .F.)
	oGridDet := MsNewGetDados():New( 045, 002, 158, 386,,"AllwaysTrue","AllwaysTrue","+Field1+Field2",{},,999,"AllwaysTrue","AllwaysTrue","AllwaysTrue",oPnlDet, aHeaderEx, aDadosAux)
	oGridDet:oBrowse:bLDblClick := {|| oGridDet:aCols[oGridDet:nAt][1] := iif(oGridDet:aCols[oGridDet:nAt][1]=="LBNO", iif(!empty(oGridDet:aCols[oGridDet:nAt][2]),"LBOK","LBNO"), "LBNO") , oGridDet:oBrowse:Refresh() }
	oGridDet:oBrowse:bHeaderClick := {|oBrw,nCol| iif(nCol > 1, OrdGrid(@oGridDet, @nCol), iif(lMARKALL .AND. !empty(oGridDet:aCols[1][2]), (aEval(oGridDet:aCols, bMarcaTodos),oBrw:Refresh(),oBrw:SetFocus(),lMARKALL:=!lMARKALL), lMARKALL:=!lMARKALL) )}

	@ 182, 355 BUTTON oButton1 PROMPT "Confirmar" SIZE 040, 012 OF oDlgDet PIXEL Action oDlgDet:End()

	ACTIVATE MSDIALOG oDlgDet CENTERED

Return

//--------------------------------------------------------------------------------------
// Monta aHeader de acordo com campos passados
//--------------------------------------------------------------------------------------
Static Function MontaHeader(aCampos, lRecno)

	Local aAuxLeg := {}
	Local aHeadRet := {}
	Local nX := 0
	Default lRecno := .T.

	For nX := 1 to Len(aCampos)
		If !("LEG_" $ aCampos[nX]) .AND. SubStr(aCampos[nX],1,3) == "LEG"
			aAuxLeg := StrToKArr(aCampos[nX],"-")
			if len(aAuxLeg) = 1
				aadd(aAuxLeg, ' ')
			endif
			Aadd(aHeadRet,{aAuxLeg[2],aAuxLeg[1],'@BMP',5,0,'','€€€€€€€€€€€€€€','C','','','',''})
		elseif aCampos[nX] == "MARK"
			Aadd(aHeadRet,{" ","MARK",'@BMP',3,0,'','€€€€€€€€€€€€€€','C','','','',''})
		elseif !empty(GetSx3Cache(aCampos[nX],"X3_CAMPO"))
			aadd(aHeadRet, U_UAHEADER(aCampos[nX]) )
		EndIf
	Next nX

	if lRecno
		Aadd(aHeadRet, {"RecNo", "RECNO", "9999999999", 10, 0, "", "€€€€€€€€€€€€€€", "N", "","V", "", ""})
	endif

Return aHeadRet


/*/{Protheus.doc} Static Function ImpRec
Valida perguntas

@type  Function
@author Gabriel
@since 26/02/2020
@version version
@param param_name, param_type, param_descr
/*/
Static Function ValidPerg()
Local _aAlias := Alias()
Local aHelp := {}

cPerg := padr(cperg,10)
dbSelectArea("SX1")
dbSetOrder(1)

If !DbSeek(cPerg+"01")

	//PEDIDO
	AADD(aHelp,{"Informe o prefixo inicial   ",;
	"dos titulos que serao considerado na selecao ",;
	"dos dados impressos."})
	AADD(aHelp,{"Informe o prefixo final     ",;
	"dos titulos que serao considerado na selecao ",;
	"dos dados impressos."})
	
	//TITULO
	AADD(aHelp,{"Informe o numero inicial   ",;
	"dos titulos que serao considerado na selecao ",;
	"dos dados impressos."})
	AADD(aHelp,{"Informe o numero final     ",;
	"dos titulos que serao considerado na selecao ",;
	"dos dados impressos."})
	
	//PARCELA
	AADD(aHelp,{"Informe a parcela inicial   ",;
	"dos titulos que serao considerado na selecao ",;
	"dos dados impressos."})
	AADD(aHelp,{"Informe a parcela final     ",;
	"dos titulos que serao considerado na selecao ",;
	"dos dados impressos."})
	
	//TIPO
	AADD(aHelp,{"Informe o tipo inicial   ",;
	"dos tï¿½tulos que serao considerado na selecao ",;
	"dos dados impressos."})
	AADD(aHelp,{"Informe o tipo final     ",;
	"dos titulos que serao considerado na selecao ",;
	"dos dados impressos."})

	//TIPO
	AADD(aHelp,{"Informe a data inicial   ",;
	"dos tï¿½tulos que serao considerado na selecao ",;
	"dos dados impressos."})
	AADD(aHelp,{"Informe a data final     ",;
	"dos titulos que serao considerado na selecao ",;
	"dos dados impressos."})
		
	//VIAS
	AADD(aHelp,{"Informe se imprime ou nao     ",;
	"duas vias na mesma pagina."})
	
	//Cliente
	AADD(aHelp,{"Informe o cliente inicial   ",;
	"dos tï¿½tulos que serao considerado na selecao ",;
	"dos dados impressos."})
	AADD(aHelp,{"Informe a loja inicial  ",;
	"dos titulos que serao considerado na selecao ",;
	"dos dados impressos."})
	AADD(aHelp,{"Informe o cliente final   ",;
	"dos tï¿½tulos que serao considerado na selecao ",;
	"dos dados impressos."})
	AADD(aHelp,{"Informe a loja final  ",;
	"dos titulos que serao considerado na selecao ",;
	"dos dados impressos."})

	//PutSX1 - Criacao de pergunta 
	//(cGrupo/cOrdem/cPergunt/cPerSpa/cPerEng/cVar/cTipo/nTamanho/nDecimal/nPresel/cGSC/cValid/cF3/cGrpSxg/cPyme/cVar01/cDef01/cDefSpa1/cDefEng1/cCnt01/cDef02/cDefSpa2/cDefEng2/cDef03/cDefSpa3/cDefEng3/cDef04/cDefSpa4/cDefEng4/cDef05/cDefSpa5/cDefEng5/aHelpPor/aHelpEng/aHelpSpa/cHelp
	U_uAjusSx1(cPerg,"01","Do Prefixo ?" ,"","","mv_ch1","C",3,0,0,"G","","SE1","","","MV_PAR01","","","","","","","","","","","","","","","","",aHelp[1])
	U_uAjusSx1(cPerg,"02","Do Titulo ?"  ,"","","mv_ch2","C",9,0,0,"G","",""   ,"","","MV_PAR02","","","","","","","","","","","","","","","","",aHelp[3])
	U_uAjusSx1(cPerg,"03","Da Parcela ?" ,"","","mv_ch3","C",3,0,0,"G","",""   ,"","","MV_PAR03","","","","","","","","","","","","","","","","",aHelp[5])
	U_uAjusSx1(cPerg,"04","Do Tipo ?"    ,"","","mv_ch4","C",3,0,0,"G","",""   ,"","","MV_PAR04","","","","","","","","","","","","","","","","",aHelp[7])
	U_uAjusSx1(cPerg,"05","Ate Prefixo ?","","","mv_ch5","C",3,0,0,"G","","SE1","","","MV_PAR05","","","","","","","","","","","","","","","","",aHelp[2])
	U_uAjusSx1(cPerg,"06","Ate Titulo ?" ,"","","mv_ch6","C",9,0,0,"G","",""   ,"","","MV_PAR06","","","","","","","","","","","","","","","","",aHelp[4])
	U_uAjusSx1(cPerg,"07","Ate Parcela ?","","","mv_ch7","C",3,0,0,"G","",""   ,"","","MV_PAR07","","","","","","","","","","","","","","","","",aHelp[6])
	U_uAjusSx1(cPerg,"08","Ate Tipo ?"   ,"","","mv_ch8","C",3,0,0,"G","",""   ,"","","MV_PAR08","","","","","","","","","","","","","","","","",aHelp[8])
	U_uAjusSx1(cPerg,"09","De Dt. Emissao ?","","","mv_ch9","D",08,0,0,"G","","","","","MV_PAR09","","","","01/01/01","","","","","","","","","","","","",aHelp[9])
	U_uAjusSx1(cPerg,"10","Ate Dt. Emissao ?","","","mv_cha","D",08,0,0,"G","","","","","MV_PAR10","","","","31/12/20","","","","","","","","","","","","",aHelp[10])
	U_uAjusSx1(cPerg,"11","Imprime 2 Vias ?","","","mv_chb","N",1,0,0,"C","","","","","MV_PAR11","Sim","","","","Nao","","","","","","","","","","","","","","","","","","","","","",aHelp[11])
	U_uAjusSx1(cPerg,"12","Do Cliente ?" ,"","","mv_chc","C",6,0,0,"G","","SA1" ,"","","MV_PAR12","","","","","","","","","","","","","","","","",aHelp[12])
	U_uAjusSx1(cPerg,"13","Da Loja ?"    ,"","","mv_chd","C",2,0,0,"G","",""   ,"","","MV_PAR13","","","","","","","","","","","","","","","","",aHelp[13])
	U_uAjusSx1(cPerg,"14","Ate Cliente ?","","","mv_che","C",6,0,0,"G","","SA1" ,"","","MV_PAR14","","","","","","","","","","","","","","","","",aHelp[14])
	U_uAjusSx1(cPerg,"15","Ate Loja ?"   ,"","","mv_chf","C",2,0,0,"G","",""   ,"","","MV_PAR15","","","","","","","","","","","","","","","","",aHelp[15])
EndIf

DbSelectArea(_aAlias)

Return

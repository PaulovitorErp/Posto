#INCLUDE "PROTHEUS.CH"
#INCLUDE "TOTVS.CH"
#INCLUDE "TBICONN.CH"
#INCLUDE "XMLXFUN.CH"
#INCLUDE "TOPCONN.CH"

/*/{Protheus.doc} TRETE032
Retorna o limite utilizado de um cliente e grupo de cliente
(saldo em aberto de titulos do contas a receber)

@author pablo
@since 04/06/2019
@version 1.0
@return aLimites, lista de limites usados dos clientes/grupo {{X.XX [L USADO CLI], X.XX [L USADO GRP], X.XX [L CLI], X.XX [L GRP]},...}
@param nOpc, numeric, Tipo de Limtite Utilizado: 1 - LIMITE UTILIZADO VENDA / 2 - LIMITE UTILIZADO SAQUE
@param aClientes, characters, lista de clientes -> {{'CODIGO','LOJA','GRUPO'},{'CODIGO','LOJA','GRUPO'},...}
@type function
/*/
User Function TRETE032(nOpc,aClientes,cSegmento) //U_TRETE032(1,{{'000014','01',''}})

Local aArea		:= GetArea()
Local aAreaSA1 	:= SA1->(GetArea())
Local aAreaACY 	:= ACY->(GetArea())
Local aAreaUC4
Local nX
Local aLimites  := {} 
Local cAliasSE1 := "SALDOSE1"
Local cCodGrp   := ""
Local cTpSaq 	:= "RP " //Tipo: Requisição Pós-Paga de Saque (Vale Motorista)
Local lSA1Compart := Empty(xFilial("SA1")) //Verifica se SA1 é compartilhada
Local lTP_ACTLCS := SuperGetMv("TP_ACTLCS",,.F.) //habilita limite de credito por segmento
Local cSGBD	:= AllTrim(Upper(TcGetDb())) // -- Banco de dados atulizado (Para embientes TOP) 			 	
Local lTP_ACTLGR := SuperGetMv("TP_ACTLGR",,.T.) //habilita limite de credito por grupo de clientes

Default nOpc := 1 //1 - LIMITE UTILIZADO VENDA
Default cSegmento := SuperGetMv("TP_MYSEGLC",," ") //define o segmento da filial (parametro deve ser criado exclusivo na retaguarda)

if lTP_ACTLCS
	aAreaUC4 	:= UC4->(GetArea())
	if empty(cSegmento)
		cSegmento := Posicione("UC5",2,xFilial("UC5")+cFilAnt,"UC5_COD")
	endif
endif

cHoraInicio := TIME() // Armazena hora de inicio do processamento...
LjGrvLog("TRETE032", "INICIO - Retorna o limite utilizado de um CLIENTE e GRUPO DE CLIENTE",)
LjGrvLog("TRETE032", "Tempo: ", ElapTime( cHoraInicio, TIME() ))

If IsInCallStack("LOJA070")
	aRet 	:= {0,0,0,0,'2','2'}
	aadd(aLimites,aRet)
	Return aLimites
endif

#IFDEF TOP

	For nX:=1 to Len(aClientes)

		LjGrvLog("TRETE032", "aClientes[nX]", aClientes[nX])
		LjGrvLog("TRETE032", "nOpc", nOpc)

		If !Empty(aClientes[nX][01])
			cCodCli := aClientes[nX][01]
			cCodLoj := aClientes[nX][02]
			if lTP_ACTLGR
				cCodGrp := Posicione("SA1",1,xFilial("SA1")+cCodCli+cCodLoj,"A1_GRPVEN")
			endif
		Else
			cCodCli := ""
			cCodLoj := ""
			cCodGrp := aClientes[nX][03]
		EndIf
		
		aRet := {0,0,0,0,'2','2'} 	//[01] [limite venda] ou [limite saque] UTILIZADO  do [Cliente] / [02] [limite venda] ou [limite saque] UTILIZADO  do [Grupo de Cliente]
				  					//[03] [limite venda] ou [limite saque] CADASTRADO do [Cliente] / [04] [limite venda] ou [limite saque] CADASTRADO do [Grupo de Cliente]
				  					//[05] [bloqueio venda] ou [bloqueio saque] do [Cliente]		/ [06] [bloqueio venda] ou [bloqueio saque] do [Grupo de Cliente]
		
		If nOpc == 1 //1 - LIMITE UTILIZADO VENDA
		
			//**********************//
			// LIMITE VENDA CLIENTE //
			//**********************//
			If !Empty(cCodCli)
			
				If Select(cAliasSE1) > 0
					(cAliasSE1)->( DbCloseArea() )
				Endif
			
				cQuery := " SELECT SUM(SE1.E1_SALDO) SALDO "
				cQuery += " FROM " + RetSQLName("SE1") + " SE1 "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+" "
				cQuery += " WHERE "
				cQuery += " SE1.E1_CLIENTE  = '"+cCodCli+"'"
				cQuery += " AND SE1.E1_LOJA = '"+cCodLoj+"'"
				If !lSA1Compart //se SA1 for exclusiva
					cQuery += 	" 	AND SUBSTRING(SE1.E1_FILIAL,1,"+cValToChar(Len(Alltrim(xFilial("SA1"))))+") = '"+Alltrim(xFilial("SA1"))+"' "
				EndIf
				cQuery += " AND SE1.E1_SALDO > 0"
				cQuery += " AND SE1.E1_TIPO NOT IN " + FormatIn(cTpSaq+"|"+MVABATIM+"|"+MV_CRNEG +"|"+MVPROVIS+"|"+MVRECANT+"|"+MV_CPNEG+"|"+ MVTAXA+"|"+MVTXA+"|"+MVINSS+"|"+"SES","|")  
				cQuery += " AND SE1.D_E_L_E_T_ = ' '"
				if lTP_ACTLCS
					cQuery += " AND SE1.E1_FILORIG IN ( "
					cQuery += " 	SELECT UC5_FILERP  "
					cQuery += " 	FROM "+RetSQLName("UC5")+" UC5  "
					cQuery += " 	WHERE UC5.UC5_FILIAL = '"+xFilial("UC5")+"'  "
					cQuery += " 	AND UC5.D_E_L_E_T_ = ' '  "
					cQuery += " 	AND UC5_COD = '"+cSegmento+"' "
					cQuery += " ) "
				endif
				
				cQuery := ChangeQuery(cQuery)
				LjGrvLog("TRETE032", "1 - LIMITE VENDA CLIENTE: cQuery", cQuery)

				TcQuery cQuery New ALIAS &(cAliasSE1)
				DbSelectArea(cAliasSE1)
				lAchouSE1 := (cAliasSE1)->( !EoF() )
				
				LjGrvLog("TRETE032", "1 - LIMITE VENDA CLIENTE: lAchouSE1", lAchouSE1)
				LjGrvLog("TRETE032", "Tempo: ", ElapTime( cHoraInicio, TIME() ))

				If lAchouSE1
					aRet[01] := (cAliasSE1)->SALDO
				EndIf
				
				if lTP_ACTLCS
					aRet[03] := Posicione("UC4",1,xFilial("UC4")+cCodCli+cCodLoj+cSegmento,"UC4_LIMVEN")
					aRet[05] := Posicione("UC4",1,xFilial("UC4")+cCodCli+cCodLoj+cSegmento,"UC4_BLQVEN")
				else
					aRet[03] := Posicione("SA1",1,xFilial("SA1")+cCodCli+cCodLoj,"A1_XLC")
					aRet[05] := Posicione("SA1",1,xFilial("SA1")+cCodCli+cCodLoj,"A1_XBLQLC")
				endif
				
				(cAliasSE1)->( DbCloseArea() )

			EndIf
			
			//****************************//
			// LIMITE VENDA GRUPO CLIENTE //
			//****************************//
			If !Empty(cCodGrp)
			
				If Select(cAliasSE1) > 0
					(cAliasSE1)->( DbCloseArea() )
				Endif
			
				cQuery := " SELECT SUM(SE1.E1_SALDO) SALDO"
				cQuery += " FROM " + RetSQLName("SE1") + " SE1 "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+""

				cQuery += " INNER JOIN " + RetSQLName("SA1") + " SA1 "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+" ON ("
				cQuery += " 	SA1.A1_COD = SE1.E1_CLIENTE"
				cQuery += " 	AND SA1.A1_LOJA = SE1.E1_LOJA"
				If !lSA1Compart //se SA1 for exclusiva
					cQuery += 	" 	AND SA1.A1_FILIAL = '"+xFilial("SA1")+"' "
				EndIf
				cQuery += " 	AND SA1.D_E_L_E_T_ = ' ' "
				cQuery += 	" 	)"
					
				cQuery += " WHERE "
				cQuery += " SA1.A1_GRPVEN = '"+cCodGrp+"'"	
				If !lSA1Compart //se SA1 for exclusiva
					cQuery += 	" 	AND SUBSTRING(SE1.E1_FILIAL,1,"+cValToChar(Len(Alltrim(xFilial("SA1"))))+") = '"+Alltrim(xFilial("SA1"))+"' "
				EndIf
				cQuery += " AND SE1.E1_SALDO > 0"
				cQuery += " AND SE1.E1_TIPO NOT IN " + FormatIn(cTpSaq+"|"+MVABATIM+"|"+MV_CRNEG +"|"+MVPROVIS+"|"+MVRECANT+"|"+MV_CPNEG+"|"+ MVTAXA+"|"+MVTXA+"|"+MVINSS+"|"+"SES","|")  + " "
				cQuery += " AND SE1.D_E_L_E_T_ = ' '"
				if lTP_ACTLCS
					cQuery += " AND SE1.E1_FILORIG IN ( "
					cQuery += " 	SELECT UC5_FILERP  "
					cQuery += " 	FROM "+RetSQLName("UC5")+" UC5  "
					cQuery += " 	WHERE UC5.UC5_FILIAL = '"+xFilial("UC5")+"'  "
					cQuery += " 	AND UC5.D_E_L_E_T_ = ' '  "
					cQuery += " 	AND UC5_COD = '"+cSegmento+"' "
					cQuery += " ) "
				endif
			
				cQuery := ChangeQuery(cQuery)
				LjGrvLog("TRETE032", "2 - LIMITE VENDA GRUPO CLIENTE: cQuery", cQuery)

				TcQuery cQuery New ALIAS &(cAliasSE1)
				DbSelectArea(cAliasSE1)
				lAchouSE1 := (cAliasSE1)->( !EoF() )
				
				LjGrvLog("TRETE032", "2 - LIMITE VENDA GRUPO CLIENTE: lAchouSE1", lAchouSE1)
				LjGrvLog("TRETE032", "Tempo: ", ElapTime( cHoraInicio, TIME() ))

				If lAchouSE1
					aRet[02] := (cAliasSE1)->SALDO
				EndIf

				if lTP_ACTLCS
					aRet[04] := Posicione("UC4",2,xFilial("UC4")+cCodGrp+cSegmento,"UC4_LIMVEN")
					aRet[06] := Posicione("UC4",2,xFilial("UC4")+cCodGrp+cSegmento,"UC4_BLQVEN")
				else
					aRet[04] := Posicione("ACY",1,xFilial("ACY")+cCodGrp,"ACY_XLC")
					aRet[06] := Posicione("ACY",1,xFilial("ACY")+cCodGrp,"ACY_XBLPRZ")
				endif
				
				(cAliasSE1)->( DbCloseArea() )

			EndIf
		
		ElseIf nOpc == 2 //2 - LIMITE UTILIZADO SAQUE
		
			//**********************//
			// LIMITE SAQUE CLIENTE //
			//**********************//
			If !Empty(cCodCli)
			
				If Select(cAliasSE1) > 0
					(cAliasSE1)->( DbCloseArea() )
				Endif
			
				cQuery := " SELECT SUM(SE1.E1_SALDO) SALDO "
				cQuery += " FROM " + RetSQLName("SE1") + " SE1 "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+" "
				cQuery += " WHERE "
				cQuery += " SE1.E1_CLIENTE  = '"+cCodCli+"'"
				cQuery += " AND SE1.E1_LOJA = '"+cCodLoj+"'
				cQuery += " AND SE1.E1_TIPO = '"+cTpSaq+"' " 
				If !lSA1Compart //se SA1 for exclusiva
					cQuery += 	" 	AND SUBSTRING(SE1.E1_FILIAL,1,"+cValToChar(Len(Alltrim(xFilial("SA1"))))+") = '"+Alltrim(xFilial("SA1"))+"' "
				EndIf
				cQuery += " AND SE1.E1_SALDO > 0"
				cQuery += " AND SE1.D_E_L_E_T_ = ' '"
				if lTP_ACTLCS
					cQuery += " AND SE1.E1_FILORIG IN ( "
					cQuery += " 	SELECT UC5_FILERP  "
					cQuery += " 	FROM "+RetSQLName("UC5")+" UC5  "
					cQuery += " 	WHERE UC5.UC5_FILIAL = '"+xFilial("UC5")+"'  "
					cQuery += " 	AND UC5.D_E_L_E_T_ = ' '  "
					cQuery += " 	AND UC5_COD = '"+cSegmento+"' "
					cQuery += " ) "
				endif
			
				cQuery := ChangeQuery(cQuery)
				LjGrvLog("TRETE032", "1 - LIMITE SAQUE CLIENTE: cQuery", cQuery)

				//dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),cAliasSE1,.F.,.F.)
				TcQuery cQuery New ALIAS &(cAliasSE1)
				DbSelectArea(cAliasSE1)
				lAchouSE1 := (cAliasSE1)->( !EoF() )

				LjGrvLog("TRETE032", "1 - LIMITE SAQUE CLIENTE: lAchouSE1", lAchouSE1)
				LjGrvLog("TRETE032", "Tempo: ", ElapTime( cHoraInicio, TIME() ))
			
				If lAchouSE1
					aRet[01] := (cAliasSE1)->SALDO
				EndIf

				if lTP_ACTLCS
					aRet[03] := Posicione("UC4",1,xFilial("UC4")+cCodCli+cCodLoj+cSegmento,"UC4_LIMSAQ")
					aRet[05] := Posicione("UC4",1,xFilial("UC4")+cCodCli+cCodLoj+cSegmento,"UC4_BLQSAQ")
				else
					aRet[03] := Posicione("SA1",1,xFilial("SA1")+cCodCli+cCodLoj,"A1_XLIMSQ")
					aRet[05] := Posicione("SA1",1,xFilial("SA1")+cCodCli+cCodLoj,"A1_XBLQSQ")
				endif
				
				(cAliasSE1)->( DbCloseArea() )

			EndIf
			
			//****************************//
			// LIMITE SAQUE GRUPO CLIENTE //
			//****************************//
			If !Empty(cCodGrp)
			
				If Select(cAliasSE1) > 0
					(cAliasSE1)->( DbCloseArea() )
				Endif
			
				cQuery := "SELECT SUM(SE1.E1_SALDO) SALDO"
				cQuery += 	" FROM " + RetSQLName("SE1") + " SE1 "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+""

				cQuery += " INNER JOIN " + RetSQLName("SA1") + " SA1 "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+" ON ("
				cQuery += " 	SA1.A1_COD = SE1.E1_CLIENTE"
				cQuery += " 	AND SA1.A1_LOJA = SE1.E1_LOJA"
				If !lSA1Compart //se SA1 for exclusiva
					cQuery += 	" 	AND SA1.A1_FILIAL = '"+xFilial("SA1")+"' "
				EndIf
				cQuery += " 	AND SA1.D_E_L_E_T_ = ' ' "
				cQuery += 	" 	)"
				
				cQuery += " WHERE "
				cQuery += " SA1.A1_GRPVEN = '"+cCodGrp+"'"
				If !lSA1Compart //se SA1 for exclusiva
					cQuery += 	" 	AND SUBSTRING(SE1.E1_FILIAL,1,"+cValToChar(Len(Alltrim(xFilial("SA1"))))+") = '"+Alltrim(xFilial("SA1"))+"' "
				EndIf
				cQuery += " AND SE1.E1_TIPO = '"+cTpSaq+"' " 
				cQuery += " AND SE1.E1_SALDO > 0"
				cQuery += " AND SE1.D_E_L_E_T_ = ' '"
				if lTP_ACTLCS
					cQuery += " AND SE1.E1_FILORIG IN ( "
					cQuery += " 	SELECT UC5_FILERP  "
					cQuery += " 	FROM "+RetSQLName("UC5")+" UC5  "
					cQuery += " 	WHERE UC5.UC5_FILIAL = '"+xFilial("UC5")+"'  "
					cQuery += " 	AND UC5.D_E_L_E_T_ = ' '  "
					cQuery += " 	AND UC5_COD = '"+cSegmento+"' "
					cQuery += " ) "
				endif
			
				cQuery := ChangeQuery(cQuery)
				LjGrvLog("TRETE032", "2 - LIMITE SAQUE GRUPO CLIENTE: cQuery", cQuery)

				//dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),cAliasSE1,.F.,.F.)
				TcQuery cQuery New ALIAS &(cAliasSE1)
				DbSelectArea(cAliasSE1)
				lAchouSE1 := (cAliasSE1)->( !EoF() )

				LjGrvLog("TRETE032", "2 - LIMITE SAQUE GRUPO CLIENTE: lAchouSE1", lAchouSE1)
				LjGrvLog("TRETE032", "Tempo: ", ElapTime( cHoraInicio, TIME() ))
			
				If lAchouSE1
					aRet[02] := (cAliasSE1)->SALDO
				EndIf

				if lTP_ACTLCS
					aRet[04] := Posicione("UC4",2,xFilial("UC4")+cCodGrp+cSegmento,"UC4_LIMSAQ")
					aRet[06] := Posicione("UC4",2,xFilial("UC4")+cCodGrp+cSegmento,"UC4_BLQSAQ")
				else
					aRet[04] := Posicione("ACY",1,xFilial("ACY")+cCodGrp,"ACY_XLIMSQ")
					aRet[06] := Posicione("ACY",1,xFilial("ACY")+cCodGrp,"ACY_XBLRSA")
				endif
				
				(cAliasSE1)->( DbCloseArea() )
				
			EndIf
		
		EndIf
		
		aadd(aLimites,aRet)
	
	Next nX
	
	If Select(cAliasSE1) > 0
		(cAliasSE1)->( DbCloseArea() )
	EndIf
	
#ELSE

	For nX:=1 to Len(aClientes)
		aRet 	:= {0,0,0,0,'2','2'}
		aadd(aLimites,aRet)
	Next nX
	
#ENDIF

//LjGrvLog("TRETE032", "aLimites", aLimites)
LjGrvLog("TRETE032", "Tempo: ", ElapTime( cHoraInicio, TIME() ))
LjGrvLog("TRETE032", "FIM - Retorna o limite utilizado de um CLIENTE e GRUPO DE CLIENTE",)

if lTP_ACTLCS
	RestArea(aAreaUC4)
endif
RestArea(aAreaACY)
RestArea(aAreaSA1)
RestArea(aArea)
	
Return aLimites //[01] [limite venda] ou [limite saque] utilizado do cliente / [02] [limite venda] ou [limite saque] utilizado do grupo de cliente

/*/{Protheus.doc} TR032OFF
Retorna o limite OFFLINE utilizado de um cliente e grupo de cliente, na tabela UC4

@author danilo
@since 17/04/2024
@version 1.0
@return aLimites, lista de limites usados dos clientes/grupo {{X.XX [L USADO CLI], X.XX [L USADO GRP], X.XX [L CLI], X.XX [L GRP]},...}
@param nOpc, numeric, Tipo de Limtite Utilizado: 1 - LIMITE UTILIZADO VENDA / 2 - LIMITE UTILIZADO SAQUE
@param aClientes, characters, lista de clientes -> {{'CODIGO','LOJA','GRUPO'},{'CODIGO','LOJA','GRUPO'},...}
@type function
/*/
User Function TR032OFF(nOpc,aClientes,cSegmento)

	Local aArea		:= GetArea()
	Local aAreaSA1 	:= SA1->(GetArea())
	Local aAreaUC4	:= UC4->(GetArea())
	Local nX
	Local aLimites  := {} 
	Local cCodGrp   := ""
	Local lTP_ACTLCS := SuperGetMv("TP_ACTLCS",,.F.) //habilita limite de credito por segmento
	Local lTP_ACTLGR := SuperGetMv("TP_ACTLGR",,.T.) //habilita limite de credito por grupo de clientes

	Default nOpc := 1 //1 - LIMITE UTILIZADO VENDA
	Default cSegmento := SuperGetMv("TP_MYSEGLC",," ") //define o segmento da filial (parametro deve ser criado exclusivo na retaguarda)

	if lTP_ACTLCS .AND. empty(cSegmento)
		cSegmento := Posicione("UC5",2,xFilial("UC5")+cFilAnt,"UC5_COD")
	endif

	cHoraInicio := TIME() // Armazena hora de inicio do processamento...
	LjGrvLog("TRETE032", "INICIO - Retorna o limite utilizado de um CLIENTE e GRUPO DE CLIENTE",)
	LjGrvLog("TRETE032", "Tempo: ", ElapTime( cHoraInicio, TIME() ))

	For nX:=1 to Len(aClientes)

		LjGrvLog("TRETE032", "aClientes[nX]", aClientes[nX])
		LjGrvLog("TRETE032", "nOpc", nOpc)

		If !Empty(aClientes[nX][01])
			cCodCli := aClientes[nX][01]
			cCodLoj := aClientes[nX][02]
			if lTP_ACTLGR
				cCodGrp := Posicione("SA1",1,xFilial("SA1")+cCodCli+cCodLoj,"A1_GRPVEN")
			endif
		Else
			cCodCli := ""
			cCodLoj := ""
			cCodGrp := aClientes[nX][03]
		EndIf
		
		aRet := {0,0,0,0,'2','2'} 	//[01] [limite venda] ou [limite saque] UTILIZADO  do [Cliente] / [02] [limite venda] ou [limite saque] UTILIZADO  do [Grupo de Cliente]
				  					//[03] [limite venda] ou [limite saque] CADASTRADO do [Cliente] / [04] [limite venda] ou [limite saque] CADASTRADO do [Grupo de Cliente]
				  					//[05] [bloqueio venda] ou [bloqueio saque] do [Cliente]		/ [06] [bloqueio venda] ou [bloqueio saque] do [Grupo de Cliente]
		
		If nOpc == 1 //1 - LIMITE UTILIZADO VENDA

			//**********************//
			// LIMITE VENDA CLIENTE //
			//**********************//
			If !Empty(cCodCli)
				UC4->(DbSetOrder(1)) //UC4_FILIAL+UC4_CLIENT+UC4_LOJA+UC4_SEG
				If UC4->(DbSeek(xFilial("UC4")+cCodCli+cCodLoj+iif(lTP_ACTLCS,cSegmento," ")))
					aRet[01] := UC4->UC4_SALDO
					aRet[03] := UC4->UC4_LIMVEN
					aRet[05] := UC4->UC4_BLQVEN
				EndIf

			endif

			//****************************//
			// LIMITE VENDA GRUPO CLIENTE //
			//****************************//
			If !Empty(cCodGrp)

				UC4->(DbSetOrder(2)) //UC4_FILIAL+UC4_GRUPO+UC4_SEG
				If UC4->(DbSeek(xFilial("UC4")+cCodGrp+iif(lTP_ACTLCS,cSegmento," ")))
					aRet[02] := UC4->UC4_SALDO
					aRet[04] := UC4->UC4_LIMVEN
					aRet[06] := UC4->UC4_BLQVEN
				endif
			endif
		
		ElseIf nOpc == 2 //2 - LIMITE UTILIZADO SAQUE
		
			//**********************//
			// LIMITE SAQUE CLIENTE //
			//**********************//
			If !Empty(cCodCli)
				UC4->(DbSetOrder(1)) //UC4_FILIAL+UC4_CLIENT+UC4_LOJA+UC4_SEG
				If UC4->(DbSeek(xFilial("UC4")+cCodCli+cCodLoj+iif(lTP_ACTLCS,cSegmento," ")))
					aRet[01] := UC4->UC4_SALSAQ
					aRet[03] := UC4->UC4_LIMSAQ
					aRet[05] := UC4->UC4_BLQSAQ
				EndIf

			endif

			//****************************//
			// LIMITE SAQUE GRUPO CLIENTE //
			//****************************//
			If !Empty(cCodGrp)

				UC4->(DbSetOrder(2)) //UC4_FILIAL+UC4_GRUPO+UC4_SEG
				If UC4->(DbSeek(xFilial("UC4")+cCodGrp+iif(lTP_ACTLCS,cSegmento," ")))
					aRet[02] := UC4->UC4_SALSAQ
					aRet[04] := UC4->UC4_LIMSAQ
					aRet[06] := UC4->UC4_BLQSAQ
				endif
			endif

		EndIf
		
		aadd(aLimites,aRet)
	
	Next nX

	//LjGrvLog("TRETE032", "aLimites", aLimites)
	LjGrvLog("TRETE032", "Tempo: ", ElapTime( cHoraInicio, TIME() ))
	LjGrvLog("TRETE032", "FIM - Retorna o limite utilizado de um CLIENTE e GRUPO DE CLIENTE",)

	RestArea(aAreaUC4)
	RestArea(aAreaSA1)
	RestArea(aArea)

Return aLimites //[01] [limite venda] ou [limite saque] utilizado do cliente / [02] [limite venda] ou [limite saque] utilizado do grupo de cliente


/*/{Protheus.doc} TRETE32A
Gatilho do campo: A1_XLC e A1_XLIMSQ, UC4_LIMVEN
Retorna o novo Saldo de Limite para os campos: A1_XSLDLC (VENDA) e A1_XSLDSQ (SAQUE), UC4_LIMVEN (VENDA POR SEGMENTO)

@author pablo
@since 07/06/2019
@version 1.0
@return ${return}, ${return_description}
@param nOpc, numeric, descricao
@type function
/*/
User Function TRETE32A()
	Local nRet := 0
	Local oModel

	If Alltrim(ReadVar()) == "M->A1_XLC" //limite venda cliente
		nRet := (M->A1_XLC) - (U_TRETE032(1,{{M->A1_COD,M->A1_LOJA,''}})[01][01])
	ElseIf Alltrim(ReadVar()) == "M->A1_XLIMSQ" //limite saque cliente
		nRet := (M->A1_XLIMSQ) - (U_TRETE032(2,{{M->A1_COD,M->A1_LOJA,''}})[01][01])
	ElseIf Alltrim(ReadVar()) == "M->UC4_LIMVEN" //limite saque cliente
		oModel := FWModelActive()
		//Comentei o UC4_LIMVEN pois o campo Saldo agora será referente ao saldo usado do limite, e nao o saldo disponível
		if oModel <> Nil .AND. oModel:cSource == "TRETA052"
			nRet := /*(M->UC4_LIMVEN) - */(U_TRETE032(1,{{SA1->A1_COD,SA1->A1_LOJA,''}}, FwFldGet("UC4_SEG") )[01][01])
		elseif oModel <> Nil .AND. oModel:cSource == "TRETA053"
			nRet := /*(M->UC4_LIMVEN) - */(U_TRETE032(1,{{'','',ACY->ACY_GRPVEN}}, FwFldGet("UC4_SEG") )[01][02])
		endif
	ElseIf Alltrim(ReadVar()) == "M->UC4_LIMSAQ" //limite saque cliente
		oModel := FWModelActive()
		//Comentei o UC4_LIMSAQ pois o campo Saldo agora será referente ao saldo usado do limite, e nao o saldo disponível
		if oModel <> Nil .AND. oModel:cSource == "TRETA052"
			nRet := /*(M->UC4_LIMSAQ) - */(U_TRETE032(2,{{SA1->A1_COD,SA1->A1_LOJA,''}}, FwFldGet("UC4_SEG") )[01][01])
		elseif oModel <> Nil .AND. oModel:cSource == "TRETA053"
			nRet := /*(M->UC4_LIMSAQ) - */(U_TRETE032(2,{{'','',ACY->ACY_GRPVEN}}, FwFldGet("UC4_SEG") )[01][02])
		endif
	EndIf

Return nRet

/*/{Protheus.doc} TRETE32B
Gatilho do campo: ACY_XLC e ACY_XLIMSQ
Retorna o novo Saldo de Limite para os campos: ACY_XSLDLC (VENDA) e ACY_XSLDSQ (SAQUE)

@author pablo
@since 07/06/2019
@version 1.0
@return ${return}, ${return_description}
@param nOpc, numeric, descricao
@type function
/*/
User Function TRETE32B()
Local nRet := 0

	If Alltrim(ReadVar()) == "M->ACY_XLC" //limite venda grupo de cliente
		nRet := M->ACY_XLC-U_TRETE032(1,{{'','',M->ACY_GRPVEN}})[01][02]
	ElseIf Alltrim(ReadVar()) == "M->ACY_XLIMSQ" //limite saque grupo de cliente
		nRet := M->ACY_XLIMSQ-U_TRETE032(2,{{'','',M->ACY_GRPVEN}})[01][02]
	EndIf

Return nRet


/*/{Protheus.doc} TRETE32C
Migração dos valores de limite/bloqueio da tabela UI3 para SA1

@author pablo
@since 13/06/2019
@version 1.0
@return ${return}, ${return_description}
@param cEmp, characters, descricao
@param cFil, characters, descricao
@type function
/*/
User Function TRETE32C(cEmp,cFil)
Local cSqlUpd := "", nStatus := 0
Local lRet := .T.

Default cEmp  := ""
Default cFil  := ""

	If !Empty(cEmp) .and. !Empty(cFil)
		RpcSetType(3)       
		RpcSetEnv(cEmp,cFil)
		
		SET DATE FORMAT TO "dd/mm/yyyy"
		SET CENTURY ON
		SET DATE BRITISH
	EndIf
	
	cSqlUpd := "update SA1"+CRLF
	cSqlUpd += " set"+CRLF

	//LIMITES
	cSqlUpd += "	SA1.A1_XLC    = UI3.UI3_LC,"+CRLF
	cSqlUpd += "	SA1.A1_XLIMSQ = UI3.UI3_LCSQ,"+CRLF

	If SA1->(FieldPos("A1_XFILBLQ")) > 0
		cSqlUpd += "	SA1.A1_XFILBLQ = UI3.UI3_FILBLQ,"+CRLF
	endif
	If SA1->(FieldPos("A1_XEMCHQ")) > 0
		cSqlUpd += "	SA1.A1_XEMCHQ = UI3.UI3_EMICHQ,"+CRLF
	endif
	If SA1->(FieldPos("A1_XEMICF")) > 0
		cSqlUpd += "	SA1.A1_XEMICF = UI3.UI3_EMITCF,"+CRLF
	endif
	If SA1->(FieldPos("A1_XCONDSA")) > 0
		cSqlUpd += "	SA1.A1_XCONDSA = UI3.UI3_CONDSA,"+CRLF
	endif
	If SA1->(FieldPos("A1_XVLSPOS")) > 0
		cSqlUpd += "	SA1.A1_XVLSPOS = UI3.UI3_VLSPOS,"+CRLF
	endif
	If SA1->(FieldPos("A1_XCDVLSP")) > 0
		cSqlUpd += "	SA1.A1_XCDVLSP = UI3.UI3_CDVLSP,"+CRLF
	endif
	If SA1->(FieldPos("A1_XTIPONF")) > 0
		cSqlUpd += "	SA1.A1_XTIPONF = UI3.UI3_TIPONF,"+CRLF
	EndIf

	//replicar os clientes para os PDVs
	//cSqlUpd += "	SA1.A1_MSEXP  = '',"+CRLF
	//cSqlUpd += "	SA1.A1_HREXP  = '',"+CRLF

	//BLOQUEIOS
	cSqlUpd += "	SA1.A1_XBLQLC = CASE WHEN UI3.UI3_BLQCR = 'S' THEN '1' ELSE '2' END,"+CRLF
	cSqlUpd += "	SA1.A1_XBLQSQ = CASE WHEN UI3.UI3_BLQRS = 'S' THEN '1' ELSE '2' END"+CRLF

	cSqlUpd += " from " + RetSQLName("SA1") + " SA1"+CRLF
	cSqlUpd += "	inner join " + RetSQLName("UI3") + " UI3" +CRLF
	cSqlUpd += "		on (    UI3.UI3_FILIAL = SA1.A1_FILIAL" +CRLF
	cSqlUpd += "			and UI3.UI3_COD    = SA1.A1_COD"+CRLF
	cSqlUpd += "			and UI3.UI3_LOJA   = SA1.A1_LOJA"+CRLF
	cSqlUpd += "			and UI3.D_E_L_E_T_ = SA1.D_E_L_E_T_ )"+CRLF
	cSqlUpd += " where SA1.D_E_L_E_T_ = ' '"+CRLF
	
	//Se quiser rodar só para os que ainda nao foram atualizados, descomentar
	/*
	cSqlUpd += " and ( "
	cSqlUpd += " 	SA1.A1_XLC <> UI3.UI3_LC  "
	cSqlUpd += " 	or SA1.A1_XLIMSQ <> UI3.UI3_LCSQ "
	cSqlUpd += " 	or SA1.A1_XBLQLC <> CASE WHEN UI3.UI3_BLQCR = 'S' THEN '1' ELSE '2' END "
	cSqlUpd += " 	or SA1.A1_XBLQSQ <> CASE WHEN UI3.UI3_BLQRS = 'S' THEN '1' ELSE '2' END "
	If SA1->(FieldPos("A1_XFILBLQ")) > 0
		cSqlUpd += "	or SA1.A1_XFILBLQ <> UI3.UI3_FILBLQ "
	endif
	If SA1->(FieldPos("A1_XEMCHQ")) > 0
		cSqlUpd += "	or SA1.A1_XEMCHQ = UI3.UI3_EMICHQ"
	endif
	If SA1->(FieldPos("A1_XEMICF")) > 0
		cSqlUpd += "	or SA1.A1_XEMICF = UI3.UI3_EMITCF"
	endif
	If SA1->(FieldPos("A1_XCONDSA")) > 0
		cSqlUpd += "	or SA1.A1_XCONDSA = UI3.UI3_CONDSA"
	endif
	If SA1->(FieldPos("A1_XVLSPOS")) > 0
		cSqlUpd += "	or SA1.A1_XVLSPOS = UI3.UI3_VLSPOS"
	endif
	If SA1->(FieldPos("A1_XCDVLSP")) > 0
		cSqlUpd += "	or SA1.A1_XCDVLSP = UI3.UI3_CDVLSP"
	endif
	If SA1->(FieldPos("A1_XTIPONF")) > 0
		cSqlUpd += "	or SA1.A1_XTIPONF = UI3.UI3_TIPONF"
	EndIf
	cSqlUpd += " 	) "
	*/

	nStatus := TCSQLEXEC(cSqlUpd)

	If (nStatus < 0)
		//conout("TCSQLError() " + TCSQLError())
		lRet := .F.
    EndIf
    
Return lRet

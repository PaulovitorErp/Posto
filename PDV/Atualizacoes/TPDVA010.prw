#INCLUDE 'PROTHEUS.CH'
#INCLUDE 'FWMVCDEF.CH'
#INCLUDE 'TOPCONN.CH'
#include "rwmake.ch"
#INCLUDE "tbiconn.ch"

/*/{Protheus.doc} TPDVA010
Conf. de Carga por Registro.

@author Danilo Brito
@since 07/12/2017
@version 1.0
@return ${return}, ${return_description}

@type function
/*/
User Function TPDVA010()

Private cCadastro := "Conf. de Carga por Registro"

Private aRotina := { {"Pesquisar","AxPesqui",0,1} ,;
		             {"Visualizar","AxVisual",0,2} ,;
		             {"Incluir","AxInclui",0,3} ,;
		             {"Alterar","AxAltera",0,4} ,;
		             {"Excluir","AxDeleta",0,5} }

Private cDelFunc := ".T." // Validacao para a exclusao. Pode-se utilizar ExecBlock

Private cString := "UCA"

    dbSelectArea("UCA")
    dbSetOrder(1)

    dbSelectArea(cString)
    mBrowse( 6,1,22,75,cString)

Return

//------------------------------------------------------------------
// Faz conexão com retaguarda para buscar dados e atualiza na base
//------------------------------------------------------------------
User Function TPDVA10A(cFilOri, aRegAtu)
	
	Local aDadosProc := {}
	Local lRet := .F.
	Local cIniCampo
	Local lInclui := .F.
    Local nX
	Local nY

    aDadosProc := Nil

	aParam := {cFilOri, aRegAtu}
	aParam := {"U_TPDVA10B",aParam}
	If !STBRemoteExecute("_EXEC_RET",aParam,,,@aDadosProc)
		// Tratamento do erro de conexao
		alert("Falha de comunicação com a retaguarda...")
		lRet := .F.

	ElseIf aDadosProc = Nil .or. Empty(aDadosProc) .or. Len(aDadosProc) == 0
		// Tratamento para retorno vazio
        alert("Ocorreu falha na recuperação dos dados do cliente...")
		lRet := .F.

	ElseIf Len(aDadosProc) > 0 //-- consulta realizada com sucesso
		lRet := .T.

	EndIf
    
    If lRet //se conectou e pegou os registros
	
		// LOG para saber os dados do array recebido
        //For nX:=1 to Len(aDadosProc)
        //    Conout(" >> TPDVA10A - aDadosProc[nX] => " + U_XtoStrin(aDadosProc[nX]))
        //Next nX
		
		BeginTran()
		
        //gravar alterações
		If valtype(aDadosProc) == "A" .AND. len(aDadosProc) > 0 .AND. valtype(aDadosProc[1]) == "A"
			
			//fazendo deleções
			For nX := 1 to len(aDadosProc)
				
				If ChkFile(aDadosProc[nX][1]) //verifica existência de arquivo

					If aDadosProc[nX][5] //se deletado
					
						cIniCampo := iif(left(aDadosProc[nX][1],1)<>"S",aDadosProc[nX][1],right(aDadosProc[nX][1],2))
						
						//AADD(aDadosProc, {_cTab,_nIndex,_cChave,_aCampos,_lDeleted})
						DbSelectArea(aDadosProc[nX][1])
						(aDadosProc[nX][1])->(DbSetOrder(aDadosProc[nX][2]))
					
						If (aDadosProc[nX][1])->(DbSeek(&(aDadosProc[nX][3]))) //se o registro existe, deleta
							
							If Reclock(aDadosProc[nX][1], .F.) 
								
								(aDadosProc[nX][1])->(DbDelete())
								(aDadosProc[nX][1])->(MsUnlock())

							EndIf 
							
						EndIf
						
					EndIf

				EndIf
				
			Next nX
			
			//fazendo alterações e inclusoes
			For nX := 1 to len(aDadosProc)

				If ChkFile(aDadosProc[nX][1]) //verifica existência de arquivo
				
					If !aDadosProc[nX][5] //se não deletado
					
						//Conout("aDadosProc = " + U_XtoStrin(aDadosProc[nX]))
						cIniCampo := iif(left(aDadosProc[nX][1],1)<>"S",aDadosProc[nX][1],right(aDadosProc[nX][1],2))
							
						//AADD(aDadosProc, {_cTab,_nIndex,_cChave,_aCampos,_lDeleted})
						DbSelectArea(aDadosProc[nX][1])
						(aDadosProc[nX][1])->(DbSetOrder(aDadosProc[nX][2]))
						
						If (aDadosProc[nX][1])->(DbSeek(&(aDadosProc[nX][3])))
							lInclui := .F. 
							
							//verificar registro se teve alteração na base DBF
							//neste caso aborto atualização
							if !empty(GetSx3Cache(cIniCampo+"_SITUA","X3_CAMPO")) //se o campo _SITUA existe
								If (aDadosProc[nX][1])->&(cIniCampo+"_SITUA") == "00" //se está pendente de subir
									//confirmo se realmente está pendente
									DbSelectArea("SLI")
									SLI->(DbSetOrder(3)) //LI_FILIAL+LI_ALIAS+LI_MSG
									If SLI->(DbSeek(xFilial("SLI")+aDadosProc[nX][1]+&(aDadosProc[nX][3]) ))
										LOOP //aborto a alteração
									EndIf
								EndIf
							EndIf  
							
						Else
							lInclui := .T.
						EndIf
						
						If Reclock(aDadosProc[nX][1], lInclui)
							
							For nY := 1 to Len(aDadosProc[nX][4])
								
								If aDadosProc[nX][4][nY][1] == cIniCampo+"_XSITUA"
									(aDadosProc[nX][1])->&(aDadosProc[nX][4][nY][1]) := "" 
									
								ElseIf aDadosProc[nX][4][nY][1] == cIniCampo+"_SITUA"
									(aDadosProc[nX][1])->&(aDadosProc[nX][4][nY][1]) := "" 
									
								ElseIf aDadosProc[nX][4][nY][1] == cIniCampo+"_MSEXP"
									(aDadosProc[nX][1])->&(aDadosProc[nX][4][nY][1]) := "" 
									
								ElseIf aDadosProc[nX][4][nY][1] == cIniCampo+"_HREXP"
									(aDadosProc[nX][1])->&(aDadosProc[nX][4][nY][1]) := "" 
									
								ElseIf aDadosProc[nX][4][nY][1] == cIniCampo+"_XINDEX"
									(aDadosProc[nX][1])->&(aDadosProc[nX][4][nY][1]) := 0 
									
								ElseIf !empty(GetSx3Cache( aDadosProc[nX][4][nY][1] ,"X3_CAMPO")) //se o campo _SITUA existe
									(aDadosProc[nX][1])->&(aDadosProc[nX][4][nY][1]) := aDadosProc[nX][4][nY][2]	
									
								EndIf 
								
							Next
							(aDadosProc[nX][1])->(MsUnlock())

						EndIf
					
					EndIf
				
				EndIf

			Next nX
			
		Else 
			lRet := .F.
		EndIf  
		
		EndTran()
		
	EndIf

Return lRet 

//--------------------------------------------------------
// Consulta dos dados na retaguarda
//--------------------------------------------------------
User Function TPDVA10B(cFilOri, aRegAtu)
    
    Local aDadosProc := {}
    Local nX := 0 
    Local cTabAtu
    Local cIndAtu 
    LOcal cTabDes  
    Local _cChave
    Local cQry := "" 
    Local cIniCampo
    Local nQtdReg 
    Local lAchou := .F.
    Local nRecPrin := 0
    
    Default cFilOri := ""
    Default aRegAtu := {}

	AddConfigs() //caso nao exista as configurações, cria
   	
   	//aRegAtu -> {alias, indice, chave_registro, addRet, tabela_destino, reg_deleted} )

	cHoraInicio := TIME() // Armazena hora de inicio do processamento...
	LjGrvLog("TPDVA10B", "INICIO - Consulta dos dados na retaguarda (F9)",)
	LjGrvLog("TPDVA10B", "Tempo: ", ElapTime( cHoraInicio, TIME() ))

   	nQtdReg := len(aRegAtu)
   	nX 		:= 1

    While nX <= nQtdReg
        
        //Conout("nX = " +Str(nX)+ "  aRegAtu = " + U_XtoStrin(aRegAtu))
        cTabAtu := aRegAtu[nX][1]  
        cIndAtu := aRegAtu[nX][2]  
        cTabDes := Alltrim(aRegAtu[nX][5]) 
        
        If aRegAtu[nX][6] //se registro pai está deletado
			SET DELETED OFF //Desabilita filtro do campo D_E_L_E_T_
		EndIf
        
        //tenta encontrar o registro
    	DbSelectArea(cTabAtu)
	    (cTabAtu)->(DbSetOrder(cIndAtu))
	    If (cTabAtu)->(DbSeek( aRegAtu[nX][3] ))
     		
     		lAchou := .T.
     		nRecPrin := (cTabAtu)->(Recno())
     		
             If aRegAtu[nX][4] //atualiza tbm esse registro
                _cChave := IndexKey(IndexOrd())
                If !Empty(_cChave)
                    _cChave := (cTabAtu)->&(_cChave)
                    AddReg(cTabAtu, cIndAtu, _cChave, @aDadosProc, (cTabAtu)->(Deleted()) /*lDeleted*/)
                EndIf
    		EndIf
    		
    	EndIf 
    	
    	If aRegAtu[nX][6] //se registro pai está deletado
        	SET DELETED ON //Habilita filtro do campo D_E_L_E_T_
        EndIf
    	
    	If lAchou //se achou o registro principal
    	
		    DbSelectArea("UCA")
		    UCA->(DbSetOrder(1))
		    UCA->(DbSeek(xFilial("UCA")+cTabAtu+cTabDes ))
		    While UCA->(!Eof()) .AND. UCA->(UCA_FILIAL+UCA_ALIORI)+iif(empty(cTabDes),"",UCA->UCA_ALIRET) == xFilial("UCA")+cTabAtu+cTabDes
      			
      			//posicionando no registro pai para pegar chave comparação
      			If aRegAtu[nX][6] //se registro pai está deletado
					SET DELETED OFF //Desabilita filtro do campo D_E_L_E_T_
                EndIf
		        (cTabAtu)->(DbGoTo( nRecPrin ))
		        _cChave := (cTabAtu)->&(UCA->UCA_CPOORI)
		    	If aRegAtu[nX][6] //se registro pai está deletado
		        	SET DELETED ON //Habilita filtro do campo D_E_L_E_T_
		        EndIf
      			
	        	cIniCampo := iif(left(UCA->UCA_ALIRET,1)<>"S",UCA->UCA_ALIRET,right(UCA->UCA_ALIRET,2))
	        	
	        	cQry := " SELECT R_E_C_N_O_, D_E_L_E_T_ ISDEL "
	        	cQry += " FROM "+RetSqlName(UCA->UCA_ALIRET)+" "
	        	cQry += " WHERE  "
	        	If UCA->UCA_DELETE == "S"
	        		cQry += " 1 = 1 "
	        	Else
	        		cQry += " D_E_L_E_T_ = ' ' "
	        	EndIf
	        	cQry += "   AND " + cIniCampo + "_FILIAL = '" + xFilial(UCA->UCA_ALIRET,cFilOri) + "' " 
	        	cQry += "   AND " + Alltrim(UCA->UCA_CHVCOM) + " = '" + _cChave + "' "
	        	If !empty(UCA->UCA_WHERE)
	        		cQry += "   AND " + &(Alltrim(UCA->UCA_WHERE))
	        	EndIf
	        	
	        	If Select("QRYTAB") > 0
					QRYTAB->(DbCloseArea())
				EndIf

				LjGrvLog("TPDVA10B", "cQuery:", cQry)
	        	cQry := ChangeQuery(cQry)
	        	TcQuery cQry New Alias "QRYTAB" // Cria uma nova area com o resultado do query
	        	QRYTAB->(DbGoTop())
				
				LjGrvLog("TPDVA10B", "lAchou", QRYTAB->(!Eof()))
				LjGrvLog("TPDVA10B", "Tempo: ", ElapTime( cHoraInicio, TIME() ))
	        	
	        	While QRYTAB->(!Eof()) 
	        	
	        		DbSelectArea(UCA->UCA_ALIRET)
	        		
	        		If UCA->UCA_DELETE == "S"
	        	   		SET DELETED OFF //Desabilita filtro do campo D_E_L_E_T_
	        		EndIf
	        		
		        	(UCA->UCA_ALIRET)->(DbGoTo( QRYTAB->R_E_C_N_O_ ))
		        	
		        	_cChave := (UCA->UCA_ALIRET)->&((UCA->UCA_ALIRET)->(INDEXKEY(UCA->UCA_INDRET)))
		        	AddReg(UCA->UCA_ALIRET, UCA->UCA_INDRET, _cChave, @aDadosProc, QRYTAB->ISDEL == "*" )
		        	
		        	AAdd(aRegAtu, {UCA->UCA_ALIRET, UCA->UCA_INDRET, _cChave, .F. /*não adiciona no aDadosProc*/, "", (QRYTAB->ISDEL == "*") } )
		        	nQtdReg++
		            
		            If UCA->UCA_DELETE == "S"
			        	SET DELETED ON //Habilita filtro do campo D_E_L_E_T_
			        EndIf
			        
		        	QRYTAB->(DbSkip())
		        EndDo
		        	
		        QRYTAB->(DBCLOSEAREA()) //Encerra Alias auxiliar
	        	
	        	UCA->(DbSkip())
	        EndDo
	    EndIf
	    
	    nX++
    Enddo

	// LOG para saber os dados do array enviado
    //For nX:=1 to Len(aDadosProc)
    //    Conout(" >> TPDVA10B - aDadosProc[nX] => " + U_XtoStrin(aDadosProc[nX]))
    //Next nX

	LjGrvLog("TPDVA10B", "Tempo: ", ElapTime( cHoraInicio, TIME() ))
	LjGrvLog("TPDVA10B", "FIM - Consulta dos dados na retaguarda (F9)",)

Return aDadosProc   

//--------------------------------------------------------
// Considera que o registro ja está posicionado
//--------------------------------------------------------
Static Function AddReg(_cTab, _nIndex, _cChave, aDadosProc, lDeleted)
	
	Local _aCampos := {}
	Local aSX3Tab, nX
	
	If !lDeleted
		
		aSX3Tab := FWSX3Util():GetAllFields( _cTab , .F./*lVirtual*/ )
		For nX := 1 to len(aSX3Tab)
			//Campos que serao ignorados
			if "_USERLGI" $ aSX3Tab[nX] .OR.;
				"_USERLGA" $ aSX3Tab[nX] .OR. ;
				"_MSEXP" $ aSX3Tab[nX] .OR. ;
				"_HREXP" $ aSX3Tab[nX] .OR. ;
				"_SITUA" $ aSX3Tab[nX] .OR. ;
				"_XSITUA" $ aSX3Tab[nX]
			else
				aadd(_aCampos, { aSX3Tab[nX] , (_cTab)->( FieldGet( FieldPos(aSX3Tab[nX]) ) ) })
			endif
		next nX

    EndIf
	
	If Len(_aCampos) > 0 .OR. lDeleted
		AADD(aDadosProc, {_cTab, _nIndex, "'"+_cChave+"'", _aCampos, lDeleted})
	EndIf
	
Return


Static Function AddConfigs()

	Local aCfgTab := {}
	Local nX

	dbSelectArea("UCA")
    UCA->(dbSetOrder(1))
	UCA->(dbGoTop())
	UCA->(DbSeek(xFilial("UCA")))
	if UCA->(Eof()) //se nao tem registros ainda

		aadd(aCfgTab, {"SA1","A1_COD+A1_LOJA","DA3",1,"DA3_XCODCL+DA3_XLOJCL","","S"} )
		aadd(aCfgTab, {"SA1","A1_COD+A1_LOJA","U25",1,"U25_CLIENT+U25_LOJA",'"'+"(U25_DTFIM = '' OR U25_DTFIM >= '"+'"+DTOS(MonthSub(DDATABASE,5))+"'+"')"+'"',"S"} )
		aadd(aCfgTab, {"SA1","A1_COD+A1_LOJA","U52",1,"U52_CODCLI+U52_LOJA","","S"} )
		aadd(aCfgTab, {"SA1","A1_COD+A1_LOJA","U53",1,"U53_CODCLI+U53_LOJA","","S"} )
		aadd(aCfgTab, {"ACY","ACY_GRPVEN","DA3",1,"DA3_XGRPCL","","S"} )
		aadd(aCfgTab, {"ACY","ACY_GRPVEN","U25",1,"U25_GRPCLI",'"'+"(U25_DTFIM = '' OR U25_DTFIM >= '"+'"+DTOS(MonthSub(DDATABASE,5))+"'+"')"+'"',"S"} )
		aadd(aCfgTab, {"ACY","ACY_GRPVEN","U52",1,"U52_GRPVEN","","S"} )
		aadd(aCfgTab, {"ACY","ACY_GRPVEN","U53",1,"U53_GRPVEN","","S"} )

		for nX := 1 to len(aCfgTab)
			RecLock("UCA", .t.)
				UCA->UCA_FILIAL := xFilial("UCA")
				UCA->UCA_ALIORI := aCfgTab[nX][1]
				UCA->UCA_CPOORI := aCfgTab[nX][2]
				UCA->UCA_ALIRET := aCfgTab[nX][3]
				UCA->UCA_INDRET := aCfgTab[nX][4]
				UCA->UCA_CHVCOM := aCfgTab[nX][5]
				UCA->UCA_WHERE  := aCfgTab[nX][6]
				UCA->UCA_DELETE := aCfgTab[nX][7]
			MsUnlock()
		next nX

	Endif

Return

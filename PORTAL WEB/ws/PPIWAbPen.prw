#include 'protheus.ch'
#include 'parmtype.ch'
#include 'topconn.ch'

/*/{Protheus.doc} User Function PPIWAbPen
WebService busca de abastecimentos
@type  Function
@author thebritto
@since 07/04/2020
@version 1
@param oEnv, object, recebido pelo WS
@return nil
/*/
User Function PPIWAbPen(oEnvXml, oRetXml)
    
    GetMIDPend(oEnvXml:cBico, oEnvXml:cVendedor, @oRetXml)

Return 

//
// Atualiza o grid de abastecimentos pendentes da tela do PDV
//
Static Function GetMIDPend(cFilBico, cFilVend, oRetXml)

    Local cQry			:= ""
    Local cNomVend      := ""
    Local lSQLite := AllTrim(Upper(GetSrvProfString("RpoDb",""))) == "SQLITE" //PDVM/Fat Client

    //ajsute tamanho de campo bico colocando zeros a esquerda
	MIC->(DbSetOrder(3)) //MIC_FILIAL+MIC_CODBIC+MIC_CODTAN
	If !Empty(cFilBico)
		If !MIC->(DbSeek(xFilial("MIC")+cFilBico))
			If MIC->(DbSeek(xFilial("MIC")+padl(AllTrim(cFilBico),tamsx3("MID_CODBIC")[1],"0")))
				cFilBico := padl(AllTrim(cFilBico),tamsx3("MID_CODBIC")[1],"0")
			EndIf
		EndIf
	EndIf

    //CENTRAL SEMPRE É TOPCONN
    cQry += "select distinct(MID.R_E_C_N_O_) MIDRECNO, "
    cQry += " (select A3_NOME from " + RetSqlName("SA3") + " SA3 "
    cQry += "   where SA3.d_e_l_e_t_ = ' ' "
    cQry += "   and SA3.A3_FILIAL = '"+xFilial("SA3")+"' "
    If lSQLite
        cQry += "   and A3_RFID like '%'||RTRIM(MID_RFID)||'%' LIMIT 1) as A3_NOME, "
    Else
        cQry += "   and A3_RFID like CONCAT('%',RTRIM(MID_RFID),'%') LIMIT 1) as A3_NOME, "
    EndIf
    cQry += " MID.* "
    cQry += "	from " + RetSqlName("MID") + " MID"
    cQry += "	inner join " + RetSqlName("MIC") + " MIC" //-- posiciono na tabela de bicos
    cQry += "		on (MIC_FILIAL = MID_FILIAL "
    cQry += "			and MIC_CODBIC = MID_CODBIC "
    //cQry += " 			and MIC_STATUS = '1'" //1=Ativado;2=Desativado;
    cQry += "           AND ((MIC_STATUS = '1' AND MIC_XDTATI <= '"+DToS(dDataBase)+"') OR (MIC_STATUS = '2' AND MIC_XDTDES >= '"+DToS(dDataBase)+"'))"
    cQry += "			and MIC.D_E_L_E_T_ = ' ')"
    cQry += "	where MID.D_E_L_E_T_ = ' ' "
    cQry += "   and MID_FILIAL = '"+ xFilial("MID") + "' "
    cQry += "   and MID_NUMORC IN ('"+Padr("P",tamsx3("MID_NUMORC")[1])+"','"+Padr("PP",tamsx3("MID_NUMORC")[1])+"','"+Padr("O",tamsx3("MID_NUMORC")[1])+"') "
    If !Empty(cFilBico)
        cQry += " and MID_CODBIC like '%" + AllTrim(cFilBico) + "%'"
    EndIf

    If Select("QRYMID") > 0
        QRYMID->(DbCloseArea())
    EndIf

    cQry := ChangeQuery(cQry)
    TcQuery cQry New Alias "QRYMID" // Cria uma nova area com o resultado do query

    QRYMID->(dbGoTop())
    While QRYMID->(!Eof())

        MID->(DbGoTo(QRYMID->MIDRECNO))
        
        //filtro vendedor
        cNomVend := Alltrim(QRYMID->A3_NOME) 
        If !Empty(cFilVend) .AND. !(AllTrim(cFilVend) $ cNomVend)
            QRYMID->( DbSkip() )
            Loop
        EndIf

        //cria objeto e add no array de retorno
        AAdd( oRetXml:aAbastPen, ObjWSMID() )

        QRYMID->(DbSkip())
    EndDo

    QRYMID->(DbCloseArea())

Return

//Monta Objeto retorno a partir da MID
Static Function ObjWSMID()
    
    Local oNewAbast
    Local nTimerAba := SuperGetMV("MV_XTABAST",,120) //tempo em minutos para destacar abastecimentos pendentes: default 2 hora
    Local lDestaca := .F.

    //se data e hora do abastecimento for menor ou igual ao tempo
    if DTOS(MID->MID_DATACO)+MID->MID_HORACO <= RetDtHora(nTimerAba)
        lDestaca := .T.
    endif

    // Cria e alimenta uma nova instancia do contrato
    oNewAbast :=  WSClassNew( "AbastPen" )
    oNewAbast:cDestaca := iif(lDestaca,"S","N")
    oNewAbast:cBico := MID->MID_CODBIC
    oNewAbast:cData := DTOS(MID->MID_DATACO)
    oNewAbast:cHora := MID->MID_HORACO
    oNewAbast:cProduto := Alltrim(POSICIONE('SB1',1,XFILIAL('SB1')+ MID->MID_XPROD ,'B1_DESC'))
    oNewAbast:nQtd := MID->MID_LITABA
    oNewAbast:nVlrUnit := MID->MID_PREPLI
    oNewAbast:nVlrTot := MID->MID_TOTAPA
    oNewAbast:nEncerr := MID->MID_ENCFIN
    oNewAbast:cVendedor := Alltrim(QRYMID->A3_NOME) 
    
Return oNewAbast

//
// Atualiza o grid de abastecimentos pendentes da tela do PDV
//
Static Function GetU51Pend(cFilBico, cFilVend, oRetXml)

    Local cQry			:= ""
    Local cNomVend      := ""

    U50->(DbSetOrder(5)) //U50_FILIAL+U50_NUM
    If !Empty(cFilBico)
        If !U50->(DbSeek(xFilial("U50")+cFilBico))
            If U50->(DbSeek(xFilial("U50")+padl(AllTrim(cFilBico),tamsx3("U51_NUMBIC")[1],"0")))
                cFilBico := padl(AllTrim(cFilBico),tamsx3("U51_NUMBIC")[1],"0")
            EndIf
        EndIf
    EndIf

    #IFDEF TOP

        cQry += "select distinct(U51.R_E_C_N_O_) U51RECNO, U51.*"
        cQry += "	from " + RetSqlName("U51") + " U51"
        cQry += "	inner join " + RetSqlName("U50") + " U50" //-- posiciono na tabela de bicos
        cQry += "		on (U50.U50_FILIAL = U51.U51_FILIAL"
        cQry += "			and U50.U50_NUM = U51.U51_NUMBIC"
        cQry += "			and U50.U50_CODIGO = U51.U51_CODBIC"
        cQry += "			and U50.U50_NLOGIC = U51.U51_NLOGIC"
        cQry += "			and U50.U50_GRPTQ = U51.U51_GRPTQ"
        cQry += " 			and U50.U50_STATUS = '1'" //1=Ativado;2=Desativado;
        cQry += "			and U50.D_E_L_E_T_ <> '*')"
        cQry += "	where U51.D_E_L_E_T_ <> '*'"
        cQry += "   and U51.U51_FILIAL = '"+ xFilial("U51") + "' "
        cQry += "	and U51.U51_STATUS = '1'"
        If !Empty(cFilBico)
            cQry += "	and U51.U51_NUMBIC like '%" + AllTrim(cFilBico) + "%'"
        EndIf

        If Select("QRYU51") > 0
            QRYU51->(DbCloseArea())
        EndIf

        cQry := ChangeQuery(cQry)
        TcQuery cQry New Alias "QRYU51" // Cria uma nova area com o resultado do query

        QRYU51->(dbGoTop())

        While QRYU51->(!Eof())

            U51->(DbGoTo(QRYU51->U51RECNO))
            
            //filtro vendedor (virtual)
            cNomVend := Alltrim(POSICIONE("SA3",1,XFILIAL("SA3")+POSICIONE("U68",3,XFILIAL("U68")+U51->U51_IDVEND,"U68_VEND"),"A3_NOME"))
            If !Empty(cFilVend) .AND. !(AllTrim(cFilVend) $ cNomVend)
                QRYU51->( DbSkip() )
                Loop
            EndIf

            //cria objeto e add no array de retorno
            AAdd( oRetXml:aAbastPen, ObjWSU51() )

            QRYU51->(DbSkip())
        EndDo

        QRYU51->(DbCloseArea())

    #ELSE

        U50->(DbSetOrder(1)) //U50_FILIAL+U50_CODIGO
        U51->(DbSetOrder(5)) //U51->FILIAL+U51_STATUS+U51_CODIGO

        U51->(DbGoTop())
        U51->(DbSeek(xFilial("U51") + "1")) // apenas abastecimentos em aberto

        while !U51->( Eof() ) .and. (U51->U51_FILIAL == xFilial("U51")) .and. (U51->U51_STATUS == "1")

            //verifico ativacao do bico
            if !U50->( DbSeek(xFilial("U50") + U51->U51_CODBIC) ) .OR. U50->U50_STATUS <> '1'
                U51->( DbSkip() )
                Loop
            endif
            //filtro bicos
            If !Empty(cFilBico) .AND. !(AllTrim(cFilBico) $ U51->U51_NUMBIC)
                U51->( DbSkip() )
                Loop
            EndIf
            //filtro vendedor (virtual)
            cNomVend := Alltrim(POSICIONE("SA3",1,XFILIAL("SA3")+POSICIONE("U68",3,XFILIAL("U68")+U51->U51_IDVEND,"U68_VEND"),"A3_NOME"))
            If !Empty(cFilVend) .AND. !(AllTrim(cFilVend) $ cNomVend)
                U51->( DbSkip() )
                Loop
            EndIf

            //cria objeto e add no array de retorno
            AAdd( oRetXml:aAbastPen, ObjWSU51() )

            U51->( DbSkip() )

        enddo

    #ENDIF

Return

//Monta Objeto retorno a partir da U51
Static Function ObjWSU51()
    
    Local oNewAbast
    Local nTimerAba := SuperGetMV("MV_XTABAST",,120) //tempo em minutos para destacar abastecimentos pendentes: default 2 hora
    Local lDestaca := .F.

    //se data e hora do abastecimento for menor ou igual ao tempo
    if DTOS(U51->U51_DATA)+U51->U51_HORA <= RetDtHora(nTimerAba)
        lDestaca := .T.
    endif

    // Cria e alimenta uma nova instancia do contrato
    oNewAbast :=  WSClassNew( "AbastPen" )
    oNewAbast:cDestaca := iif(lDestaca,"S","N")
    oNewAbast:cBico := U51->U51_NUMBIC
    oNewAbast:cData := DTOS(U51->U51_DATA)
    oNewAbast:cHora := U51->U51_HORA
    oNewAbast:cProduto := Alltrim(POSICIONE('SB1',1,XFILIAL('SB1')+U51->U51_PROD,'B1_DESC'))
    oNewAbast:nQtd := U51->U51_QTDLT
    oNewAbast:nVlrUnit := U51->U51_VLUNIT
    oNewAbast:nVlrTot := U51->U51_TOTAL
    oNewAbast:nEncerr := U51->U51_ENCERR
    oNewAbast:cVendedor := Alltrim(POSICIONE("SA3",1,XFILIAL("SA3")+POSICIONE("U68",3,XFILIAL("U68")+U51->U51_IDVEND,"U68_VEND"),"A3_NOME"))
    
Return oNewAbast

//calcula data/hora para destacar
Static Function RetDtHora(nMinutos)
	
	Local cHrAtu := Substr(Time(),1,5)
	Local _nHora := Val(Substr(cHrAtu,1,2))
	Local _nMin  := Val(Substr(cHrAtu,4,2))
	Local cHrRet := ""
	Local cDtRet := Date()
	
	while nMinutos >= 60
		nMinutos -= 60		
		_nHora -= 1
		
		if _nHora < 0
			_nHora := 23
			cDtRet := cDtRet - 1
		endif
	enddo
	
	if nMinutos > 0
		if _nMin < nMinutos  
			_nHora -= 1 
			if _nHora < 0
				_nHora := 23
				cDtRet := cDtRet - 1
			endif
			_nMin := 60 - nMinutos + _nMin
		else
			_nMin -= nMinutos
		endif
	endif

	cHrRet := StrZero(_nHora,2)+":"+StrZero(_nMin,2)
	
Return DTOS(cDtRet)+cHrRet 

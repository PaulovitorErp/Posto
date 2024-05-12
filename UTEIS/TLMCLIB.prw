#include "protheus.ch"
#include "topconn.ch"

/*/{Protheus.doc} TLmcLib
Classe para Consultas e Gravação dados LMC

@author    Danilo Brito
@since     06/08/2020
@version   1.0
@type class
/*/
class TLmcLib

    DATA cProd //produto
    DATA dData //data do livro
    DATA aTq   //tanques a consultar
    DATA cBico //Filtro por Bico
    DATA lU0I  //Define se tem tabela U0I-historico vendas

    //Define o tipo de retorno do metodo RetVen: 1=Vlr Total Vendas; 2=Array Dados; 3=Qtd Registros
    DATA nTRetVen  

    //Define os campos de retorno, caso tipo retorno seja 2 (array dados)
    //Valores possíveis: {_TANQUE, _BICO, _NLOGIC, _BOMBA, _PROD, _FECH, _ABERT, _AFERIC, _VDBICO, _VDSUMMID}
    DATA aCpRetVen  

    method New(_cProd, _dData) constructor
    method SetChave(_cProd, _dData)
    method SetTanques(aTanques)
    method SetBico(_cBico)
	method SetTRetVen(nTipo)
    method SetDRetVen(aCampos)

    //Metodos de retorno dados de Venda
    method RetVen(lQry)
    method RetVenQry()
    method RetVenU0I()
	method RetManut(nTp,cBomba,cBico,nAbertura)
	method RetAbManut(cTq,cBico,cBomba)
	method RetFechM(cTq,cBico,cBomba,nFech)
    method RetAferic(cTq,cBico,nFech,nAbert)

endclass

/*/{Protheus.doc} New
Metodo Construtor

@author Danilo Brito
@since 06/08/2020
@version 1.0
@return Objeto da classe
@type function
/*/
method New(_cProd, _dData) class TLmcLib

    Default _cProd := ""
    Default _dData := stod("")

    ::cProd := _cProd
    ::dData := _dData
    ::aTq := {}
    ::cBico := ""
    ::lU0I := ChkFile("U0I")

    ::nTRetVen := 1 //Default valor total
    ::aCpRetVen := {}

Return

/*/{Protheus.doc} SetChave
Seta a chave de Produto e Data a trabalhar

@author Danilo Brito
@since 10/08/2020
@version 1.0
@return Objeto da classe
@type function
/*/
method SetChave(_cProd, _dData) class TLmcLib
    ::cProd := _cProd
    ::dData := _dData
Return

/*/{Protheus.doc} SetTanques
Seta os codigos de tanques a utilizar nas buscas

@author Danilo Brito
@since 06/08/2020
@version 1.0
@return Nil
@type function
/*/
method SetTanques(aTanques) class TLmcLib
    ::aTq := aTanques
return

/*/{Protheus.doc} SetTanques
Seta os codigos de tanques a utilizar nas buscas

@author Danilo Brito
@since 06/08/2020
@version 1.0
@return Nil
@type function
/*/
method SetBico(_cBico) class TLmcLib
    ::cBico := _cBico
return


/*/{Protheus.doc} SetTRetVen
Seta o tipo de retorno da funcao RetVen 
1=Vlr Total Vendas; 2=Array Dados; 3=Qtd Registros

@author Danilo Brito
@since 06/08/2020
@version 1.0
@return Nil
@type function
/*/
method SetTRetVen(nTipo) class TLmcLib
    ::nTRetVen := nTipo
return


/*/{Protheus.doc} SetDRetVen
Seta os campos de retorno da funcao RetVen, quanto tipo retorno for 2(array)
//Valores possíveis: {_TANQUE, _BICO, _NLOGIC, _BOMBA, _PROD, _FECH, _ABERT, _AFERIC, _VDBICO, _VDSUMMID}

@author Danilo Brito
@since 06/08/2020
@version 1.0
@return Nil
@type function
/*/
method SetDRetVen(aCampos) class TLmcLib
    ::aCpRetVen := aCampos
return

/*/{Protheus.doc} RetVen
Busca Dados de Venda do LMC, olhando se busca da Qry ou tabela U0I

@author Danilo Brito
@since 06/08/2020
@version 1.0
@return Nil
@type function
/*/
method RetVen(lQry) class TLmcLib

    Local xRet
    Default lQry := .F.

    If !::lU0I //se tabela nao presente no dicionario, é sempre por query
        lQry := .T.
    EndIf

    If !lQry //se nao buscar da query, vejo se tem U0I. Se nao tem faço pela query
        U0I->(DbSetOrder(1)) //U0I_FILIAL+U0I_DATA+U0I_PROD+U0I_TANQUE+U0I_BICO
		lQry := !U0I->(DbSeek(xFilial("U0I")+DTOS(::dData)+::cProd ))
    EndIf

    If lQry
        xRet := ::RetVenQry()
    Else
        xRet := ::RetVenU0I()
    EndIf

Return xRet

/*/{Protheus.doc} RetVen
Busca Dados de Venda do LMC

@author Danilo Brito
@since 06/08/2020
@version 1.0
@return Nil
@type function
/*/
method RetVenQry() class TLmcLib

    Local nI
    Local xRet
    Local aTmp := {}

    Local cQry 			:= ""
    Local cTq			:= ""

    Local nAbert 		:= 0
    Local nAbert2 		:= 0
    Local nFech			:= 0
    Local nFech2		:= 0
    Local nAferic		:= 0  

    Local lManut		:= .F.
    Local lManutDia		:= .F.
    Local lSemMovDia    := .F.

    Local cSGBD 	 	:= Upper(AllTrim(TcGetDB()))	// Guarda Gerenciador de banco de dados

    Private nAbManut	:= 0
    Private nAbManut2	:= 0
    Private nFcManut	:= 0

    //1=Vlr Total Vendas; 2=Array Dados; 3=Qtd Registros
    If ::nTRetVen == 2
        xRet := {}
    Else
        xRet := 0
    EndIf

    //se nao passado os tanques, busco
    If empty(::aTq)
        If Select("QRYTQ") > 0
            QRYTQ->(DbCloseArea())
        EndIf

        cQry := "SELECT MHZ_CODTAN"
        cQry += CRLF + " FROM "+RetSqlName("MHZ")+""
        cQry += CRLF + " WHERE D_E_L_E_T_ 	<> '*'"
        cQry += CRLF + " AND MHZ_FILIAL	= '"+xFilial("MHZ")+"'"
        cQry += CRLF + " AND MHZ_CODPRO	= '"+::cProd+"'"
        cQry += CRLF + " AND ((MHZ_STATUS = '1' AND MHZ_DTATIV <= '"+DTOS(::dData)+"') OR (MHZ_STATUS = '2' AND MHZ_DTDESA >= '"+DTOS(::dData)+"'))"
        cQry += CRLF + " ORDER BY 1"

        cQry := ChangeQuery(cQry)
        //MemoWrite("c:\temp\TRETE009.txt",cQry)
        TcQuery cQry NEW Alias "QRYTQ"

        While QRYTQ->(!EOF())

            aAdd(::aTq,QRYTQ->MHZ_CODTAN)

            QRYTQ->(dbSkip())
        EndDo
        
        QRYTQ->(DbCloseArea())
    EndIf

    //tratando tanques para query
    If len(::aTq) == 0 
        cTq := "'  '"
    ElseIf len(::aTq) == 1
        cTq := "'"+::aTq[1]+"'"
    Else
        For nI := 1 To Len(::aTq)
            If nI == Len(::aTq)
                cTq += "'" + ::aTq[nI] + "'"
            Else
                cTq += "'" + ::aTq[nI] + "',"
            EndIf
        Next nI
    EndIf

    If Select("QRYVEN") > 0
        QRYVEN->(DbCloseArea())
    EndIf

    cQry := "SELECT MIC.MIC_CODTAN, MIC.MIC_CODBIC, "+ ;
                "MIC.MIC_NLOGIC, MIC.MIC_CODBOM, "+ ;
                "MIC.MIC_STATUS, "

    //Maior encerrante do Dia
    cQry += CRLF + " (SELECT MAX(MID_ENCFIN)"
    cQry += CRLF + " FROM "+RetSqlName("MID")+""
    cQry += CRLF + " WHERE D_E_L_E_T_ <> '*'"
    cQry += CRLF + " AND MID_FILIAL	= '"+xFilial("MID")+"'"
    cQry += CRLF + " AND MID_XPROD	= '"+::cProd+"'"
    cQry += CRLF + " AND MID_DATACO	= '"+DTOS(::dData)+"'"
    cQry += CRLF + " AND MID_CODTAN	= MIC.MIC_CODTAN"
    cQry += CRLF + " AND MID_CODBIC	= MIC.MIC_CODBIC"
    cQry += CRLF + " AND MID_CODBOM	= MIC.MIC_CODBOM"
    cQry += CRLF + ") AS FECH,

    //Encerrante inicial do dia, considerando a ordem MID registrada (recno)
    If "ORACLE" $ cSGBD //Oracle 
        cQry += CRLF + " (SELECT MID_ENCFIN - MID_LITABA"
    else
        cQry += CRLF + " (SELECT TOP 1 MID_ENCFIN - MID_LITABA"
    endif
    cQry += CRLF + " FROM "+RetSqlName("MID")+""
    cQry += CRLF + " WHERE D_E_L_E_T_ <> '*'"
    cQry += CRLF + " AND MID_FILIAL	= '"+xFilial("MID")+"'"
    cQry += CRLF + " AND MID_XPROD	= '"+::cProd+"'"
    cQry += CRLF + " AND MID_DATACO	= '"+DTOS(::dData)+"'"
    cQry += CRLF + " AND MID_CODTAN	= MIC.MIC_CODTAN"
    cQry += CRLF + " AND MID_CODBIC	= MIC.MIC_CODBIC"
    cQry += CRLF + " AND MID_CODBOM	= MIC.MIC_CODBOM"
    If "ORACLE" $ cSGBD //Oracle 
		cQry += CRLF + " AND ROWNUM <= 1"
    endif
    cQry += CRLF + ") AS ABERT_M,"

    //Encerrante inicial do dia, considerando o menor encerrante do dia
    If "ORACLE" $ cSGBD //Oracle 
        cQry += CRLF + " (SELECT MID_ENCFIN - MID_LITABA"
    else
        cQry += CRLF + " (SELECT TOP 1 MID_ENCFIN - MID_LITABA"
    endif
    cQry += CRLF + " FROM "+RetSqlName("MID")+""
    cQry += CRLF + " WHERE D_E_L_E_T_ <> '*'"
    cQry += CRLF + " AND MID_FILIAL	= '"+xFilial("MID")+"'"
    cQry += CRLF + " AND MID_XPROD	= '"+::cProd+"'"
    cQry += CRLF + " AND MID_DATACO	= '"+DTOS(::dData)+"'"
    cQry += CRLF + " AND MID_CODTAN	= MIC.MIC_CODTAN"
    cQry += CRLF + " AND MID_CODBIC	= MIC.MIC_CODBIC"
    cQry += CRLF + " AND MID_CODBOM	= MIC.MIC_CODBOM"
    cQry += CRLF + " AND MID_ENCFIN	= (SELECT MIN(MID_ENCFIN)"
    cQry += CRLF + " 						FROM "+RetSqlName("MID")+""
    cQry += CRLF + " 						WHERE D_E_L_E_T_ 	<> '*'"
    cQry += CRLF + " 						AND MID_FILIAL		= '"+xFilial("MID")+"'"
    cQry += CRLF + " 						AND MID_XPROD		= '"+::cProd+"'"
    cQry += CRLF + " 						AND MID_DATACO		= '"+DTOS(::dData)+"'"
    cQry += CRLF + " 						AND MID_CODTAN		= MIC.MIC_CODTAN"
    cQry += CRLF + " 						AND MID_CODBIC		= MIC.MIC_CODBIC"
    cQry += CRLF + "                        AND MID_CODBOM	    = MIC.MIC_CODBOM"
    cQry += CRLF + ")"
    If "ORACLE" $ cSGBD //Oracle 
		cQry += CRLF + " AND ROWNUM <= 1"
    endif
    cQry += CRLF + ") AS ABERT_DT,"

    //Encerrante inicial do dia, considerando o maior encerrante do dia anterior
    cQry += CRLF + " (SELECT MAX(MID_ENCFIN)"
    cQry += CRLF + " FROM "+RetSqlName("MID")+""
    cQry += CRLF + " WHERE D_E_L_E_T_ <> '*'"
    cQry += CRLF + " AND MID_FILIAL	= '"+xFilial("MID")+"'"
    cQry += CRLF + " AND MID_XPROD	= '"+::cProd+"'"
    cQry += CRLF + " AND MID_DATACO	< '"+DTOS(::dData)+"'"
    cQry += CRLF + " AND MID_CODTAN	= MIC.MIC_CODTAN"
    cQry += CRLF + " AND MID_CODBIC	= MIC.MIC_CODBIC"
    cQry += CRLF + " AND MID_CODBOM	= MIC.MIC_CODBOM"
    cQry += CRLF + ") AS ABERT,"

    //somando afericoes
    cQry += CRLF + " (SELECT SUM(MID_LITABA)"
    cQry += CRLF + " FROM "+RetSqlName("MID")+""
    cQry += CRLF + " WHERE D_E_L_E_T_ <> '*'"
    cQry += CRLF + " AND MID_FILIAL	= '"+xFilial("MID")+"'"
    cQry += CRLF + " AND MID_XPROD	= '"+::cProd+"'"
    cQry += CRLF + " AND MID_DATACO	= '"+DTOS(::dData)+"'"
    cQry += CRLF + " AND MID_CODTAN	= MIC.MIC_CODTAN"
    cQry += CRLF + " AND MID_CODBIC	= MIC.MIC_CODBIC"
    cQry += CRLF + " AND MID_CODBOM	= MIC.MIC_CODBOM"
    cQry += CRLF + " AND MID_AFERIR	= 'S'" //Aferição
    cQry += CRLF + " ) AS AFERIC "

    //somando o volume de vendas pela litragem
    If aScan(::aCpRetVen, "_VDSUMMID")
        cQry += CRLF + ", (SELECT SUM(MID_LITABA)"
        cQry += CRLF + " FROM "+RetSqlName("MID")+""
        cQry += CRLF + " WHERE D_E_L_E_T_ <> '*'"
        cQry += CRLF + " AND MID_FILIAL	= '"+xFilial("MID")+"'"
        cQry += CRLF + " AND MID_XPROD	= '"+::cProd+"'"
        cQry += CRLF + " AND MID_DATACO	= '"+DTOS(::dData)+"'"
        cQry += CRLF + " AND MID_CODTAN	= MIC.MIC_CODTAN"
        cQry += CRLF + " AND MID_CODBIC	= MIC.MIC_CODBIC"
        cQry += CRLF + " AND MID_CODBOM	= MIC.MIC_CODBOM"
        cQry += CRLF + " AND MID_AFERIR	<> 'S'" //diferente de Aferição
        cQry += CRLF + " ) AS VDSUMMID"
    EndIf

    cQry += CRLF + " FROM "+RetSqlName("MIC")+" MIC"
    cQry += CRLF + " WHERE MIC.D_E_L_E_T_ <> '*'"
    cQry += CRLF + " AND MIC.MIC_FILIAL	= '"+xFilial("MIC")+"'"
    If len(::aTq) > 1
        cQry += CRLF + " AND MIC.MIC_CODTAN IN ("+cTq+")"
    Else
        cQry += CRLF + " AND MIC.MIC_CODTAN = " + cTq 
    EndIf

    If !empty(::cBico)
        cQry += CRLF + " AND MIC.MIC_CODBIC = '"+::cBico+"' "
    EndIf

    //cQry += CRLF + " AND MIC.MIC_STATUS = '1'"
    cQry += CRLF + " AND ((MIC.MIC_STATUS = '1' AND MIC.MIC_XDTATI <= '"+DTOS(::dData)+"') OR (MIC.MIC_STATUS = '2' AND MIC.MIC_XDTDES >= '"+DTOS(::dData)+"'))"
    cQry += CRLF + " ORDER BY 3"

    cQry := ChangeQuery(cQry)
    MemoWrite("c:\temp\QRYVEND.txt",cQry)
    TcQuery cQry NEW Alias "QRYVEN"

    If QRYVEN->(!EOF())

        While QRYVEN->(!EOF())

            lSemMovDia := QRYVEN->FECH <= 0 .and. QRYVEN->ABERT_DT <= 0 //bico sem movimento no dia (sem encerrante de fechamento e sem encerrante de abertura no dia)

            //se retorna só quantidade de registros
            If ::nTRetVen == 3
                If QRYVEN->FECH == 0 .And. QRYVEN->ABERT == 0
                    If QRYVEN->MIC_STATUS == "2" //Inativo
                        QRYVEN->(DbSkip())
                        LOOP
                    EndIf
                Else
                    xRet++
                EndIf
                
                QRYVEN->(DbSkip())
                LOOP
            EndIf

            nAbert 		:= 0
            nAbert2		:= 0
            nFech		:= 0
            nFech2		:= 0

            If QRYVEN->FECH == 0 .And. QRYVEN->ABERT == 0
                If QRYVEN->MIC_STATUS == "2" //Inativo
                    QRYVEN->(DbSkip())
                    LOOP
                EndIf
            Else
                lManut 		:= ::RetManut(1,QRYVEN->MIC_CODBOM,QRYVEN->MIC_CODBIC,QRYVEN->ABERT)
                lManutDia 	:= ::RetManut(2,QRYVEN->MIC_CODBOM,QRYVEN->MIC_CODBIC,IIF(QRYVEN->ABERT_DT < QRYVEN->ABERT_M,QRYVEN->ABERT_M,QRYVEN->ABERT_DT))

                If lManut .or. lManutDia

                    If lManutDia
                        nAbert 	:= nAbManut
                        nAbert2	:= nAbManut2
                        nFech	:= nFcManut

                    Else
                        nAbert := ::RetAbManut(QRYVEN->MIC_CODTAN,QRYVEN->MIC_CODBIC,QRYVEN->MIC_CODBOM)
                        If nAbert == 0
                            nAbert := QRYVEN->ABERT_DT
                            If nAbert == 0
                                nAbert := nAbManut
                            EndIf
                        EndIf
                        If QRYVEN->FECH > 0
                            nFech	:= QRYVEN->FECH
                        Else
                            nFech	:= nAbert
                        EndIf
                    EndIf
                Else
                    If QRYVEN->ABERT > 0
                        nAbert 	:= QRYVEN->ABERT
                    Else
                        nAbert 	:= QRYVEN->ABERT_DT
                    EndIf
                    If QRYVEN->FECH > 0
                        nFech	:= QRYVEN->FECH
                    Else
                        nFech	:= nAbert
                    EndIf
                EndIf
            EndIf

            //se retorna total venda
            If ::nTRetVen == 1

                If lManutDia

                    nFech2 := ::RetFechM(QRYVEN->MIC_CODTAN,QRYVEN->MIC_CODBIC,QRYVEN->MIC_CODBOM,nFech)

                    If /*nAbert2 > 0 .And.*/ nFech2 > 0

                        //Se houve manutenção de bomba no dia, considerar somente se houve abastecimento anterior a manutenção
                        If nAbert <> nAbert2 .And. (nAbert2 - nAbert <> nAbert2) .And. IIF(nAbert2 > 0,abs(nAbert2 - nAbert) > 0.05,.T.)
                            xRet += nFech - nAbert + (nFech2 - nAbert2)
                        Else 
                            xRet += nFech2 - nAbert2
                        EndIf
                    Else
                        //Se houve manutenção de bomba no dia, considerar somente se houve abastecimento anterior a manutenção
                        If nAbert <> nAbert2 .And. (nAbert2 - nAbert <> nAbert2) .And. IIF(nAbert2 > 0,abs(nAbert2 - nAbert) > 0.05,.T.)
                            xRet += nFech - nAbert
                        EndIf
                    EndIf
                Else
                    //Se houve manutenção de bomba no dia, considerar somente se houve abastecimento anterior a manutenção
                    //DANILO: Comentado pois sempre o nAbert2 está zerado caso variavel lManutDia seja falso
                    //If nAbert <> nAbert2 .And. (nAbert2 - nAbert <> nAbert2) .And. IIF(nAbert2 > 0,abs(nAbert2 - nAbert) > 0.05,.T.)
                        xRet += nFech - nAbert
                    //EndIf
                EndIf

                xRet -= QRYVEN->AFERIC
            
            //se retorna array de dados
            ElseIf ::nTRetVen == 2

                //Se houve manutenção de bomba no dia, considerar somente se houve abastecimento anterior a manutenção
                //DANILO/PABLO: adicionado "lSemMovDia .OR." no if, para considerar bicos sem movimentação
                If lSemMovDia .OR. (nAbert <> nAbert2 .And. (nAbert2 - nAbert <> nAbert2) .And. IIF(nAbert2 > 0,abs(nAbert2 - nAbert) > 0.05,.T.))
                    
                    nAferic := QRYVEN->AFERIC
                    //Se tem manutenção no dia, verifico se as afericoes sao desse bloco de encerrantes
                    if QRYVEN->AFERIC > 0 .AND. lManutDia
                        nAferic := ::RetAferic(QRYVEN->MIC_CODTAN,QRYVEN->MIC_CODBIC,nFech,nAbert)
                    endif
                    
                    aTmp := {}

                    //valores possíveis: {_TANQUE, _BICO, _NLOGIC, _BOMBA, _PROD, _FECH, _ABERT, _AFERIC, _VDBICO, _VDSUMMID}
                    for nI := 1 to len(::aCpRetVen)
                        DO CASE
                            CASE ::aCpRetVen[nI] == "_TANQUE"
                                aadd(aTmp, QRYVEN->MIC_CODTAN)
                            CASE ::aCpRetVen[nI] == "_BICO"
                                aadd(aTmp, QRYVEN->MIC_CODBIC)
                            CASE ::aCpRetVen[nI] == "_NLOGIC"
                                aadd(aTmp, QRYVEN->MIC_NLOGIC)
                            CASE ::aCpRetVen[nI] == "_BOMBA"
                                aadd(aTmp, QRYVEN->MIC_CODBOM)
                            CASE ::aCpRetVen[nI] == "_PROD"
                                //Indice 1: MHZ_FILIAL+MHZ_CODTAN
                                aadd(aTmp, Posicione("MHZ",1,xFilial("MHZ")+QRYVEN->MIC_CODTAN,"MHZ_CODPRO") )
                            CASE ::aCpRetVen[nI] == "_FECH"
                                aadd(aTmp, Round(nFech,3))
                            CASE ::aCpRetVen[nI] == "_ABERT"
                                aadd(aTmp, Round(nAbert,3))
                            CASE ::aCpRetVen[nI] == "_AFERIC"
                                aadd(aTmp, Round(nAferic,3))
                            CASE ::aCpRetVen[nI] == "_VDBICO"
                                aadd(aTmp, Round(nFech - nAbert - nAferic,3) )
                            CASE ::aCpRetVen[nI] == "_VDSUMMID"
                                aadd(aTmp, Round(QRYVEN->VDSUMMID,3) )
                            OTHERWISE
                                aadd(aTmp, Nil)
                        ENDCASE
                    next nI
                    aadd(aTmp, .F.) //deleted

                    aAdd(xRet, aTmp)

                EndIf

                If lManutDia
                    
                    nFech2 := ::RetFechM(QRYVEN->MIC_CODTAN,QRYVEN->MIC_CODBIC,QRYVEN->MIC_CODBOM,nFech)

                    If /*nAbert2 > 0 .And.*/ nFech2 > 0

                        //verifico se as afericoes sao desse bloco de encerrantes
                        nAferic := 0
                        if QRYVEN->AFERIC > 0 
                            nAferic := ::RetAferic(QRYVEN->MIC_CODTAN,QRYVEN->MIC_CODBIC,nFech2,nAbert2)
                        endif

                        //somente se teve movimentação após a manutenção do dia, que irei adicionar a linha
				        if (nFech2 - nAbert2) <> 0 .OR. nAferic > 0

                            aTmp := {}

                            //valores possíveis: {_TANQUE, _BICO, _NLOGIC, _BOMBA, _PROD, _FECH, _ABERT, _AFERIC, _VDBICO,_VDSUMMID}
                            for nI := 1 to len(::aCpRetVen)
                                DO CASE
                                    CASE ::aCpRetVen[nI] == "_TANQUE"
                                        aadd(aTmp, QRYVEN->MIC_CODTAN)
                                    CASE ::aCpRetVen[nI] == "_BICO"
                                        aadd(aTmp, QRYVEN->MIC_CODBIC)
                                    CASE ::aCpRetVen[nI] == "_NLOGIC"
                                        aadd(aTmp, QRYVEN->MIC_NLOGIC)
                                    CASE ::aCpRetVen[nI] == "_BOMBA"
                                        aadd(aTmp, QRYVEN->MIC_CODBOM)
                                    CASE ::aCpRetVen[nI] == "_PROD"
                                        //Indice 1: MHZ_FILIAL+MHZ_CODTAN
                                        aadd(aTmp, Posicione("MHZ",1,xFilial("MHZ")+QRYVEN->MIC_CODTAN,"MHZ_CODPRO") )
                                    CASE ::aCpRetVen[nI] == "_FECH"
                                        aadd(aTmp, Round(nFech2,3))
                                    CASE ::aCpRetVen[nI] == "_ABERT"
                                        aadd(aTmp, Round(nAbert2,3))
                                    CASE ::aCpRetVen[nI] == "_AFERIC"
                                        aadd(aTmp, Round(nAferic,3))
                                    CASE ::aCpRetVen[nI] == "_VDBICO"
                                        aadd(aTmp, Round(nFech2 - nAbert2 - nAferic,3) )
                                    CASE ::aCpRetVen[nI] == "_VDSUMMID"
                                        aadd(aTmp, Round(QRYVEN->VDSUMMID,3) )
                                    OTHERWISE
                                        aadd(aTmp, Nil)
                                ENDCASE
                            next nI
                            aadd(aTmp, .F.) //deleted

                            aAdd(xRet, aTmp)
                        endif

                    EndIf
                EndIf

            EndIf

            QRYVEN->(DbSkip())
        EndDo

    EndIf

    If Select("QRYVEN") > 0
        QRYVEN->(DbCloseArea())
    EndIf

return xRet

/*/{Protheus.doc} RetManut
Retorna se houve manutenção de bomba para o bico

@author Danilo Brito
@since 06/08/2020
@version 1.0
@return Nil
@type function
/*/
method RetManut(nTp,cBomba,cBico,nAbertura) class TLmcLib

    Local lRet 	:= .F.

	Local cQry 	:= ""
	Local cQry2	:= ""

	If Select("QRYU00") > 0
		QRYU00->(DbCloseArea())
	EndIf

	cQry := "SELECT U00_NUMSEQ"
	cQry += CRLF + " FROM " +RetSqlName("U00")"
	cQry += CRLF + " WHERE D_E_L_E_T_	<> '*'"
	cQry += CRLF + " AND U00_FILIAL 	= '"+xFilial("U00")+"'"
	cQry += CRLF + " AND U00_BOMBA 	= '"+cBomba+"'"

	If nTp == 1 //Houve manutenção
		cQry += CRLF + " AND U00_DTINT < '"+DTOS(::dData)+"'"
	Else //Manutenção na data do LMC
		cQry += CRLF + " AND U00_DTINT = '"+DTOS(::dData)+"'"
	EndIf

	cQry += CRLF + "ORDER BY 1 DESC"

	cQry := ChangeQuery(cQry)
	TcQuery cQry New Alias "QRYU00"

	If QRYU00->(!EOF())

		If Select("QRYBICO") > 0
			QRYBICO->(DbCloseArea())
		EndIf

		cQry2 := "SELECT U02_ENCANT,U02_ENCATU"
		cQry2 += " FROM "+RetSqlName("U02")+" U02"
		cQry2 += " WHERE D_E_L_E_T_	<> '*'"
		cQry2 += " AND U02_FILIAL 	= '"+xFilial("U02")+"'" 
		cQry2 += " AND U02_NUMSEQ 	= '"+QRYU00->U00_NUMSEQ+"'"
		cQry2 += " AND U02_BICO		= '"+cBico+"'"

		cQry2 := ChangeQuery(cQry2)
		TcQuery cQry2 NEW Alias "QRYBICO"

		If QRYBICO->(!EOF())

            If nAbertura <= 0 //não teve movimento do dia
                nAbManut 	:= QRYBICO->U02_ENCATU //QRYBICO->U02_ENCANT (TODO: considera encerrante atual ou anterior ?)
				nAbManut2	:= QRYBICO->U02_ENCATU
		    ElseIf nAbertura < QRYBICO->U02_ENCANT
				nAbManut 	:= nAbertura
				nAbManut2	:= QRYBICO->U02_ENCATU
			Else
				nAbManut := QRYBICO->U02_ENCATU
			EndIf

			If nTp == 2
                If nAbertura <= 0 //não teve movimento do dia
                    nFcManut := QRYBICO->U02_ENCATU //QRYBICO->U02_ENCANT (TODO: considera encerrante atual ou anterior ?)
                Else
				    nFcManut := QRYBICO->U02_ENCANT
                EndIf
			EndIf

			lRet := .T.
		EndIf
	EndIf

	If Select("QRYU00") > 0
		QRYU00->(DbCloseArea())
	EndIf

	If Select("QRYBICO") > 0
		QRYBICO->(DbCloseArea())
	EndIf

return lRet


/*/{Protheus.doc} RetAbManut
Retorna maior encerrante ultimo dia anterior

@author Danilo Brito
@since 06/08/2020
@version 1.0
@return Nil
@type function
/*/
method RetAbManut(cTq,cBico,cBomba) class TLmcLib

    Local cQry := ""
    Local nRet := 0

    If Select("QRYABERT") > 0
        QRYABERT->(dbCloseArea())
    EndIf

    cQry := "SELECT MAX(MID_ENCFIN) ABERT"
    cQry += CRLF + " FROM "+RetSqlName("MID")+""
    cQry += CRLF + " WHERE D_E_L_E_T_ <> '*'"
    cQry += CRLF + " AND MID_FILIAL	= '"+xFilial("MID")+"'"
    cQry += CRLF + " AND MID_XPROD	= '"+::cProd+"'"
    cQry += CRLF + " AND MID_DATACO	< '"+DTOS(::dData)+"'"
    cQry += CRLF + " AND MID_CODTAN	= '"+cTq+"'"
    cQry += CRLF + " AND MID_CODBIC	= '"+cBico+"'"
    cQry += CRLF + " AND MID_DATACO	> (SELECT MAX(U00_DTINT)
    cQry += CRLF + " 						FROM " +RetSqlName("U00")"
    cQry += CRLF + " 						WHERE D_E_L_E_T_	<> '*'"
    cQry += CRLF + " 						AND U00_FILIAL 	= '"+xFilial("U00")+"'"
    cQry += CRLF + " 						AND U00_DTINT 	< '"+DTOS(::dData)+"'"
    cQry += CRLF + " 						AND U00_BOMBA 	= '"+cBomba+"'""
    cQry += CRLF + "						)"

    cQry := ChangeQuery(cQry)
    TcQuery cQry New Alias "QRYABERT"

    If QRYABERT->(!EOF())
        nRet := QRYABERT->ABERT
    EndIf

    If Select("QRYABERT") > 0
        QRYABERT->(dbCloseArea())
    EndIf

Return nRet


/*/{Protheus.doc} RetFechM
Retorna maior encerrante ultimo dia anterior

@author Danilo Brito
@since 06/08/2020
@version 1.0
@return Nil
@type function
/*/
method RetFechM(cTq,cBico,cBomba,nFech) class TLmcLib

    Local cQry := ""
    Local nRet := 0

    If Select("QRYFECH") > 0
        QRYFECH->(dbCloseArea())
    EndIf

    cQry := "SELECT MID_ENCFIN FECH"
    cQry += CRLF + " FROM "+RetSqlName("MID")+""
    cQry += CRLF + " WHERE D_E_L_E_T_ <> '*'"
    cQry += CRLF + " AND MID_FILIAL	= '"+xFilial("MID")+"'"
    cQry += CRLF + " AND MID_XPROD	= '"+::cProd+"'"
    cQry += CRLF + " AND MID_DATACO	= '"+DTOS(::dData)+"'"
    cQry += CRLF + " AND MID_CODTAN	= '"+cTq+"'"
    cQry += CRLF + " AND MID_CODBIC	= '"+cBico+"'"
    cQry += CRLF + " AND MID_ENCFIN	<> "+cValToChar(nFech)+""
    cQry += CRLF + " AND MID_CODABA	= (SELECT MAX(MID_CODABA)
    cQry += CRLF + " 						FROM " +RetSqlName("MID")"
    cQry += CRLF + " 						WHERE D_E_L_E_T_	<> '*'"
    cQry += CRLF + " 						AND MID_FILIAL		= '"+xFilial("MID")+"'"
    cQry += CRLF + " 						AND MID_XPROD		= '"+::cProd+"'"
    cQry += CRLF + " 						AND MID_DATACO		= '"+DTOS(::dData)+"'"
    cQry += CRLF + " 						AND MID_CODTAN		= '"+cTq+"'"
    cQry += CRLF + " 						AND MID_CODBIC		= '"+cBico+"'"
    cQry += CRLF + "						)"

    cQry := ChangeQuery(cQry)
    TcQuery cQry New Alias "QRYFECH"

    If QRYFECH->(!EOF())
        nRet := QRYFECH->FECH
    EndIf

    If Select("QRYFECH") > 0
        QRYFECH->(DbCloseArea())
    EndIf

Return nRet

/*/{Protheus.doc} RetAferic
Retorna as aferições que teve entre os encerrantes informados

@author Danilo Brito
@since 06/11/2020
@version 1.0
@return Nil
@type function
/*/
method RetAferic(cTq,cBico,nFech,nAbert) class TLmcLib

    Local cQry := ""   
    Local nRet := 0 

    If Select("QRYAFER") > 0
        QRYAFER->(dbCloseArea())
    Endif

    cQry += CRLF + " SELECT SUM(MID_LITABA) AS AFERIC "
    cQry += CRLF + " FROM "+RetSqlName("MID")+""
    cQry += CRLF + " WHERE D_E_L_E_T_ <> '*'"
    cQry += CRLF + " AND MID_FILIAL	= '"+xFilial("MID")+"'"
    cQry += CRLF + " AND MID_XPROD	= '"+::cProd+"'"
    cQry += CRLF + " AND MID_DATACO	= '"+DTOS(::dData)+"'"
    cQry += CRLF + " AND MID_CODTAN	= '"+cTq+"'"
    cQry += CRLF + " AND MID_CODBIC	= '"+cBico+"'"
    cQry += CRLF + " AND MID_AFERIR	= 'S'" //Aferição
    cQry += CRLF + " AND MID_ENCFIN	>= "+cValToChar(nAbert)+""
    cQry += CRLF + " AND MID_ENCFIN	<= "+cValToChar(nFech)+""

    cQry := ChangeQuery(cQry)
    TcQuery cQry New Alias "QRYAFER"

    If QRYAFER->(!EOF())    	
        nRet := QRYAFER->AFERIC
    Endif

    If Select("QRYAFER") > 0
        QRYAFER->(dbCloseArea())
    Endif

Return nRet

/*/{Protheus.doc} RetVenU0I
Busca Dados de Venda do LMC, ja gravados na tabela U0I-Historico

@author Danilo Brito
@since 06/08/2020
@version 1.0
@return Nil
@type function
/*/
method RetVenU0I() class TLmcLib

    Local xRet
    Local aTmp := {}
    Local nI
    Local cSeekBico := ""
    Local cFilTq := ""

    //tratando tanques para query
    If len(::aTq) == 1
        cSeekBico := ::aTq[1]
        If !empty(::cBico)
            cSeekBico += ::cBico
        EndIf
    ElseIf len(::aTq) > 0
        cFilTq += "U0I->U0I_TANQUE $ '"
        For nI := 1 To Len(::aTq)
            cFilTq += "" + ::aTq[nI] + "/"
        Next nI
        cFilTq += "' "
        If !empty(::cBico)
            cFilTq += " .AND. U0I->U0I_BICO == '" + ::cBico + "'"
        EndIf
    EndIf

    //1=Vlr Total Vendas; 2=Array Dados; 3=Qtd Registros
    If ::nTRetVen == 2
        xRet := {}
    Else
        xRet := 0
    EndIf

    DbSelectArea("U0I")
    U0I->(DbSetOrder(1)) //U0I_FILIAL+DTOS(U0I_DATA)+U0I_PROD+U0I_TANQUE+U0I_BICO
    If U0I->(DbSeek(xFilial("U0I")+DTOS(::dData)+::cProd+cSeekBico ))
        While U0I->(!Eof()) .AND. U0I->(U0I_FILIAL+DTOS(U0I_DATA)+U0I_PROD) == xFilial("U0I")+DTOS(::dData)+::cProd ;
            .AND. (empty(cSeekBico) .OR. U0I->U0I_TANQUE+iif(!empty(::cBico),U0I->U0I_BICO,"") == cSeekBico) 

            If U0I->U0I_ATUALI == "X" //ignora os marcados com X (atualizado removido)
                U0I->(DbSkip())
                LOOP
            EndIf

            //sem filtro ou que atenda ao filtro
            If empty(cFilTq) .OR. &(cFilTq)

                If ::nTRetVen == 1
                    If U0I->U0I_ATUALI == "S"
                        xRet += U0I->U0I_NEWVDB
                    Else
                        xRet += U0I->U0I_VDBICO
                    EndIf

                ElseIf ::nTRetVen == 2

                    aTmp := {}

                    //valores possíveis: {_TANQUE, _BICO, _NLOGIC, _BOMBA, _PROD, _FECH, _ABERT, _AFERIC, _VDBICO, ou U0I_*}
                    for nI := 1 to len(::aCpRetVen)
                        DO CASE
                            CASE ::aCpRetVen[nI] == "_TANQUE"
                                aadd(aTmp, U0I->U0I_TANQUE )
                            CASE ::aCpRetVen[nI] == "_BICO"
                                aadd(aTmp, U0I->U0I_BICO )
                            CASE ::aCpRetVen[nI] == "_NLOGIC"
                                aadd(aTmp, U0I->U0I_NLOGIC )
                            CASE ::aCpRetVen[nI] == "_BOMBA"
                                aadd(aTmp, U0I->U0I_BOMBA )
                            CASE ::aCpRetVen[nI] == "_PROD"
                                aadd(aTmp, U0I->U0I_PROD )
                            CASE ::aCpRetVen[nI] == "_FECH"
                                aadd(aTmp, iif(U0I->U0I_ATUALI == "S", Round(U0I->U0I_NEWEF, 3), Round(U0I->U0I_ENCFEC, 3) ) )
                            CASE ::aCpRetVen[nI] == "_ABERT"
                                aadd(aTmp, iif(U0I->U0I_ATUALI == "S", Round(U0I->U0I_NEWEA, 3), Round(U0I->U0I_ENCABE, 3) ) )
                            CASE ::aCpRetVen[nI] == "_AFERIC"
                                aadd(aTmp, iif(U0I->U0I_ATUALI == "S", Round(U0I->U0I_NEWAFE, 3), Round(U0I->U0I_AFERIC, 3) ) )
                            CASE ::aCpRetVen[nI] == "_VDBICO"
                                aadd(aTmp, iif(U0I->U0I_ATUALI == "S", Round(U0I->U0I_NEWVDB, 3), Round(U0I->U0I_VDBICO, 3) ) )
                            CASE ::aCpRetVen[nI] == "_VDSUMMID" //nao é pra usar nesse contexto, por segurança coloquei zero
                                aadd(aTmp, 0 )
                            OTHERWISE
                                aadd(aTmp, U0I->&(::aCpRetVen[nI]))
                        ENDCASE
                    next nI
                    aadd(aTmp, .F.) //deleted

                    aAdd(xRet, aTmp)

                Else
                    xRet++
                EndIf
            EndIf

            U0I->(DbSkip())
        Enddo
    EndIf

Return xRet
